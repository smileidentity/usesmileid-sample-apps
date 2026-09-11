# Icon sources

The design set's SVG export, kept as the source of record so all four apps import the same geometry
instead of each re-exporting from the design file and drifting.

File names match the ids `spec/` already uses: a product's icon is its product id from
`scenarios.json` in snake case, so the mapping to a platform's asset name is mechanical.

The two document products share `document_verification.svg`: the design tells them apart by the
card's hue, which is already what tints the icon, so there is no second file to keep in sync.
Enhanced KYC has no icon yet and falls back to the shared product mark; see
`spec/components.json` → `ProductCard`.

`material-symbols/` holds the Material Symbols Outlined stand-ins for the glyphs the design supplies
nowhere. Check the design node's exported assets before adding one, and commit the export here the
day it is used: `trash` and `flash` sat there for a month while Android drew the design's own from
Figma exports that never reached this folder, and a port that generated from it shipped the stand-in.

Per platform:

- **Android** — `android/sample-ui/src/main/res/drawable/sample_ic_*.xml`, **generated** by
  `scripts/generate_android_icons.py` (stroke widths, caps, joins and inherited opacity preserved)
  and tinted at the use site; `android/verify.sh` fails on a stale, missing or unsourced drawable.
  The drawables carry an opaque base colour because the format requires one; nothing reads it.
  Until 2026-09-11 each drawable was written by hand from Figma's export, by which point four of the
  six product marks had drifted from this folder without anything noticing.
