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
sample-ui                                          SDK (unchanged)
──────────                                         ───────────────
products → [userDetails] → [KYC / ID details] →    consent → instructions → capture
                                                     → preview → processing
                                                                    │
verifications ← verificationDetails ←───────────────── result callback
```

`userDetails` and the KYC/ID form are **sample-owned screens shown before the flow starts**. That is
deliberate: it means no SDK change is needed to collect them, and the SDK's own consent step stays
exactly where it is. Never re-implement an SDK flow screen — the sample decides only whether a step
is present and how it is configured.

**How the Settings toggles reach the SDK** (three of these look like booleans and are not — see
`spec/components.json` → `settingsToSdkMapping`):

| Settings row | Mechanism |
|---|---|
| Agent mode | `SelfieCaptureConfig.allowAgentMode` — a real boolean |
| Dark mode | app theme selection; the SDK follows the host |
| Consent screen | include or omit `consent()` in the flow builder |
| Instruction screen | include or omit `instructions()` |
| Preview screen | include or omit `preview()` |

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
4. **userDetails** → **kycIdForm** → **countryPickerSheet** / **idTypePickerSheet**
5. **profiles** → **profileConfig** → **newProfileSheet**
6. **scanToken**
7. **ResultCard** and the automation affordances (launch arguments, deep link)

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

**Design set:**
1. The chosen products layout (board 01b) has only the sandbox state. Token-session, expired and
   production states exist only on the superseded list layout — re-draw, or let engineering
   transpose? (`spec/screens.json` → `openQuestions.transposeStates`)
2. The grid shows 5 of the SDK's 7 job types; `EnhancedKyc` and `BVN` are absent and there is exactly
   one empty slot. Intentional?
3. Board 05 is titled "Consent & KYC" but holds no consent screen — the consent frames are in board
   04. Worth renaming to avoid a wrong-board lookup.
4. The Settings footer reads "Smile ID Sample App · 1.0.0" while the agreed display name is
   "UseSmileID Sample" (`spec/app-identity.json`). Which string ships?
5. The ABOUT section links `docs.usesmileid.com` — confirm that host.
6. `ResultCard` is required by `spec/result-card.schema.json` but is not in the design. Needs a
   placement decision; the honest default is a collapsible panel on verification details plus a
   compact line on products while a job is in flight.

**Token source** (`spec/design-tokens.json` → `deltas`) — the good news first: the design file's
variables match the design system **exactly** (`#151f72` primary, `#21232c` title, `#848282` muted,
`#eaecf0` border, `#f9fafb` background, pill radius, DM Sans). Three real deltas:

7. **Attention badge:** the design uses a soft amber pair (`#fff0d9` / `#7a4a00`); the design system's
   warning badge is saturated brand orange. Pick one — a soft-fill badge variant in the system is
   arguably what all four status chips want.
8. **`color.border` does not change in dark mode** (`#eaecf0` in both). A near-white border on the
   dark background will read as a bright outline around every card. Fix in the token source, not
   locally.
9. **`color.text.muted` is the same grey in both modes**, landing near the small-text contrast
   threshold on dark. Verify or lighten.

Plus: the design system has **no `Switch` contract** and **no Dart output** — both are requests to
the design system rather than things to solve locally.

---

## 6. Effort

Android reference ≈ 1–2 weeks (U0 ≈ 1 day once the Dart question is parked, U1 ≈ 2 days, U2 ≈ 4 days,
U3 ≈ 4 days, U4 ≈ 2 days). Each port ≈ 1 week, and the three can run in parallel because they share
no code. The `spec/` files are what make that parallelism safe.
