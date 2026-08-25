# Products visual refresh — Android, read off node 5447:1701

**Status:** Planned, nothing built. Source: **`Products · expressive -update`** (node `5447:1701`), read
2026-08-24 with `get_metadata`, `get_variable_defs` and `get_design_context` on the frame, the header,
the session card, one product card and the nav bar. Every number below is quoted from the design, not
measured off a screenshot.

**This supersedes the canonical products layout.** `spec/screens.json` names `5206-4037` as
`canonicalLayout` for `products` and the owner ruled on 2026-08-13 that it was the build target. That
ruling predates this frame. Changing `canonicalLayout` and `designVersion` is a `spec/` change and is
ask-first (§7.1).

**Companion reading:** `environment-from-token-android.md` — it collides with this plan in exactly three
places (§5.6), and its §6.5 question about the environment chip is **answered by this frame**.

**Every open ruling was answered on 2026-08-24** and §7 records each one with what it costs. The frame
is final as drawn, so §7 is a specification now rather than a question list. The one thing it does not
settle is the **four cards whose gradients carry an alpha stop** — they will render differently in the
two schemes by construction (§7.2), which changes how PVR-A12 reads a light-vs-dark golden diff.

**The one-line goal:** the products screen matches 5447:1701 in both colour schemes, and the values it
introduces are tokens rather than a second set of magic numbers.

---

## 1. Light mode — yes, and here is how

**You can see the light values, from a different tool than the one that shows the dark ones.** The
frame is authored in dark, and the two Figma reads disagree on purpose:

- **`get_variable_defs`** resolves each variable **in the frame's current mode** — so it returns the
  **dark** values. There is no mode parameter.
- **`get_design_context`** emits CSS custom properties with **fallbacks**, and the fallback is the
  variable's **default (light) mode** value — `bg-[var(--main-bg,#f9fafb)]`,
  `text-[color:var(--off_black,#2d2b2a)]`, `text-[color:var(--cta-button,#151f72)]`.

Read together they give both modes without anyone switching the frame. That trick is worth keeping;
it is how the ports can check their own light values without a second frame.

**The gradients are the exception, and they turned out not to matter.** Neither the card fills nor the
session card's appears in `get_variable_defs` — they come back as raw CSS, so they have no light-mode
counterpart in Figma. **Owner ruling 2026-08-24: they are mode-invariant and already vendored**, which
the file confirms — Biometric KYC's fill is exactly `smileProductHues["biometricKyc"]`, and
`UseSmileIDSampleProductCard` already treats a hue as scheme-independent on purpose. So nothing here
blocks light mode. §7.2 records the two fills that still need a look.

---

## 2. The token map, both modes, checked against the vendored output

| Figma variable | Light (from the `var()` fallback) | Dark (from `get_variable_defs`) | Repo token | Verdict |
|---|---|---|---|---|
| `Main BG` | `#F9FAFB` | `#1A1C23` | `colorBackground` | **exact match, both modes** |
| `Card BG` | `#FFFFFF` | `#272A35` | `colorSurface` | **exact match, both modes** |
| `CTA Button` | `#151F72` | `#4D88FF` | `colorPrimary` | **exact match, both modes** |
| `color/surface` | `#FFFFFF` | `#FFFFFF` | `colorSurface` (light) | matches |
| `Off_black` | `#2D2B2A` | `#F9F0E7` | — | **no match. See below** |
| card + session gradients | *(mode-invariant)* | raw CSS | `smileProductHues` | **already vendored** — §7.2 |

**Four of the five map cleanly**, which is the good news: this refresh is mostly *re-pointing at tokens
the repo already vendors*, not importing a new palette.

**`Off_black` is the one real divergence, and it is load-bearing.** It paints the page title, the page
subtitle, the product-card stroke and the unselected nav labels. The design's pair is **warm**
(`#2D2B2A` ↔ `#F9F0E7`); the repo's nearest semantic pair, `colorTextTitle`, is **cool**
(`#21232C` ↔ `#F2F2F2`). Implementing `Off_black` as `textTitle` ships a visibly different, cooler
screen in both modes. Both design values *do* exist in the vendored primitives — `#F9F0E7` is
`colorNeutralOffWhite` (and light `colorSurfaceAlt`), `#2D2B2A` is light `colorFeedbackWarningOn` and
dark `colorTextInverse` — but reaching for either is consuming a primitive, which `AGENTS.md` forbids.
**So this needs a semantic token, not a workaround.** Ruled 2026-08-24: **Figma is truth** — adopt the
warm pair as a new semantic token (§7.3).

One more thing the vendored output shows while we are here: **`colorBorder` is `#EAECF0` in *both*
schemes** — a light hairline on a `#1A1C23` background. Nothing uses it on a dark surface today, and
this refresh adds strokes. Worth a look before it becomes a visible defect.

---

## 3. What changed, component by component

Everything in this section is quoted from `get_design_context`. Current values are from the code.

> **Read §7.8 before implementing any number here.** This section records what the design *draws*.
> Three of those values were ruled onto the token scale afterwards and **§7 wins**: icon-tile radius
> `14 → 16`, go affordance `26 → 24`, session-card padding `14/15/16 → 16` on all four sides. They are
> flagged inline below, but §7.8 is the authority.

### 3.1 Product card — `UseSmileIDSampleProductCard`

| Property | Now | 5447:1701 |
|---|---|---|
| Corner radius | `radiusXl` = **20** | **16** (`radiusLg` / `radiusSurface`) |
| Padding | `spacingSm` = **12** | **16** (`spacingMd`) |
| Shadow | **10dp coloured** (`ambientColor`/`spotColor` = the hue) | **none** |
| Stroke | none | **0.2px** in `Off_black` |
| Fill | `hue.brush()`, two stops at 13.4% / 86.6% | `linear-gradient(135.81deg, rgb(255,181,61) 66.6%, rgba(167,139,250,.79) 129.8%)` |
| Icon tile | 40, radius `radiusMd` = **12** | 40, radius **14** → **build 16**, §7.8 |
| Icon | glyph, hue-tinted | **21** |
| Label | one line, `textStyleSubtitle` | **two runs in one text node** |
| — title run | — | DM Sans **SemiBold 16 / 24 / −0.4** |
| — subtitle run | — | DM Sans **Regular 12 / 16** |
| Go affordance | `sizeIconLg` = **24**, icon glyph | **26** → **build 24**, §7.8; a text **"→"** at DM Sans Medium 12 |
| Go fill | `hue.scrim` @ 16% | `rgba(45,43,42,0.16)` — `#2D2B2A` @ **16%**, unchanged |
| Ghost glyph | offset `(16, −8)` | left **124**, top **−9**, size **69.3** (two cards use **60**) |

Two structural notes. The label is **one text node with two styled runs**, so it is an
`AnnotatedString`, not two stacked `Text`s — stacking them gets the baseline gap wrong at large font
scales. And the design's strings carry **trailing spaces** (`"Registration "`, `"SmartSelfie™ "`);
those are a Figma artefact, not content.

### 3.2 Names, and a sixth card

| Card | Now | Title | Subtitle |
|---|---|---|---|
| 1 | SmartSelfie Enrollment | **Registration** | **SmartSelfie™** |
| 2 | SmartSelfie Authentication | **Auth** | **SmartSelfie™** |
| 3 | Document Verification | **Document** | **Verification** |
| 4 | Enhanced Doc Verification | **Enhanced Doc.** | **Verification** |
| 5 | Biometric KYC | **Biometric** | **KYC** |
| 6 | *(absent from 5206-4037)* | **Enhanced** | **KYC** |

Also: section header **`Authentication` → `Biometric Authentication`**, and the page subtitle
**"…powered by our library" → "…powered by our Anti-Fraud SDKs"**.

This is a bigger change than a rename. `spec/scenarios.json` carries `label` per product as a single
string, and the owner ruled on 2026-08-13 that the label is **"SmartSelfie Authentication" in full**
specifically so it matches the SDK's job-type name. This frame splits every label into a
**title + family** pair and shortens the title. Three places have to agree afterwards — the card, the
verifications row and the result card — and today they all read one `label`. §7.4.

### 3.3 Session card

- Gradient **left → right**, `rgba(12,65,178,0.78)` → `rgba(167,139,250,0.79)`
- Stroke **0.5px** `Off_black` as drawn → **build 0.2dp**, §7.6
- Radius **16**; padding as drawn is **top 14, bottom 16, sides 15** → **build 16 on all four**, §7.8
- `ACTIVE TOKEN SESSION` — DM Sans **Bold 10, tracking +1**
- `Linked to session 9f3a` — DM Sans **Regular 12 / 16**
- `5:00` — DM Sans **Bold 24**, line-height 1.1

### 3.4 Nav bar — mostly already right

The current `UseSmileIDSampleNavBar` already ships **21dp** tab icons, a **58dp** token button and an
**8.5sp** token label, all matching. What changes:

| Property | Now | Design |
|---|---|---|
| Pill fill | `colors.surface` | **`Main BG`** — the page background |
| Unselected label | `colors.textMuted` (`#848282`) | **`Off_black`** |
| Selected label | `colors.primary` | `CTA Button` — **already correct** |
| Label size | — | **10 Bold** |
| Shadow | `shadowElevation` = 8dp | **`0 8 24 rgba(0,0,0,0.12)`** |
| Token button border | `borderWidthThick` (2) in `colors.border` | **none** |

**The finding worth acting on:** the pill moves from `surface` to `Main BG`, which is *the same colour
as the page*. In light that is fine — `#FFFFFF` on `#F9FAFB` was barely a step anyway, and the shadow
carries the edge. In dark the pill becomes `#1A1C23` on `#1A1C23`, separated only by a **12 % black**
shadow, which is close to invisible on a near-black ground. The bar may lose its edge entirely.
Verify on a device in dark before accepting it, and if it disappears the fix is design's, not a
local nudge.

### 3.5 Header

- Gap **4**, bottom padding **6**
- `Smile ID` — DM Sans **Bold 26 / 1.2**, tracking **−0.26px**, colour `Off_black`
- Subtitle — DM Sans **Medium 12 / 1.4**, colour `Off_black` at **full opacity**, same as the title

**A units trap:** the `Type/Heading` style reports `letterSpacing: -1`, but the rendered node is
**−0.26px** — the style is **−1 %** of 26px. Implementing `-1.sp` is four times too tight. The same
applies to `Type/Title`'s `-0.4`, which is a real px value on the card. Read the node, not the style.

---

## 4. What the change list missed

Names, colours, icons, padding, radius, stroke, tab colours, shadows and type were all correct. Seven
more:

1. **The environment chip is `hidden="true"`, not deleted** (node 5447:1705). It is still in the frame,
   switched off. That is a *much* better answer to `environment-from-token-android.md` §6.5 than
   deleting the component — and it means the chip can come back the day environment is worth showing.
2. **The header avatar button is gone entirely.** Not hidden — absent. Owner decision 2026-08-13 added
   a header avatar button *because* the chip stopped being the profile-switch trigger. This frame has
   neither, so **on this screen there is no way to switch profile at all.** That is a functional
   regression, not a visual one, and it needs an answer before the screen ships (§7.5).
3. **A sixth product card exists** — Enhanced KYC is drawn. The old frame had five and an empty slot,
   which is why `UseSmileIDSampleProductSlot` exists. With six cards the slot has no job.
4. **The card shadow is removed**, not restyled — the 10dp coloured shadow goes and a 0.2px stroke
   replaces it. The shadows that remain are on the nav bar and the token button.
5. **Stroke widths disagree with each other — and it is card-vs-card, not card-vs-session.** Five card
   nodes are `0.2px`; **Biometric (5448:2062) is `0.5px`**, as is the session card. §7.6 rules 0.2dp
   everywhere and records the two outliers to normalise in Figma.
6. **The session card's padding is asymmetric and off-scale** — 14 / 15 / 16 on three sides. There is
   no 14 or 15 in `SmileDimens`, and nothing in the design explains the asymmetry.
7. **`Card-Subtitle` is composed from primitives** (`font size/12`, `font weight/400`,
   `line height/16`, `font family/Font 2`) while every `Type/*` style is a composite token. The type
   system is mid-migration in the design file, and `AGENTS.md` says never consume a primitive. Ask for
   `Card-Subtitle` as a proper semantic style before four platforms hard-code 12/16/400.

Two cosmetic ones, recorded so nobody trips: every product card node is named
`card/Document Verification` regardless of which product it is, so layer names cannot be used to map
cards to products; and the frame's `spacer` heights differ by 2 between the two grids (26 vs 28),
which is what makes the authentication row 136 tall and the verification rows 138.

---

## 5. The work items

| Id | What | Priority | Depends on |
|---|---|---|---|
| PVR-A1 | `Off_black` gets a semantic token; the map in §2 lands in `spec/design-tokens.json` | **P1** | §7.3 |
| PVR-A2 | Product card: radius, padding, stroke, shadow removal, icon tile, go affordance | **P1** | A1, §7.6 |
| PVR-A3 | Two-line card label as one `AnnotatedString`; `cardTitle` + `cardFamily` join `spec/scenarios.json` | **P1** | §7.4 |
| PVR-A4 | The sixth card, the section rename, the page subtitle; retire `UseSmileIDSampleProductSlot` | **P1** | A3 |
| PVR-A5 | Card gradients: four replaced hue pairs, three new palette colours | **P1** | §7.2 |
| PVR-A6 | Session card: gradient, stroke, radius, padding, three type styles | P2 | A1, §7.2 |
| PVR-A7 | Nav bar: pill fill, unselected label, shadow, drop the token border | P2 | A1 |
| PVR-A8 | Header: type, tracking, colours | P2 | A1 |
| PVR-A9 | Icons re-exported at 21 and 16, stroke weight per the frame | P2 | §7.7 |
| PVR-A10 | ~~The header's missing profile trigger~~ — **closed, no work**: the avatar button stays | — | §7.5 |
| PVR-A11 | `spec/` follows: `screens.json`, `components.json`, `design-tokens.json`, `scenarios.json` | **P1** | A1–A9 |
| PVR-A12 | Goldens and the structural predicates re-recorded | P2 | A2–A9 |
| PVR-A13 | Scale migration: 16 across the board, sheets included; rules on `Shapes.extraLarge` | P2 | §7.8 |
| PVR-A14 | Ghost glyph to 10 %; split `SCRIM_ALPHA` from the go pill's 16 % | P3 | §7.9 |

### 5.6 Where this collides with the environment plan

Three collisions, all of them cheap if sequenced and expensive if not:

- **The environment chip.** That plan's §6.5 asks "delete or move?". This frame answers **neither —
  hide it**. Take that answer, drop the deletion branch, and keep the component in
  `spec/components.json` marked hidden-on-products. `screen_products_production` still goes.
- **The SmartSelfie™ mark.** That plan's §6.10 asks where the mark applies. This frame puts it on the
  **card subtitle**, and the titles become `Registration` / `Auth` — so the mark is **not** part of the
  product's own name. `UseSmileIDSampleMarks.SMART_SELFIE` is still the right shape; it just lands in
  one more place than expected.
- **Product labels.** ENV-A13 assumed labels are single strings that gain a mark. PVR-A3 splits them
  in two. **PVR-A3 must land first, or ENV-A13 edits a string that is about to stop existing.**

### 5.7 Files this touches

Traced, not estimated. `spec/` first, because it is the four-platform surface.

**`spec/`** — `screens.json` (`canonicalLayout`, `designVersion`, `products.states`, the section rename,
the page subtitle), `components.json` (`ProductCard`, `SessionCard`, `NavBar`, `BottomSheet` radius),
`design-tokens.json` (`Off_black`, four replaced `productHues`, three new palette colours under
`deltas`), `scenarios.json` (`cardTitle` + `cardFamily` beside the existing `label`).

**`sample-ui`**

| File | Why |
|---|---|
| `components/UseSmileIDSampleProductCard.kt` | radius, padding, stroke, shadow removal, icon tile, go affordance, the two-run label, ghost opacity |
| `components/UseSmileIDSampleProductGrid.kt` | the `UseSmileIDSampleProductSlot` call site — six cards leave no odd slot (PVR-A4) |
| `components/UseSmileIDSampleSessionCard.kt` | gradient, stroke, radius, padding, three type styles |
| `components/UseSmileIDSampleSessionEndedBanner.kt` | inherits the new card treatment per §7.10 |
| `components/UseSmileIDSampleNavBar.kt` | pill fill, unselected label colour, shadow, drop the token border |
| `screens/ProductsScreen.kt` | header type and colour, section rename, page subtitle |
| `model/UseSmileIDSampleProduct.kt` | `cardTitle` / `cardFamily` |
| `tokens/SmileProductHues.kt` | four replaced pairs |
| `tokens/SmileTokens.kt` | the `Off_black` semantic token. **`radiusXl` stays** — §6 |
| `theme/UseSmileIDSampleTheme.kt` | **only if** PVR-A13 rules `Shapes.extraLarge` moves. Not part of PVR-A2 |

**Assets** — `design/icons/`, re-exported per §7.7 at one 21 × 21 box plus the 16 token glyph.

**Tests and flows** — the twelve golden images in §8, the `ScreenGoldenTest` /
`ScreenCompositeGoldenTest` fixtures, and `android/maestro/deep-links.yaml`, which asserts the literal
text `"SmartSelfie Enrollment"` that PVR-A3 removes from the card.

**One shared token to leave alone.** The card's label currently uses
`UseSmileIDSampleTheme.type.textStyleSubtitle`, which has **three other consumers** —
`UserDetailsScreen.kt` and `UseSmileIDSampleKeyValueEditRow.kt` twice. The card stops *using* it;
nothing may *change* it. Editing the style to match the new card would silently restyle a form and a
key-value row that no design frame in this refresh covers.

---

## 6. Should the whole app move to these padding and radius values?

Asked directly, and the answer is a qualified yes — because the audit says the app is **already**
mostly there and the product card is the outlier.

**Radius, counted across every component in `sample-ui`:**

Counted across **all** of `sample-ui/src/main`, not just `components/` — the distinction matters, and
an earlier count that scanned only `components/` got the key row wrong:

| Token | Value | Uses |
|---|---|---|
| `radiusSurface` | 16 | 10 |
| `radiusField` | 12 | 7 |
| `radiusSheet` | 20 | 6 |
| `radiusChip` | 999 | 4 |
| `radiusSm` / `radiusControl` | 8 / 32 | 3 each |
| `radiusXl` | **20** | **2 — the product card *and* the Material 3 shape scale** |
| `radiusMd` | 12 | 2 |

**`radiusXl` is not a single-use alias, and PVR-A13 must not simply delete it.** Its second consumer is
`UseSmileIDSampleTheme.kt:81` — `Shapes(extraLarge = RoundedCornerShape(SmileDimens.radiusXl))` — the
app's Material 3 shape scale. Every M3 component not given an explicit shape resolves its corner from
that scale, so `radiusXl` reaches far beyond the one card that names it.

That splits the work in two, and only the first half is what the design asked for:

1. **The card stops using it** (PVR-A2): `CARD_RADIUS` moves from `radiusXl` to `radiusSurface` (16).
   Contained, and exactly what node 5447:1701 draws.
2. **Whether `Shapes.extraLarge` also moves to 16 is a separate question with a wider blast radius**,
   because it silently re-shapes any M3 component relying on the default. It should not ride along with
   a products refresh. Leave `extraLarge` at 20 in PVR-A2, and let PVR-A13 decide it deliberately, with
   a device look — the affected surfaces are whichever M3 components take the default.

So: **do not delete `radiusXl`.** After PVR-A2 it has one consumer left, and that consumer is a
theme-level scale, not a stray.

**Padding is the same story.** The card's 12 → 16 moves it onto `spacingMd`, which is already the
second-most-used value and the one every screen-level gutter uses. No new token.

**Owner ruling 2026-08-24: 16 across the board.** So the migration is wider than the audit alone would
have justified, and that is a deliberate call for uniformity over per-surface nuance:

- Card radius `20 → 16`, card padding `12 → 16`, icon-tile radius `14 → 16`, session-card padding
  `14/15/16 → 16`. All land on tokens that already exist.
- `radiusXl` (20) is **kept**, not deleted — the card stops using it, but `Shapes.extraLarge` still
  does. Whether that scale also moves to 16 is decided separately in PVR-A13, on a device.
- `radiusSheet` (20 × 6) migrates too. This is the one that trades against `AGENTS.md`'s *"presentation
  stays platform-native"*, since a bottom sheet's corner is part of its native silhouette — it is
  called out in §7.8 and it is a one-word reversal if the device look says otherwise.
- The go affordance's `26` is not a radius; it snaps to `sizeIconLg` (24), a 2dp change nobody sees
  that keeps it on the scale every other circular control uses.

**What still does not get migrated on the strength of this frame.** Verifications, the forms, the
details screen and the pickers were drawn against boards 5447:1701 does not supersede. "Uniform" here
means *one radius value where a radius is chosen*, not *redraw screens this frame never covered*.
PVR-A13 is therefore a scale migration with a written diff, not a find-and-replace — and the review
that matters is the golden re-record, because a radius change is invisible in a diff and obvious on a
screen.

---

## 7. Rulings — answered 2026-08-24

All eight answered by the owner. Recorded with what each one costs, and with two places where the
design contradicts the ruling and needs one more pass.

### 7.1 Canonical layout — **5447:1701, confirmed** ("use Figma as truth")

`spec/screens.json` currently names `5206-4037` as the `products` screen's `canonicalLayout`, with an
owner ruling from 2026-08-13 behind it. That is now stale, so PVR-A11 moves `canonicalLayout` to
`5447-1701`, bumps `designVersion`, and marks the 2026-08-13 ruling superseded rather than deleting it.

*(This was the question that read as unclear. It is bookkeeping: `spec/screens.json` records, per
screen, which Figma node engineering builds against, so a reviewer can tell whether a screen matches
its source. Pointing it at the new node is the whole change.)*

**One consequence, resolved in §7.10:** the four other product states — `tokenLinked`,
`tokenLinkedLate`, `tokenExpired` and `production` — are drawn on the *superseded list* layout, and
were already being transposed by engineering under the 2026-08-13 `transposeStates` ruling. The
session card is now drawn on this frame, so `tokenLinked` is covered; `tokenLinkedLate` and
`tokenExpired` still are not, and `production` is deleted by the environment plan. **§7.10 settles it:
transpose, per the 2026-08-13 precedent.** No design pass is owed.

### 7.2 Gradients — **final as drawn; four of the six change**

**Owner ruling 2026-08-24: the frame is final, nothing unfinished.** So the Registration card's
amber-into-violet is the intent, and all six were read node by node rather than inferred. The result
is bigger than "already vendored": **two hues match `smileProductHues` exactly and four are replaced.**

| Card | Node | Gradient | Angle | Stops | vs `smileProductHues` |
|---|---|---|---|---|---|
| Registration | 5448:1999 | `#FFB53D` → `#A78BFA` **@79 %** | 135.81° | 66.63 / 129.78 | **new** (was `#05723A → #0A9B4C`) |
| Auth | 5448:1809 | `#3A49B4` → `#5361D6` | 136.52° | 6.45 / 91.91 | **exact match** |
| Document | 5448:1887 | `#2CC05C` → `#00AA99` **@79 %** | 135.40° | 66.63 / 129.78 | **new** (was `#E08600 → #FFB53D`) |
| Enhanced Doc. | 5448:2026 | `#04713A` → `#00AA99` **@79 %** | 135.40° | 66.63 / 129.78 | **new** (was `#2D2B2A → #4A4645`) |
| Biometric | 5448:2062 | `#151F72` → `#2B3A9E` | 141.80° | 56.02 / 110.51 | **exact match** |
| Enhanced | 5448:2080 | `#0EA5E9` **@79 %** → `#151F72` | 135.40° | 66.63 / 129.78 | **new** (was `#05726E → #0A9B96`) |

**So PVR-A5 is a token change, not a confirmation.** `smileProductHues` gains four replaced pairs, and
the palette gains **three colours it has never carried** — `#A78BFA`, `#00AA99` and `#0EA5E9`. The
other endpoints all already exist somewhere in the vendored set (`#FFB53D` is Document Verification's
old `to`; `#2CC05C` is dark `colorDecorativeGreen`; `#04713A` is the success badge's text; `#151F72` is
light `colorPrimary`), which is a good sign the new hues were picked from the system rather than
invented — but the three new ones need to land in the design-system source, not be pasted here.
Until they do, `spec/design-tokens.json` → `deltas` records them with their node ids.

**The dark/light behaviour, stated precisely, because "mode-invariant" is true of the definition and
not of the result.** The *gradient definitions* carry no mode variants — correct, and that is what
unblocks light mode. But **four of the six carry a `0.79` alpha stop**, and a card's only background is
its gradient, so that stop composites against the page: `#1A1C23` in dark, `#F9FAFB` in light. Those
four cards will therefore **render differently in the two schemes** — Enhanced KYC most of all, since
its alpha is on the *first* stop and covers the card's top-left. Auth and Biometric are fully opaque
and immune.

That is very likely the intent — a translucent card over the page is a real effect and it is why the
stops run past 100 %. The consequence to plan around is testing: a light-mode golden that differs from
its dark twin by more than text colour is **correct** here, and PVR-A12 must not treat the divergence
as a defect. Worth one confirming look at the four on a light background before the goldens are
recorded, because that combination has only ever been seen on dark.

### 7.3 `Off_black` — **Figma is truth**

Adopt the design's warm pair as a **new semantic token**, not the repo's cooler `colorTextTitle`
(`#21232C` ↔ `#F2F2F2`) and not a primitive:

| | Light | Dark |
|---|---|---|
| `Off_black` | `#2D2B2A` | `#F9F0E7` |

Figma models it as **one** variable across four roles — page title, page subtitle, card stroke,
unselected nav label — so PVR-A1 adds one token and uses it in all four. The design-system repo is
where it should be named; this repo vendors it. Until it lands there, `spec/design-tokens.json`
records it under `deltas` with the node id, which is exactly what that section is for.

### 7.4 Product names — **shortened to prevent overflow; the full name survives elsewhere**

The clarification settles the shape. `Registration`, `Auth`, `Document`, `Enhanced Doc.`,
`Biometric`, `Enhanced` are **card display titles chosen to fit a 114.5dp text column**, with the
family (`SmartSelfie™`, `Verification`, `KYC`) on the second line. They are not a rename of the
product.

So the 2026-08-13 ruling — *the label is the SDK's job-type name in full* — **still holds** for the
verifications row and the result card. Only the card gets the short pair.

That still has to be specified rather than derived, because four platforms must abbreviate
identically: "Enhanced Doc." and "Enh. Doc" are both reasonable and only one is right.
`spec/scenarios.json` therefore grows two fields beside the existing `label`:

```json
{ "id": "enhancedDocumentVerification",
  "label": "Enhanced Document Verification",
  "cardTitle": "Enhanced Doc.",
  "cardFamily": "Verification" }
```

`label` is untouched, so nothing downstream of it moves. **This is the collision with the environment
plan** (§5.6): ENV-A13 adds `SmartSelfie™` to labels, and the mark now belongs in `cardFamily`, so
PVR-A3 lands first.

### 7.5 Profile switcher — **stays as it is today**

The header avatar button remains, per the 2026-08-13 owner decision; its absence from 5447:1701 is a
drawing omission, not a removal. `sample_profile_avatar_button` keeps its target and `profiles.yaml`
keeps working. Worth one line in `spec/screens.json` saying the frame omits it and the app keeps it,
so the next conformance pass does not report it as an extra.

### 7.6 Stroke — **0.2dp, uniform**

Ruled: **0.2dp**, not snapped to `borderWidthHairline`. Applied to every card and to the session card.

**Recorded, not re-asked:** with all six cards now read, five are `0.2px` and **Biometric (5448:2062)
is `0.5px`**, as is the session card. Since 0.2 is the ruling and the frame is final, the
implementation uses 0.2 everywhere and those two nodes are the odd ones out — worth normalising in
Figma next time the file is touched, so a future reader does not "correct" the code back to 0.5.

**It renders, and it is density-dependent.** Compose anti-aliases a fractional-dp border rather than
rounding it away, so 0.2dp is a faint sub-pixel line — roughly 0.6px on a 3x device, 0.8px on 4x. It
will not vanish, but its apparent weight varies by device and the four platforms anti-alias
differently. That is an acceptable cost for a deliberately hairline treatment; it is not acceptable as
a surprise, so PVR-A12 asserts it on a device at two densities rather than trusting a golden rendered
at one.

### 7.7 Icons — **re-export all of them**

Not just the products set: the whole `design/icons/` inventory, at the sizes and stroke weights this
frame uses. `spec/components.json` already forbids substituting a Material Symbol and records that the
design supplies all eleven settings icons as 19px stroke exports; those become part of the re-export
too, because scaling a stroke-based icon is exactly what changes the property that changed.

Sizes read off the frame: **21** in the card tile and the nav tabs, **16** in the token button.

**Normalise the glyph box — agreed 2026-08-24.** Five card glyphs export at `21 × 21`; Biometric's is
`13.44 × 12.95` inside the same 40dp tile. Four platforms centring differently sized glyphs in a fixed
tile will not agree, so the re-export delivers **one 21 × 21 box** for every card icon, with optical
sizing done inside the artboard rather than by the container. Same rule for the nav set at 21 and the
token glyph at 16.

### 7.8 Scale — **16 everywhere, uniform across the board**

Applied as: card radius `20 → 16`, card padding `12 → 16`, icon-tile radius `14 → 16`, session-card
padding `14/15/16 → 16` on all four sides.

**`radiusXl` survives** — see §6: its second consumer is the Material 3 `Shapes.extraLarge` scale, so
deleting it would break the theme and silently re-shape any M3 component taking the default. PVR-A13
rules on that scale separately.

Two values the ruling does not cover, resolved the same way and flagged rather than assumed:

- **The go affordance, 26.** Not a radius. Snapped to `sizeIconLg` (24) — a 2dp difference nobody can
  see, and it keeps the affordance on the icon scale where every other circular control lives.
- **`radiusSheet` (20 → 16), used six times — confirmed 2026-08-24, "proceed and update specs".** So
  PVR-A13 migrates sheets too and `spec/components.json` → `BottomSheet` records 16. It is a visible
  change on six surfaces, so it still wants a device look rather than a golden diff — the reason to
  look is that a sheet's corner reads as part of its native silhouette, and 16 is a slightly squarer
  sheet than Android users see elsewhere. Not a blocker, just the one change here that is felt rather
  than measured.

### 7.9 Ghost glyph — **10 %, and the constant splits**

Ruled: **the new design is the direction.** So the ghost glyph is **10 %** (node 5448:2068 carries it
explicitly) while the go pill stays **16 %** (`rgba(45,43,42,0.16)`, unchanged on all six cards).

Today both come from one constant, `SCRIM_ALPHA = 0.16f`. PVR-A14 splits it in two — the go pill keeps
`SCRIM_ALPHA`, the ghost gets its own — and names both after what they are, so the next reader does not
re-unify them on the assumption they drifted by accident.

### 7.10 The other product states — **the question, restated plainly**

*What `states` are:* `spec/screens.json` lists, per screen, every visual state with the Figma node that
draws it, so a reviewer can check the build against a source. The `products` screen has five:
`default`, `tokenLinked`, `tokenLinkedLate`, `tokenExpired` and `production`.

*Where they stand after 5447:1701:*

| State | Drawn on the new frame? |
|---|---|
| `default` | **yes** — this is the frame |
| `tokenLinked` | **yes** — the session card at `5:00` |
| `production` | n/a — deleted by the environment plan; there is no production *chip* any more |
| `tokenLinkedLate` | **no** — the "countdown at 1:40" variant |
| `tokenExpired` | **no** — the session-ended banner with its Scan action |

So two states have no drawing on the new layout. They were in the same position last time and the
owner ruled on 2026-08-13 (`transposeStates`) that **engineering transposes** rather than waiting for
design, because the header, session strip and nav bar are identical between layouts and only the card
grid differs.

**Answered 2026-08-24 — read as: the new design covers products, all six cards.** That settles the
card inventory (PVR-A4) and leaves the two token *states* undrawn on the new layout, so they follow the
2026-08-13 `transposeStates` precedent by default.

**Proceeding on that reading: transpose**, on the precedent and because both states are variants of a component the
new frame *does* draw. The session card at `1:40` is the same card with a different number and,
per the old frames, a warning-coloured ring; the ended banner is an existing built component
(`UseSmileIDSampleSessionEndedBanner`) that only needs the new card's radius, stroke and padding.
Record it in `spec/screens.json` as transposed, with the node the treatment came from, so the next
conformance pass knows the difference between "engineering chose this" and "design drew this".

*If a frame does exist for either state on the new layout, point at it and this becomes a straight
implementation instead — the recommendation is only the fallback for two states nothing draws.*


---

## 8. Testing

`android/verify.sh` stays the definition of done.

- **Goldens, and the list is longer than the screens.** Screen goldens: `screen_products`,
  `screen_products_token_linked`, `screen_products_token_expired`, `screen_products_in_flight`, light
  and dark — plus `screen_products_production` deleted by the environment plan, and `profile_env_chip`
  following §5.6. **Composite goldens re-record too, and there are five, not three** — checked against
  `ScreenCompositeGoldenTest`: `product_card`, **`product_grid`**, `session_card`,
  **`session_ended_banner`** and `nav_bar`. `product_grid` moves because the card geometry and the card
  count both change; `session_ended_banner` moves because §7.10 gives it the new card's radius, stroke
  and padding. **Look at each one**; a re-recorded golden that nobody opened is a rubber stamp.
- **Both schemes, every time — and expect them to differ by more than text colour.** Four of the six
  gradients carry an alpha stop that composites against the page (§7.2), so those cards genuinely
  render differently in light and dark. A light-vs-dark golden diff bigger than typography is
  **correct** here. Do not "fix" it, and do not let a reviewer treat it as a regression — say so in the
  PR. Auth and Biometric are fully opaque and should match across schemes; if they do not, that *is* a
  bug.
- **The structural predicates are the real gate here, not the goldens.** The card label goes from one
  line to two runs in a fixed 138dp card at a fixed 172.5dp width. `assertSurvivesMaxFontScale` on the
  product grid is the test that matters, and `Enhanced Doc. Verification` in a 114.5dp text column is
  the worst case. `spec/components.json` already warns that `SmartSelfie Authentication` wraps to two
  lines at default scale on this card width — the new titles are shorter, but the subtitle adds a line
  the old card did not have.
- **Contrast, in both presentations.** The stroke and the nav-pill change both move contrast: a 0.2px
  `Off_black` stroke on a mid-tone gradient, and a nav pill the same colour as the page. Run
  `UseSmileIDSampleContrastTest` over the new values and treat a fail as a design question, not a
  local nudge.
- **On a device, in dark, specifically for §3.4.** Whether the nav bar still reads as a bar when its
  fill matches the page is not answerable from a golden — the shadow is 12 % black and goldens render
  it faithfully at a size nobody looks at.
- **Device flows.** `profiles.yaml` breaks if §7.5 removes the avatar trigger, and any flow asserting
  product names by text breaks on the rename — `deep-links.yaml` asserts the literal
  `"SmartSelfie Enrollment"`, which no longer exists on this screen. Move those onto `sample_*` ids in
  the same change.

---

## 9. What the other three inherit

**The token map in §2 is the deliverable, not the screenshots.** Four of five variables map exactly
onto tokens all four platforms already vendor, so the ports need no new palette — they need the
mapping, and they need `Off_black` resolved once (§7.3) rather than four times.

**The reading technique travels too.** `get_variable_defs` gives the frame's mode;
`get_design_context`'s `var(--token, …)` fallback gives the default mode. A port that reads only the
first will implement the dark values as if they were the only values.

**Three rules that must not drift:** the card label is one text node with two runs, not two stacked
labels; the go affordance is a text glyph, not an icon asset; and the strokes are one width across
both card types once §7.6 answers. Each is a place where a port would otherwise make a locally
reasonable choice and diverge.

**And the sequencing note:** PVR-A3 changes `spec/scenarios.json`, which is the file the ports read
for product labels. Until §7.4 is answered, a port implementing product cards is implementing a
label shape that is about to change.

---

## 10. Landing order

**This plan is phase three.** Owner-set sequence 2026-08-24: the token/environment chain lands first,
then the Settings work, then this. **Its first blocker is clear:**
`environment-from-token-android.md`'s PR 1 merged as **PR #27 on 2026-08-25**, so ENV-A3 has already
removed the environment surfaces this plan's header changes sit on top of — the ordering that would
have re-recorded the same goldens twice is no longer possible. What remains ahead of it is the
Settings PR, which re-records `screen_settings` and the result card, and ENV-A13 is now part of this
plan rather than of that one (§5.6, and ENV-A13 in the other document).

1. **§7 answered first, and §7.2 and §7.5 are the two that actually block.** Without gradients there is
   no light mode; without a profile trigger the screen ships a dead end.
2. **PVR-A1 alone** — the token map into `spec/design-tokens.json`, plus whatever `Off_black` becomes.
   Everything else reads it, and getting it wrong once is cheaper than getting it wrong nine times.
3. **PVR-A3 before `environment-from-token-android.md`'s ENV-A13** (§5.6), or the mark lands on a
   string that is about to be split.
4. **PVR-A2 + A4 + A9** — the card itself, the sixth product, the icons. One PR, one golden re-record.
5. **PVR-A5** the moment §7.2 lands, and not before — a card with the right geometry and the old hues
   is a useful intermediate state; a card with invented gradients is not.
6. **PVR-A6 + A7 + A8** — session card, nav bar, header. Cheap once A1 exists.
7. **PVR-A11 + A12** with whichever PR touches the surface they describe, never as a catch-up.
8. **PVR-A13** last and on its own, as a written audit — it changes files this frame does not cover,
   so it needs its own reviewer.

One PR per repo, single conventional-commit subject lines, no changelog. And every claim about colour
verified in **both** schemes on a device, because this is the first change in this app where the two
can be structurally different rather than just differently tinted.
