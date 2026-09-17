#!/usr/bin/env python3
"""Vendor design/icons/ into the Flutter package and name each one in Dart.

Flutter renders the design's SVGs directly, so this copies them BYTE FOR BYTE rather than
converting: the Android and iOS generators convert because a VectorDrawable and a SwiftUI
shape are different formats, and every conversion is a chance to drift. A byte copy cannot.
The source colour in each file is irrelevant — every call site tints through a colour filter,
exactly as the Compose twin tints its drawables.

The Dart side is generated too, so a missing or renamed icon is a compile error rather than a
blank square at runtime, which is what `R.drawable.*` gives the Compose twin for free.

    scripts/generate_flutter_icons.py            # vendor and generate
    scripts/generate_flutter_icons.py --check    # fail if any output is stale, missing or unsourced
"""

from __future__ import annotations

import argparse
import io
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ICON_DIR = "design/icons"
MATERIAL_DIR = "design/icons/material-symbols"

FLUTTER_UI = "flutter/sample_ui"
ASSET_DIR = f"{FLUTTER_UI}/assets/icons"
DART_OUT = f"{FLUTTER_UI}/lib/src/tokens/smile_icons.dart"

HEADER = """// Smile ID icon set — GENERATED. Do not edit by hand.
//
// Regenerate with: scripts/generate_flutter_icons.py
// Source: design/icons/, vendored byte for byte; every call site tints through a colour filter.
//
// TWO families, deliberately not interchangeable — see spec/components.json → conventions.

// ignore_for_file: public_member_api_docs
"""


class IconError(RuntimeError):
    """An icon the generator cannot name or source. Fails the run rather than being skipped."""


def dart_name(svg_name: str) -> str:
    """`arrow_back` -> `arrowBack`, matching every other generated Dart identifier."""
    head, *rest = svg_name.split("_")
    return head + "".join(part.capitalize() for part in rest)


def sources() -> dict[str, tuple[str, str]]:
    """Every icon, mapped to its source path and the asset path it is vendored to."""
    found: dict[str, tuple[str, str]] = {}
    for source_dir, prefix in ((ICON_DIR, ""), (MATERIAL_DIR, "material-symbols/")):
        absolute = os.path.join(REPO, source_dir)
        if not os.path.isdir(absolute):
            raise IconError(f"{source_dir} is missing; the shared icon record is the only source")
        for entry in sorted(os.listdir(absolute)):
            if not entry.endswith(".svg"):
                continue
            name = entry[: -len(".svg")]
            if not re.fullmatch(r"[a-z][a-z0-9_]*", name):
                raise IconError(f"{source_dir}/{entry} is not a lower_snake_case name")
            key = dart_name(name if not prefix else f"material_{name}")
            if key in found:
                raise IconError(f"two icons resolve to the Dart name {key!r}")
            found[key] = (os.path.join(source_dir, entry), f"{prefix}{entry}")
    if not found:
        raise IconError("no icons found; the shared record cannot be empty")
    return found


def emit_dart(icons: dict[str, tuple[str, str]]) -> str:
    """One constant per icon, addressed through the package that ships it."""
    lines = [
        HEADER,
        "/// Every icon in the shared record, addressed through the package so no host declares them.",
        "abstract final class SmileIcons {",
        "  static const String _base = 'packages/sample_ui/assets/icons';",
        "",
    ]
    for key, (_, asset) in icons.items():
        lines.append(f"  static const String {key} = '$_base/{asset}';")
    lines += [
        "",
        "  /// All of them, which the generator's test counts against the shared record.",
        "  static const List<String> all = <String>[",
    ]
    lines += [f"    {key}," for key in icons]
    lines += ["  ];", "}", ""]
    return "\n".join(lines)


def dart_formatted(content: str) -> str:
    """Emit what `dart format` would, or the generator and the formatter fight over the file.

    Without this, `--check` passes or fails depending on which of the two ran last.
    """
    if not shutil.which("dart"):
        return content
    with tempfile.TemporaryDirectory() as tmp:
        path = os.path.join(tmp, "smile_icons.dart")
        with io.open(path, "w", encoding="utf-8") as handle:
            handle.write(content)
        result = subprocess.run(["dart", "format", path], capture_output=True, text=True, check=False)
        if result.returncode != 0:
            raise IconError(
                "dart format rejected the generated source, which means the emitter produced "
                "invalid Dart:\n" + (result.stderr or result.stdout).strip()[:800]
            )
        with io.open(path, encoding="utf-8") as handle:
            return handle.read()


def write_text(rel_path: str, content: str, check: bool) -> bool:
    target = os.path.join(REPO, rel_path)
    existing = None
    if os.path.isfile(target):
        with io.open(target, encoding="utf-8") as handle:
            existing = handle.read()
    if existing == content:
        print(f"  unchanged  {rel_path}")
        return True
    if check:
        print(f"  STALE      {rel_path}")
        return False
    os.makedirs(os.path.dirname(target), exist_ok=True)
    with io.open(target, "w", encoding="utf-8") as handle:
        handle.write(content)
    print(f"  {'updated' if existing else 'created'}    {rel_path}")
    return True


def write_bytes(rel_path: str, payload: bytes, check: bool) -> bool:
    """A byte comparison, so `--check` catches an icon re-exported upstream."""
    target = os.path.join(REPO, rel_path)
    existing = None
    if os.path.isfile(target):
        with open(target, "rb") as handle:
            existing = handle.read()
    if existing == payload:
        return True
    if check:
        print(f"  STALE      {rel_path}")
        return False
    os.makedirs(os.path.dirname(target), exist_ok=True)
    with open(target, "wb") as handle:
        handle.write(payload)
    print(f"  {'updated' if existing else 'created'}    {rel_path}")
    return True


def unsourced(icons: dict[str, tuple[str, str]]) -> list[str]:
    """A vendored file with no source is an icon nobody can regenerate."""
    expected = {asset for _, asset in icons.values()}
    absolute = os.path.join(REPO, ASSET_DIR)
    if not os.path.isdir(absolute):
        return []
    present = set()
    for root, _, files in os.walk(absolute):
        for name in files:
            present.add(os.path.relpath(os.path.join(root, name), absolute))
    return sorted(present - expected)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if any output is stale")
    args = parser.parse_args(argv)

    if not os.path.isdir(os.path.join(REPO, FLUTTER_UI)):
        print(f"  skipped    {DART_OUT} ({FLUTTER_UI} does not exist yet)")
        return 0

    try:
        icons = sources()
    except IconError as error:
        print(f"\n{error}", file=sys.stderr)
        return 1

    ok = True
    for _, (source, asset) in icons.items():
        with open(os.path.join(REPO, source), "rb") as handle:
            ok = write_bytes(f"{ASSET_DIR}/{asset}", handle.read(), args.check) and ok
    print(f"  vendored   {len(icons)} icons from {ICON_DIR}")

    ok = write_text(DART_OUT, dart_formatted(emit_dart(icons)), args.check) and ok

    stray = unsourced(icons)
    if stray:
        for name in stray:
            print(f"  UNSOURCED  {ASSET_DIR}/{name} (no file in {ICON_DIR} produces it)")
        ok = False

    if not ok:
        message = (
            "Icons are stale. Run scripts/generate_flutter_icons.py"
            if args.check
            else "Icon generation failed; see the messages above."
        )
        print(f"\n{message}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
