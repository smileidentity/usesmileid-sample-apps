# Icon sources

The design set's SVG export, kept as the source of record so all four apps import the same geometry
instead of each re-exporting from the design file and drifting.

File names match the ids `spec/` already uses: a product's icon is its product id from
`scenarios.json` in snake case, so the mapping to a platform's asset name is mechanical.

The two document products share `document_verification.svg`: the design tells them apart by the
card's hue, which is already what tints the icon, so there is no second file to keep in sync.
Enhanced KYC has no icon yet and falls back to the shared product mark; see
`spec/components.json` → `ProductCard`.

Per platform:

- **Android** — `android/sample-ui/src/main/res/drawable/sample_ic_*.xml`, converted faithfully
  (stroke widths, caps and joins preserved) and tinted at the use site. The drawables carry an
  opaque base colour because the format requires one; nothing reads it.
