#!/usr/bin/env python3
"""Turn the platform's launcher mark in svgs/ into the iOS app-icon asset.

`svgs/<platform>.svg` is the shared source: the Smile ID mark plus a badge naming the platform, and
the badge is the point — four sample apps sit on one home screen and the badge is what tells them
apart. A mark without it was committed once by hand, which is why this is generated now.

Three transforms the source cannot carry, because it is also used as an ordinary illustration:

- the corner radius is dropped, because iOS masks the icon itself and a rounded source is masked
  twice, leaving a pale fringe on the device
- the alpha channel is dropped, because App Store Connect rejects an icon that has one
- the artwork is inset, because the home screen's mask is a superellipse rather than the source's
  rounded rectangle, and it cuts further into the corners: measured against it, the platform badge's
  outer corner sits at 1.07 of the mask's boundary at full size and is clipped on a real device

Rendered through QuickLook, which is WebKit: ImageMagick's own SVG renderer ignores a nested `<svg>`
element's x/y placement and drops the badge in the top-left corner at the wrong size, silently.

Writing the asset needs Pillow and QuickLook, which a developer's Mac has and CI does not — so
`--check` compares a recorded hash of the source and the scale instead of re-rendering. It catches
the failure that actually happens (the art changes and nobody regenerates) without putting an image
dependency or a window server in the gate, the way the other generators here stay pure stdlib.

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

# Chosen against a render of the actual mask, not from a guideline: at 1.00 the badge is cut, at 0.86
# the mark starts swimming in its own margin. Raising it back past ~0.94 re-clips the badge.
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
