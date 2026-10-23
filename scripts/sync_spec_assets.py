#!/usr/bin/env python3
"""Copies the spec files an app bundles into the apps whose bundler cannot read outside their own tree.

Android and iOS bundle the spec files straight from the build; Flutter's asset list and Metro's
resolver only see files under the app, so those two ship byte-identical copies that this keeps honest.

    scripts/sync_spec_assets.py            # rewrite the copies
    scripts/sync_spec_assets.py --check    # fail if any copy is stale
"""
from __future__ import annotations

import argparse
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# The `catalogue=fixture` lists and the four apps' one navigation graph.
FILES = ["catalogue-fixture.json", "njia-graph.json"]
APPS = [os.path.join(REPO, "flutter", "app", "assets"), os.path.join(REPO, "expo", "app", "assets")]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="compare instead of writing")
    args = parser.parse_args()
    stale = []
    for name in FILES:
        with open(os.path.join(REPO, "spec", name), "rb") as handle:
            source = handle.read()
        stale += sync(source, [os.path.join(app, name) for app in APPS], args.check)
    if stale:
        print(f"{', '.join(stale)} stale: run scripts/sync_spec_assets.py", file=sys.stderr)
        return 1
    return 0


def sync(source: bytes, targets: list[str], check: bool) -> list[str]:
    """Writes `source` to each stale target, or with `check` only names them."""
    stale = []
    for target in targets:
        current = open(target, "rb").read() if os.path.isfile(target) else None
        if current == source:
            continue
        if check:
            stale.append(os.path.relpath(target, REPO))
            continue
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with open(target, "wb") as handle:
            handle.write(source)
        print(f"wrote {os.path.relpath(target, REPO)}")
    return stale


if __name__ == "__main__":
    sys.exit(main())
