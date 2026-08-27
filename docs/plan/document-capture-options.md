# The document-capture options the sample does not exercise

**Status:** planning. Post-release. Read out of the SDK's own public config surface, so the gap is
countable rather than estimated.

## 1. The surface, and what the sample uses of it

`DocumentCaptureConfig` is the SDK's public document-capture contract. Six configurable fields, and the
sample meaningfully exercises **one** of them.

| Field | Default | Sample today | |
|---|---|---|---|
| `documentType` | `null` | *derived* from the ID type, never chosen | ⚠️ §2.0 |
| `captureBothSides` | `true` | hard-coded `true` | ⚠️ §3 |
| `allowSkipBack` | `false` | set `true` | ✅ |
| `captureMode` | `AutoCaptureWithManualFallback(10s)` | **never set** | ❌ |
| `allowGalleryUpload` | `false` | **never set** | ❌ |
| `knownIdAspectRatio` | `null` | **never set** | ❌ |

`FlowBuilderConfig.kt:161–168` is the whole of it. So three options ship as documented public API with
**no host in this org exercising them at all**, and a fourth — the document type itself — is set but never
*chosen*, which turns out to be the one that matters most (§2.0). None of the four has device coverage or
a screenshot.

## 2. What each unexercised option is worth

### 2.0 Selecting the document type is the keystone — owner ruling 2026-08-27

The sample never lets anyone *choose* a document type. `FlowBuilderConfig.kt:164` derives it —
`documentType = snapshot.idDetails.idType.toDocumentType()` — so whatever the ID-type field maps to is
what the SDK gets, and the three concrete `DocumentType` cases cannot be exercised independently.

**Owner ruling: direct selection of the document type is the most important item here**, ahead of the
three unset options, and the reason holds up in the type definitions. `DocumentType` is not a label — it
carries three behavioural fields, and each concrete case sets them differently:

| Case | `hasBackSide` | `orientation` | `knownAspectRatio` |
|---|---|---|---|
| `SouthAfricaGreenBook` | **false** | Portrait | 320/428 |
| `Passport` | true | Landscape | 356/272 |
| `GenericDocument(...)` | caller's choice (default true) | caller's choice (default Landscape) | **`null`** |

So one control makes four separate behaviours observable that nothing observes today: back-side capture
appearing or not, the capture frame's aspect ratio, portrait versus landscape framing, and — because
`GenericDocument` is the only case with a null ratio — **the exact situation `knownIdAspectRatio` exists
for**. Selecting the type is what turns that field from an orphan into a demonstrable one.

It also makes §3's suspected defect visible rather than theoretical: pick the Green Book and the sample
currently asks for both sides of a one-sided document, on screen, where anyone can see it.

Two things it should carry. `GenericDocument` takes a display name, a back-side flag and an orientation,
so choosing it needs to expose those rather than accept defaults silently — that is the case a partner
with an unlisted document is in. And the selection must be independent of the ID-type field, because
conflating them is how the current derivation hid all of this.


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

**How the host observes it, and the one constraint that comes with it.** The sample already configures the
SDK's own `network { config { … } }` block and already raises logging to body level on debug, which is
where the field becomes readable. That makes the assertion cheap — but it is **debug-only by design**: the
same block's comment records that release must never log traffic. So DOC-A4 is a debug-lane check, and the
release lane still needs the on-screen behaviour as its signal. Worth stating up front rather than
discovering when the release suite has nothing to assert on.

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

The temptation is a row of Settings switches. That is right for one of these, wrong for the rest —
placement should follow *when a partner decides*, not what is easiest to add:

- **The document type belongs with the journey's inputs, not in Settings.** It is a per-run choice, the
  same kind as the ID details, and burying it in Settings would repeat the mistake of decoupling it from
  the run it describes. It sits with the ID-details form, and choosing the generic case reveals both the
  generic fields and `knownIdAspectRatio`.

- **`captureMode` belongs in Settings.** It is a genuine product choice a partner makes once, it applies
  to every document journey, and Settings is already where SDK-journey composition lives. Three options,
  so a segmented control rather than a switch. The fallback duration stays at its default and is not
  exposed — a partner tuning a timeout is out of scope for a reference app.
- **`allowGalleryUpload` belongs in Settings** for the same reason, and it is a switch.
- **`knownIdAspectRatio` does not belong in Settings at all** — it is a float that only means anything
  alongside a `GenericDocument`, so it lives where that choice is made, per the first bullet.

All of them then need what every other surface in this app already has: a `spec/` entry, an id in
`spec/test-ids.json`, goldens light and dark, and the same treatment in the other three apps — so this is
four apps' work, not one's, and it should land per-platform with each port rather than as a fifth pass
afterwards.

## 5. Work items

| ID | Item | Notes |
|---|---|---|
| DOC-A0 | **Direct document-type selection** — Green Book, Passport, generic — decoupled from the ID-type field, with the generic case's own fields exposed | §2.0. The keystone: it makes back-side, aspect ratio, orientation and `knownIdAspectRatio` all observable |
| DOC-A1 | `captureBothSides` follows `documentType.hasBackSide` | §3. A correctness fix, not a feature — one line plus a unit test |
| DOC-A2 | Verify what the SDK does with `captureBothSides = true` on a `hasBackSide = false` type | Decides whether anything gets filed against the SDK |
| DOC-A3 | `captureMode` as a three-way Settings control, wired into the builder | The significant one |
| DOC-A4 | Assert the capture mode on the wire (`auto_capture_enabled`) rather than on screen | Cheaper and stronger than a screenshot |
| DOC-A5 | Device coverage that the manual shutter actually appears after the fallback duration | The only way to prove a duration |
| DOC-A6 | `allowGalleryUpload` Settings switch, with its permission consequence | Changes the capture surface, so goldens too |
| DOC-A7 | `knownIdAspectRatio` on the ID-details form, revealed by a generic document type | Not a Settings row |
| DOC-A8 | `spec/` + test ids + goldens for A3, A6, A7; mirrored in the three ports | Four apps, per §4 |

## 6. Landing order

DOC-A0 first, because every other item on this list is easier to build and easier to *see* once a
document type can be chosen — and because DOC-A1's fix is invisible without it. Then DOC-A1 and DOC-A2
together — one is a fix, the other decides whether there is a second fix elsewhere, and neither waits on
a design answer. DOC-A3 through A5 next as one change: a control nobody
can observe is not worth shipping, so the wire assertion and the device proof belong in the same PR as the
control. DOC-A6 after, since it is the same shape but smaller. DOC-A7 last of the features — it needs a
form change, which is the most invasive surface here for the least reach.

DOC-A8 is not a final step; each of A3, A6 and A7 carries its own share of it, per the repo's rule that a
`spec/` change lands with its app-side updates.
