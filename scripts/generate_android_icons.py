#!/usr/bin/env python3
"""Generate the Android vector drawables from design/icons/, and check them.

`android:pathData` takes SVG path grammar as-is, so this only wraps: `<g>` opacity is inherited,
a negative-origin viewBox becomes a `<group>` translate, strokes keep their caps and joins, and
`<defs>` is skipped (its clip paths are the full frame). The name map below is explicit so an
unmapped file on either side fails `--check`.

Usage:
    scripts/generate_android_icons.py            # write the drawables
    scripts/generate_android_icons.py --check    # fail if any drawable is stale, missing, or unsourced
"""
from __future__ import annotations

import argparse
import io
import os
import re
import sys
from xml.etree import ElementTree

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICON_DIR = "design/icons"
OUT_DIR = "android/sample-ui/src/main/res/drawable"
PREFIX = "sample_ic_"

# Android's resource names as they stand; everything else is `sample_ic_<file name>`.
RENAMED = {
    "agent": "setting_agent",
    "consent": "setting_consent",
    "dark_mode": "setting_dark_mode",
    "docs": "setting_docs",
    "instructions": "setting_instructions",
    "licenses": "setting_licenses",
    "preview": "setting_preview",
    "privacy": "setting_privacy",
    "smile": "setting_smile",
    "support": "setting_support",
    "terms": "setting_terms",
    "chevron": "chevron_right",
    "torch": "flash",
}

HEADER = "<!-- GENERATED from {source} by scripts/generate_android_icons.py. Do not edit by hand. -->"
NUMBER = re.compile(r"-?\d*\.?\d+(?:e[+-]?\d+)?")
BASE = "#FF000000"  # Tinted at the use site; the format needs an opaque colour and nothing reads it.


class IconError(Exception):
    pass


def resource_name(svg_name: str) -> str:
    return PREFIX + RENAMED.get(svg_name, svg_name)


def fmt(value: float) -> str:
    return f"{value:g}"


def parse(text: str, name: str) -> str:
    root = ElementTree.fromstring(text)
    if "viewBox" not in root.attrib:
        raise IconError(f"{name} has no viewBox, so it cannot be scaled")
    numbers = [float(v) for v in NUMBER.findall(root.attrib["viewBox"])]
    if len(numbers) != 4:
        raise IconError(f"{name} has a viewBox with {len(numbers)} numbers, expected 4")
    min_x, min_y, width, height = numbers
    if width <= 0 or height <= 0:
        raise IconError(f"{name} has a zero-sized viewBox")

    paths: list[str] = []

    def walk(element, opacity: float) -> None:
        tag = element.tag.rsplit("}", 1)[-1]
        if tag in ("defs", "clipPath"):
            return  # The set's clip paths are the full frame; a real one would need a <clip-path>.
        if "transform" in element.attrib:
            raise IconError(f"{name} carries a transform, which this emitter does not apply")
        opacity *= float(element.attrib.get("opacity", 1))
        if tag == "path" and element.attrib.get("d"):
            data = " ".join(element.attrib["d"].split())
            stroke = element.attrib.get("stroke")
            attrs = [f'android:pathData="{data}"']
            if stroke and stroke != "none":
                attrs.append(f'android:strokeColor="{BASE}"')
                attrs.append(f'android:strokeWidth="{fmt(float(element.attrib.get("stroke-width", 1)))}"')
                cap = element.attrib.get("stroke-linecap")
                join = element.attrib.get("stroke-linejoin")
                if cap in ("round", "square"):
                    attrs.append(f'android:strokeLineCap="{cap}"')
                if join in ("round", "bevel"):
                    attrs.append(f'android:strokeLineJoin="{join}"')
                fill = element.attrib.get("fill", "none")
                if fill and fill != "none":
                    attrs.append(f'android:fillColor="{BASE}"')
                if opacity < 1:
                    attrs.append(f'android:strokeAlpha="{opacity:g}"')
                    if fill and fill != "none":
                        attrs.append(f'android:fillAlpha="{opacity:g}"')
            else:
                attrs.append(f'android:fillColor="{BASE}"')
                if element.attrib.get("fill-rule") == "evenodd":
                    attrs.append('android:fillType="evenOdd"')
                if opacity < 1:
                    attrs.append(f'android:fillAlpha="{opacity:g}"')
            paths.append("<path\n        " + "\n        ".join(attrs) + " />")
        elif tag in ("rect", "circle", "ellipse", "line", "polyline", "polygon"):
            raise IconError(f"{name} draws a <{tag}> outside <defs>, which this emitter does not convert")
        for child in element:
            walk(child, opacity)

    walk(root, 1.0)
    if not paths:
        raise IconError(f"{name} has no <path>, so nothing would be drawn")

    indent = "    "
    body = "\n\n".join(indent + p.replace("\n        ", "\n" + indent + "    ") for p in paths)
    if min_x or min_y:
        # The Material Symbols exports sit at y −960..0; a group translate puts them in the frame.
        body = (
            f'{indent}<group\n{indent}    android:translateX="{fmt(-min_x)}"\n{indent}    android:translateY="{fmt(-min_y)}">\n'
            + "\n\n".join(indent + "    " + p.replace("\n        ", "\n" + indent + "        ") for p in paths)
            + f"\n{indent}</group>"
        )
    return (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        f"{HEADER.format(source=f'{ICON_DIR}/{name}.svg')}\n"
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        f'    android:width="{fmt(width)}dp"\n'
        f'    android:height="{fmt(height)}dp"\n'
        f'    android:viewportWidth="{fmt(width)}"\n'
        f'    android:viewportHeight="{fmt(height)}">\n'
        f"{body}\n"
        "</vector>\n"
    )


def sources() -> dict[str, str]:
    root = os.path.join(REPO, ICON_DIR)
    found: dict[str, str] = {}
    for directory, _, names in os.walk(root):
        for filename in sorted(names):
            if not filename.endswith(".svg"):
                continue
            name = os.path.splitext(filename)[0]
            if name in found:
                raise IconError(f"two icons are both named {name!r}")
            found[name] = os.path.join(directory, filename)
    if not found:
        raise IconError(f"{ICON_DIR} holds no SVGs; nothing to generate")
    return found


def generate() -> dict[str, str]:
    out: dict[str, str] = {}
    for name, path in sorted(sources().items()):
        with io.open(path, encoding="utf-8") as handle:
            out[resource_name(name) + ".xml"] = parse(handle.read(), name)
    return out


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if any drawable is stale, missing, or unsourced")
    args = parser.parse_args(argv)
    try:
        wanted = generate()
    except (IconError, ElementTree.ParseError) as error:
        print(f"generate_android_icons.py: {error}", file=sys.stderr)
        return 1

    out_dir = os.path.join(REPO, OUT_DIR)
    if args.check:
        problems = []
        on_disk = {f for f in os.listdir(out_dir) if f.startswith(PREFIX) and f.endswith(".xml")}
        for filename, content in wanted.items():
            path = os.path.join(out_dir, filename)
            if not os.path.isfile(path):
                problems.append(f"missing: {OUT_DIR}/{filename}")
            elif io.open(path, encoding="utf-8").read() != content:
                problems.append(f"stale:   {OUT_DIR}/{filename}")
        for filename in sorted(on_disk - set(wanted)):
            problems.append(f"unsourced: {OUT_DIR}/{filename} has no {ICON_DIR} source")
        if problems:
            print("\n".join(problems), file=sys.stderr)
            print("run scripts/generate_android_icons.py", file=sys.stderr)
            return 1
        print(f"    {len(wanted)} drawables match {ICON_DIR}")
        return 0

    os.makedirs(out_dir, exist_ok=True)
    for filename, content in wanted.items():
        with io.open(os.path.join(out_dir, filename), "w", encoding="utf-8") as handle:
            handle.write(content)
    print(f"wrote {len(wanted)} drawables to {OUT_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
