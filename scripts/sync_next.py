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


def sync(repo: str = ".", attempts: int = 3) -> str:
    """Merges origin/main into next and pushes it when that is clean, and says what it did."""
    for _ in range(attempts):
        git(repo, "fetch", "--quiet", "origin", "main", "next")
        if git(repo, "merge-base", "--is-ancestor", "origin/main", "origin/next", check=False).returncode == 0:
            return "next already holds everything on main"

        git(repo, "checkout", "--quiet", "-B", "next", "origin/next")
        merged = git(repo, "merge", "--no-ff", "--no-edit", "origin/main", check=False)
        if merged.returncode != 0:
            conflicts = git(repo, "diff", "--name-only", "--diff-filter=U").stdout.split()
            git(repo, "merge", "--abort", check=False)
            if not conflicts:
                raise SyncError(f"merging main into next failed: {(merged.stderr or merged.stdout).strip()}")
            raise SyncError(
                f"merging main into next conflicts in {', '.join(conflicts)}; merge main into next by hand, "
                "resolve them there and push next"
            )

        pushed = git(repo, "push", "origin", "HEAD:next", check=False)
        if pushed.returncode == 0:
            return f"merged main ({git(repo, 'rev-parse', '--short=8', 'origin/main').stdout.strip()}) into next"
        git(repo, "fetch", "--quiet", "origin", "next")
        if git(repo, "rev-parse", "origin/next").stdout == git(repo, "rev-parse", "HEAD^1").stdout:
            raise SyncError(f"pushing to next failed, and next hasn't moved: {pushed.stderr.strip()}")
    raise SyncError(f"next moved during each of {attempts} attempts; run Sync next again once it settles")


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
