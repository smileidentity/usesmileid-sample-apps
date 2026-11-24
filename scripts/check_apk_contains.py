#!/usr/bin/env python3
"""Fails unless a release APK's code still names each given string, so a native piece R8 dropped cannot pass silently."""
from __future__ import annotations

import sys
import zipfile


def missing(apk: str, names: list[str]) -> list[str]:
    """The names no dex file in [apk] contains."""
    with zipfile.ZipFile(apk) as archive:
        dex = [archive.read(entry) for entry in archive.namelist() if entry.endswith(".dex")]
    if not dex:
        sys.exit(f"check_apk_contains: {apk} holds no dex file, so there is no code to check.")
    return [name for name in names if not any(name.encode() in body for body in dex)]


def main(argv: list[str]) -> int:
    apk, names = argv[0], argv[1:]
    absent = missing(apk, names)
    for name in absent:
        print(f"check_apk_contains: {apk} no longer names {name}; R8 or the build dropped it.", file=sys.stderr)
    return 1 if absent else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
