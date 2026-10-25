#!/usr/bin/env python3
"""Merges main into next after every push to main; docs/source-build.md has the rules."""
from __future__ import annotations

import subprocess
import sys
import time


WORKFLOWS = ".github/workflows"


class SyncError(Exception):
    """A state the sync leaves to a person, saying what to do about it."""


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


def main() -> int:
    """Syncs next, as an Actions error when it can't."""
    try:
        print(sync())
        return 0
    except SyncError as error:
        print(annotation(str(error)))
    except subprocess.CalledProcessError as error:
        print(annotation(f"git {' '.join(error.cmd[3:])} failed: {(error.stderr or '').strip()}"))
    return 1


if __name__ == "__main__":
    sys.exit(main())
