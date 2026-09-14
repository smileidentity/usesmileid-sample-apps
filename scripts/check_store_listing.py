#!/usr/bin/env python3
"""Check the App Store listing: copy within every limit, panels store-legal, art not stale.

Both stores truncate over-length copy silently instead of rejecting it, and App Store Connect
rejects a screenshot at the wrong size or carrying an alpha channel — all of which surface after
an upload is already accepted. Reading files needs no simulator, so `ios/verify.sh archive` runs
this before it builds and a hand-built archive is held to the same rule as a CI one.

Usage:
    scripts/check_store_listing.py           # report and exit non-zero on any problem
    scripts/check_store_listing.py --check   # the same; the flag matches the sibling scripts
"""
from __future__ import annotations

import argparse
import hashlib
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STORE = ROOT / "ios" / "store"

# App Store Connect's own limits, in characters.
LIMITS = {
    "name.txt": 30,
    "subtitle.txt": 30,
    "keywords.txt": 100,
    "promotional-text.txt": 170,
    "description.txt": 4000,
    "whats-new.txt": 4000,
    "review-notes.txt": 4000,
}

# The ios-phone preset. The frames are rendered at it too, so a recorder on a 2x device is caught
# here rather than shipping as visibly soft art that composes to the right size anyway.
PANEL_SIZE = (1320, 2868)

# capture comes from a device and is the one panel that may legitimately be absent; the five
# rendered ones may not. render-store-art.sh composes exactly this list, in this order.
REQUIRED_PANELS = ["products", "token_session", "verifications", "verification_details", "settings"]
OPTIONAL_PANELS = ["capture"]

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
# 4 and 6 carry an alpha channel outright; 3 is a palette, which carries one through a tRNS chunk.
ALPHA_COLOUR_TYPES = {3, 4, 6}

DEV_SHORTHAND = re.compile(r"\(#\d+\)|\[\d{4}-\d{2}-\d{2}\]")
EMOJI = re.compile("[\U0001f300-\U0001faff☀-➿]")


def png_header(path: Path) -> tuple[int, int, int]:
    """Width, height and colour type from IHDR, which is at a fixed offset in every valid PNG."""
    data = path.read_bytes()[:26]
    if len(data) < 26 or not data.startswith(PNG_SIGNATURE):
        raise ValueError(f"{path.name} is not a PNG")
    width, height = struct.unpack(">II", data[16:24])
    return width, height, data[25]


def check_copy(problems: list[str]) -> None:
    for name, limit in LIMITS.items():
        path = STORE / name
        if not path.exists():
            problems.append(f"{name} is missing")
            continue
        text = path.read_text(encoding="utf-8").strip("\n")
        if not text:
            problems.append(f"{name} is empty")
        if len(text) > limit:
            problems.append(f"{name} is {len(text)} characters, over the App Store's {limit}")
        if DEV_SHORTHAND.search(text):
            problems.append(f"{name} carries a PR number or a commit date")
        if EMOJI.search(text):
            problems.append(f"{name} carries an emoji")

    description_path = STORE / "description.txt"
    if not description_path.exists():
        return
    description = description_path.read_text(encoding="utf-8")
    if "SmartSelfie™ Enrollment" not in description:
        problems.append("description.txt must name the first product as the app's own list does")
    if "SmartSelfie™ Registration" in description:
        problems.append("description.txt uses docs-v3's name; the listing takes the app's, by owner ruling")


def check_images(problems: list[str], kind: str, directory: Path, suffix: str, *, alpha_ok: bool) -> list[str]:
    """Every panel or frame present is store-legal; returns the names found."""
    found = []
    for panel in REQUIRED_PANELS + OPTIONAL_PANELS:
        path = directory / f"{panel}{suffix}"
        if not path.exists():
            if panel in REQUIRED_PANELS:
                problems.append(f"{kind} {panel} is missing — run ios/store/render-store-art.sh")
            continue
        found.append(panel)
        try:
            width, height, colour = png_header(path)
        except ValueError as error:
            problems.append(str(error))
            continue
        if (width, height) != PANEL_SIZE:
            problems.append(f"{kind} {panel} is {width}x{height}, not the ios-phone preset")
        # Only the composed panels are uploaded. A frame is a simulator render and keeps its alpha;
        # storeshots flattens it on compose, which is the step that makes the panel store-legal.
        if colour in ALPHA_COLOUR_TYPES and not alpha_ok:
            problems.append(f"{kind} {panel} carries an alpha channel, which the App Store rejects")
    return found


def check_directory_holds_only_panels(problems: list[str], found: list[str]) -> None:
    """The review strip validates as nothing, so a listing built from this directory would break."""
    screenshots = STORE / "screenshots"
    if not screenshots.is_dir():
        problems.append("ios/store/screenshots is missing — run ios/store/render-store-art.sh")
        return
    actual = {p.name for p in screenshots.iterdir() if not p.name.startswith(".")}
    expected = {f"{panel}.png" for panel in found}
    for extra in sorted(actual - expected):
        problems.append(f"ios/store/screenshots holds {extra}, which is not a panel")


def check_lock(problems: list[str], frames: list[str]) -> None:
    """The panels are rendered from the frames, so a frame that moved without a re-render is stale art."""
    lock = STORE / "panels.lock"
    if not lock.exists():
        problems.append("ios/store/panels.lock is missing — run ios/store/render-store-art.sh")
        return
    recorded = {}
    for line in lock.read_text(encoding="utf-8").splitlines():
        parts = line.split()
        if len(parts) == 2:
            recorded[parts[1]] = parts[0]

    # Asserted rather than iterated: a lock written while a frame was missing lists fewer entries,
    # every one of which matches, so iterating it alone would pass on stale art.
    if set(recorded) != {f"{frame}.frame.png" for frame in frames}:
        problems.append("ios/store/panels.lock does not cover exactly the recorded frames")
        return

    for name, expected in recorded.items():
        digest = hashlib.sha256((STORE / "frames" / name).read_bytes()).hexdigest()
        if digest != expected:
            problems.append(f"{name} changed since the panels were rendered — re-run render-store-art.sh")


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="accepted for symmetry with the sibling scripts")
    parser.parse_args(argv)

    problems: list[str] = []
    check_copy(problems)
    frames = check_images(problems, "frame", STORE / "frames", ".frame.png", alpha_ok=True)
    panels = check_images(problems, "panel", STORE / "screenshots", ".png", alpha_ok=False)
    check_directory_holds_only_panels(problems, panels)
    check_lock(problems, frames)

    if problems:
        for problem in problems:
            print(f"store listing: {problem}", file=sys.stderr)
        return 1
    print(f"    {len(panels)} panels, {len(LIMITS)} copy fields, art current")
    return 0


if __name__ == "__main__":
    sys.exit(main())
