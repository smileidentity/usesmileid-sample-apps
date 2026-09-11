#!/usr/bin/env python3
"""Render svgs/ios.svg into the iOS app-icon asset, and check it.

Three transforms the shared art cannot carry: the corner radius is dropped (iOS masks the icon
itself), the alpha channel is dropped (App Store Connect rejects one), and the artwork is inset
(the home-screen mask is a superellipse and clipped the badge at full size). Rendered through
QuickLook because ImageMagick misplaces a nested `<svg>`. `--check` compares a recorded hash of the
source and scale, so CI needs neither Pillow nor a window server.

Usage:
    scripts/generate_app_icon.py            # write the asset
    scripts/generate_app_icon.py --check    # fail if the asset is stale
"""
from __future__ import annotations

import argparse
import hashlib
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "svgs" / "ios.svg"
TARGET = ROOT / "ios" / "App" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon1024.png"
LOCK = ROOT / "scripts" / "app-icon.lock"
SIZE = 1024

# Chosen against a render of the mask: 1.00 clips the badge, 0.86 leaves the mark swimming.
CONTENT_SCALE = 0.90


def squared_off(svg: str) -> str:
    """The same artwork with its corner radius removed, so the platform's mask is the only one."""
    return re.sub(r'\s+r[xy]="[^"]*"', "", svg, count=2)


def render(svg: str) -> bytes:
    if shutil.which("qlmanage") is None:
        raise SystemExit("generate_app_icon.py needs qlmanage, which ships with macOS")
    from PIL import Image

    with tempfile.TemporaryDirectory() as work:
        source = Path(work) / "icon.svg"
        source.write_text(svg, encoding="utf-8")
        inner = round(SIZE * CONTENT_SCALE)
        subprocess.run(
            ["qlmanage", "-t", "-s", str(inner), "-o", work, str(source)],
            check=True,
            capture_output=True,
        )
        rendered = Path(work) / "icon.svg.png"
        if not rendered.is_file():
            raise SystemExit("qlmanage rendered nothing; is the source valid SVG?")
        artwork = flatten(rendered, inner)
        # Sampled rather than hard-coded: the ground is the squared-off source's own background.
        canvas = Image.new("RGB", (SIZE, SIZE), artwork.getpixel((1, 1)))
        canvas.paste(artwork, ((SIZE - inner) // 2, (SIZE - inner) // 2))
        return encode(canvas)


def flatten(path: Path, size: int):
    from PIL import Image

    image = Image.open(path).convert("RGBA")
    if image.size != (size, size):
        image = image.resize((size, size), Image.LANCZOS)
    opaque = Image.new("RGB", image.size, (255, 255, 255))
    opaque.paste(image, mask=image.split()[3])
    return opaque


def encode(image) -> bytes:
    buffer = tempfile.NamedTemporaryFile(suffix=".png", delete=False)
    image.save(buffer.name, "PNG")
    return Path(buffer.name).read_bytes()


def stamp() -> str:
    """What the asset was rendered from: the source's bytes and the inset the render applied."""
    digest = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    return f"{digest}  {SOURCE.relative_to(ROOT)}  scale={CONTENT_SCALE}\n"


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if the asset is stale")
    args = parser.parse_args(argv)

    if args.check:
        for missing in (TARGET, LOCK):
            if not missing.is_file():
                print(f"{missing.relative_to(ROOT)} is missing", file=sys.stderr)
                return 1
        if LOCK.read_text(encoding="utf-8") != stamp():
            print(
                f"{TARGET.relative_to(ROOT)} was not rendered from the current "
                f"{SOURCE.relative_to(ROOT)} — run scripts/generate_app_icon.py",
                file=sys.stderr,
            )
            return 1
        print(f"    {TARGET.relative_to(ROOT)} matches {SOURCE.relative_to(ROOT)}")
        return 0

    TARGET.parent.mkdir(parents=True, exist_ok=True)
    TARGET.write_bytes(render(squared_off(SOURCE.read_text(encoding="utf-8"))))
    LOCK.write_text(stamp(), encoding="utf-8")
    print(f"wrote {TARGET.relative_to(ROOT)} from {SOURCE.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
