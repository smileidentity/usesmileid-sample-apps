#!/usr/bin/env python3
"""Bring the Smile ID design system's tokens into this repo.

The design system is distributed as an agent skill, not as a Maven / SPM / npm / pub
package, so there is no dependency to declare — the only way to consume it is to vendor
its generated output. This script does that in one command per platform, so refreshing
after a token change is repeatable rather than four manual copies.

Three platforms have upstream-generated output and are COPIED verbatim, keeping the
design system's own naming and conventions as the single source of truth:

    dist/android/SmileTokens.kt   -> android/sample-ui/.../SmileTokens.kt
    dist/ios/SmileTokens.swift    -> ios/SampleUI/.../SmileTokens.swift
    dist/ts/tokens.ts             -> expo/sample-ui/src/tokens.ts

Dart has no upstream target, so it is GENERATED here from the platform-neutral
dist/json/tokens.flat.json, mirroring the Compose emitter's naming (camelCase from the
token path, SmileColorLight / SmileColorDark / SmileDimens / SmileType).

One deliberate difference from Compose: that emitter leaves typography as comments
because Compose needs font resources wired first. Dart can express a TextStyle directly,
so text styles are emitted as real values.

Usage:
    scripts/sync_design_tokens.py --dart                  # generate Dart only (default)
    scripts/sync_design_tokens.py --all                   # Dart + copy the other three
    scripts/sync_design_tokens.py --design-system <path>  # override autodetection
    scripts/sync_design_tokens.py --check                  # fail if output is stale (CI)

Output is passed through `dart format` when the Dart SDK is on PATH, so the generator and
the formatter cannot disagree.
"""

from __future__ import annotations

import argparse
import io
import json
import os
import re
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Where the design system usually sits on a machine with the shared skills checked out.
DEFAULT_DS_PATHS = [
    "~/.claude/skills/smile-design-system",
    "~/.agents/skills/smile-design-system",
    "~/AndroidStudioProjects/SmileID/claude-skills/smile-design-system",
]

DART_OUT = "flutter/sample_ui/lib/src/tokens/smile_tokens.dart"
COPIES = [
    ("dist/android/SmileTokens.kt", "android/sample-ui/src/main/kotlin/com/usesmileid/sampleapps/ui/tokens/SmileTokens.kt"),
    ("dist/ios/SmileTokens.swift", "ios/SampleUI/Sources/SampleUI/Tokens/SmileTokens.swift"),
    ("dist/ts/tokens.ts", "expo/sample-ui/src/tokens.ts"),
]

# Token groups whose dimension values become SmileDimens entries (mirrors emitCompose).
DIMENSION_GROUPS = {"spacing", "radius", "size", "space", "border-width"}

HEADER = """// Smile ID Design System — GENERATED. Do not edit by hand.
//
// Regenerate with: scripts/sync_design_tokens.py --dart
// Source: the design system's dist/json/tokens.flat.json (fully resolved light + dark).
//
// Naming mirrors the Compose output (SmileColorLight / SmileColorDark / SmileDimens /
// SmileType) so the two platforms are diffable against each other.

import 'package:flutter/material.dart';
"""


def find_design_system(explicit: str | None) -> str:
    candidates = [explicit] if explicit else DEFAULT_DS_PATHS
    for c in candidates:
        if not c:
            continue
        p = os.path.realpath(os.path.expanduser(c))
        if os.path.isfile(os.path.join(p, "dist", "json", "tokens.flat.json")):
            return p
    sys.exit(
        "Could not find the design system. Pass --design-system <path> to the folder "
        "containing dist/json/tokens.flat.json.\nLooked in: " + ", ".join(DEFAULT_DS_PATHS)
    )


def camel(path: list[str]) -> str:
    """['color','text','title'] -> colorTextTitle; matches the Compose emitter."""
    parts: list[str] = []
    for seg in path:
        parts.extend(re.split(r"[-_ ]+", seg))
    head, *rest = [p for p in parts if p]
    return head[:1].lower() + head[1:] + "".join(p[:1].upper() + p[1:] for p in rest)


def is_type_leaf(node) -> bool:
    return isinstance(node, dict) and "fontSize" in node and "fontWeight" in node


def is_shadow_leaf(node) -> bool:
    """A composite shadow: {color, offsetX, offsetY, blur, spread}.

    These appear both as their own groups (shadow.card, elevation.floating) AND nested
    inside component groups (card.shadow, filter.popover-shadow), so they must be detected
    by SHAPE. Detecting by group name silently leaks their nested `color` into the colour
    classes, which is exactly how this generator first diverged from the Compose output.
    """
    return isinstance(node, dict) and "color" in node and ("offsetX" in node or "blur" in node)


def walk(node, path=None):
    """Yield (path, value) for every leaf. Typography and shadow composites are leaves."""
    path = path or []
    if isinstance(node, dict):
        if is_type_leaf(node) or is_shadow_leaf(node):
            yield path, node
            return
        for key, value in node.items():
            yield from walk(value, path + [key])
    else:
        yield path, node


RGBA = re.compile(r"rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*(?:,\s*([\d.]+)\s*)?\)")


def is_color(value) -> bool:
    if not isinstance(value, str):
        return False
    return bool(re.fullmatch(r"#[0-9a-fA-F]{6,8}", value) or RGBA.fullmatch(value))


def dart_color(value: str) -> str:
    """#rrggbb, #rrggbbaa or rgba(r,g,b,a) -> Color(0xAARRGGBB)."""
    match = RGBA.fullmatch(value)
    if match:
        r, g, b, a = match.groups()
        alpha = round(float(a) * 255) if a is not None else 255
        argb = f"{alpha:02X}{int(float(r)):02X}{int(float(g)):02X}{int(float(b)):02X}"
        return f"Color(0x{argb})"
    hex_digits = value.lstrip("#")
    if len(hex_digits) == 6:
        argb = "FF" + hex_digits
    else:  # css order is rrggbbaa, Flutter wants aarrggbb
        argb = hex_digits[6:8] + hex_digits[0:6]
    return f"Color(0x{argb.upper()})"


def px(value: str) -> str:
    number = float(re.sub(r"[a-z%]+$", "", str(value)) or 0)
    return str(int(number)) if number.is_integer() else str(number)


def ms(value: str) -> str:
    return px(value)


def dart_font_weight(weight) -> str:
    return f"FontWeight.w{int(weight)}"


def emit_colors(class_name: str, tokens: dict) -> str:
    lines = [f"abstract final class {class_name} {{"]
    for path, value in walk(tokens):
        if is_color(value):
            lines.append(f"  static const Color {camel(path)} = {dart_color(value)};")
    lines.append("}")
    return "\n".join(lines)


def emit_shadows(tokens: dict) -> str:
    """BoxShadows from every composite shadow token, wherever it lives — Compose omits these."""
    lines = ["abstract final class SmileShadows {"]
    for path, spec in walk(tokens):
        if is_shadow_leaf(spec):
            lines += [
                f"  static const BoxShadow {camel(path)} = BoxShadow(",
                f"    color: {dart_color(spec['color'])},",
                f"    offset: Offset({px(spec.get('offsetX', '0px'))}, {px(spec.get('offsetY', '0px'))}),",
                f"    blurRadius: {px(spec.get('blur', '0px'))},",
                f"    spreadRadius: {px(spec.get('spread', '0px'))},",
                "  );",
            ]
    lines.append("}")
    return "\n".join(lines)


def emit_dimens(tokens: dict) -> str:
    lines = ["abstract final class SmileDimens {"]
    for path, value in walk(tokens):
        if path[0] in DIMENSION_GROUPS and isinstance(value, str) and value.endswith("px"):
            lines.append(f"  static const double {camel(path)} = {px(value)};")
    lines.append("}")
    return "\n".join(lines)


def emit_durations(tokens: dict) -> str:
    lines = ["abstract final class SmileMotion {"]
    for path, value in walk(tokens):
        if isinstance(value, str) and value.endswith("ms"):
            lines.append(
                f"  static const Duration {camel(path)} = Duration(milliseconds: {ms(value)});"
            )
    lines.append("}")
    return "\n".join(lines)


def emit_type(tokens: dict) -> str:
    """Real TextStyles — the Compose emitter leaves these as comments, Dart need not."""
    lines = ["abstract final class SmileType {"]
    for path, value in walk(tokens):
        if not (isinstance(value, dict) and "fontSize" in value):
            continue
        family = value.get("fontFamily") or []
        primary = family[0] if isinstance(family, list) and family else "DM Sans"
        size = float(px(value["fontSize"]))
        line_height = float(px(value.get("lineHeight", value["fontSize"])))
        tracking = float(px(value.get("letterSpacing", "0px")))
        height = round(line_height / size, 4) if size else 1.0
        lines += [
            f"  static const TextStyle {camel(path)} = TextStyle(",
            f"    fontFamily: '{primary}',",
            f"    fontWeight: {dart_font_weight(value['fontWeight'])},",
            f"    fontSize: {size:g},",
            f"    height: {height:g},",
            f"    letterSpacing: {tracking:g},",
            "  );",
        ]
    lines.append("}")
    return "\n".join(lines)


def dart_formatted(content: str) -> str:
    """Run `dart format` over the generated source when the SDK is available.

    Without this the generator and the formatter disagree and the file oscillates between
    them, so `--check` passes or fails depending on which ran last.
    """
    if not shutil_which("dart"):
        return content
    with tempfile.TemporaryDirectory() as tmp:
        path = os.path.join(tmp, "smile_tokens.dart")
        with io.open(path, "w", encoding="utf-8") as fh:
            fh.write(content)
        # Format IN PLACE and read the file back. Parsing `--output=show` from stdout is a
        # trap: dart also prints a summary line there, which lands in the generated source.
        result = subprocess.run(
            ["dart", "format", path], capture_output=True, text=True, check=False
        )
        if result.returncode != 0:
            print("  warning    dart format failed; writing unformatted output", file=sys.stderr)
            print((result.stderr or result.stdout).strip()[:400], file=sys.stderr)
            return content
        with io.open(path, encoding="utf-8") as fh:
            return fh.read()


def shutil_which(name: str):
    from shutil import which

    return which(name)


def generate_dart(ds: str) -> str:
    with io.open(os.path.join(ds, "dist", "json", "tokens.flat.json"), encoding="utf-8") as fh:
        data = json.load(fh)
    light, dark = data["light"], data["dark"]
    blocks = [
        HEADER,
        emit_colors("SmileColorLight", light),
        emit_colors("SmileColorDark", dark),
        emit_dimens(light),
        emit_type(light),
        emit_shadows(light),
        emit_durations(light),
    ]
    return dart_formatted("\n\n".join(blocks).rstrip() + "\n")


def _block(text: str, opener: str) -> str:
    """The text from `opener` up to the next line that closes it."""
    start = text.find(opener)
    if start < 0:
        return ""
    end = text.find("\n}", start)
    return text[start : end if end > 0 else len(text)]


def write(rel_path: str, content: str, check: bool) -> bool:
    """Returns True when the file on disk already matches."""
    target = os.path.join(REPO, rel_path)
    existing = None
    if os.path.isfile(target):
        with io.open(target, encoding="utf-8") as fh:
            existing = fh.read()
    if existing == content:
        print(f"  unchanged  {rel_path}")
        return True
    if check:
        print(f"  STALE      {rel_path}")
        return False
    os.makedirs(os.path.dirname(target), exist_ok=True)
    with io.open(target, "w", encoding="utf-8") as fh:
        fh.write(content)
    print(f"  {'updated' if existing else 'created'}    {rel_path}")
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--design-system", help="path to the design system folder")
    parser.add_argument("--all", action="store_true", help="also copy the three upstream outputs")
    parser.add_argument("--dart", action="store_true", help="generate Dart only (default)")
    parser.add_argument("--check", action="store_true", help="fail if any output is stale")
    args = parser.parse_args()

    ds = find_design_system(args.design_system)
    print(f"design system: {ds}")

    dart = generate_dart(ds)
    ok = write(DART_OUT, dart, args.check)

    # Regression guard: the Dart colour classes must have the same membership as the
    # upstream Compose ones. A generator that silently drops a value format (rgba) or
    # over-emits nested composites is the failure mode this catches.
    kotlin_path = os.path.join(ds, "dist", "android", "SmileTokens.kt")
    if os.path.isfile(kotlin_path):
        with io.open(kotlin_path, encoding="utf-8") as fh:
            kotlin = fh.read()
        for cls in ("SmileColorLight", "SmileColorDark"):
            kt = set(re.findall(r"val ([A-Za-z0-9]+) = Color\(", _block(kotlin, f"object {cls} {{")))
            dt = set(re.findall(r"static const Color ([A-Za-z0-9]+) =", _block(dart, f"abstract final class {cls} {{")))
            if kt != dt:
                print(f"  PARITY     {cls}: dart {len(dt)} vs compose {len(kt)}")
                for name in sorted(kt - dt):
                    print(f"               missing in dart: {name}")
                for name in sorted(dt - kt):
                    print(f"               extra in dart:   {name}")
                ok = False
            else:
                print(f"  parity ok  {cls} ({len(dt)} colours match the Compose output)")

    if args.all:
        for src, dest in COPIES:
            src_path = os.path.join(ds, src)
            if not os.path.isfile(src_path):
                print(f"  MISSING    {src} (upstream output absent)")
                ok = False
                continue
            with io.open(src_path, encoding="utf-8") as fh:
                ok = write(dest, fh.read(), args.check) and ok

    if args.check and not ok:
        print("\nOutputs are stale. Run scripts/sync_design_tokens.py --all", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
