#!/usr/bin/env python3
"""Turn the shared icon record into a TypeScript module react-native-svg can draw.

`design/icons/` holds the design's marks as SVG. Android consumes them as vector drawables and iOS
has to re-emit every path as a SwiftUI shape, because SwiftUI cannot render an SVG and that port
would not add a library for it.

This platform is the easy one: `react-native-svg` is already a required peer of the SDK, so the
path data is carried through VERBATIM rather than re-parsed. That removes the whole class of bug the
iOS emitter has to guard against — a dropped subpath, a command it does not implement — because
nothing here interprets a path.

What IS interpreted is the frame and the paint: the viewBox, and whether each subpath is stroked or
filled, at what width and with what cap. A mark carries the answer so a caller never guesses.

Anything unexpected FAILS the run rather than being skipped: a mark that renders wrong is worse
than a build that stops.

Usage:
    scripts/generate_expo_icons.py            # regenerate
    scripts/generate_expo_icons.py --check    # fail if the output is stale
"""

from __future__ import annotations

import argparse
import io
import json
import os
import re
import sys
from xml.etree import ElementTree

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICON_DIR = "design/icons"
EXPO_UI = "expo/sample-ui"
OUT = f"{EXPO_UI}/src/smile-icons.ts"

NUMBER = re.compile(r"[-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?")

HEADER = """// Smile ID icons — GENERATED from design/icons/*.svg. Do not edit by hand.
//
// Regenerate with: scripts/generate_expo_icons.py
//
// The path data is carried through verbatim: react-native-svg draws an SVG path directly, so unlike
// the SwiftUI emitter nothing here re-parses one. Each mark keeps its own viewBox and says whether
// its subpaths are stroked or filled, because the design's set is strokes and the Material Symbols
// stand-ins are fills.

/// How one subpath of a mark is painted. The caller supplies the colour; the mark supplies the rest.
export type SmileIconPaint =
  | { readonly kind: 'fill' }
  | { readonly kind: 'stroke'; readonly width: number; readonly round: boolean };

/// One subpath: its path data, how it is painted, and the opacity it inherited from the record.
export type SmileIconPart = {
  readonly d: string;
  readonly paint: SmileIconPaint;
  readonly opacity: number;
};

/// One mark in its own coordinate space, which the renderer maps onto the size a caller asks for.
export type SmileIcon = {
  readonly minX: number;
  readonly minY: number;
  readonly width: number;
  readonly height: number;
  readonly parts: readonly SmileIconPart[];
};
"""


class IconError(Exception):
    pass


def camel(name: str) -> str:
    head, *rest = name.replace("-", "_").split("_")
    return head + "".join(part[:1].upper() + part[1:] for part in rest)


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

    parts: list[dict] = []

    def walk(element, opacity: float) -> None:
        tag = element.tag.rsplit("}", 1)[-1]
        # No mark uses one today, and silently ignoring one would move the whole subtree.
        if "transform" in element.attrib:
            raise IconError(f"{name} carries a transform, which this emitter does not apply")
        opacity *= float(element.attrib.get("opacity", 1))

        if tag == "path" and element.attrib.get("d"):
            stroke_colour = element.attrib.get("stroke")
            if stroke_colour and stroke_colour != "none":
                paint = {
                    "kind": "stroke",
                    "width": float(element.attrib.get("stroke-width", 1)),
                    "round": element.attrib.get("stroke-linecap") == "round",
                }
            else:
                paint = {"kind": "fill"}
            parts.append({"d": element.attrib["d"].strip(), "paint": paint, "opacity": opacity})

        for child in element:
            walk(child, opacity)

    walk(root, 1.0)
    if not parts:
        raise IconError(f"{name} has no <path>, so nothing would be drawn")
    return {"minX": min_x, "minY": min_y, "width": width, "height": height, "parts": parts}


def number(value: float) -> str:
    text = f"{value:g}"
    return text


def emit_paint(paint: dict) -> str:
    if paint["kind"] == "fill":
        return "{ kind: 'fill' }"
    return "{ kind: 'stroke', width: %s, round: %s }" % (
        number(paint["width"]),
        "true" if paint["round"] else "false",
    )


def emit_icon(name: str, icon: dict) -> str:
    lines = [f"  {camel(name)}: {{"]
    for key in ("minX", "minY", "width", "height"):
        lines.append(f"    {key}: {number(icon[key])},")
    lines.append("    parts: [")
    for part in icon["parts"]:
        # json.dumps so a path containing a quote or a backslash cannot break the emitted module.
        lines.append(
            "      { d: %s, paint: %s, opacity: %s },"
            % (json.dumps(part["d"]), emit_paint(part["paint"]), number(part["opacity"]))
        )
    lines += ["    ],", "  },"]
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

    body = "\n".join(blocks)
    doc = "/** Every mark in `design/icons/`, keyed by its file name in camelCase. */"
    return (
        f"{HEADER}\n{doc}\nexport const smileIcons = {{\n{body}\n}} as const"
        " satisfies Readonly<Record<string, SmileIcon>>;\n\n"
        "/** A mark's name, so a caller cannot ask for one the record does not hold. */\n"
        "export type SmileIconName = keyof typeof smileIcons;\n"
    )


def write(rel_path: str, content: str, check: bool) -> bool:
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


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if the output is stale")
    args = parser.parse_args(argv)

    if not os.path.isdir(os.path.join(REPO, EXPO_UI)):
        print(f"  skipped    {OUT} ({EXPO_UI} does not exist yet)")
        return 0

    try:
        content = generate()
    except (IconError, ElementTree.ParseError) as error:
        print(f"\n{error}", file=sys.stderr)
        return 1

    if not write(OUT, content, args.check):
        print("\nIcons are stale. Run scripts/generate_expo_icons.py", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
