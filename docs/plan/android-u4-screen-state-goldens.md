# Android U4 — every screen state goldened, and the test that keeps it that way

Android had roughly 109 golden tests across eleven files in `sample-ui`'s `golden/` package, light
and dark, plus the font-scale predicates. What it did not have was **enforcement**: its
`spec/screens.json` reference was a doc comment on `ScreenGoldenTest`, so a state added to the spec
failed nothing here. iOS closed the same gap on 2026-09-10 with
`UseSmileIDSampleScreenStateGoldenTest` (`ios-port-hardening.md` §19), which deliberately left the
Android *shape* open. This doc closes U4 and records the two calls that shape forced.

The spec is the count of record: **16 screens, 41 states**, two of them the SDK's own consent
screen. Where `ui-work-plan.md` disagreed with it, the doc was wrong and is corrected.

---

## D1 — the enforcement is a state→golden name table, parsed out of the golden sources

`ScreenStateGoldenTest` holds a `state → golden name` map plus an exemption map whose values are the
reasons, and fails on all five conditions the requirement names:

| Failure | What catches it |
|---|---|
| a state added to `spec/screens.json` | the spec's state set must equal `goldens.keys + exempt.keys` |
| a stale exemption (or a stale table entry) | the same equality, in the other direction |
| an exemption that is also recorded | the two key sets must not intersect |
| two states sharing one baseline | the table's values must be distinct |
| a golden renamed out from under its entry | every name must appear as a `goldens("…")` call in the package |
| a baseline missing in light or dark | every name must have `<name>_light.png` **and** `<name>_dark.png` |

It parses **every** file in the golden package rather than one, so splitting a screen's goldens into
a new file later does not red it — the same property iOS's version has.

**Sources *and* recorded files, because they catch different things.** The source parse proves a
test produces the name and is the only thing that sees a rename: Roborazzi leaves the old PNG on
disk when a `goldens("…")` argument changes, so a disk-only check would keep passing against a
stale baseline. The disk check proves the clause the source parse cannot see — that the picture
exists **in both schemes** — and it is free, because `src/test/screenshots` is already a declared
input of every `Test` task, so an edited baseline re-runs this test.

**Why not a `@Preview` inventory**, which is closer to what Android's screenshot tooling wants:

- The repo has **zero** `@Preview` functions today. Driving the inventory from previews means
  authoring 37 of them *and* adopting `roborazzi-compose-preview-scanner` as a second capture path
  beside the eleven files that already record 134 baselines — or migrating all of them. That is a
  tooling migration wearing an enforcement task's clothes.
- Preview-scanner names its output from the preview's fully-qualified function name, so a golden's
  identity becomes package + file + function: **moving a file renames every baseline it owns.** The
  name table's identity is a string a reviewer chose.
- Previews live beside the composable in `main`, so the fixtures 37 states need — seeded profiles, a
  linked session, eleven job rows — would move onto the shipped classpath, against the grain of the
  rule that keeps made-up records behind a launch argument.
- It would put Android's enforcement in a shape the iOS reviewer cannot read beside their own, for
  no gain the table does not already give.

**What happens when someone renames a test method:** nothing, and that is the point. Roborazzi names
its output from the `goldens("…")` argument, not from the method, so renaming `fun products()` to
`fun productsDefault()` changes no baseline and reds nothing. Renaming the golden *string* is what
reds it, and that is the rename worth catching. Under a preview inventory the opposite holds — the
function name *is* the baseline name, so an ordinary rename reds the lane and the fix is a
re-record rather than a one-word table edit.

**What it cannot do**, stated so a green run is not over-read: it proves a golden *exists* for a
state, never that the golden *shows* that state. That is the review of the picture, and it is why
this slice read every baseline it recorded.

## D2 — the exemption set is re-derived on Compose's terms, not ported

iOS exempts five. Android exempts **four**, and two of iOS's five do not survive the translation.

**Exempt (4):**

- `consent.notAgreed`, `consent.agreed` — `owner: "sdk"` in the spec. This app decides whether the
  step runs; it never draws the screen.
- `products.supersededListLayout` — a layout the spec keeps only so nobody rebuilds it. There is no
  composable to render.
- `verifications.refreshing` — **and for a different reason than iOS's.** iOS exempted it because
  the indicator is system-drawn and a static render never sees it. That reason does not travel:
  Compose's `PullToRefreshBox` takes `isRefreshing` as a hoisted boolean and renders its indicator
  perfectly well in a Robolectric capture — `VerificationDetailsScreen` already passes one. The
  Android reason is that **the list has no pull affordance at all**: the gesture lives on the
  details screen (`sample_details_refresh`), and the *list's* own pull is still deferred with the
  owner (`ios-port-hardening.md` §15). There is nothing to draw, on either platform, for opposite
  reasons.

**Recorded, where iOS could not (2):**

- `verifications.swipeToDelete` — iOS's reveal rests at zero because it is `@GestureState`.
  Android's is `SwipeToDismissBox`, whose offset is an anchored draggable that **holds** while a
  pointer is down: `down(center)` then `moveBy(-140f, 0f)` with no `up()` leaves the row half open
  and the "Hide" backdrop in the picture. Measured, then recorded.
- `userDetails.editing` — the spec's state is "focused row with caret". `requestFocus()` plus a held
  clock puts a real caret in the baseline. The caret blink is a repeating 500 ms alpha, so the
  capture sets `mainClock.autoAdvance = false` and advances **250 ms** past focus, landing inside
  the visible phase deterministically. Without the held clock the blink is an animation the capture
  would race. Copying iOS's reading — partial values, no caret — would also have shipped a picture
  nearly identical to `userDetails.empty`, which is exactly the shared-baseline failure D1 tests
  for; the golden carries partial values *and* the caret.

So the count is **37 recorded + 4 exempt = 41**. Copying iOS's five would have under-covered Android
by two states silently, which is the failure this test exists to prevent.

### The sheets needed no new dependency, and no new harness

Four of the states are `ModalBottomSheet`s, which render into their own window and so fall outside
`onNodeWithTag(GOLDEN_ROOT)`. Roborazzi already handles this: `captureRoboImage` calls
`captureScreenIfMultipleWindows`, which detects the second window and captures every root instead —
the sheet over its scrim, over the screen that owns it. That is a truer picture than the sheet alone
(R12: a sheet is a layer over its owner, never a destination), and the goldens compose each sheet
over the screen that opens it. The one cost is that a full-window capture is the device width,
411 dp, rather than the 393 dp box the other goldens use.

---

## The app-bar title at AX5 — Android and iOS diverge, deliberately, and here is the measurement

§19 ruled that at accessibility sizes iOS's shared bar takes its controls on one row and the title
on the next at full width, because its title was breaking character by character — "Sca / n / tok /
en", "Veri / fica / tion" — and blessing that baseline would have handed a picture of a defect on as
the reference.

**Android does not adopt that layout, because Android does not have that defect.**

`UseSmileIDSampleTopAppBarButton` is `.size(SmileDimens.space40)` — a `dp`, which does not scale with
`fontScale`; only the row's `defaultMinSize` does. iOS's two 40 pt controls scale *with* Dynamic
Type, and that is what squeezed its title column to a few characters. Measured rather than assumed:
at `fontScale = 2f` the Android title column is **233 dp** whether or not the bar carries a trailing
action, and every title the app ships wraps on word boundaries only —

```
'Verification details'           -> [Verification , details]
'SmartSelfie Authentication'     -> [SmartSelfie , Authentication]
'Enhanced Document Verification' -> [Enhanced , Document , Verification]
'Open-source licenses'           -> [Open-source , licenses]
'Kazi Microlending'              -> [Kazi Microlending]
```

— all thirteen, with and without an action. Adopting iOS's stacked layout would put a `fontScale`
branch into a shared component for no user-visible gain, make the bar two rows tall where one reads
correctly, and ship a layout the design has never drawn on the platform three ports are compared
against. The uniformity rule is about the design; below the accessibility sizes the two bars are
identical, and the divergence exists only where each platform's own type system takes over — which
is the "native behaviour" half of that rule.

**What travels is the guarantee, not the layout.** A measurement in a doc rots, so the claim is a
committed predicate: `assertTitlesBreakBetweenWordsAtMaxFontScale` lays out every shipped title at
2× and fails on a line break inside a word. That closes precisely the hole the existing predicate
leaves — `didExceedMaxLines` never fires on a title that *wraps* rather than truncates, which is why
iOS's defect survived a green lane for as long as it did.

## Two four-app copy questions §19 parked — both ruled, neither changed here

**The day header prints its date twice.** `UseSmileIDSampleJobDates.groupByDay` falls back to the
absolute date when a day is older than yesterday, and `UseSmileIDSampleDateGroupHeader` renders
`"$relative  ·  $absolute"` regardless, so `screen_verifications` reads
"TUE, 14 JUL 2026 · TUE, 14 JUL 2026". Visible in the committed baseline.

**Ruled a defect, not a copy preference** — `spec/components.json` already settles it: the
`DateGroupHeader` format is `'<relative> · <absolute>'` and the note reads "relative **word** plus
absolute date". With no relative word there is nothing to put left of the dot, so the header should
be the absolute date alone. Nothing about that needs an owner.

**Not landed in this slice, on purpose.** It changes a shipped string in Android *and* iOS — the two
apps that exist — and the four-app rule means one change touching both. Folding it in here would
bury an iOS `verifications` rebaseline inside an Android enforcement PR, and would leave the two
apps divergent for the life of the review if only Android moved. It is one line per platform plus
both `verifications` baselines, and it is carried in `ui-work-plan.md` §5 so it is not rediscovered
a third time.

**The literal backticks in "Tap `Hide from List` to confirm" stay**, and the reason is sharper than
"the twin ships them too". `spec/components.json` writes the copy *with* the backticks —
"Copy changes with count: 'Tap rows to select' → 'Tap `Hide from List` to confirm'" — and that note
is genuinely ambiguous: they are either characters to render or the spec author's emphasis around a
button label. Both apps resolved it as literal. Resolving it the other way is a `spec/` clarification
and a shipped string in two apps, so it needs Harun rather than an engineer's reading. Recorded
here, ambiguity named, so the next reader inherits the question rather than the surprise.

---

## What reading the baselines found

Recording is not the check; the pictures are. What the 2× renders showed:

- **The product cards break mid-word at 2×** — "Registr / ation", "Docum / ent", "Biometr / ic",
  "Enhanc / ed" — because the design's 2-up expressive grid leaves each card a 102 dp text column,
  and no product word fits it at doubled type. It does not clip, so the existing predicate passes,
  and §5 already records that this card's text was tuned once for exactly this reason. **Not fixed
  here:** collapsing the grid to one column at accessibility sizes is a layout the design has not
  drawn, and Android is the arbiter three ports copy, so inventing one propagates. Raised as a
  design ask in `ui-work-plan.md` §5.
- **`UseSmileIDSampleDataFieldRow` does *not* have iOS's defect.** iOS's label/value pair collapsed
  into two columns a few characters wide at AX5; Android's `Row` gives the label its intrinsic width
  and the value `weight(1f)`, and at 2× the details screen reads cleanly — "Provisional — needs
  review" wraps on words, the timestamp takes three whole lines, and the heading beside the status
  badge reads "Enhanced / Document / Verification". No change needed, so the AX stack iOS added is
  a fix Android already had by construction.
- **`verificationDetails` had three of its four states pointing at the wrong job.** The committed
  `screen_verification_details` was the *clear* fixture and `…_queued` was that same clear fixture
  with a 202 pasted onto it — a status the row's badge contradicts. The spec's four states are
  `attention`, `clear`, `blocked`, `processing`, and each now renders the fixture that actually
  carries that status.
- The ellipsis on `job_03ky…` is `UseSmileIDSampleJob.shortId`, a model-level shortening, not layout
  truncation — worth stating because it looks like the thing the no-clipping predicate exists to
  catch.

**Where two states could differ only below the fold, the baselines were hashed rather than eyeballed**
— `products.tokenLinked` against `products.tokenLinkedLate` (the countdown alone), and the two
scenario-drawer states (which selection has moved). This is §19's scan-token lesson applied rather
than re-learned.
