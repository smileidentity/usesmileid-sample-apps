#!/usr/bin/env python3
"""Merges main into next after every push to main; docs/source-build.md has the rules."""
from __future__ import annotations

import subprocess
import sys


class SyncError(Exception):
    """A state the sync leaves to a person, saying what to do about it."""


def git(repo: str, *args: str, check: bool = True) -> subprocess.CompletedProcess:
    """One git command in repo, its output captured."""
    return subprocess.run(["git", "-C", repo, *args], check=check, capture_output=True, text=True)


def sync(repo: str = ".") -> str:
    """Merges origin/main into next and pushes it when that is clean, and says what it did."""
    git(repo, "fetch", "--quiet", "origin", "main", "next")
    if git(repo, "merge-base", "--is-ancestor", "origin/main", "origin/next", check=False).returncode == 0:
        return "next already holds everything on main"

    git(repo, "checkout", "--quiet", "-B", "next", "origin/next")
    if git(repo, "merge", "--no-ff", "--no-edit", "origin/main", check=False).returncode != 0:
        conflicts = git(repo, "diff", "--name-only", "--diff-filter=U").stdout.split()
        git(repo, "merge", "--abort", check=False)
        raise SyncError(
            f"merging main into next conflicts in {', '.join(conflicts) or 'the merge'}; merge main into next by "
            "hand, resolve them there and push next"
        )

    pushed = git(repo, "push", "origin", "HEAD:next", check=False)
    if pushed.returncode != 0:
        raise SyncError(f"next moved while this ran, so the merge wasn't pushed; run Sync next again: {pushed.stderr.strip()}")
    main_sha = git(repo, "rev-parse", "--short=8", "origin/main").stdout.strip()
    return f"merged main ({main_sha}) into next"


def main() -> int:
    """Syncs next, as an Actions error when it can't."""
    try:
        print(sync())
        return 0
    except SyncError as error:
        print(f"::error::{error}")
    except subprocess.CalledProcessError as error:
        print(f"::error::git refused {' '.join(error.cmd[3:5])}: {(error.stderr or '').strip()}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
