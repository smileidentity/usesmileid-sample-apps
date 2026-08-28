#!/usr/bin/env python3
"""Turn the shared icon record into SwiftUI shapes.

`design/icons/` holds the design's marks as SVG, and Android consumes them as vector drawables it
already has. iOS had nothing: a SwiftUI view cannot render an SVG, and adding an SVG library to a
sample app would put a dependency in front of a partner for the sake of eight arrows.

So the paths are GENERATED into Swift, the same way the design tokens are, and for the same reason:
a hand-copied path is a hand-copied constant nobody can re-derive.

Only the commands the record actually uses are supported — M L H V C Q T Z, absolute and relative.
Anything else FAILS the run rather than being skipped, because a silently dropped subpath is a
mark that renders wrong rather than not at all.

Usage:
    scripts/generate_ios_icons.py            # regenerate
    scripts/generate_ios_icons.py --check    # fail if the output is stale
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
from xml.etree import ElementTree

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICON_DIR = "design/icons"
OUT = "ios/SampleUI/Sources/SampleUI/Icons/SmileIcons.swift"

# `d="…"` only where `d` is its own attribute — `id="…"` also ends in `d="`.
PATH_D = re.compile(r'(?:^|[\s;])d="([^"]+)"')
NUMBER = re.compile(r"[-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?")
TOKEN = re.compile(r"([MmLlHhVvCcQqTtZz])|([-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?)")

HEADER = '''// Smile ID icons — GENERATED from design/icons/*.svg. Do not edit by hand.
//
// Regenerate with: scripts/generate_ios_icons.py
//
// SwiftUI cannot render an SVG and this repo will not add a library to do it, so the marks are
// emitted as Shapes in their own viewBox coordinates and scaled to the size the caller asks for.
// The Compose twin consumes the same SVGs as vector drawables.

import SwiftUI

/// How one subpath of a mark is drawn. The design's marks are strokes; the Material Symbols
/// stand-ins are fills, so a mark carries the answer rather than the caller guessing.
public enum SmileIconStroke: Equatable, Sendable {
  case fill
  case stroke(width: CGFloat, round: Bool)
}

/// One mark: its own coordinate space, and the subpaths that draw it.
public struct SmileIcon: Equatable, Sendable {
  public let width: CGFloat
  public let height: CGFloat
  public let minX: CGFloat
  public let minY: CGFloat
  public let parts: [SmileIconPart]
}

public struct SmileIconPart: Equatable, Sendable {
  public let stroke: SmileIconStroke
  /// Inherited down the SVG tree — the scan glyph draws its whole group at 0.45.
  public let opacity: CGFloat
  public let build: @Sendable (inout Path) -> Void

  public static func == (lhs: SmileIconPart, rhs: SmileIconPart) -> Bool {
    lhs.stroke == rhs.stroke && lhs.opacity == rhs.opacity
  }
}
'''


class IconError(RuntimeError):
    """A mark the emitter cannot turn into a Path. Fails the run rather than being skipped."""


def camel(name: str) -> str:
    head, *rest = re.split(r"[_\-]", name)
    return head + "".join(part.capitalize() for part in rest)


def tokenize(data: str):
    for match in TOKEN.finditer(data):
        yield match.group(1) or float(match.group(2))


def emit_path(data: str) -> list[str]:
    """SVG path data to SwiftUI `Path` calls, in the mark's own coordinates."""
    lines: list[str] = []
    tokens = list(tokenize(data))
    index = 0
    command = None
    x = y = start_x = start_y = 0.0
    # The previous quadratic control point, which T reflects around the current point.
    last_qx = last_qy = None

    def take(count: int) -> list[float]:
        nonlocal index
        values = tokens[index : index + count]
        if len(values) != count or any(isinstance(v, str) for v in values):
            raise IconError(f"command {command!r} wants {count} numbers, got {values!r}")
        index += count
        return [float(v) for v in values]

    while index < len(tokens):
        if isinstance(tokens[index], str):
            command = tokens[index]
            index += 1
            if command in "Zz":
                lines.append("    path.closeSubpath()")
                x, y = start_x, start_y
                last_qx = last_qy = None
                continue
        elif command is None:
            raise IconError("path data starts with a number rather than a command")
        elif command == "M":
            command = "L"  # A repeated moveto pair is an implicit lineto, per the SVG grammar.
        elif command == "m":
            command = "l"

        relative = command.islower()
        upper = command.upper()

        if upper == "M":
            dx, dy = take(2)
            x, y = (x + dx, y + dy) if relative else (dx, dy)
            start_x, start_y = x, y
            lines.append(f"    path.move(to: CGPoint(x: {x:g}, y: {y:g}))")
            last_qx = last_qy = None
        elif upper == "L":
            dx, dy = take(2)
            x, y = (x + dx, y + dy) if relative else (dx, dy)
            lines.append(f"    path.addLine(to: CGPoint(x: {x:g}, y: {y:g}))")
            last_qx = last_qy = None
        elif upper == "H":
            (dx,) = take(1)
            x = x + dx if relative else dx
            lines.append(f"    path.addLine(to: CGPoint(x: {x:g}, y: {y:g}))")
            last_qx = last_qy = None
        elif upper == "V":
            (dy,) = take(1)
            y = y + dy if relative else dy
            lines.append(f"    path.addLine(to: CGPoint(x: {x:g}, y: {y:g}))")
            last_qx = last_qy = None
        elif upper == "C":
            x1, y1, x2, y2, ex, ey = take(6)
            if relative:
                x1, y1, x2, y2, ex, ey = x + x1, y + y1, x + x2, y + y2, x + ex, y + ey
            lines.append(
                f"    path.addCurve(to: CGPoint(x: {ex:g}, y: {ey:g}), "
                f"control1: CGPoint(x: {x1:g}, y: {y1:g}), control2: CGPoint(x: {x2:g}, y: {y2:g}))"
            )
            x, y = ex, ey
            last_qx = last_qy = None
        elif upper == "Q":
            cx, cy, ex, ey = take(4)
            if relative:
                cx, cy, ex, ey = x + cx, y + cy, x + ex, y + ey
            lines.append(
                f"    path.addQuadCurve(to: CGPoint(x: {ex:g}, y: {ey:g}), "
                f"control: CGPoint(x: {cx:g}, y: {cy:g}))"
            )
            x, y, last_qx, last_qy = ex, ey, cx, cy
        elif upper == "T":
            ex, ey = take(2)
            if relative:
                ex, ey = x + ex, y + ey
            # T with no quadratic before it uses the current point, so the segment is a line.
            cx = x if last_qx is None else 2 * x - last_qx
            cy = y if last_qy is None else 2 * y - last_qy
            lines.append(
                f"    path.addQuadCurve(to: CGPoint(x: {ex:g}, y: {ey:g}), "
                f"control: CGPoint(x: {cx:g}, y: {cy:g}))"
            )
            x, y, last_qx, last_qy = ex, ey, cx, cy
        else:
            raise IconError(f"unsupported path command {command!r}; see the module docstring")

    return lines


def parse_svg(text: str, name: str) -> dict:
    """Walked as XML, not matched with a regex: opacity is inherited from an enclosing <g>, and a
    pattern that only sees one element at a time cannot know it is inside one."""
    root = ElementTree.fromstring(text)
    if "viewBox" not in root.attrib:
        raise IconError(f"{name} has no viewBox, so it cannot be scaled")
    numbers = [float(v) for v in NUMBER.findall(root.attrib["viewBox"])]
    if len(numbers) != 4:
        raise IconError(f"{name} has a viewBox with {len(numbers)} numbers, expected 4")
    min_x, min_y, width, height = numbers
    if width <= 0 or height <= 0:
        raise IconError(f"{name} has a zero-sized viewBox")

    parts: list[tuple[str, float, list[str]]] = []

    def walk(element, opacity: float) -> None:
        tag = element.tag.rsplit("}", 1)[-1]
        # No mark uses one today, and silently ignoring one would move the whole subtree.
        if "transform" in element.attrib:
            raise IconError(f"{name} carries a transform, which this emitter does not apply")
        opacity *= float(element.attrib.get("opacity", 1))

        if tag == "path" and element.attrib.get("d"):
            stroke_colour = element.attrib.get("stroke")
            if stroke_colour and stroke_colour != "none":
                stroke_width = float(element.attrib.get("stroke-width", 1))
                round_cap = element.attrib.get("stroke-linecap") == "round"
                stroke = f"stroke(width: {stroke_width:g}, round: {str(round_cap).lower()})"
            else:
                stroke = "fill"
            parts.append((stroke, opacity, emit_path(element.attrib["d"])))

        for child in element:
            walk(child, opacity)

    walk(root, 1.0)
    if not parts:
        raise IconError(f"{name} has no <path>, so nothing would be drawn")
    return {"minX": min_x, "minY": min_y, "width": width, "height": height, "parts": parts}


def emit_icon(name: str, icon: dict) -> str:
    lines = [
        f"  public static let {camel(name)} = SmileIcon(",
        f"    width: {icon['width']:g},",
        f"    height: {icon['height']:g},",
        f"    minX: {icon['minX']:g},",
        f"    minY: {icon['minY']:g},",
        "    parts: [",
    ]
    for stroke, opacity, body in icon["parts"]:
        lines.append(f"      SmileIconPart(stroke: .{stroke}, opacity: {opacity:g}) {{ path in")
        lines += [f"  {line}" for line in body]
        lines.append("      },")
    lines += ["    ]", "  )"]
    return "\n".join(lines)


def generate() -> str:
    root = os.path.join(REPO, ICON_DIR)
    files = []
    for directory, _, names in os.walk(root):
        for filename in sorted(names):
            if filename.endswith(".svg"):
                files.append(os.path.join(directory, filename))
    if not files:
        raise IconError(f"{ICON_DIR} holds no SVGs; nothing to generate")

    seen: dict[str, str] = {}
    blocks = []
    for path in sorted(files, key=lambda p: os.path.basename(p)):
        name = os.path.splitext(os.path.basename(path))[0]
        if name in seen:
            raise IconError(f"two icons are both named {name!r}: {seen[name]} and {path}")
        seen[name] = path
        with io.open(path, encoding="utf-8") as handle:
            blocks.append(emit_icon(name, parse_svg(handle.read(), name)))

    body = "\n\n".join(blocks)
    return f"{HEADER}\n/// Every mark in `design/icons/`, keyed by its file name.\npublic enum SmileIcons {{\n{body}\n}}\n"


def formatted(content: str) -> str:
    """Kept swiftformat-clean here, so the generator and `ios/verify.sh` cannot disagree."""
    if not shutil.which("swiftformat"):
        return content
    config = os.path.join(REPO, "ios", ".swiftformat")
    with tempfile.TemporaryDirectory() as tmp:
        path = os.path.join(tmp, "SmileIcons.swift")
        with io.open(path, "w", encoding="utf-8") as handle:
            handle.write(content)
        result = subprocess.run(
            ["swiftformat", "--config", config, "--quiet", path],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode != 0:
            raise IconError(
                "swiftformat rejected the generated source, which means the emitter produced "
                "invalid Swift:\n" + (result.stderr or result.stdout).strip()[:800]
            )
        with io.open(path, encoding="utf-8") as handle:
            return handle.read()


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if the output is stale")
    args = parser.parse_args(argv)

    try:
        content = formatted(generate())
    except IconError as error:
        print(f"\n{error}", file=sys.stderr)
        return 1

    target = os.path.join(REPO, OUT)
    existing = None
    if os.path.isfile(target):
        with io.open(target, encoding="utf-8") as handle:
            existing = handle.read()
    if existing == content:
        print(f"  unchanged  {OUT}")
        return 0
    if args.check:
        print(f"  STALE      {OUT}", file=sys.stderr)
        print("\nRun scripts/generate_ios_icons.py", file=sys.stderr)
        return 1
    os.makedirs(os.path.dirname(target), exist_ok=True)
    with io.open(target, "w", encoding="utf-8") as handle:
        handle.write(content)
    print(f"  {'updated' if existing else 'created'}    {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
