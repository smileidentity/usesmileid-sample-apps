#!/usr/bin/env python3
"""Copies spec/catalogue-fixture.json into the apps whose bundler cannot read outside their own tree.

Android and iOS bundle the spec file straight from the build; Flutter's asset list and Metro's
resolver only see files under the app, so those two ship a byte-identical copy that this keeps honest.

    scripts/sync_catalogue_fixture.py            # rewrite the copies
    scripts/sync_catalogue_fixture.py --check    # fail if any copy is stale
"""
from __future__ import annotations

import argparse
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(REPO, "spec", "catalogue-fixture.json")
TARGETS = [
    os.path.join(REPO, "flutter", "app", "assets", "catalogue-fixture.json"),
    os.path.join(REPO, "expo", "app", "assets", "catalogue-fixture.json"),
]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="compare instead of writing")
    args = parser.parse_args()
    with open(SOURCE, "rb") as handle:
        source = handle.read()
    stale = []
    for target in TARGETS:
        current = open(target, "rb").read() if os.path.isfile(target) else None
        if current == source:
            continue
        if args.check:
            stale.append(os.path.relpath(target, REPO))
            continue
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with open(target, "wb") as handle:
            handle.write(source)
        print(f"wrote {os.path.relpath(target, REPO)}")
    if stale:
        print(f"{', '.join(stale)} stale: run scripts/sync_catalogue_fixture.py", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
