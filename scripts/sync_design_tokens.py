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

A copy whose destination app does not exist yet is skipped rather than created, so this is
safe to run at any point in the build-out.

Dart has no upstream target, so it is GENERATED here from the platform-neutral
dist/json/tokens.flat.json, mirroring the Compose emitter's naming (camelCase from the
token path, SmileColorLight / SmileColorDark / SmileDimens / SmileType).

Compose's type styles and the DM Sans faces they resolve against are generated here too, because
the upstream emitter writes all 29 styles as comments. That is an emitter gap rather than a
platform limit — see spec/design-tokens.json -> deltas -> composeTypeStylesAreComments — so this
is a stopgap until upstream emits them. Compose also omits shadows, which Dart emits directly.

Every token leaf must classify into a known kind. An unrecognised value FAILS the run
rather than being skipped, because silent skipping is how this generator first diverged
from the Compose output: rgba() colours vanished and nothing complained.

Usage:
    scripts/sync_design_tokens.py                          # generate Dart (default)
    scripts/sync_design_tokens.py --dart                   # the same, stated explicitly
    scripts/sync_design_tokens.py --all                    # Dart + Compose type + fonts + copies
    scripts/sync_design_tokens.py --design-system <path>   # override autodetection
    scripts/sync_design_tokens.py --check                  # fail if output is stale

Output goes through `dart format` when the Dart SDK is on PATH, so the generator and the
formatter cannot disagree. `--check` needs the design system present locally, so CI has to
check it out before running the check.
"""

from __future__ import annotations

import argparse
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Where the design system sits on a machine with the shared agent skills present.
DEFAULT_DS_PATHS = [
    "~/.claude/skills/smile-design-system",
    "~/.agents/skills/smile-design-system",
]

DART_OUT = "flutter/sample_ui/lib/src/tokens/smile_tokens.dart"

ANDROID_UI = "android/sample-ui"
KOTLIN_TYPE_OUT = f"{ANDROID_UI}/src/main/kotlin/com/usesmileid/sampleapps/ui/tokens/SmileTypeStyles.kt"

# The five DM Sans weights the ramp uses (400–800). Android resource names must be lowercase.
FONT_COPIES = [
    (f"assets/fonts/DMSans-{upstream}.ttf", f"{ANDROID_UI}/src/main/res/font/dm_sans_{local}.ttf")
    for upstream, local in [
        ("Regular", "regular"),
        ("Medium", "medium"),
        ("SemiBold", "semibold"),
        ("Bold", "bold"),
        ("ExtraBold", "extrabold"),
    ]
]

# (upstream file, destination, the app directory that must exist for the copy to apply)
COPIES = [
    (
        "dist/android/SmileTokens.kt",
        "android/sample-ui/src/main/kotlin/com/usesmileid/sampleapps/ui/tokens/SmileTokens.kt",
        "android/sample-ui",
    ),
    (
        "dist/ios/SmileTokens.swift",
        "ios/SampleUI/Sources/SampleUI/Tokens/SmileTokens.swift",
        "ios/SampleUI",
    ),
    ("dist/ts/tokens.ts", "expo/sample-ui/src/tokens.ts", "expo/sample-ui"),
]

# Token groups whose dimension values become SmileDimens entries (mirrors emitCompose).
DIMENSION_GROUPS = {"spacing", "radius", "size", "space", "border-width"}

# Kinds an emitter turns into Dart, and kinds that are recognised but deliberately not
# emitted (they are inputs to the type styles, or plain metadata).
EMITTED_KINDS = {"color", "dimension", "duration", "type", "shadow"}
CARRIED_KINDS = {"number", "text", "font-stack"}

HEADER = """// Smile ID Design System — GENERATED. Do not edit by hand.
//
// Regenerate with: scripts/sync_design_tokens.py
// Source: the design system's dist/json/tokens.flat.json (fully resolved light + dark).
//
// Naming mirrors the Compose output (SmileColorLight / SmileColorDark / SmileDimens /
// SmileType) so the two platforms are diffable against each other.
//
// Requires Dart 3 — the token holders use `abstract final class`.

import 'package:flutter/material.dart';
"""

KOTLIN_HEADER = """@file:Suppress("MagicNumber")
// Smile ID Design System — GENERATED. Do not edit by hand.
//
// Regenerate with: scripts/sync_design_tokens.py --all
//
// A stopgap: the upstream Compose emitter writes these as comments. Names mirror the Dart emitter's
// SmileType. Delete this file once upstream emits real TextStyles.

package com.smileid.designsystem

import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
"""

RGBA = re.compile(r"rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*(?:,\s*([\d.]+)\s*)?\)")
HEX = re.compile(r"#[0-9a-fA-F]{6,8}")
NUMBER = re.compile(r"-?\d+(\.\d+)?")
DIMENSION = re.compile(r"-?\d+(\.\d+)?(px|rem|em|%)")
DURATION = re.compile(r"\d+(\.\d+)?m?s")


class TokenError(RuntimeError):
    """A token the emitters cannot handle. Fails the run rather than being skipped."""


def find_design_system(explicit: str | None) -> str:
    candidates = [explicit] if explicit else DEFAULT_DS_PATHS
    for candidate in candidates:
        if not candidate:
            continue
        path = os.path.realpath(os.path.expanduser(candidate))
        if os.path.isfile(os.path.join(path, "dist", "json", "tokens.flat.json")):
            return path
    sys.exit(
        "Could not find the design system. Pass --design-system <path> to the folder "
        "containing dist/json/tokens.flat.json.\nLooked in: " + ", ".join(DEFAULT_DS_PATHS)
    )


def camel(path: list[str]) -> str:
    """['color','text','title'] -> colorTextTitle; matches the Compose emitter."""
    parts: list[str] = []
    for segment in path:
        parts.extend(re.split(r"[-_ ]+", segment))
    head, *rest = [part for part in parts if part]
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


def classify(value) -> str | None:
    """The kind of a token leaf, or None when nothing recognises it."""
    if is_type_leaf(value):
        return "type"
    if is_shadow_leaf(value):
        return "shadow"
    if isinstance(value, list):
        return "font-stack"
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        return "number"
    if isinstance(value, str):
        if HEX.fullmatch(value) or RGBA.fullmatch(value):
            return "color"
        if DURATION.fullmatch(value):
            return "duration"
        if DIMENSION.fullmatch(value):
            return "dimension"
        if NUMBER.fullmatch(value):
            return "number"
        if re.fullmatch(r"[A-Za-z][A-Za-z0-9 ,._'\"-]*", value):
            return "text"
    return None


def audit(tokens: dict, mode: str) -> dict[str, int]:
    """Classify every leaf, raising on anything unrecognised. Returns per-kind counts."""
    counts: dict[str, int] = {}
    unknown: list[str] = []
    for path, value in walk(tokens):
        kind = classify(value)
        if kind is None:
            unknown.append(f"{'.'.join(path)} = {value!r}")
        else:
            counts[kind] = counts.get(kind, 0) + 1
    if unknown:
        raise TokenError(
            f"{len(unknown)} token(s) in the {mode} set use a value format this generator "
            "does not recognise. Teach `classify` about them rather than letting them be "
            "dropped:\n  " + "\n  ".join(unknown[:20])
        )
    return counts


def is_color(value) -> bool:
    return classify(value) == "color"


def dart_color(value: str) -> str:
    """#rrggbb, #rrggbbaa or rgba(r,g,b,a) -> Color(0xAARRGGBB)."""
    match = RGBA.fullmatch(value)
    if match:
        red, green, blue, alpha = match.groups()
        opacity = round(float(alpha) * 255) if alpha is not None else 255
        argb = f"{opacity:02X}{int(float(red)):02X}{int(float(green)):02X}{int(float(blue)):02X}"
        return f"Color(0x{argb})"
    hex_digits = value.lstrip("#")
    if len(hex_digits) == 6:
        argb = "FF" + hex_digits
    else:  # css order is rrggbbaa, Flutter wants aarrggbb
        argb = hex_digits[6:8] + hex_digits[0:6]
    return f"Color(0x{argb.upper()})"


def number(value) -> str:
    """'16px' / '-0.4px' / '300ms' / 1.5 -> a bare Dart numeric literal."""
    text = re.sub(r"(px|rem|em|%|ms|s)$", "", str(value))
    parsed = float(text or 0)
    return str(int(parsed)) if parsed.is_integer() else str(parsed)


def is_unitless(value) -> bool:
    return isinstance(value, (int, float)) or bool(NUMBER.fullmatch(str(value)))


def dart_duration(value) -> str:
    """'300ms' / '0.3s' / 300 -> a Duration whose argument is always an int.

    Seconds must be converted, not just stripped of their unit: `number('0.3s')` yields 0.3,
    and `Duration(milliseconds: 0.3)` does not compile — Dart wants an int — besides meaning
    a 0.3 ms animation rather than 300 ms. Sub-millisecond values fall back to microseconds
    so no value is ever rounded away.
    """
    text = str(value).strip()
    if text.endswith("ms"):
        millis = float(text[:-2])
    elif text.endswith("s"):
        millis = float(text[:-1]) * 1000
    else:
        millis = float(text)
    micros = round(millis * 1000)
    if micros % 1000 == 0:
        return f"Duration(milliseconds: {micros // 1000})"
    return f"Duration(microseconds: {micros})"


def dart_font_weight(weight) -> str:
    return f"FontWeight.w{int(float(weight))}"


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
            offset_x = number(spec.get("offsetX", 0))
            offset_y = number(spec.get("offsetY", 0))
            lines += [
                f"  static const BoxShadow {camel(path)} = BoxShadow(",
                f"    color: {dart_color(spec['color'])},",
                f"    offset: Offset({offset_x}, {offset_y}),",
                f"    blurRadius: {number(spec.get('blur', 0))},",
                f"    spreadRadius: {number(spec.get('spread', 0))},",
                "  );",
            ]
    lines.append("}")
    return "\n".join(lines)


def emit_dimens(tokens: dict) -> str:
    lines = ["abstract final class SmileDimens {"]
    for path, value in walk(tokens):
        if path[0] in DIMENSION_GROUPS and classify(value) == "dimension":
            lines.append(f"  static const double {camel(path)} = {number(value)};")
    lines.append("}")
    return "\n".join(lines)


def emit_durations(tokens: dict) -> str:
    lines = ["abstract final class SmileMotion {"]
    for path, value in walk(tokens):
        if classify(value) == "duration":
            lines.append(f"  static const Duration {camel(path)} = {dart_duration(value)};")
    lines.append("}")
    return "\n".join(lines)


def emit_type(tokens: dict) -> str:
    """Real TextStyles — the Compose emitter leaves these as comments, Dart need not."""
    lines = ["abstract final class SmileType {"]
    for path, value in walk(tokens):
        if not is_type_leaf(value):
            continue
        family = value.get("fontFamily") or []
        primary = family[0] if isinstance(family, list) and family else str(family or "DM Sans")
        size = float(number(value["fontSize"]))
        raw_line_height = value.get("lineHeight", value["fontSize"])
        # A line height arrives either as a length ('24px') or as a unitless ratio (1.5).
        # Dividing a ratio by the font size would silently produce a height near 0.09.
        if is_unitless(raw_line_height):
            height = float(number(raw_line_height))
        else:
            height = round(float(number(raw_line_height)) / size, 4) if size else 1.0
        tracking = float(number(value.get("letterSpacing", 0)))
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


def kotlin_sp(value: float) -> str:
    """A Compose `.sp` literal. Negatives need parentheses: `-0.4.sp` does not parse."""
    text = f"{value:g}"
    return f"({text}).sp" if value < 0 else f"{text}.sp"


def emit_kotlin_type(tokens: dict) -> str:
    """Compose wants an ABSOLUTE lineHeight, so a unitless ratio is multiplied out, not divided."""
    lines = [
        "/** The token source's type ramp, bound to the font families the app supplies. */",
        "class SmileTypeStyles(display: FontFamily, body: FontFamily) {",
    ]
    for path, value in walk(tokens):
        if not is_type_leaf(value):
            continue
        family = value.get("fontFamily") or []
        primary = family[0] if isinstance(family, list) and family else str(family or "DM Sans")
        slot = "body" if primary.strip().lower() == "dm sans" else "display"
        size = float(number(value["fontSize"]))
        raw_line_height = value.get("lineHeight", value["fontSize"])
        if is_unitless(raw_line_height):
            line_height = float(number(raw_line_height)) * size
        else:
            line_height = float(number(raw_line_height))
        tracking = float(number(value.get("letterSpacing", 0)))
        lines += [
            f"    val {camel(path)} = TextStyle(",
            f"        fontFamily = {slot},",
            f"        fontWeight = FontWeight({int(float(value['fontWeight']))}),",
            f"        fontSize = {kotlin_sp(size)},",
            f"        lineHeight = {kotlin_sp(line_height)},",
            f"        letterSpacing = {kotlin_sp(tracking)},",
            "    )",
        ]
    lines.append("}")
    return "\n".join(lines)


def generate_kotlin_type(ds: str) -> str:
    tokens_path = os.path.join(ds, "dist", "json", "tokens.flat.json")
    with io.open(tokens_path, encoding="utf-8") as handle:
        data = json.load(handle)
    return KOTLIN_HEADER + "\n" + emit_kotlin_type(data["light"]) + "\n"


def write_binary(rel_path: str, payload: bytes, check: bool) -> bool:
    """Byte comparison, so `--check` catches a font swapped upstream."""
    target = os.path.join(REPO, rel_path)
    existing = None
    if os.path.isfile(target):
        with open(target, "rb") as handle:
            existing = handle.read()
    if existing == payload:
        print(f"  unchanged  {rel_path}")
        return True
    if check:
        print(f"  STALE      {rel_path}")
        return False
    os.makedirs(os.path.dirname(target), exist_ok=True)
    with open(target, "wb") as handle:
        handle.write(payload)
    print(f"  {'updated' if existing else 'created'}    {rel_path}")
    return True


def copy_fonts(ds: str, check: bool) -> bool:
    ok = True
    for source, dest in FONT_COPIES:
        source_path = os.path.join(ds, source)
        if not os.path.isfile(source_path):
            print(f"  MISSING    {source} (the design system does not ship this face)")
            ok = False
            continue
        with open(source_path, "rb") as handle:
            ok = write_binary(dest, handle.read(), check) and ok
    return ok


def dart_formatted(content: str) -> str:
    """Run `dart format` over the generated source when the SDK is available.

    Without this the generator and the formatter disagree and the file oscillates between
    them, so `--check` passes or fails depending on which ran last.
    """
    if not shutil.which("dart"):
        return content
    with tempfile.TemporaryDirectory() as tmp:
        path = os.path.join(tmp, "smile_tokens.dart")
        with io.open(path, "w", encoding="utf-8") as handle:
            handle.write(content)
        # Format IN PLACE and read the file back. Parsing `--output=show` from stdout is a
        # trap: dart also prints a summary line there, which lands in the generated source.
        result = subprocess.run(
            ["dart", "format", path], capture_output=True, text=True, check=False
        )
        if result.returncode != 0:
            raise TokenError(
                "dart format rejected the generated source, which means the emitters "
                "produced invalid Dart:\n" + (result.stderr or result.stdout).strip()[:800]
            )
        with io.open(path, encoding="utf-8") as handle:
            return handle.read()


def generate_dart(ds: str) -> tuple[str, dict[str, int]]:
    tokens_path = os.path.join(ds, "dist", "json", "tokens.flat.json")
    with io.open(tokens_path, encoding="utf-8") as handle:
        data = json.load(handle)
    light, dark = data["light"], data["dark"]
    counts = audit(light, "light")
    audit(dark, "dark")
    blocks = [
        HEADER,
        emit_colors("SmileColorLight", light),
        emit_colors("SmileColorDark", dark),
        emit_dimens(light),
        emit_type(light),
        emit_shadows(light),
        emit_durations(light),
    ]
    return dart_formatted("\n\n".join(blocks).rstrip() + "\n"), counts


def block(text: str, opener: str) -> str:
    """The text from `opener` up to the next line that closes it."""
    start = text.find(opener)
    if start < 0:
        return ""
    end = text.find("\n}", start)
    return text[start : end if end > 0 else len(text)]


def check_parity(dart: str, ds: str) -> bool:
    """The Dart colour classes must have the same membership as the Compose output."""
    kotlin_path = os.path.join(ds, "dist", "android", "SmileTokens.kt")
    if not os.path.isfile(kotlin_path):
        print("  skipped    colour parity (no upstream Compose output to compare against)")
        return True
    with io.open(kotlin_path, encoding="utf-8") as handle:
        kotlin = handle.read()
    ok = True
    for class_name in ("SmileColorLight", "SmileColorDark"):
        upstream = set(
            re.findall(r"val ([A-Za-z0-9]+) = Color\(", block(kotlin, f"object {class_name} {{"))
        )
        ours = set(
            re.findall(
                r"static const Color ([A-Za-z0-9]+) =",
                block(dart, f"abstract final class {class_name} {{"),
            )
        )
        if upstream != ours:
            print(f"  PARITY     {class_name}: dart {len(ours)} vs compose {len(upstream)}")
            for name in sorted(upstream - ours):
                print(f"               missing in dart: {name}")
            for name in sorted(ours - upstream):
                print(f"               extra in dart:   {name}")
            ok = False
        else:
            print(f"  parity ok  {class_name} ({len(ours)} colours match the Compose output)")
    return ok


def check_counts(counts: dict[str, int]) -> bool:
    """Every emitted kind must be non-empty — a silent shrink is the failure to catch."""
    ok = True
    for kind in sorted(EMITTED_KINDS):
        if counts.get(kind, 0) == 0:
            print(f"  EMPTY      no {kind} tokens classified; that emitter would output nothing")
            ok = False
    summary = " · ".join(f"{k} {counts.get(k, 0)}" for k in sorted(EMITTED_KINDS | CARRIED_KINDS))
    print(f"  classified {summary}")
    return ok


def write(rel_path: str, content: str, check: bool) -> bool:
    """Returns True when the file on disk already matches."""
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


def copy_upstream(ds: str, check: bool) -> bool:
    ok = True
    for source, dest, app_dir in COPIES:
        if not os.path.isdir(os.path.join(REPO, app_dir)):
            print(f"  skipped    {dest} ({app_dir} does not exist yet)")
            continue
        source_path = os.path.join(ds, source)
        if not os.path.isfile(source_path):
            print(f"  MISSING    {source} (upstream output absent)")
            ok = False
            continue
        with io.open(source_path, encoding="utf-8") as handle:
            ok = write(dest, handle.read(), check) and ok
    return ok


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--design-system", help="path to the design system folder")
    parser.add_argument("--all", action="store_true", help="also copy the three upstream outputs")
    parser.add_argument("--dart", action="store_true", help="generate Dart only (the default)")
    parser.add_argument("--check", action="store_true", help="fail if any output is stale")
    args = parser.parse_args(argv)

    if args.all and args.dart:
        parser.error("--all and --dart are mutually exclusive")

    ds = find_design_system(args.design_system)
    print(f"design system: {ds}")

    try:
        dart, counts = generate_dart(ds)
    except TokenError as error:
        print(f"\n{error}", file=sys.stderr)
        return 1

    ok = write(DART_OUT, dart, args.check)
    ok = check_counts(counts) and ok
    ok = check_parity(dart, ds) and ok

    if args.all:
        ok = copy_upstream(ds, args.check) and ok
        if os.path.isdir(os.path.join(REPO, ANDROID_UI)):
            ok = write(KOTLIN_TYPE_OUT, generate_kotlin_type(ds), args.check) and ok
            ok = copy_fonts(ds, args.check) and ok
        else:
            print(f"  skipped    {KOTLIN_TYPE_OUT} ({ANDROID_UI} does not exist yet)")

    if not ok:
        message = (
            "Outputs are stale. Run scripts/sync_design_tokens.py --all"
            if args.check
            else "Token sync failed; see the messages above."
        )
        print(f"\n{message}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
