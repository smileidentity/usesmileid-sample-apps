# iOS port — what to harden before the remaining fourteen screens

Written 2026-08-28, against the stack that finished U0–U2 and the first two U3 screens. Every item
here is something that gets **more expensive the longer it waits**, because the cost scales with the
number of screens built on top of it. Fourteen screens, the result card and U4's state sweep are
still to come, so the multiplier is large.

Ranked by that multiplier, not by severity.

---

## 1. The golden harness cannot see truncation, and every screen inherits that

**Now:** `assertSurvivesMaxDynamicType` asserts that nothing lays out past the viewport, and writes
an AX5 baseline. It cannot assert that text is un-truncated, because SwiftUI publishes no truncation
flag a unit test can read — the Compose twin gets `didExceedMaxLines` from the semantics tree.

**Why it compounds:** clipping inside the viewport is currently caught only by a human reading the
baseline. Two screens is readable. Sixteen screens across 38 states is not, and the failure is
silent — a clipped label still produces a passing test and a plausible-looking picture.

**Options, cheapest first:**

- Compare the AX5 render against the same content laid out with unbounded height. A component whose
  bounded height is smaller than its unbounded height has lost content. This is measurable today
  with two `UIHostingController.sizeThatFits` calls and needs no new dependency.
- Failing that, assert per-component that the rendered image's bottom row of pixels is background —
  weaker, and prone to false positives on a component that legitimately fills its frame.

**Do it before U4**, because U4 is where the 38 states land and where a silent clip is most likely.

---

## 2. A test id can be declared and never applied — CLOSED 2026-08-28

**Now:** `UseSmileIDSampleSpecTest` asserts every id in `UseSmileIDSampleTestIds.all` exists in
`spec/test-ids.json`. It does not assert that any view applies it.

**Evidence this is real, not theoretical:** `sample_selection_bar` shipped declared-but-unapplied and
was caught by the review bot on PR #40, not by the suite. A device flow waiting on it would have
timed out with no clue why.

**Why it compounds:** every screen adds ids. The screens still to come own most of the spec's
remaining ids, so the window for this defect is widening, not narrowing.

**Done:** `UseSmileIDSampleTestIdUsageTest` scans `Sources/` for each declared id's symbol and
asserts the unused set exactly matches a listed inventory — so an id that stops being applied fails,
and a stale entry fails too. Writing it corrected the estimate: six ids are unapplied, not the twelve
assumed. Two are the bare prefixes the spec check anchors on; the other four wait on the
verifications screen.

---

## 3. The custom nav bar exists but the shell still uses `TabView`

**Now:** `UseSmileIDSampleNavBar` is built, has goldens, and is used by nothing. The shell renders
the platform `TabView`, which the simulator run confirms — the app shows the system tab bar, not the
design's floating pill.

**The question is a real one, not an oversight to fix blindly.** A tab bar's appearance is a visual,
and visuals are meant to be uniform across the four apps; its behaviour is navigation, and navigation
is meant to be platform-native. The Compose twin draws the floating pill. Someone has to rule on
which side of that line the iOS tab bar falls.

**Why it compounds:** every screen lands inside whichever container wins. Switching later means
re-checking every screen's bottom inset and re-recording every screen-level baseline.

**Ask for the ruling before U3 continues.** If the pill wins, the shell hosts it over the content and
`TabView` goes; if `TabView` wins, delete `UseSmileIDSampleNavBar` and its goldens rather than
leaving a component the app does not use.

---

## 4. Overriding one property of a type style is verbose enough to be got wrong

**Now:** `SmileTextStyle.with(size:tracking:)` covers size and tracking. Weight has no equivalent, so
five call sites rebuild the whole value:

```swift
SmileTextStyle(
  family: base.family,
  weight: 700,
  size: base.size,
  lineHeight: base.lineHeight,
  tracking: base.tracking
)
```

**Why it compounds:** it is five call sites across two PRs and the screens have barely started. Each
one is a chance to drop `lineHeight` or `tracking` silently — the value still compiles and the text
still renders, just fractionally wrong, which is exactly the class of defect goldens catch late and
expensively.

**Plan:** extend `with(...)` to take `weight` too, and convert the five sites. Small, mechanical, and
it removes a whole category of near-miss.

---

## 5. Deep-link delivery is still unproven end to end

**Now:** link resolution is unit-tested (URL → router state) and that is solid. Delivery is not:
`simctl openurl` on a custom scheme raises a system "Open in?" prompt that swallows the link —
re-confirmed on iOS 26.5 during this stack's simulator pass.

**Why it compounds:** every screen adds a route and a deep link. The longer delivery goes unproven,
the more links are asserted only at the resolver, and the larger the first XCUITest becomes.

**Plan:** one XCUITest that launches with a link and asserts the resulting screen id. It is owed for
the device pass regardless, and it gets cheaper the earlier it exists because each new route then
costs one line instead of a new harness.

---

## 6. The icon generator will meet a path command it does not support

**Now:** `scripts/generate_ios_icons.py` supports M, L, H, V, C, Q, T and Z, absolute and relative —
which is exactly what today's 35 icons use. Anything else fails the run loudly, which is the correct
behaviour and deliberate.

**Why it matters later:** Enhanced KYC is still owed an icon, and the nav icons may yet be adopted.
A new mark exported with an arc (`A`) or a smooth curve (`S`) will stop the build. That is the right
failure, but whoever hits it should not have to rediscover the parser.

**Plan:** no code change needed now. Add the two-line note to the generator's docstring saying which
commands are missing and that adding one means implementing it in `emit_path`, not loosening the
check. Cheap insurance against someone "fixing" the loud failure by skipping the subpath.

---

## Considered and rejected

- **Giving the SPM test target a host app so `UISwitch` renders its thumb.** The thumb is missing
  from the switch baseline because the offscreen render path skips its layer, and the strategy that
  would capture it needs a host application. Adding one is a structural change to the package for
  one component's cosmetic coverage; the tracks still catch tint and state regressions, and the
  device pass covers the thumb. Not worth it.
- **Replacing the hand-rolled two-column grid with a lazy grid.** The host screen already scrolls, so
  the current rows are correct and cheaper. No change.
