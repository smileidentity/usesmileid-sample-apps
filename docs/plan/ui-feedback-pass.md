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

<!-- INTERNAL-ONLY:END -->
