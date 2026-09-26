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

SwiftUI needs the same two stopgaps and is a step worse: its upstream output omits the type ramp
entirely, not even as comments. All three platforms also need the values the design system carries
no role for (product and profile hues, soft badge fills, the light/dark pairs), which come from
spec/design-tokens.json -> deltas rather than upstream, and are emitted from the same entries so
the three cannot disagree.

TypeScript needs only that deltas file. Its upstream output already carries the 14 named text
styles, the component fonts and every component dimension, so the two stopgaps the other platforms
need do not apply here.

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

FLUTTER_UI = "flutter/sample_ui"
DART_OUT = f"{FLUTTER_UI}/lib/src/tokens/smile_tokens.dart"
DART_HUES_OUT = f"{FLUTTER_UI}/lib/src/tokens/smile_product_hues.dart"

ANDROID_UI = "android/sample-ui"
KOTLIN_TYPE_OUT = f"{ANDROID_UI}/src/main/kotlin/com/usesmileid/sampleapps/ui/tokens/SmileTypeStyles.kt"
KOTLIN_HUES_OUT = f"{ANDROID_UI}/src/main/kotlin/com/usesmileid/sampleapps/ui/tokens/SmileProductHues.kt"

IOS_UI = "ios/SampleUI"
IOS_TOKENS = f"{IOS_UI}/Sources/SampleUI/Tokens"
SWIFT_TYPE_OUT = f"{IOS_TOKENS}/SmileTypeStyles.swift"
SWIFT_HUES_OUT = f"{IOS_TOKENS}/SmileProductHues.swift"

EXPO_UI = "expo/sample-ui"
# No type-ramp stopgap: unlike the Compose and SwiftUI emitters, dist/ts carries text-style and
# every component dimension, so only the `deltas` need generating here.
TS_HUES_OUT = f"{EXPO_UI}/src/smile-product-hues.ts"

# Product hues come from spec/, not the design system: they are bound to no variable upstream.
SPEC_TOKENS = "spec/design-tokens.json"

# The five DM Sans weights the ramp uses (400–800). Android resource names must be lowercase.
FACES = ["Regular", "Medium", "SemiBold", "Bold", "ExtraBold"]

FONT_COPIES = [
    (f"assets/fonts/DMSans-{face}.ttf", f"{ANDROID_UI}/src/main/res/font/sample_dm_sans_{face.lower()}.ttf")
    for face in FACES
]

# iOS keeps the upstream file names: a custom face is addressed by its PostScript name, and
# DMSans-SemiBold's family is "DM Sans SemiBold", so weight selection cannot reach it.
IOS_FONT_COPIES = [
    (f"assets/fonts/DMSans-{face}.ttf", f"{IOS_UI}/Sources/SampleUI/Resources/Fonts/DMSans-{face}.ttf")
    for face in FACES
]

# Flutter keeps the upstream names too: the package's pubspec maps each file to one weight of one
# family, so the face is addressed by path and `fontWeight` resolves within the declared family.
FLUTTER_FONT_COPIES = [
    (f"assets/fonts/DMSans-{face}.ttf", f"{FLUTTER_UI}/assets/fonts/DMSans-{face}.ttf")
    for face in FACES
]

# Expo keeps the upstream file names too: the faces are required from TypeScript by path, so the
# name is the identifier and a rename silently drops a weight to the platform font.
EXPO_FONT_COPIES = [
    (f"assets/fonts/DMSans-{face}.ttf", f"{EXPO_UI}/assets/fonts/DMSans-{face}.ttf")
    for face in FACES
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

// ignore_for_file: public_member_api_docs

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

KOTLIN_HUES_HEADER = """// Smile ID product hues — GENERATED. Do not edit by hand.
// Regenerate with: scripts/sync_design_tokens.py --all
//
// A stopgap: the source is spec/design-tokens.json → productHues, not the design system. Delete this
// file once the design system carries a decorative product role; a port generates from the same entry.

package com.smileid.designsystem

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
"""

SWIFT_HEADER = """// Smile ID Design System — GENERATED. Do not edit by hand.
//
// Regenerate with: scripts/sync_design_tokens.py --all
//
// A stopgap: the upstream SwiftUI emitter omits the type ramp entirely. Names mirror the other
// platforms' SmileType so they stay diffable. Delete this file once upstream emits the styles.
//
// This is DATA, not a Font: a custom face is addressed by PostScript name, which the weight number
// resolves to in the app's typography layer.

import CoreGraphics

/// One style from the token source's ramp.
public struct SmileTextStyle: Equatable, Sendable {
    /// The token's own family name, resolved to a bundled face by the app's typography layer.
    public let family: String
    /// The DTCG numeric weight (400–800), not a `Font.Weight`.
    public let weight: Int
    public let size: CGFloat
    public let lineHeight: CGFloat
    public let tracking: CGFloat

    public init(family: String, weight: Int, size: CGFloat, lineHeight: CGFloat, tracking: CGFloat) {
        self.family = family
        self.weight = weight
        self.size = size
        self.lineHeight = lineHeight
        self.tracking = tracking
    }

    /// SwiftUI's `lineSpacing` is the gap BETWEEN lines, where the token carries the total height.
    public var lineSpacing: CGFloat { max(0, lineHeight - size) }
}
"""

TS_HUES_HEADER = """// Smile ID product hues — GENERATED. Do not edit by hand.
// Regenerate with: scripts/sync_design_tokens.py --all
//
// A stopgap: the source is spec/design-tokens.json → deltas, not the design system. Everything the
// design system carries no role for lives here; delete each value once upstream carries its role.
"""

SWIFT_HUES_HEADER = """// Smile ID product hues — GENERATED. Do not edit by hand.
// Regenerate with: scripts/sync_design_tokens.py --all
//
// A stopgap: the source is spec/design-tokens.json → deltas, not the design system. Everything the
// design system carries no role for lives here; delete each value once upstream carries its role.

import SwiftUI

/// One product's colouring. `cardIcon` tints the card's glyph; `icon` and `tile` are the list row's pair.
public struct SmileProductHue: Equatable, Sendable {
    public let from: Color
    public let to: Color
    public let cardIcon: Color
    public let icon: Color
    public let tile: Color
    /// Stop positions as fractions. `stopEnd` may exceed 1: the design runs it past the card's edge.
    public let stopStart: CGFloat
    public let stopEnd: CGFloat
    public let fromAlpha: CGFloat
    public let toAlpha: CGFloat
}

/// One status pill's soft fill: a pale background with text that clears contrast on it.
public struct SmileSoftBadgeFill: Equatable, Sendable {
    public let background: Color
    public let text: Color
}
"""

DART_HUES_HEADER = """// Smile ID product hues — GENERATED. Do not edit by hand.
// Regenerate with: scripts/sync_design_tokens.py --all
//
// A stopgap: the source is spec/design-tokens.json → deltas, not the design system. Everything the
// design system carries no role for lives here; delete each value once upstream carries its role.
//
// Metrics are bare doubles because Flutter measures in logical pixels — there is no dp or sp type
// for the emitter to name, and the Compose twin's `.dp`/`.sp` carry the same numbers.

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

/// One product's colouring. `cardIcon` tints the card's glyph; `icon` and `tile` are the list row's pair.
@immutable
class SmileProductHue {
  const SmileProductHue({
    required this.from,
    required this.to,
    required this.cardIcon,
    required this.icon,
    required this.tile,
    required this.stopStart,
    required this.stopEnd,
    required this.fromAlpha,
    required this.toAlpha,
  });

  final Color from;
  final Color to;
  final Color cardIcon;
  final Color icon;
  final Color tile;

  /// Stop positions as fractions. `stopEnd` may exceed 1: the design runs it past the card's edge.
  final double stopStart;
  final double stopEnd;
  final double fromAlpha;
  final double toAlpha;
}

/// One status pill's soft fill: a pale background with text that clears contrast on it.
@immutable
class SmileSoftBadgeFill {
  const SmileSoftBadgeFill({required this.background, required this.text});

  final Color background;
  final Color text;
}
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


def kotlin_color(value: str) -> str:
    """`#RRGGBB` to a Compose `Color(0xFFRRGGBB)`. Alpha is applied at the use site, never baked in."""
    text = value.strip().lstrip("#")
    if len(text) != 6 or not all(c in "0123456789abcdefABCDEF" for c in text):
        raise TokenError(f"product hue {value!r} is not a #RRGGBB colour")
    return f"Color(0xFF{text.upper()})"


def emit_kotlin_product_hues(hues: dict) -> str:
    """One entry per product, keyed by the same id `spec/` uses everywhere else."""
    if not hues:
        raise TokenError("spec/design-tokens.json carries no productHues.hues entries")
    lines = [
        "/** One product's colouring. `cardIcon` tints the card's glyph; `icon` and `tile` are the list row's pair, which the products frame does not govern. */",
        "data class SmileProductHue(",
        "    val from: Color,",
        "    val to: Color,",
        "    val cardIcon: Color,",
        "    val icon: Color,",
        "    val tile: Color,",
        "    /** Stop positions as fractions. `stopEnd` may exceed 1: the design runs it past the card's edge. */",
        "    val stopStart: Float,",
        "    val stopEnd: Float,",
        "    val fromAlpha: Float,",
        "    val toAlpha: Float,",
        ")",
        "",
        "/** Keyed by the product id in spec/scenarios.json. A product absent here has no hue yet. */",
        "val smileProductHues: Map<String, SmileProductHue> = mapOf(",
    ]
    for product, hue in hues.items():
        missing = {"from", "to", "cardIcon", "icon", "tile"} - set(hue)
        if missing:
            raise TokenError(f"product hue {product!r} is missing {sorted(missing)}")
        lines += [
            f'    "{product}" to SmileProductHue(',
            f"        from = {kotlin_color(hue['from'])},",
            f"        to = {kotlin_color(hue['to'])},",
            f"        cardIcon = {kotlin_color(hue['cardIcon'])},",
            f"        icon = {kotlin_color(hue['icon'])},",
            f"        tile = {kotlin_color(hue['tile'])},",
        ]
        for role in ("stopStart", "stopEnd", "fromAlpha", "toAlpha"):
            if hue.get(role) is None:
                raise TokenError(f"product hue {product!r} is missing {role}")
            lines.append(f"        {role} = {hue[role]}f,")
        lines.append("    ),")
    lines.append(")")
    return "\n".join(lines)


def emit_kotlin_soft_badge_fills(fills: dict) -> str:
    """The soft status pills, keyed by the feedback role the four job statuses map onto."""
    roles = ["success", "info", "warning", "error"]
    missing = [role for role in roles if role not in fills]
    if missing:
        raise TokenError(f"spec/design-tokens.json softBadgeFills.fills is missing {missing}")
    lines = [
        "",
        "/** One status pill's soft fill: a pale background with text that clears contrast on it. */",
        "data class SmileSoftBadgeFill(",
        "    val background: Color,",
        "    val text: Color,",
        ")",
        "",
        "/** Keyed by feedback role. The design system's own badge.* pairs are saturated, which is a different treatment. */",
        "val smileSoftBadgeFills: Map<String, SmileSoftBadgeFill> = mapOf(",
    ]
    for role in roles:
        pair = fills[role]
        for key in ("background", "text"):
            if key not in pair:
                raise TokenError(f"soft badge fill {role!r} is missing {key!r}")
        lines += [
            f'    "{role}" to SmileSoftBadgeFill(',
            f"        background = {kotlin_color(pair['background'])},",
            f"        text = {kotlin_color(pair['text'])},",
            "    ),",
        ]
    lines.append(")")
    return "\n".join(lines)


def read_spec_delta(delta_id: str, key: str) -> dict:
    spec_path = os.path.join(REPO, SPEC_TOKENS)
    with io.open(spec_path, encoding="utf-8") as handle:
        spec = json.load(handle)
    for delta in spec.get("deltas", []):
        if delta.get("id") == delta_id:
            return delta.get(key, {})
    raise TokenError(f"{SPEC_TOKENS} has no {delta_id} delta to generate from")


def read_product_hues() -> dict:
    return read_spec_delta("productHues", "hues")


def read_soft_badge_fills() -> dict:
    return read_spec_delta("softBadgeFills", "fills")


def emit_kotlin_spec_color(name: str, delta_id: str, doc: str, value) -> str:
    """A colour the design uses that the design system carries no semantic role for."""
    if not isinstance(value, str) or not value:
        raise TokenError(f"spec/design-tokens.json {delta_id} carries no value")
    return "\n".join(["", f"/** {doc} */", f"val {name}: Color = {kotlin_color(value)}"])


def emit_kotlin_border_strong(value) -> str:
    return emit_kotlin_spec_color(
        "smileBorderStrong",
        "borderStrong",
        "The design's `color/border-strong`, for a control ring that `color.border` is too pale to draw.",
        value,
    )


def emit_kotlin_surface2(value) -> str:
    return emit_kotlin_spec_color(
        "smileSurface2",
        "surface2",
        "The design's `color/surface-2`, a cool grey subtle fill — `color.surface-alt` is a warm cream.",
        value,
    )


def emit_kotlin_off_black(values) -> str:
    """A pair, not a single value: every role it paints is drawn in both schemes."""
    missing = [mode for mode in ("light", "dark") if not values.get(mode)]
    if missing:
        raise TokenError(f"spec/design-tokens.json offBlack is missing {missing}")
    return "\n".join([
        "",
        "/** The design's `Off_black`: the warm strong foreground. Seven roles, one variable — see the `offBlack` delta. */",
        f"val smileOffBlackLight: Color = {kotlin_color(values['light'])}",
        f"val smileOffBlackDark: Color = {kotlin_color(values['dark'])}",
    ])


def read_off_black() -> dict:
    return read_spec_delta("offBlack", "values")


def emit_kotlin_nav_bar_fill(values) -> str:
    """The bar's own fill: the page's own colour leaves it invisible in dark."""
    missing = [mode for mode in ("light", "dark") if not values.get(mode)]
    if missing:
        raise TokenError(f"spec/design-tokens.json navBarFill is missing {missing}")
    return "\n".join([
        "",
        "/** The floating nav bar's fill — see the `navBarFill` delta. */",
        f"val smileNavBarLight: Color = {kotlin_color(values['light'])}",
        f"val smileNavBarDark: Color = {kotlin_color(values['dark'])}",
    ])


def read_nav_bar_fill() -> dict:
    return read_spec_delta("navBarFill", "values")


def read_border_strong() -> str:
    return read_spec_delta("borderStrong", "value")


def read_surface2() -> str:
    return read_spec_delta("surface2", "value")


def read_profile_hues() -> list:
    return read_spec_delta("profileHues", "hues")


def read_token_session() -> dict:
    for key in ("cardGradient", "ring", "ringTrackOpacity"):
        pass
    spec_path = os.path.join(REPO, SPEC_TOKENS)
    with io.open(spec_path, encoding="utf-8") as handle:
        spec = json.load(handle)
    for delta in spec.get("deltas", []):
        if delta.get("id") == "tokenSessionGreens":
            return delta
    raise TokenError(f"{SPEC_TOKENS} has no tokenSessionGreens delta to generate from")


def emit_kotlin_token_session(delta: dict) -> str:
    """The session card's gradient and the countdown ring, which no semantic role covers."""
    grad = delta.get("cardGradient") or []
    alpha = delta.get("cardGradientAlpha") or []
    ring = delta.get("ring")
    opacity = delta.get("ringTrackOpacity")
    if len(grad) != 2 or len(alpha) != 2 or not ring or opacity is None:
        raise TokenError("tokenSessionGreens needs a two-stop cardGradient with its alphas, a ring and a ringTrackOpacity")
    return "\n".join([
        "",
        "/** The session card's horizontal gradient. Both stops are translucent, so the card composites against the page. */",
        "val smileTokenSessionGradient: List<Color> = listOf(%s, %s)" % (kotlin_color(grad[0]), kotlin_color(grad[1])),
        "val smileTokenSessionGradientAlpha: List<Float> = listOf(%sf, %sf)" % (alpha[0], alpha[1]),
        "",
        "/** The countdown ring: this colour solid for progress, and the same colour faded for the track. */",
        "val smileTokenRing: Color = %s" % kotlin_color(ring),
        "const val SMILE_TOKEN_RING_TRACK_OPACITY = %sf" % opacity,
    ])


def read_label_type_style() -> dict:
    spec_path = os.path.join(REPO, SPEC_TOKENS)
    with io.open(spec_path, encoding="utf-8") as handle:
        spec = json.load(handle)
    for delta in spec.get("deltas", []):
        if delta.get("id") == "labelTypeStyle":
            return delta
    raise TokenError(f"{SPEC_TOKENS} has no labelTypeStyle delta to generate from")


def emit_kotlin_label_type_style(delta: dict) -> str:
    """The all-caps label size and tracking, which text-style.overline sets a point small and solid."""
    size = delta.get("size")
    tracking = delta.get("tracking")
    if not size or tracking is None:
        raise TokenError("labelTypeStyle needs a size and a tracking")
    return "\n".join([
        "",
        "/** The design's Type/Label: a point larger than text-style.overline, and spaced. */",
        "val smileLabelSize = %s.sp" % size,
        "val smileLabelTracking = %s.sp" % tracking,
    ])


def read_card_label_runs() -> dict:
    spec_path = os.path.join(REPO, SPEC_TOKENS)
    with io.open(spec_path, encoding="utf-8") as handle:
        spec = json.load(handle)
    for delta in spec.get("deltas", []):
        if delta.get("id") == "cardLabelRuns":
            return delta
    raise TokenError(f"{SPEC_TOKENS} has no cardLabelRuns delta to generate from")


def emit_kotlin_card_label_runs(delta: dict) -> str:
    """The one property each card-label run needs that its nearest semantic style does not carry."""
    tracking = delta.get("tracking")
    weight = delta.get("familyWeight")
    if tracking is None or not weight:
        raise TokenError("cardLabelRuns needs a tracking and a familyWeight")
    return "\n".join([
        "",
        "/** The card's two label runs, each one property off a token — see the `cardLabelRuns` delta. */",
        "val smileCardTitleTracking = %s.sp" % tracking,
        "const val SMILE_CARD_FAMILY_WEIGHT = %s" % weight,
    ])


def read_card_stroke() -> dict:
    return read_spec_delta("cardStroke", "values")


def emit_kotlin_card_stroke(values: dict) -> str:
    """A pair, not one value: `color.border` is the same near-white in both schemes, which is the defect."""
    missing = [mode for mode in ("light", "dark") if not values.get(mode)]
    if missing or values.get("width") is None:
        raise TokenError(f"spec/design-tokens.json cardStroke is missing {missing or ['width']}")
    return "\n".join([
        "",
        "/** One outline for every card and row, equally quiet in both schemes — see the `cardStroke` delta. */",
        "val smileCardStrokeLight: Color = %s" % kotlin_color(values["light"]),
        "val smileCardStrokeDark: Color = %s" % kotlin_color(values["dark"]),
        "val smileCardStrokeWidth = %s.dp" % values["width"],
    ])


def read_products_type() -> dict:
    spec_path = os.path.join(REPO, SPEC_TOKENS)
    with io.open(spec_path, encoding="utf-8") as handle:
        spec = json.load(handle)
    for delta in spec.get("deltas", []):
        if delta.get("id") == "productsScreenType":
            return delta
    raise TokenError(f"{SPEC_TOKENS} has no productsScreenType delta to generate from")


def emit_kotlin_products_type(delta: dict) -> str:
    """The frame's Type/Heading and Type/Title, which the vendored ramp does not match."""
    keys = ("headingSize", "headingLineHeight", "headingTracking", "headingWeight",
            "sectionSize", "sectionLineHeight", "sectionWeight")
    missing = [k for k in keys if delta.get(k) is None]
    if missing:
        raise TokenError(f"productsScreenType is missing {missing}")
    return "\n".join([
        "",
        "/** The products header and section headers, which text-style.* does not match — see the `productsScreenType` delta. */",
        "val smileHeadingPageSize = %s.sp" % delta["headingSize"],
        "val smileHeadingPageLineHeight = %s.sp" % delta["headingLineHeight"],
        "val smileHeadingPageTracking = %s.sp" % delta["headingTracking"],
        "const val SMILE_HEADING_PAGE_WEIGHT = %s" % delta["headingWeight"],
        "val smileSectionHeaderSize = %s.sp" % delta["sectionSize"],
        "val smileSectionHeaderLineHeight = %s.sp" % delta["sectionLineHeight"],
        "const val SMILE_SECTION_HEADER_WEIGHT = %s" % delta["sectionWeight"],
    ])


def emit_kotlin_profile_hues(hues) -> str:
    """One avatar fill per profile, cycled by list position."""
    if not hues:
        raise TokenError("spec/design-tokens.json profileHues carries no hues")
    lines = [
        "",
        "/** Avatar fills, one per profile, taken in list order and cycled beyond the list. */",
        "val smileProfileHues: List<Color> = listOf(",
    ]
    lines += ["    %s," % kotlin_color(h) for h in hues]
    lines.append(")")
    return "\n".join(lines)


def dart_double(value) -> str:
    """A bare Dart `double` literal, always with a decimal point so the type is unambiguous."""
    parsed = float(str(value))
    return f"{parsed:.1f}" if parsed.is_integer() else str(parsed)


def dart_hue_color(value: str) -> str:
    """The delta colours are all `#RRGGBB`; alpha is applied at the use site, never baked in."""
    text = value.strip().lstrip("#")
    if len(text) != 6 or not all(c in "0123456789abcdefABCDEF" for c in text):
        raise TokenError(f"product hue {value!r} is not a #RRGGBB colour")
    return f"Color(0xFF{text.upper()})"


def emit_dart_product_hues(hues: dict) -> str:
    """One entry per product, keyed by the same id `spec/` uses everywhere else."""
    if not hues:
        raise TokenError("spec/design-tokens.json carries no productHues.hues entries")
    lines = [
        "/// Keyed by the product id in spec/scenarios.json. A product absent here has no hue yet.",
        "const Map<String, SmileProductHue> smileProductHues = <String, SmileProductHue>{",
    ]
    for product, hue in hues.items():
        missing = {"from", "to", "cardIcon", "icon", "tile"} - set(hue)
        if missing:
            raise TokenError(f"product hue {product!r} is missing {sorted(missing)}")
        lines += [
            f"  '{product}': SmileProductHue(",
            f"    from: {dart_hue_color(hue['from'])},",
            f"    to: {dart_hue_color(hue['to'])},",
            f"    cardIcon: {dart_hue_color(hue['cardIcon'])},",
            f"    icon: {dart_hue_color(hue['icon'])},",
            f"    tile: {dart_hue_color(hue['tile'])},",
        ]
        for role in ("stopStart", "stopEnd", "fromAlpha", "toAlpha"):
            if hue.get(role) is None:
                raise TokenError(f"product hue {product!r} is missing {role}")
            lines.append(f"    {role}: {dart_double(hue[role])},")
        lines.append("  ),")
    lines.append("};")
    return "\n".join(lines)


def emit_dart_soft_badge_fills(fills: dict) -> str:
    """The soft status pills, keyed by the feedback role the four job statuses map onto."""
    roles = ["success", "info", "warning", "error"]
    missing = [role for role in roles if role not in fills]
    if missing:
        raise TokenError(f"spec/design-tokens.json softBadgeFills.fills is missing {missing}")
    lines = [
        "",
        "/// Keyed by feedback role. The design system's own badge.* pairs are saturated, a different treatment.",
        "const Map<String, SmileSoftBadgeFill> smileSoftBadgeFills = <String, SmileSoftBadgeFill>{",
    ]
    for role in roles:
        pair = fills[role]
        for key in ("background", "text"):
            if key not in pair:
                raise TokenError(f"soft badge fill {role!r} is missing {key!r}")
        lines += [
            f"  '{role}': SmileSoftBadgeFill(",
            f"    background: {dart_hue_color(pair['background'])},",
            f"    text: {dart_hue_color(pair['text'])},",
            "  ),",
        ]
    lines.append("};")
    return "\n".join(lines)


def emit_dart_spec_color(name: str, delta_id: str, doc: str, value) -> str:
    """A colour the design uses that the design system carries no semantic role for."""
    if not isinstance(value, str) or not value:
        raise TokenError(f"spec/design-tokens.json {delta_id} carries no value")
    return "\n".join(["", f"/// {doc}", f"const Color {name} = {dart_hue_color(value)};"])


def emit_dart_border_strong(value) -> str:
    return emit_dart_spec_color(
        "smileBorderStrong",
        "borderStrong",
        "The design's `color/border-strong`, for a control ring that `color.border` is too pale to draw.",
        value,
    )


def emit_dart_surface2(value) -> str:
    return emit_dart_spec_color(
        "smileSurface2",
        "surface2",
        "The design's `color/surface-2`, a cool grey subtle fill — `color.surface-alt` is a warm cream.",
        value,
    )


def emit_dart_off_black(values) -> str:
    """A pair, not a single value: every role it paints is drawn in both schemes."""
    missing = [mode for mode in ("light", "dark") if not values.get(mode)]
    if missing:
        raise TokenError(f"spec/design-tokens.json offBlack is missing {missing}")
    return "\n".join([
        "",
        "/// The design's `Off_black`: the warm strong foreground. Seven roles, one variable — see the `offBlack` delta.",
        f"const Color smileOffBlackLight = {dart_hue_color(values['light'])};",
        f"const Color smileOffBlackDark = {dart_hue_color(values['dark'])};",
    ])


def emit_dart_nav_bar_fill(values) -> str:
    """The bar's own fill: the page's own colour leaves it invisible in dark."""
    missing = [mode for mode in ("light", "dark") if not values.get(mode)]
    if missing:
        raise TokenError(f"spec/design-tokens.json navBarFill is missing {missing}")
    return "\n".join([
        "",
        "/// The floating nav bar's fill — see the `navBarFill` delta.",
        f"const Color smileNavBarLight = {dart_hue_color(values['light'])};",
        f"const Color smileNavBarDark = {dart_hue_color(values['dark'])};",
    ])


def emit_dart_profile_hues(hues) -> str:
    """One avatar fill per profile, cycled by list position."""
    if not hues:
        raise TokenError("spec/design-tokens.json profileHues carries no hues")
    lines = [
        "",
        "/// Avatar fills, one per profile, taken in list order and cycled beyond the list.",
        "const List<Color> smileProfileHues = <Color>[",
    ]
    lines += ["  %s," % dart_hue_color(h) for h in hues]
    lines.append("];")
    return "\n".join(lines)


def emit_dart_token_session(delta: dict) -> str:
    """The session card's gradient and the countdown ring, which no semantic role covers."""
    grad = delta.get("cardGradient") or []
    alpha = delta.get("cardGradientAlpha") or []
    ring = delta.get("ring")
    opacity = delta.get("ringTrackOpacity")
    if len(grad) != 2 or len(alpha) != 2 or not ring or opacity is None:
        raise TokenError("tokenSessionGreens needs a two-stop cardGradient with its alphas, a ring and a ringTrackOpacity")
    return "\n".join([
        "",
        "/// The session card's horizontal gradient. Both stops are translucent, so the card composites against the page.",
        "const List<Color> smileTokenSessionGradient = <Color>[%s, %s];"
        % (dart_hue_color(grad[0]), dart_hue_color(grad[1])),
        "const List<double> smileTokenSessionGradientAlpha = <double>[%s, %s];"
        % (dart_double(alpha[0]), dart_double(alpha[1])),
        "",
        "/// The countdown ring: this colour solid for progress, and the same colour faded for the track.",
        "const Color smileTokenRing = %s;" % dart_hue_color(ring),
        "const double smileTokenRingTrackOpacity = %s;" % dart_double(opacity),
    ])


def emit_dart_label_type_style(delta: dict) -> str:
    """The all-caps label size and tracking, which text-style.overline sets a point small and solid."""
    size = delta.get("size")
    tracking = delta.get("tracking")
    if not size or tracking is None:
        raise TokenError("labelTypeStyle needs a size and a tracking")
    return "\n".join([
        "",
        "/// The design's Type/Label: a point larger than text-style.overline, and spaced.",
        "const double smileLabelSize = %s;" % dart_double(size),
        "const double smileLabelTracking = %s;" % dart_double(tracking),
    ])


def emit_dart_card_label_runs(delta: dict) -> str:
    """The one property each card-label run needs that its nearest semantic style does not carry."""
    tracking = delta.get("tracking")
    weight = delta.get("familyWeight")
    if tracking is None or not weight:
        raise TokenError("cardLabelRuns needs a tracking and a familyWeight")
    return "\n".join([
        "",
        "/// The card's two label runs, each one property off a token — see the `cardLabelRuns` delta.",
        "const double smileCardTitleTracking = %s;" % dart_double(tracking),
        "const int smileCardFamilyWeight = %s;" % int(weight),
    ])


def emit_dart_card_stroke(values: dict) -> str:
    """A pair, not one value: `color.border` is the same near-white in both schemes, which is the defect."""
    missing = [mode for mode in ("light", "dark") if not values.get(mode)]
    if missing or values.get("width") is None:
        raise TokenError(f"spec/design-tokens.json cardStroke is missing {missing or ['width']}")
    return "\n".join([
        "",
        "/// One outline for every card and row, equally quiet in both schemes — see the `cardStroke` delta.",
        "const Color smileCardStrokeLight = %s;" % dart_hue_color(values["light"]),
        "const Color smileCardStrokeDark = %s;" % dart_hue_color(values["dark"]),
        "const double smileCardStrokeWidth = %s;" % dart_double(values["width"]),
    ])


def emit_dart_products_type(delta: dict) -> str:
    """The frame's Type/Heading and Type/Title, which the vendored ramp does not match."""
    keys = ("headingSize", "headingLineHeight", "headingTracking", "headingWeight",
            "sectionSize", "sectionLineHeight", "sectionWeight")
    missing = [k for k in keys if delta.get(k) is None]
    if missing:
        raise TokenError(f"productsScreenType is missing {missing}")
    return "\n".join([
        "",
        "/// The products header and section headers, which text-style.* does not match — see the `productsScreenType` delta.",
        "const double smileHeadingPageSize = %s;" % dart_double(delta["headingSize"]),
        "const double smileHeadingPageLineHeight = %s;" % dart_double(delta["headingLineHeight"]),
        "const double smileHeadingPageTracking = %s;" % dart_double(delta["headingTracking"]),
        "const int smileHeadingPageWeight = %s;" % int(delta["headingWeight"]),
        "const double smileSectionHeaderSize = %s;" % dart_double(delta["sectionSize"]),
        "const double smileSectionHeaderLineHeight = %s;" % dart_double(delta["sectionLineHeight"]),
        "const int smileSectionHeaderWeight = %s;" % int(delta["sectionWeight"]),
    ])


def generate_dart_product_hues() -> str:
    body = (
        DART_HUES_HEADER
        + "\n"
        + emit_dart_product_hues(read_product_hues())
        + "\n"
        + emit_dart_soft_badge_fills(read_soft_badge_fills())
        + "\n"
        + emit_dart_border_strong(read_border_strong())
        + "\n"
        + emit_dart_surface2(read_surface2())
        + "\n"
        + emit_dart_off_black(read_off_black())
        + emit_dart_nav_bar_fill(read_nav_bar_fill())
        + "\n"
        + emit_dart_profile_hues(read_profile_hues())
        + "\n"
        + emit_dart_token_session(read_token_session())
        + emit_dart_label_type_style(read_label_type_style())
        + emit_dart_card_label_runs(read_card_label_runs())
        + emit_dart_card_stroke(read_card_stroke())
        + emit_dart_products_type(read_products_type())
        + "\n"
    )
    return dart_formatted(body)


def swift_color(value: str) -> str:
    """`#RRGGBB` to the vendored `Color(hex:)`. Alpha is applied at the use site, never baked in."""
    text = value.strip().lstrip("#")
    if len(text) != 6 or not all(c in "0123456789abcdefABCDEF" for c in text):
        raise TokenError(f"product hue {value!r} is not a #RRGGBB colour")
    return f"Color(hex: 0x{text.upper()})"


def emit_swift_type(tokens: dict) -> str:
    """SwiftUI wants the ABSOLUTE line height, as Compose does; `lineSpacing` derives from it."""
    lines = [
        "/// The token source's type ramp, bound to the font families the app supplies.",
        "public struct SmileTypeStyles: Sendable {",
        "    private let display: String",
        "    private let body: String",
        "",
        "    public init(display: String, body: String) {",
        "        self.display = display",
        "        self.body = body",
        "    }",
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
            "",
            f"    public var {camel(path)}: SmileTextStyle {{",
            "        SmileTextStyle(",
            f"            family: {slot},",
            f"            weight: {int(float(value['fontWeight']))},",
            f"            size: {size:g},",
            f"            lineHeight: {line_height:g},",
            f"            tracking: {tracking:g}",
            "        )",
            "    }",
        ]
    lines.append("}")
    return "\n".join(lines)


def emit_swift_product_hues(hues: dict) -> str:
    """One entry per product, keyed by the same id `spec/` uses everywhere else."""
    if not hues:
        raise TokenError("spec/design-tokens.json carries no productHues.hues entries")
    lines = [
        "/// Keyed by the product id in spec/scenarios.json. A product absent here has no hue yet.",
        "public let smileProductHues: [String: SmileProductHue] = [",
    ]
    for product, hue in hues.items():
        missing = {"from", "to", "cardIcon", "icon", "tile"} - set(hue)
        if missing:
            raise TokenError(f"product hue {product!r} is missing {sorted(missing)}")
        lines += [
            f'    "{product}": SmileProductHue(',
            f"        from: {swift_color(hue['from'])},",
            f"        to: {swift_color(hue['to'])},",
            f"        cardIcon: {swift_color(hue['cardIcon'])},",
            f"        icon: {swift_color(hue['icon'])},",
            f"        tile: {swift_color(hue['tile'])},",
        ]
        for index, role in enumerate(("stopStart", "stopEnd", "fromAlpha", "toAlpha")):
            if hue.get(role) is None:
                raise TokenError(f"product hue {product!r} is missing {role}")
            comma = "" if index == 3 else ","
            lines.append(f"        {role}: {hue[role]}{comma}")
        lines.append("    ),")
    lines.append("]")
    return "\n".join(lines)


def emit_swift_soft_badge_fills(fills: dict) -> str:
    """The soft status pills, keyed by the feedback role the four job statuses map onto."""
    roles = ["success", "info", "warning", "error"]
    missing = [role for role in roles if role not in fills]
    if missing:
        raise TokenError(f"spec/design-tokens.json softBadgeFills.fills is missing {missing}")
    lines = [
        "",
        "/// Keyed by feedback role. The design system's own badge.* pairs are saturated, a different treatment.",
        "public let smileSoftBadgeFills: [String: SmileSoftBadgeFill] = [",
    ]
    for role in roles:
        pair = fills[role]
        for key in ("background", "text"):
            if key not in pair:
                raise TokenError(f"soft badge fill {role!r} is missing {key!r}")
        lines += [
            f'    "{role}": SmileSoftBadgeFill(',
            f"        background: {swift_color(pair['background'])},",
            f"        text: {swift_color(pair['text'])}",
            "    ),",
        ]
    lines.append("]")
    return "\n".join(lines)


def emit_swift_spec_color(name: str, delta_id: str, doc: str, value) -> str:
    """A colour the design uses that the design system carries no semantic role for."""
    if not isinstance(value, str) or not value:
        raise TokenError(f"spec/design-tokens.json {delta_id} carries no value")
    return "\n".join(["", f"/// {doc}", f"public let {name}: Color = {swift_color(value)}"])


def emit_swift_border_strong(value) -> str:
    return emit_swift_spec_color(
        "smileBorderStrong",
        "borderStrong",
        "The design's `color/border-strong`, for a control ring that `color.border` is too pale to draw.",
        value,
    )


def emit_swift_surface2(value) -> str:
    return emit_swift_spec_color(
        "smileSurface2",
        "surface2",
        "The design's `color/surface-2`, a cool grey subtle fill — `color.surface-alt` is a warm cream.",
        value,
    )


def emit_swift_off_black(values) -> str:
    """A pair, not a single value: every role it paints is drawn in both schemes."""
    missing = [mode for mode in ("light", "dark") if not values.get(mode)]
    if missing:
        raise TokenError(f"spec/design-tokens.json offBlack is missing {missing}")
    return "\n".join([
        "",
        "/// The design's `Off_black`: the warm strong foreground. Seven roles, one variable — see the `offBlack` delta.",
        f"public let smileOffBlackLight: Color = {swift_color(values['light'])}",
        f"public let smileOffBlackDark: Color = {swift_color(values['dark'])}",
    ])


def emit_swift_nav_bar_fill(values) -> str:
    """The bar's own fill: the page's own colour leaves it invisible in dark."""
    missing = [mode for mode in ("light", "dark") if not values.get(mode)]
    if missing:
        raise TokenError(f"spec/design-tokens.json navBarFill is missing {missing}")
    return "\n".join([
        "",
        "/// The floating nav bar's fill — see the `navBarFill` delta.",
        f"public let smileNavBarLight: Color = {swift_color(values['light'])}",
        f"public let smileNavBarDark: Color = {swift_color(values['dark'])}",
    ])


def emit_swift_profile_hues(hues) -> str:
    """One avatar fill per profile, cycled by list position."""
    if not hues:
        raise TokenError("spec/design-tokens.json profileHues carries no hues")
    lines = [
        "",
        "/// Avatar fills, one per profile, taken in list order and cycled beyond the list.",
        "public let smileProfileHues: [Color] = [",
    ]
    lines += ["    %s," % swift_color(h) for h in hues]
    lines.append("]")
    return "\n".join(lines)


def emit_swift_token_session(delta: dict) -> str:
    """The session card's gradient and the countdown ring, which no semantic role covers."""
    grad = delta.get("cardGradient") or []
    alpha = delta.get("cardGradientAlpha") or []
    ring = delta.get("ring")
    opacity = delta.get("ringTrackOpacity")
    if len(grad) != 2 or len(alpha) != 2 or not ring or opacity is None:
        raise TokenError("tokenSessionGreens needs a two-stop cardGradient with its alphas, a ring and a ringTrackOpacity")
    return "\n".join([
        "",
        "/// The session card's horizontal gradient. Both stops are translucent, so the card composites against the page.",
        "public let smileTokenSessionGradient: [Color] = [%s, %s]" % (swift_color(grad[0]), swift_color(grad[1])),
        "public let smileTokenSessionGradientAlpha: [CGFloat] = [%s, %s]" % (alpha[0], alpha[1]),
        "",
        "/// The countdown ring: this colour solid for progress, and the same colour faded for the track.",
        "public let smileTokenRing: Color = %s" % swift_color(ring),
        "public let smileTokenRingTrackOpacity: CGFloat = %s" % opacity,
    ])


def emit_swift_label_type_style(delta: dict) -> str:
    """The all-caps label size and tracking, which text-style.overline sets a point small and solid."""
    size = delta.get("size")
    tracking = delta.get("tracking")
    if not size or tracking is None:
        raise TokenError("labelTypeStyle needs a size and a tracking")
    return "\n".join([
        "",
        "/// The design's Type/Label: a point larger than text-style.overline, and spaced.",
        "public let smileLabelSize: CGFloat = %s" % size,
        "public let smileLabelTracking: CGFloat = %s" % tracking,
    ])


def emit_swift_card_label_runs(delta: dict) -> str:
    """The one property each card-label run needs that its nearest semantic style does not carry."""
    tracking = delta.get("tracking")
    weight = delta.get("familyWeight")
    if tracking is None or not weight:
        raise TokenError("cardLabelRuns needs a tracking and a familyWeight")
    return "\n".join([
        "",
        "/// The card's two label runs, each one property off a token — see the `cardLabelRuns` delta.",
        "public let smileCardTitleTracking: CGFloat = %s" % tracking,
        "public let smileCardFamilyWeight: Int = %s" % weight,
    ])


def emit_swift_card_stroke(values: dict) -> str:
    """A pair, not one value: `color.border` is the same near-white in both schemes, which is the defect."""
    missing = [mode for mode in ("light", "dark") if not values.get(mode)]
    if missing or values.get("width") is None:
        raise TokenError(f"spec/design-tokens.json cardStroke is missing {missing or ['width']}")
    return "\n".join([
        "",
        "/// One outline for every card and row, equally quiet in both schemes — see the `cardStroke` delta.",
        "public let smileCardStrokeLight: Color = %s" % swift_color(values["light"]),
        "public let smileCardStrokeDark: Color = %s" % swift_color(values["dark"]),
        "public let smileCardStrokeWidth: CGFloat = %s" % values["width"],
    ])


def emit_swift_products_type(delta: dict) -> str:
    """The frame's Type/Heading and Type/Title, which the vendored ramp does not match."""
    keys = ("headingSize", "headingLineHeight", "headingTracking", "headingWeight",
            "sectionSize", "sectionLineHeight", "sectionWeight")
    missing = [k for k in keys if delta.get(k) is None]
    if missing:
        raise TokenError(f"productsScreenType is missing {missing}")
    return "\n".join([
        "",
        "/// The products header and section headers, which text-style.* does not match — see the `productsScreenType` delta.",
        "public let smileHeadingPageSize: CGFloat = %s" % delta["headingSize"],
        "public let smileHeadingPageLineHeight: CGFloat = %s" % delta["headingLineHeight"],
        "public let smileHeadingPageTracking: CGFloat = %s" % delta["headingTracking"],
        "public let smileHeadingPageWeight: Int = %s" % delta["headingWeight"],
        "public let smileSectionHeaderSize: CGFloat = %s" % delta["sectionSize"],
        "public let smileSectionHeaderLineHeight: CGFloat = %s" % delta["sectionLineHeight"],
        "public let smileSectionHeaderWeight: Int = %s" % delta["sectionWeight"],
    ])


def generate_swift_product_hues() -> str:
    body = (
        SWIFT_HUES_HEADER
        + "\n"
        + emit_swift_product_hues(read_product_hues())
        + "\n"
        + emit_swift_soft_badge_fills(read_soft_badge_fills())
        + "\n"
        + emit_swift_border_strong(read_border_strong())
        + "\n"
        + emit_swift_surface2(read_surface2())
        + "\n"
        + emit_swift_off_black(read_off_black())
        + emit_swift_nav_bar_fill(read_nav_bar_fill())
        + "\n"
        + emit_swift_profile_hues(read_profile_hues())
        + "\n"
        + emit_swift_token_session(read_token_session())
        + emit_swift_label_type_style(read_label_type_style())
        + emit_swift_card_label_runs(read_card_label_runs())
        + emit_swift_card_stroke(read_card_stroke())
        + emit_swift_products_type(read_products_type())
        + "\n"
    )
    return swift_formatted(body)


def ts_color(value: str) -> str:
    """`#RRGGBB` to a quoted lowercase hex string, matching the vendored tokens.ts convention."""
    text = value.strip().lstrip("#")
    if len(text) != 6 or not all(c in "0123456789abcdefABCDEF" for c in text):
        raise TokenError(f"product hue {value!r} is not a #RRGGBB colour")
    return f"'#{text.lower()}'"


def emit_ts_product_hues(hues: dict) -> str:
    """One entry per product, keyed by the same id `spec/` uses everywhere else."""
    if not hues:
        raise TokenError("spec/design-tokens.json carries no productHues.hues entries")
    lines = [
        "/** One product's colouring. `cardIcon` tints the card's glyph; `icon` and `tile` are the list row's pair. */",
        "export type SmileProductHue = {",
        "  readonly from: string;",
        "  readonly to: string;",
        "  readonly cardIcon: string;",
        "  readonly icon: string;",
        "  readonly tile: string;",
        "  /** Stop positions as fractions. `stopEnd` may exceed 1: the design runs it past the card's edge. */",
        "  readonly stopStart: number;",
        "  readonly stopEnd: number;",
        "  readonly fromAlpha: number;",
        "  readonly toAlpha: number;",
        "};",
        "",
        "/** Keyed by the product id in spec/scenarios.json. A product absent here has no hue yet. */",
        "export const smileProductHues: Readonly<Record<string, SmileProductHue>> = {",
    ]
    for product, hue in hues.items():
        missing = {"from", "to", "cardIcon", "icon", "tile"} - set(hue)
        if missing:
            raise TokenError(f"product hue {product!r} is missing {sorted(missing)}")
        lines.append(f"  {product}: {{")
        for role in ("from", "to", "cardIcon", "icon", "tile"):
            lines.append(f"    {role}: {ts_color(hue[role])},")
        for role in ("stopStart", "stopEnd", "fromAlpha", "toAlpha"):
            if hue.get(role) is None:
                raise TokenError(f"product hue {product!r} is missing {role}")
            lines.append(f"    {role}: {hue[role]},")
        lines.append("  },")
    lines.append("};")
    return "\n".join(lines)


def emit_ts_soft_badge_fills(fills: dict) -> str:
    """The soft status pills, keyed by the feedback role the four job statuses map onto."""
    roles = ["success", "info", "warning", "error"]
    missing = [role for role in roles if role not in fills]
    if missing:
        raise TokenError(f"spec/design-tokens.json softBadgeFills.fills is missing {missing}")
    lines = [
        "",
        "/** One status pill's soft fill: a pale background with text that clears contrast on it. */",
        "export type SmileSoftBadgeFill = { readonly background: string; readonly text: string };",
        "",
        "/** Keyed by feedback role. The design system's own badge.* pairs are saturated, which is a different treatment. */",
        "export const smileSoftBadgeFills: Readonly<Record<string, SmileSoftBadgeFill>> = {",
    ]
    for role in roles:
        pair = fills[role]
        for key in ("background", "text"):
            if key not in pair:
                raise TokenError(f"soft badge fill {role!r} is missing {key!r}")
        lines += [
            f"  {role}: {{",
            f"    background: {ts_color(pair['background'])},",
            f"    text: {ts_color(pair['text'])},",
            "  },",
        ]
    lines.append("};")
    return "\n".join(lines)


def emit_ts_spec_color(name: str, delta_id: str, doc: str, value) -> str:
    """A colour the design uses that the design system carries no semantic role for."""
    if not isinstance(value, str) or not value:
        raise TokenError(f"spec/design-tokens.json {delta_id} carries no value")
    return "\n".join(["", f"/** {doc} */", f"export const {name} = {ts_color(value)};"])


def emit_ts_border_strong(value) -> str:
    return emit_ts_spec_color(
        "smileBorderStrong",
        "borderStrong",
        "The design's `color/border-strong`, for a control ring that `color.border` is too pale to draw.",
        value,
    )


def emit_ts_surface2(value) -> str:
    return emit_ts_spec_color(
        "smileSurface2",
        "surface2",
        "The design's `color/surface-2`, a cool grey subtle fill — `color.surface-alt` is a warm cream.",
        value,
    )


def emit_ts_off_black(values) -> str:
    """A pair, not a single value: every role it paints is drawn in both schemes."""
    missing = [mode for mode in ("light", "dark") if not values.get(mode)]
    if missing:
        raise TokenError(f"spec/design-tokens.json offBlack is missing {missing}")
    return "\n".join([
        "",
        "/** The design's `Off_black`: the warm strong foreground. Seven roles, one variable — see the `offBlack` delta. */",
        f"export const smileOffBlackLight = {ts_color(values['light'])};",
        f"export const smileOffBlackDark = {ts_color(values['dark'])};",
    ])


def emit_ts_nav_bar_fill(values) -> str:
    """The bar's own fill: the page's own colour leaves it invisible in dark."""
    missing = [mode for mode in ("light", "dark") if not values.get(mode)]
    if missing:
        raise TokenError(f"spec/design-tokens.json navBarFill is missing {missing}")
    return "\n".join([
        "",
        "/** The floating nav bar's fill — see the `navBarFill` delta. */",
        f"export const smileNavBarLight = {ts_color(values['light'])};",
        f"export const smileNavBarDark = {ts_color(values['dark'])};",
    ])


def emit_ts_profile_hues(hues) -> str:
    """One avatar fill per profile, cycled by list position."""
    if not hues:
        raise TokenError("spec/design-tokens.json profileHues carries no hues")
    lines = [
        "",
        "/** Avatar fills, one per profile, taken in list order and cycled beyond the list. */",
        "export const smileProfileHues: readonly string[] = [",
    ]
    lines += ["  %s," % ts_color(hue) for hue in hues]
    lines.append("];")
    return "\n".join(lines)


def emit_ts_token_session(delta: dict) -> str:
    """The session card's gradient and the countdown ring, which no semantic role covers."""
    grad = delta.get("cardGradient") or []
    alpha = delta.get("cardGradientAlpha") or []
    ring = delta.get("ring")
    opacity = delta.get("ringTrackOpacity")
    if len(grad) != 2 or len(alpha) != 2 or not ring or opacity is None:
        raise TokenError("tokenSessionGreens needs a two-stop cardGradient with its alphas, a ring and a ringTrackOpacity")
    return "\n".join([
        "",
        "/** The session card's horizontal gradient. Both stops are translucent, so the card composites against the page. */",
        "export const smileTokenSessionGradient: readonly [string, string] = [%s, %s];"
        % (ts_color(grad[0]), ts_color(grad[1])),
        "export const smileTokenSessionGradientAlpha: readonly [number, number] = [%s, %s];" % (alpha[0], alpha[1]),
        "",
        "/** The countdown ring: this colour solid for progress, and the same colour faded for the track. */",
        "export const smileTokenRing = %s;" % ts_color(ring),
        "export const smileTokenRingTrackOpacity = %s;" % opacity,
    ])


def emit_ts_label_type_style(delta: dict) -> str:
    """The all-caps label size and tracking, which text-style.overline sets a point small and solid."""
    size = delta.get("size")
    tracking = delta.get("tracking")
    if not size or tracking is None:
        raise TokenError("labelTypeStyle needs a size and a tracking")
    return "\n".join([
        "",
        "/** The design's Type/Label: a point larger than text-style.overline, and spaced. */",
        "export const smileLabelSize = %s;" % size,
        "export const smileLabelTracking = %s;" % tracking,
    ])


def emit_ts_card_label_runs(delta: dict) -> str:
    """The one property each card-label run needs that its nearest semantic style does not carry."""
    tracking = delta.get("tracking")
    weight = delta.get("familyWeight")
    if tracking is None or not weight:
        raise TokenError("cardLabelRuns needs a tracking and a familyWeight")
    return "\n".join([
        "",
        "/** The card's two label runs, each one property off a token — see the `cardLabelRuns` delta. */",
        "export const smileCardTitleTracking = %s;" % tracking,
        "export const smileCardFamilyWeight = %s;" % weight,
    ])


def emit_ts_card_stroke(values: dict) -> str:
    """A pair, not one value: `color.border` is the same near-white in both schemes, which is the defect."""
    missing = [mode for mode in ("light", "dark") if not values.get(mode)]
    if missing or values.get("width") is None:
        raise TokenError(f"spec/design-tokens.json cardStroke is missing {missing or ['width']}")
    return "\n".join([
        "",
        "/** One outline for every card and row, equally quiet in both schemes — see the `cardStroke` delta. */",
        "export const smileCardStrokeLight = %s;" % ts_color(values["light"]),
        "export const smileCardStrokeDark = %s;" % ts_color(values["dark"]),
        "export const smileCardStrokeWidth = %s;" % values["width"],
    ])


def emit_ts_products_type(delta: dict) -> str:
    """The frame's Type/Heading and Type/Title, which the vendored ramp does not match."""
    keys = ("headingSize", "headingLineHeight", "headingTracking", "headingWeight",
            "sectionSize", "sectionLineHeight", "sectionWeight")
    missing = [k for k in keys if delta.get(k) is None]
    if missing:
        raise TokenError(f"productsScreenType is missing {missing}")
    return "\n".join([
        "",
        "/** The products header and section headers, which text-style.* does not match — see the `productsScreenType` delta. */",
        "export const smileHeadingPageSize = %s;" % delta["headingSize"],
        "export const smileHeadingPageLineHeight = %s;" % delta["headingLineHeight"],
        "export const smileHeadingPageTracking = %s;" % delta["headingTracking"],
        "export const smileHeadingPageWeight = %s;" % delta["headingWeight"],
        "export const smileSectionHeaderSize = %s;" % delta["sectionSize"],
        "export const smileSectionHeaderLineHeight = %s;" % delta["sectionLineHeight"],
        "export const smileSectionHeaderWeight = %s;" % delta["sectionWeight"],
        "",
    ])


def generate_ts_product_hues() -> str:
    return (
        TS_HUES_HEADER
        + "\n"
        + emit_ts_product_hues(read_product_hues())
        + "\n"
        + emit_ts_soft_badge_fills(read_soft_badge_fills())
        + "\n"
        + emit_ts_border_strong(read_border_strong())
        + "\n"
        + emit_ts_surface2(read_surface2())
        + "\n"
        + emit_ts_off_black(read_off_black())
        + emit_ts_nav_bar_fill(read_nav_bar_fill())
        + "\n"
        + emit_ts_profile_hues(read_profile_hues())
        + "\n"
        + emit_ts_token_session(read_token_session())
        + emit_ts_label_type_style(read_label_type_style())
        + emit_ts_card_label_runs(read_card_label_runs())
        + emit_ts_card_stroke(read_card_stroke())
        + emit_ts_products_type(read_products_type())
    )


def generate_swift_type(ds: str) -> str:
    tokens_path = os.path.join(ds, "dist", "json", "tokens.flat.json")
    with io.open(tokens_path, encoding="utf-8") as handle:
        data = json.load(handle)
    return swift_formatted(SWIFT_HEADER + "\n" + emit_swift_type(data["light"]) + "\n")


def generate_kotlin_product_hues() -> str:
    return (
        KOTLIN_HUES_HEADER
        + "\n"
        + emit_kotlin_product_hues(read_product_hues())
        + "\n"
        + emit_kotlin_soft_badge_fills(read_soft_badge_fills())
        + "\n"
        + emit_kotlin_border_strong(read_border_strong())
        + "\n"
        + emit_kotlin_surface2(read_surface2())
        + "\n"
        + emit_kotlin_off_black(read_off_black())
        + emit_kotlin_nav_bar_fill(read_nav_bar_fill())
        + "\n"
        + emit_kotlin_profile_hues(read_profile_hues())
        + "\n"
        + emit_kotlin_token_session(read_token_session())
        + emit_kotlin_label_type_style(read_label_type_style())
        + emit_kotlin_card_label_runs(read_card_label_runs())
        + emit_kotlin_card_stroke(read_card_stroke())
        + emit_kotlin_products_type(read_products_type())
        + "\n"
    )


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


def copy_fonts(ds: str, check: bool, copies=FONT_COPIES) -> bool:
    ok = True
    for source, dest in copies:
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


def swift_formatted(content: str) -> str:
    """Run swiftformat over the generated source when it is installed.

    The same reason the Dart output is formatted: `ios/verify.sh` lints this tree, so without
    this the generator and the formatter disagree and `--check` passes or fails depending on
    which ran last.
    """
    if not shutil.which("swiftformat"):
        return content
    config = os.path.join(REPO, "ios", ".swiftformat")
    with tempfile.TemporaryDirectory() as tmp:
        path = os.path.join(tmp, "Generated.swift")
        with io.open(path, "w", encoding="utf-8") as handle:
            handle.write(content)
        result = subprocess.run(
            ["swiftformat", "--config", config, "--quiet", path],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode != 0:
            raise TokenError(
                "swiftformat rejected the generated source, which means the emitters "
                "produced invalid Swift:\n" + (result.stderr or result.stdout).strip()[:800]
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
    ok = write(DART_HUES_OUT, generate_dart_product_hues(), args.check) and ok

    if args.all:
        ok = copy_upstream(ds, args.check) and ok
        ok = copy_fonts(ds, args.check, FLUTTER_FONT_COPIES) and ok
        if os.path.isdir(os.path.join(REPO, ANDROID_UI)):
            ok = write(KOTLIN_TYPE_OUT, generate_kotlin_type(ds), args.check) and ok
            ok = write(KOTLIN_HUES_OUT, generate_kotlin_product_hues(), args.check) and ok
            ok = copy_fonts(ds, args.check) and ok
        else:
            print(f"  skipped    {KOTLIN_TYPE_OUT} ({ANDROID_UI} does not exist yet)")

        if os.path.isdir(os.path.join(REPO, IOS_UI)):
            ok = write(SWIFT_TYPE_OUT, generate_swift_type(ds), args.check) and ok
            ok = write(SWIFT_HUES_OUT, generate_swift_product_hues(), args.check) and ok
            ok = copy_fonts(ds, args.check, IOS_FONT_COPIES) and ok
        else:
            print(f"  skipped    {SWIFT_TYPE_OUT} ({IOS_UI} does not exist yet)")

        if os.path.isdir(os.path.join(REPO, EXPO_UI)):
            ok = write(TS_HUES_OUT, generate_ts_product_hues(), args.check) and ok
            ok = copy_fonts(ds, args.check, EXPO_FONT_COPIES) and ok
        else:
            print(f"  skipped    {TS_HUES_OUT} ({EXPO_UI} does not exist yet)")

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
