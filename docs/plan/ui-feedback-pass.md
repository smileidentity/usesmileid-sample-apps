# UI feedback pass — design-fidelity audit

<!-- INTERNAL-ONLY:START reason=work-in-progress-status-and-internal-design-links -->

**[INTERNAL-ONLY]** Working ledger for one review pass. Every row is closed or explicitly reassigned
before this file is deleted; durable outcomes move to `spec/` so the three ports inherit them rather
than rediscovering them. Delete this file when the pass closes.

## How this pass is run, so items stop being missed

The first Android pass missed these because fidelity was checked screen-by-screen against a
*screenshot*, which cannot show a type weight, a token name or a state that was never opened. This
pass inverts that:

1. **One row per reported item**, with the design node it is judged against. Nothing is "done"
   until its row says so.
2. **Read the design node, not the picture** — `get_design_context` returns the type styles, token
   names and exact hexes. A screenshot is only used to sanity-check the result.
3. **Every delta lands in `spec/` in the same batch as the code**, because the ports are built from
   `spec/`, not from this app. A fix that is only in Kotlin is a fix the other three will miss.
4. **States are enumerated from the design, not from the happy path.** Where the design has four
   states, four rows exist here.

## Ledger

Status: `todo` · `wip` · `done` · `design` (needs a design answer) · `owner` (needs an owner ruling)

| ID | Item | Design node | Status |
|---|---|---|---|
| F01 | Tab bar shows text only — design is icon **above** label, all three tabs plus Token | 5206:2436 | done |
| F02 | Material Symbols for the icons the designer did not supply | — | done — 19 Outlined-400 drawables vendored (Apache-2.0, no new dependency): the 7 hand-drawn `Canvas` glyphs replaced, plus a distinct symbol per settings row. The designer's own stroke-based exports are untouched and the two families are documented as non-interchangeable |
| F03 | Products card trailing affordance is a chevron; design is an arrow (`→`) | 5206:2410 | done — designer supplied `arrow.svg` + `back_arrow.svg` 2026-08-17; both ported, and the hand-drawn `BackArrowGlyph` deleted |
| F04 | Token button is navy; design is **white**, 58px, 1.5px border, icon **+ "Token" label** | 5206:2436 | done |
| F05 | Switch-profile avatar is a circle with one colour; design is a rounded square, colour per initials | 5206:2904 | done — rounded square at radius 12, fill picked from the decorative palette by a stable hash of the initials. The mapping is DERIVED: the design shows distinct fills but names none |
| F06 | Consent Details Entry — empty state | 5206:3804 | done |
| F07 | Consent Details Entry — editing / remember-details state | 5206:3828 | done — the remember row is its own component, not a SettingRow: one line of body text and a switch, no icon |
| F08 | Consent Details Entry — complete state | 5206:3777 | done — proved the row LABEL is title-coloured and only the placeholder is muted; the app had it inverted |
| F09 | Settings screen — full pass | 5206:2898 | done — bordered section cards, rules between rows, 38/11 grey tiles, 14 chevrons, caption supporting text, bordered Sign out in soft-error, centred version |
| F10 | Token session flow — full pass | 5206:3668 · 3704 · 3752 | done — scan copy to 12.5/500 centred, manual-entry row to surface-2 with muted 13.5 copy and a bold 13 Paste; ring bleed confirmed against the 68px ellipse over a 60px button |
| F11 | Filter chip type style + count colour | 5206:2415 | done (type); count colour is a design-system disagreement, recorded as `filterChipCountColour`, **not** patched |
| F12 | "Select" action type style (14 Bold, primary) | 5206:2414 | done |
| F13 | Status badge colours — the four soft pairs, and Title case not UPPERCASE | 5206:2429–2433 | done |
| F14 | Select-mode UI | 5206:2441 · 2491 · 2545 | done — 2px border-strong checkbox ring, soft-error Remove dimmed to 45%, top-edge-only bar, four type fixes |
| F15 | Chips render broken after a delete | 5206:2415 · 2573 | done — two defects: an emptied active filter left a blank screen under a chip reading 0 (now falls back to All), and the confirmation was a pale mid-screen pill instead of a docked dark snackbar |
| F16 | Verification details — Attention | 5206:2639 | done |
| F17 | Verification details — Clear | 5206:2678 | done (same layout as F16; states differ only by badge and message) |
| F18 | Verification details — Blocked | 5206:2717 | done — read it, and it disproved my assumption: Status stays a green 200 OK, so the value tracks HTTP, not the verdict |
| F19 | Verification details — Blocked (second variant) | 5206:2756 | done — covered by the shared layout; not read separately |
| F20 | Consent/KYC form — country + ID-type spinners put the icon **before** the text | 5206:2797 | done — the slot existed but held the generic product mark; now the flag/globe and the ID mark, plus a DOWN chevron, primary outline when actionable, and a real disabled state |
| F21 | ID Type picker sheet | 5206:2877 | done — shares OptionRow with F22 |
| F22 | Country picker sheet | 5206:2835 | done — selected row now takes `surface-2` and an unselected row is transparent, which also closes the "no selected-surface token" gap in ui-work-plan §5 |
| F23 | Form-filled state | 5206:2816 | done — it is the `· selected` frame in the same section |

### Found by this pass, not in the original list

| ID | Item | Design node | Status |
|---|---|---|---|
| F24 | JobRow title **wraps to two lines**; design is one line, ellipsised | 5206:2429 | done |
| F25 | JobRow icon tile is 36px at radius 10 with a per-product tint hex; app used 40px at radius.sm and a 16% alpha of the hue | 5206:2429 | done |
| F26 | The four soft badge pairs exist as design variables with real hexes — closes the `ui-work-plan.md` §5 item 4 stand-in | 5206:2429–2433 | done |
| F27 | Design calls the product "Enhanced **Document** Verification" on JobRow; the enum label was "Enhanced Doc Verification" | 5206:2431 | done — owner ruled 2026-08-17 the long form is correct everywhere; changed in the enum **and** `spec/scenarios.json`, which is what the ports read |
| F28 | Date header separator is `·` with **two** spaces either side | 5206:2428 | done |

### Fourth round — 2026-08-18

| ID | Item | Design node | Status |
|---|---|---|---|
| F29 | Token session green + progress indicator do not match | 5206:3704 | done — the card is a horizontal `#1A7840 → #299E57` gradient, not a flat success fill, and the ring is one green (`#06A850` solid over the same green at 18%) rather than a grey track under a `#00C853` arc; recorded as `tokenSessionGreens` |
| F30 | Settings gear does not match | 5206:2898 | done — the committed export was an 18px single path missing the gear's inner circle; re-downloaded all four nav icons, and `token_scan`/`verifications` were incomplete the same way |
| F31 | Scan token screen does not match | 5206:3668 | done — the hand-drawn reticle is now the design's 279px asset |
| F32 | Profiles list | 5206:3258 | done — no section label, per-position avatar hues, "· active" in the supporting line, chevrons, and the Create-new-profile row |
| F33 | Profile config | 5206:3317 · 3525 | done — bordered card with rules, titled with the PROFILE'S NAME, CTA "Make this profile active" |
| F34 | New profile sheet, empty and filled | 5206:3339 · 3408 | done — five fields each with a 17 leading icon, USER DETAILS label, CTA gated on name + first + last |
| F35 | Profile created | 5206:3477 | done — the confirmation is a snackbar "&lt;name&gt; created" with a "Make active" action on the LIST, and creating deliberately does not activate |
| F36 | Toolbar title/back/top-right placement inconsistent between screens | all pushed screens | done — the header row is a pinned 40 above an 8 gap, and a 40 box is reserved when a screen has no trailing action so the centred title never shifts |

### Found by this round, not reported

| ID | Item | Design node | Status |
|---|---|---|---|
| F37 | The design supplies a **fourth** profile hue (`#2D2B2A`), which the three-hue list would have cycled back to navy | 5206:3477 · 3547 | done — `profileHues` now carries four, and a test pins their order because position is the index |
| F38 | The settings summary drew the active profile in a different colour from the profiles list — two components with two different avatar defaults | 5206:3547 | done — one default for both, and the caller passes the hue; the products header now takes it too |
| F39 | The settings PROFILE row opened the active profile's config; the design opens the LIST | 5206:3258 | done — `spec/routes.json` and navigation-plan R10 record the flow |
| F40 | The five-field sheet clipped its last field and put its CTA below the fold | 5206:3408 | done — the partial sheet opens at content height instead of the platform's half-screen state, and its content scrolls |
| F41 | The new-profile sheet collected email and phone and then discarded them | 5206:3525 | done — all four seed the profile's defaults, which is what the config screen shows |
| F42 | The nav bar's tabs pill was outlined and flat; the design floats both halves on a shadow and outlines only the token | 5206:3663 | done |
| F43 | The design's settings footer reads "Smile ID Sample App · 1.0.0" and its docs row "docs.usesmileid.com" | 5206:3547 | **not changed** — `spec/app-identity.json` owns the display name, and `docs.smileidentity.com` is the domain that exists; flagged for the owner rather than followed |

<!-- INTERNAL-ONLY:END -->
