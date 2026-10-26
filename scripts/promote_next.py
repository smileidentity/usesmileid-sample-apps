#!/usr/bin/env python3
"""Opens the next-into-main pull request at an SDK release; docs/source-build.md has the rules."""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys

PREFIX = "sync/next-into-main-"
VERSION = re.compile(r"[0-9]+\.[0-9]+\.[0-9]+")


class PromoteError(Exception):
    """A state the promotion refuses, saying what to do about it."""


class GitHub:
    """The REST calls a promotion makes, through the gh CLI."""

    def __init__(self, repo: str):
        self.repo = repo

    def _api(self, path: str, method: str = "GET", fields: dict[str, str] | None = None):
        """One REST call on the repository, its JSON answer or None."""
        args = ["gh", "api", "-X", method, f"repos/{self.repo}/{path}"]
        for key, value in (fields or {}).items():
            args += ["-f", f"{key}={value}"]
        out = subprocess.run(args, check=True, capture_output=True, text=True).stdout
        return json.loads(out) if out.strip() else None

    def tree(self, ref: str) -> str:
        """The tree a branch's tip holds."""
        return self._api(f"commits/{ref}")["commit"]["tree"]["sha"]

    def changed(self, base: str, head: str) -> int:
        """How many files head changes since it and base last met."""
        return len(self._api(f"compare/{base}...{head}")["files"])

    def behind(self, base: str, head: str) -> int:
        """How many commits base has that head doesn't."""
        return self._api(f"compare/{base}...{head}")["behind_by"]

    def open_pulls(self) -> list[dict]:
        """Every open pull request into main, all pages."""
        pulls, page = [], 1
        while batch := self._api(f"pulls?base=main&state=open&per_page=100&page={page}"):
            pulls += batch
            page += 1
        return pulls

    def tip(self, branch: str) -> str | None:
        """The branch's commit, or None when it doesn't exist."""
        try:
            return self._api(f"git/ref/heads/{branch}")["object"]["sha"]
        except subprocess.CalledProcessError as error:
            if "HTTP 404" in (error.stderr or ""):
                return None
            raise

    def create_branch(self, branch: str, sha: str) -> None:
        """Starts a branch at sha."""
        self._api("git/refs", "POST", {"ref": f"refs/heads/{branch}", "sha": sha})

    def move_branch(self, branch: str, sha: str) -> None:
        """Moves a branch to sha, refused unless it fast-forwards."""
        self._api(f"git/refs/heads/{branch}", "PATCH", {"sha": sha})

    def open_pull(self, branch: str, title: str, body: str) -> int:
        """Opens a pull request from branch into main, returning its number."""
        return self._api("pulls", "POST", {"base": "main", "head": branch, "title": title, "body": body})["number"]

    def describe_pull(self, number: int, body: str) -> None:
        """Replaces a pull request's description."""
        self._api(f"pulls/{number}", "PATCH", {"body": body})

    def close_pull(self, number: int, branch: str, comment: str, delete_branch: bool) -> None:
        """Comments on and closes a pull request, deleting its branch when asked."""
        self._api(f"issues/{number}/comments", "POST", {"body": comment})
        self._api(f"pulls/{number}", "PATCH", {"state": "closed"})
        if delete_branch:
            self._api(f"git/refs/heads/{branch}", "DELETE")


def version_key(version: str) -> tuple[int, ...]:
    """A version as numbers, so 12.10.0 sorts above 12.5.0."""
    return tuple(int(part) for part in version.split("."))


def description(version: str, sha: str) -> str:
    """The promotion's pull request description."""
    return f"""## Why this change

{version} has shipped, so `main` takes the changes `next` held for it, and the SDK repositories can pin `main` again.

## Before merging

- [ ] Every lane this pull request starts passes, and every SDK version it pins is released.
- [ ] Nothing on `next` needs an SDK newer than {version}. If something does, leave this open; when that version ships, run Promote next with it, which replaces this pull request.
- [ ] No conflicts. If there are, merge `main` into `next` and run Promote next again; never resolve them on this branch.

## After merging

- Sync next merges `main` back into `next`; if its run fails on a conflict or a workflow change, merge them by hand.
- Run `bump_sample_apps.yaml` in each SDK repository, to pin `main`.

This branch is a copy of `next` at {sha[:8]}, so the branch deletion that follows the merge leaves `next` as it is.
"""


def promote(github: GitHub, version: str) -> str:
    """Opens or refreshes the promotion for version, replaces an older one, and says what it did."""
    if not VERSION.fullmatch(version):
        raise PromoteError(f"'{version}' is not a release version such as 12.4.0")
    if github.tree("main") == github.tree("next") or github.changed("main", "next") == 0:
        return "main already holds everything on next, so there is nothing to promote"

    branch = PREFIX + version
    promotions = {
        pull["head"]["ref"]: pull["number"]
        for pull in github.open_pulls()
        if (pull["head"].get("repo") or {}).get("full_name") == github.repo
        and pull["head"]["ref"].startswith(PREFIX)
        and VERSION.fullmatch(pull["head"]["ref"][len(PREFIX):])
    }
    older = {}
    for ref, number in promotions.items():
        other = ref[len(PREFIX):]
        if ref == branch:
            continue
        if version_key(other) > version_key(version):
            raise PromoteError(
                f"the {other} promotion (#{number}) is open, which is newer than {version}; run this with {other} "
                "or a later version, or close that pull request if it was opened by mistake"
            )
        older[ref] = number

    sha = github.tip("next")
    if github.tip(branch) is None:
        github.create_branch(branch, sha)
    elif github.behind(branch, "next") != 0:
        raise PromoteError(
            f"{branch} has commits next doesn't, such as a conflict resolution; close its pull request, delete the "
            "branch, resolve any conflict by merging main into next, then run this again"
        )
    else:
        github.move_branch(branch, sha)

    body = description(version, sha)
    if branch in promotions:
        github.describe_pull(promotions[branch], body)
        done = f"#{promotions[branch]} from {branch} was already open; its branch and description now match next"
    else:
        number = github.open_pull(branch, f"🔀 sync: next into main, now that {version} has shipped", body)
        done = f"opened #{number} from {branch}"

    # Replaced only now that this one is open, so a failure above never leaves no promotion at all.
    for ref, number in older.items():
        keep = github.behind(ref, "next") != 0
        comment = f"Replaced by the {version} promotion." + (" Its branch has commits next doesn't, so it stays." if keep else "")
        github.close_pull(number, ref, comment, delete_branch=not keep)
    return done


def main() -> int:
    """Promotes the release the workflow names, as an Actions error when it can't."""
    try:
        print(promote(GitHub(os.environ["REPO"]), os.environ["RELEASE"]))
        return 0
    except PromoteError as error:
        print(f"::error::{error}")
    except subprocess.CalledProcessError as error:
        print(f"::error::GitHub refused {' '.join(error.cmd[1:5])}: {(error.stderr or '').strip()}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
