#!/usr/bin/env python3
"""Merges main into next after every push to main; docs/source-build.md has the rules."""
from __future__ import annotations

import json
import os
import subprocess
import sys
import time

WORKFLOWS = ".github/workflows"
BLOCKED = "Sync next is blocked"
BOT = "github-actions[bot]"


class SyncError(Exception):
    """A state the sync leaves to a person, saying what to do about it."""


class Issues:
    """The one open issue that says a sync is waiting on a person, through the gh CLI."""

    def __init__(self, repo: str, run_url: str):
        self.repo = repo
        self.run_url = run_url

    def _api(self, path: str, method: str = "GET", fields: dict[str, str] | None = None):
        """One REST call on the repository, its JSON answer or None."""
        args = ["gh", "api", "-X", method, f"repos/{self.repo}/{path}"]
        for key, value in (fields or {}).items():
            args += ["-f", f"{key}={value}"]
        out = subprocess.run(args, check=True, capture_output=True, text=True).stdout
        return json.loads(out) if out.strip() else None

    def blocked(self) -> int | None:
        """The open blocked-sync issue this workflow opened, all pages read, or None."""
        page = 1
        while issues := self._api(f"issues?state=open&per_page=100&page={page}"):
            for issue in issues:
                if issue["title"] == BLOCKED and issue["user"]["login"] == BOT and "pull_request" not in issue:
                    return issue["number"]
            page += 1
        return None

    def report(self, reason: str) -> None:
        """Opens the blocked-sync issue, or adds this run's reason to the open one."""
        text = f"{reason}\n\nRun: {self.run_url}"
        number = self.blocked()
        if number is None:
            body = f"Sync next couldn't merge `main` into `next`: {text}\n\nThe next clean run closes this issue."
            self._api("issues", "POST", {"title": BLOCKED, "body": body})
        else:
            self._api(f"issues/{number}/comments", "POST", {"body": text})

    def resolve(self, done: str) -> None:
        """Closes the blocked-sync issue, if one is open, saying what cleared it."""
        number = self.blocked()
        if number is not None:
            self._api(f"issues/{number}/comments", "POST", {"body": f"Cleared: {done}. Run: {self.run_url}"})
            self._api(f"issues/{number}", "PATCH", {"state": "closed"})


def git(repo: str, *args: str, check: bool = True) -> subprocess.CompletedProcess:
    """One git command in repo, its output captured."""
    return subprocess.run(["git", "-C", repo, *args], check=check, capture_output=True, text=True)


def sync(repo: str = ".", attempts: int = 3, wait: float = 5.0) -> str:
    """Merges origin/main into next and pushes it when that is clean, and says what it did."""
    failure = ""
    for attempt in range(attempts):
        if attempt:
            time.sleep(wait * 2 ** (attempt - 1))
        fetched = git(repo, "fetch", "--quiet", "origin", "main", "next", check=False)
        if fetched.returncode != 0:
            failure = f"fetching main and next failed: {fetched.stderr.strip()}"
            continue
        if git(repo, "merge-base", "--is-ancestor", "origin/main", "origin/next", check=False).returncode == 0:
            return "next already holds everything on main"

        checked_out = git(repo, "checkout", "--quiet", "--force", "-B", "next", "origin/next", check=False)
        if checked_out.returncode != 0:
            failure = f"checking out next failed: {checked_out.stderr.strip()}"
            continue
        merged = git(repo, "merge", "--no-ff", "--no-edit", "origin/main", check=False)
        if merged.returncode != 0:
            conflicts = git(repo, "diff", "--name-only", "--diff-filter=U").stdout.split()
            git(repo, "merge", "--abort", check=False)
            if conflicts:
                raise SyncError(
                    f"merging main into next conflicts in {', '.join(conflicts)}; merge main into next by hand, "
                    "resolve them there and push next"
                )
            failure = f"merging main into next failed: {(merged.stderr or merged.stdout).strip()}"
            continue

        workflows = git(repo, "diff", "--name-only", "origin/next", "HEAD", "--", WORKFLOWS).stdout.split()
        if workflows:
            raise SyncError(
                f"main changes {', '.join(workflows)}, which this run's token can't push; merge main into next by "
                "hand and push next"
            )

        pushed = git(repo, "push", "origin", "HEAD:next", check=False)
        if pushed.returncode == 0:
            return f"merged main ({git(repo, 'rev-parse', '--short=8', 'origin/main').stdout.strip()}) into next"
        refetched = git(repo, "fetch", "--quiet", "origin", "next", check=False).returncode == 0
        moved = refetched and git(repo, "rev-parse", "origin/next").stdout != git(repo, "rev-parse", "HEAD^1").stdout
        failure = "next moved while this ran" if moved else f"pushing to next failed: {pushed.stderr.strip()}"
    raise SyncError(f"{failure} (gave up after {attempts} attempts; the daily run tries again)")


def annotation(message: str) -> str:
    """An Actions error annotation that keeps every line of message."""
    return "::error::" + message.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def tell(issues: Issues | None, action: str, text: str) -> None:
    """Updates the blocked-sync issue, as a warning when GitHub refuses, so the sync's result stands."""
    if issues:
        try:
            getattr(issues, action)(text)
        except subprocess.CalledProcessError as error:
            print(f"::warning::couldn't {action} the {BLOCKED!r} issue: {(error.stderr or '').strip()}")


def run(issues: Issues | None, attempt=sync) -> int:
    """Syncs next and keeps the blocked-sync issue and the job summary in step with the result."""
    try:
        done = attempt()
    except SyncError as error:
        print(annotation(str(error)))
        if summary := os.environ.get("GITHUB_STEP_SUMMARY"):
            with open(summary, "a") as handle:
                handle.write(f"### {BLOCKED}\n\n{error}\n")
        tell(issues, "report", str(error))
        return 1
    except subprocess.CalledProcessError as error:
        print(annotation(f"git {' '.join(error.cmd[3:])} failed: {(error.stderr or '').strip()}"))
        return 1
    print(done)
    tell(issues, "resolve", done)
    return 0


def main() -> int:
    """Syncs the workflow's repository, reporting a blocked sync as an issue."""
    repo = os.environ.get("REPO")
    return run(Issues(repo, os.environ.get("RUN_URL", "")) if repo else None)


if __name__ == "__main__":
    sys.exit(main())
