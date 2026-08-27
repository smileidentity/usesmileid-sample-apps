# The document-capture options the sample does not exercise

**Status:** planning. Post-release. Read out of the SDK's own public config surface, so the gap is
countable rather than estimated.

## 1. The surface, and what the sample uses of it

`DocumentCaptureConfig` is the SDK's public document-capture contract. Six configurable fields; the
sample sets two of them and hard-codes a third.

| Field | Default | Sample today | |
|---|---|---|---|
| `documentType` | `null` | set from the ID-details form | ✅ |
| `captureBothSides` | `true` | hard-coded `true` | ⚠️ §3 |
| `allowSkipBack` | `false` | set `true` | ✅ |
| `captureMode` | `AutoCaptureWithManualFallback(10s)` | **never set** | ❌ |
| `allowGalleryUpload` | `false` | **never set** | ❌ |
| `knownIdAspectRatio` | `null` | **never set** | ❌ |

`FlowBuilderConfig.kt:161–168` is the whole of it. So three options ship in the SDK, are documented as
public API, and have **no host in this org exercising them** — which also means no device coverage and no
screenshot of what they look like.

## 2. What each unexercised option is worth

**`captureMode` is the significant one.** It is a sealed interface with three cases, and it replaced an
earlier `autoCapture` + `autoCaptureTimeout` flag pair — so partners migrating from that pair need to see
the typed form working:

- `AutoCapture` — fires when well-framed, no shutter button at all
- `ManualCapture` — shutter always shown, detection feedback still runs
- `AutoCaptureWithManualFallback(activateManualAfter)` — the default, surfacing a shutter after a timeout

Three reasons it deserves a sample surface. It is the option most likely to be *wrong* for a given
partner — a manual-only flow is a genuine accessibility and low-light answer, and nothing today shows it.
It projects onto the wire as `auto_capture_enabled` with values `auto_capture_only` / `manual` /
`autocapture_default`, so the host's choice is observable in a request and therefore **assertable** — a
better test than a screenshot. And the fallback timeout is a duration, which means a device flow can prove
the shutter actually appears rather than trusting that it would.

**`allowGalleryUpload`** flips the capture screen from camera-only to camera-or-gallery. It changes the
permission story and the capture surface, and it defaults off, so a partner who wants it has no reference.

**`knownIdAspectRatio`** sets the capture frame's aspect ratio when the document type does not know its
own. It is the escape hatch for `GenericDocument`, which is exactly the case a partner with an unlisted
document hits first.

## 3. One thing that looks like a defect in the sample

`captureBothSides = true` is hard-coded, but `DocumentType` carries `hasBackSide` — and
`SouthAfricaGreenBook` sets `hasBackSide = false`. So selecting a Green Book asks the SDK to capture both
sides of a document the SDK's own type model says has one.

Whether the SDK reconciles that internally is unverified and worth checking before writing it up as a bug
in either place. But the sample should not be asserting a contradiction regardless: `captureBothSides`
should follow `documentType.hasBackSide` rather than override it, which is a one-line change and a unit
test.

Worth noting the same asymmetry exists in the other direction — `Passport` has `hasBackSide = true`, which
may surprise a partner who expects a single page.

## 4. How they should surface, and how not to

The temptation is three more Settings switches. That is wrong for two of them:

- **`captureMode` belongs in Settings.** It is a genuine product choice a partner makes once, it applies
  to every document journey, and Settings is already where SDK-journey composition lives. Three options,
  so a segmented control rather than a switch. The fallback duration stays at its default and is not
  exposed — a partner tuning a timeout is out of scope for a reference app.
- **`allowGalleryUpload` belongs in Settings** for the same reason, and it is a switch.
- **`knownIdAspectRatio` does not belong in Settings at all.** It is a float that only makes sense
  alongside a `GenericDocument`, and a numeric field in a settings screen is a bad demonstration of it.
  Its right home is the ID-details form's document-type selection: choosing "Other / generic document"
  reveals it, because that is the situation in which a partner would set it.

All three then need what every other setting in this app already has: a `spec/` entry, an id in
`spec/test-ids.json`, goldens light and dark, and the same treatment in the other three apps — so this is
four apps' work, not one's, and it should land per-platform with each port rather than as a fifth pass
afterwards.

## 5. Work items

| ID | Item | Notes |
|---|---|---|
| DOC-A1 | `captureBothSides` follows `documentType.hasBackSide` | §3. One line plus a unit test; do this first, it is a correctness fix not a feature |
| DOC-A2 | Verify what the SDK does with `captureBothSides = true` on a `hasBackSide = false` type | Decides whether anything gets filed against the SDK |
| DOC-A3 | `captureMode` as a three-way Settings control, wired into the builder | The significant one |
| DOC-A4 | Assert the capture mode on the wire (`auto_capture_enabled`) rather than on screen | Cheaper and stronger than a screenshot |
| DOC-A5 | Device coverage that the manual shutter actually appears after the fallback duration | The only way to prove a duration |
| DOC-A6 | `allowGalleryUpload` Settings switch, with its permission consequence | Changes the capture surface, so goldens too |
| DOC-A7 | `knownIdAspectRatio` on the ID-details form, revealed by a generic document type | Not a Settings row |
| DOC-A8 | `spec/` + test ids + goldens for A3, A6, A7; mirrored in the three ports | Four apps, per §4 |

## 6. Landing order

DOC-A1 and DOC-A2 first and together — one is a fix, the other decides whether there is a second fix
elsewhere, and neither waits on a design answer. DOC-A3 through A5 next as one change: a control nobody
can observe is not worth shipping, so the wire assertion and the device proof belong in the same PR as the
control. DOC-A6 after, since it is the same shape but smaller. DOC-A7 last of the features — it needs a
form change, which is the most invasive surface here for the least reach.

DOC-A8 is not a final step; each of A3, A6 and A7 carries its own share of it, per the repo's rule that a
`spec/` change lands with its app-side updates.
