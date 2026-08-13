# UI work plan — Android first, then three ports

**Status:** ready to start. The design is captured in `spec/screens.json` (14 screens, 38 states,
every one linked to its design node), the component inventory in `spec/components.json` (34
components, 13 documented sub-parts), and the token contract in `spec/design-tokens.json`.

**Inputs:** the *Product Enhancements* design file (boards 01, 01b, 02–07), the Smile ID design
system (three-tier tokens with generated per-platform output), and the SDK's public flow DSL.

**The one rule that makes this cheap:** build Android completely, then treat it as the reference for
the other three. Not by copying code — by copying *decisions*. Every decision worth copying is
already data in `spec/`, so a port is "assemble the same components against the same tokens with the
same ids", not "re-derive the design".

---

## 1. What the sample owns, and what it must not touch

The sample collects everything the SDK needs **before** handing off, then lets the SDK run its own
flow untouched:

```
sample-ui                                            SDK (unchanged)
──────────                                           ───────────────
products
  └─ tap a product
       └─ Consent Details Form  (every product)
            └─ ID details form  (document + KYC products only)
                 └─────────────────────────────────→ consent → instructions → capture
                                                       → preview → processing
                                                                      │
     verificationDetails (processing, 202) ←──────────── result ───────┘
            └─ back → verifications
```

The **Consent Details Form** (first name, last name, email, phone) and the ID-details form are
**sample-owned screens shown before the flow starts**. Every product shows the Consent Details Form —
the design labels those fields "USER DETAILS — ATTACHED TO EVERY JOB" — seeded from the active
profile's configuration. That ordering is deliberate: it means no SDK change is needed to collect
them, and the SDK's own consent step stays exactly where it is.

Two things to know before reading the prototype:

- **The prototype shows the SDK consent screen *before* the Consent Details Form.** That wiring is
  stale and is not being updated. Implement `product → Consent Details Form → SDK flow`.
- **On submission the app lands on verification details in the processing state** (observed as
  `202 Accepted` straight after the ID form's Continue). The details screen doubles as the result
  screen, which is where the result card belongs.

Never re-implement an SDK flow screen — the sample decides only whether a step is present and how it
is configured.

**How the Settings toggles reach the SDK** (three of these look like booleans and are not — see
`spec/components.json` → `settingsToSdkMapping`):

| Settings row | Mechanism |
|---|---|
| Agent mode | `SelfieCaptureConfig.allowAgentMode` — a real boolean |
| Dark mode | app theme selection; the SDK follows the host |
| Consent screen | include or omit `consent()` in the flow builder |
| Instruction screen | include or omit `instructions()` |
| Preview screen | include or omit `preview()` |
| Smile to capture | **unresolved** — a second CAPTURE row; needs an SDK answer before implementing (see flags) |

---

## 2. Phases

### U0 — token pipeline (blocks everything)

Generate the platform token source from the design system and wire light/dark. Android, iOS and
Expo consume pre-generated output; **Flutter has no Dart target**, so generate one from the design
system's flat JSON and request a first-class Dart output so all four consume generated code rather
than three generated and one derived.

Done when: a screen can be built with no hex literal anywhere, and flipping dark mode changes every
colour through tokens alone.

### U1 — primitives (8)

`Avatar · Button · TextInput · SearchField · Switch · StatusBadge · SectionLabel · Toast`

Each one has a design-system contract to build against (except `Switch`, which has none — use the
platform-native control styled with semantic tokens, and flag the missing contract). Build every
state now, not later: a primitive without its disabled/error/focused state is a screen-level bug
waiting to happen.

### U2 — composites, cheapest first

`TopAppBar · DataFieldRow · KeyValueEditRow · SettingRow · ProfileRow · OptionRow · SelectTrigger ·
BottomSheet · FilterChip · DateGroupHeader · JobRow · SelectionCheckbox · SelectionBar`

Then the screen-specific ones: `ProductCard · ProductGrid · SectionHeader · ProfileEnvChip · NavBar ·
TokenRing · SessionCard · SessionEndedBanner · FloatingTokenButton · ScanGlyph · ScanSheet ·
SwipeAction`.

`SectionLabel` (6 screens), `BottomSheet`, `TopAppBar` and `Button` (4 each) are the most reused —
get those right before anything else, because a late change to them touches every screen.

### U3 — screens, in this order

1. **settings** — first, because it drives every other screen's configuration
2. **products** — second, because every flow starts here
3. **verifications** → **verificationDetails**
4. **userDetails** (the Consent Details Form) → **kycIdForm** → **countryPickerSheet** /
   **idTypePickerSheet**
5. **profiles** → **profileConfig** → **newProfileSheet**
6. **scanToken**
7. **ResultCard** and the automation affordances (launch arguments, deep link)

### U3b — routes, alongside the screens

Navigation is not a later phase. Each screen lands with its route, its deep link and its ids in the
same PR — see `docs/plan/navigation-plan.md` for the per-platform architecture and the nine shared
rules. Two navigation milestones are worth tracking separately: **N1** the shell (tabs, per-tab
stacks, deep-link parsing, cold-start restoration) belongs with the walking skeleton; **N2** the flow
handoff (both presentations, replace-don't-stack on result, cancellation, recreation survival) is the
riskiest part of the app and needs device verification per platform.

### U4 — states and goldens

Every state in `spec/screens.json` becomes a preview and a golden test, light and dark. That is 38
states, and the list is already written — no judgement needed about what to cover.

---

## 3. Definition of done

**Per component:** every variant and state built; tokens only, no literals; a preview per state;
the `sample_*` ids from `spec/test-ids.json` attached; survives maximum font scale without clipping.

**Per screen:** matches its design node at review (the node URL is in `spec/screens.json` — put it
in the PR); all states present; light and dark; the ids a flow needs are attached; inset and
system-back behaviour is platform-native even where the visual is identical; validated against
`spec/` by the spec test.

---

## 4. Porting to iOS, Flutter and Expo

Once Android is done, each port gets the same four inputs: `spec/`, the generated tokens, the Android
implementation as the visual arbiter, and this plan. What must be **identical**: component
inventory and names, screen and state lists, `sample_*` ids, spacing and size metrics, token
references, copy. What must be **platform-native**: navigation and presentation (sheets, push,
modal), the back affordance, the switch control, swipe gestures, keyboard avoidance, and haptics.

A port that reproduces Android's navigation instead of using the platform's own is a defect even if
it looks pixel-identical — that is precisely the host-interaction class these apps exist to catch.

---

## 5. Flags raised while reading the design (need a design or owner answer)

Recorded in the spec so they survive this document. None of them block starting U0–U2.

**Verified against a prototype recording (2026-08-12).** A 139-second walkthrough, decomposed into
84 distinct states, confirmed the navigation graph and corrected twelve component specs — soft status
badges, the JobRow secondary line, circular selection checkboxes, a neutral session-ended banner, the
second CAPTURE row, the ID-type dependency, per-profile avatar hues, filled circular app-bar controls
plus a torch on Scan token, the simulate primary button, and the selected-row fill. Details in
`spec/screens.json` → `verification.recording`.

**Design set:**
**Resolved (no longer blocking):**

- **Which products layout to build** — the expressive grid (`5206-4037`). The prototype runs the old
  list layout and will not be updated, so engineering transposes the session card, environment chip
  and token ring onto the grid.
- **Where the pre-flow form sits** — `product → Consent Details Form → SDK flow`, for every product.
  The prototype's consent-first order is stale wiring.
- **Where the result card goes** — verification details, which the recording showed is the
  post-submission destination.

**Open — needs a design or SDK answer:**

1. **"Smile to capture"** — which SDK field does the second CAPTURE switch set? Agent mode is
   `allowAgentMode`; `SelfieCaptureConfig` also exposes `enableEnhancedLiveness`. Do not infer.
2. **Soft badge variants** — the design uses soft tinted pills for all four statuses; the design
   system's `badge.*` tokens are saturated. Add soft variants to the system, or change the design.
3. **ID-details form for the two document products** — it is only drawn for Biometric KYC. Country
   plus document type, without an ID number?
4. **Product→hue and profile→hue mappings** — five product cards and three profile avatars each use a
   different colour, with no documented rule. Needed or the four platforms will disagree.
5. **Label copy** — "SmartSelfie Auth" (grid) versus "SmartSelfie Authentication" (list frames).
6. **Switch profile trigger** — which element on the products screen opens the sheet.
7. **Job-type coverage** — the grid shows 5 of the SDK's 7 types; `EnhancedKyc` and `BVN` are absent
   and there is exactly one empty slot. Intentional?
8. **Board 05 title** — "Consent & KYC" holds no consent screen (those are in board 04).
9. **App name** — the Settings footer reads "Smile ID Sample App · 1.0.0" while the agreed display
   name is "UseSmileID Sample" (`spec/app-identity.json`).
10. **`docs.usesmileid.com`** — confirm the host.

**Token source** (`spec/design-tokens.json` → `deltas`) — the good news first: the design file's
variables match the design system **exactly** (`#151f72` primary, `#21232c` title, `#848282` muted,
`#eaecf0` border, `#f9fafb` background, pill radius, DM Sans). Beyond the badge question above, two
dark-mode defects in the token source itself:

11. **`color.border` does not change in dark mode** (`#eaecf0` in both). A near-white border on the
    dark background will read as a bright outline around every card. Fix in the token source, not
    locally. Still unverified visually — the recording never turned dark mode on.
12. **`color.text.muted` is the same grey in both modes**, landing near the small-text contrast
    threshold on dark. Verify or lighten.

Plus: the design system has **no `Switch` contract** and **no Dart output** — both are requests to
the design system rather than things to solve locally.

---

## 6. Effort

Android reference ≈ 1–2 weeks (U0 ≈ 1 day once the Dart question is parked, U1 ≈ 2 days, U2 ≈ 4 days,
U3 ≈ 4 days, U4 ≈ 2 days). Each port ≈ 1 week, and the three can run in parallel because they share
no code. The `spec/` files are what make that parallelism safe.
