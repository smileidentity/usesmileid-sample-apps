#!/usr/bin/env python3
"""Fails unless every Gradle build that reads Central's snapshots repository limits it to com.usesmileid."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUILDS = ("android/settings.gradle.kts", "flutter/app/android/build.gradle.kts")
SNAPSHOTS = "central.sonatype.com/repository/maven-snapshots"
FILTER = re.compile(r'content\s*\{\s*includeGroup\(\s*"com\.usesmileid"\s*\)\s*\}')


def block_after(text: str, start: int) -> str:
    """The repository's own `{ … }` block that follows its URL."""
    opening = text.find("{", start)
    if opening < 0:
        return ""
    depth = 0
    for index in range(opening, len(text)):
        depth += {"{": 1, "}": -1}.get(text[index], 0)
        if depth == 0:
            return text[opening : index + 1]
    return ""


def problems(text: str) -> list[str]:
    """Why a build's snapshots repository is unsafe, or nothing when it serves only Smile ID."""
    found = [match.start() for match in re.finditer(re.escape(SNAPSHOTS), text)]
    if not found:
        return ["it has no snapshots repository, so a snapshot pin can't resolve"]
    return [
        "its snapshots repository serves more than com.usesmileid"
        for start in found
        if not FILTER.fullmatch(block_after(text, start)[1:-1].strip())
    ]


def main() -> int:
    failed = False
    for build in BUILDS:
        for problem in problems((ROOT / build).read_text()):
            print(f"{build}: {problem}; add content {{ includeGroup(\"com.usesmileid\") }}", file=sys.stderr)
            failed = True
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
