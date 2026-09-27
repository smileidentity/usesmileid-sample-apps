#!/usr/bin/env python3
"""Chooses which Android device flows a change needs, and whether the release build must run them.

    git diff --name-only origin/main... | scripts/select_android_flows.py            # prints JSON
    scripts/select_android_flows.py --all                                            # the full suite

A path it cannot place runs the full suite: a flow skipped by mistake is a regression nobody sees,
and a flow run by mistake costs only minutes.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FLOWS_DIR = os.path.join(REPO, "android", "maestro")

# Keywords in a changed file's name, and the flows that exercise that code. First match wins.
RULES: tuple[tuple[str, tuple[str, ...]], ...] = (
    (r"deeplink|sheetlink|launchintent", ("deep-links", "launch-args")),
    (r"launcharg|seed|environment", ("launch-args", "token-session")),
    (r"profile", ("profiles", "profile-journey")),
    (r"token|qrscanner|camerahold|scan|sessioncard", ("token-session",)),
    (r"sdkflow|flow|preflight|userdetails|kycid|iddetails|idtype|country|product|forms|runintent|result",
     ("sdk-flow", "profile-journey", "launch-args")),
    (r"verification|job|status|selection|filterchip|swipe|dategroup|datafield", ("verifications",)),
    (r"setting|licen|scenario", ("settings",)),
    (r"shell|navigation|destinations|transition|chrome|graphs|navbar|systembars", ("shell-navigation", "deep-links")),
)

# A change here alters what the minified release build contains, so the release variant runs the suite.
PACKAGING = re.compile(
    r"(^|/)(build\.gradle\.kts|settings\.gradle\.kts|gradle\.properties|libs\.versions\.toml|"
    r"proguard[^/]*|consumer-rules\.pro|AndroidManifest\.xml|gradle-wrapper\.properties)$"
)

# Proven off the device: unit and golden tests, and prose.
NO_FLOW = re.compile(r"^android/[^/]+/src/(test|androidTest)/|\.md$|^android/play/|^android/verify\.sh$")


def all_flows() -> list[str]:
    """Every flow file at the top of the suite; `subflows/` is not a flow."""
    return sorted(name[:-5] for name in os.listdir(FLOWS_DIR) if name.endswith(".yaml"))


def select(paths: list[str], flows: list[str] | None = None) -> dict:
    """The flows and variant for these changed paths, with the reason the suite was widened, if it was."""
    flows = flows if flows is not None else all_flows()
    chosen: set[str] = set()
    variant = "debug"
    widened = None
    for path in (p.strip() for p in paths):
        if not path:
            continue
        if PACKAGING.search(path) and path.startswith("android/"):
            variant = "release"
            widened = widened or f"{path} changes packaging"
            continue
        if not (path.startswith("android/") or path.startswith("spec/")) or NO_FLOW.search(path):
            continue
        if path.startswith("spec/") or path.startswith("android/maestro/subflows/"):
            widened = widened or f"{path} is shared by every flow"
            continue
        match = re.fullmatch(r"android/maestro/([^/]+)\.yaml", path)
        if match and match.group(1) in flows:
            chosen.add(match.group(1))
            continue
        name = os.path.basename(path).lower()
        for pattern, targets in RULES:
            if re.search(pattern, name):
                chosen.update(targets)
                break
        else:
            widened = widened or f"{path} maps to no flow"
    if widened:
        return {"flows": flows, "variant": variant, "reason": widened}
    return {"flows": sorted(chosen & set(flows)), "variant": variant, "reason": "selected by path"}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--all", action="store_true", help="the full suite, in release")
    args = parser.parse_args()
    if args.all:
        result = {"flows": all_flows(), "variant": "release", "reason": "full suite requested"}
    else:
        result = select(sys.stdin.read().splitlines())
    print(json.dumps(result))
    return 0


if __name__ == "__main__":
    sys.exit(main())
