# iOS port — where to pick up, and what to harden before the remaining screens

Written 2026-08-28, against the stack that finished U0–U2 and the first two U3 screens.

## Where to pick up

Do these in order. The first is a decision, not code, and it blocks the rest.

| # | Do this | Why it comes first | Ends when |
|---|---|---|---|
| 1 | **Rule the nav container** — floating pill or `TabView`. See §1. | The only open question that can invalidate finished work. Every remaining screen lands inside the winner and records its bottom inset and baseline against it. | A ruling exists, and the losing option's code is deleted rather than left orphaned. |
| 2 | **Merge the open stack**, oldest first. | Three PRs deep is the practical limit: this repo squash-merges, so each merge turns the branches above into a `rebase --onto`, not a plain rebase. | `main` carries all three; no stacked branches remain. |
| 3 | **Build the first XCUITest.** See §5. | Every new route is currently asserted only at the resolver. One file now makes each later screen self-verifying; deferring it accumulates fourteen screens of unproven navigation into one pass. | A link launches the app and the resulting screen id is asserted in CI. |
| 4 | **Continue U3** in `ui-work-plan.md`'s order — verifications, then verificationDetails, then the forms and pickers. | Settled order; do not relitigate it. | All sixteen screens exist. |
| 5 | **Close the truncation gap.** See §2. | Only starts biting at U4, when the 38 states land. Doing it sooner spends effort on a problem still readable by eye. | An automated check fails on clipped text. |

**The open stack, in merge order:** #40 (verifications list and select mode) → #42 (products grid and
nav bar) → #43 (settings and products screens). All three are green with no unresolved review
threads. #43 also carries this document.

---

## 1. The nav container is undecided, and the shell and the component disagree

**Now:** `UseSmileIDSampleNavBar` is built, has goldens, and is called by nothing. The shell renders
the platform `TabView`, which the simulator run on 2026-08-28 confirms — the app shows the system tab
bar, not the design's floating pill.

**This is a real question, not an oversight to fix blindly.** A tab bar's appearance is a visual, and
visuals are meant to be uniform across the four apps. Its behaviour is navigation, and navigation is
meant to be platform-native. The Compose twin draws the floating pill. Someone has to rule which side
of that line the iOS tab bar falls on.

**Whichever way it goes, one of the two gets deleted.** If the pill wins, the shell hosts it over the
content and `TabView` goes. If `TabView` wins, `UseSmileIDSampleNavBar` and its goldens go, rather
than leaving a component the app does not use.

**How it got here, so it does not recur:** the component was built because it was on U2's list,
without checking what would consume it. The shell has used `TabView` since the walking skeleton. Run
the app on a simulator at the end of each slice — that is what surfaced this, and it would have
surfaced it a PR earlier.

---

## 2. The golden harness cannot see truncation, and every screen inherits that

**Now:** `assertSurvivesMaxDynamicType` asserts nothing lays out past the viewport and writes an AX5
baseline. It cannot assert text is un-truncated, because SwiftUI publishes no truncation flag a unit
test can read — the Compose twin gets `didExceedMaxLines` from the semantics tree.

**Why it compounds:** clipping inside the viewport is caught only by a human reading the baseline.
Two screens is readable. Sixteen screens across 38 states is not, and the failure is silent: a
clipped label still produces a passing test and a plausible-looking picture.

**Options, cheapest first:**

- Compare the AX5 render against the same content laid out with unbounded height. A component whose
  bounded height is smaller than its unbounded height has lost content. Measurable today with two
  `UIHostingController.sizeThatFits` calls; needs no new dependency.
- Failing that, assert the rendered image's bottom row of pixels is background. Weaker, and prone to
  false positives on a component that legitimately fills its frame.

**Do it before U4**, which is where the 38 states land.

---

## 3. A test id can be declared and never applied — CLOSED 2026-08-28

`UseSmileIDSampleTestIdUsageTest` scans `Sources/` for each declared id's symbol and asserts the
unused set matches a listed inventory exactly — so an id that stops being applied fails, and a stale
entry fails too.

Kept here because the inventory is a live to-do list: **six ids are not yet on a view.**
`productCardPrefix` and `settingNavPrefix` are expected — they exist so the spec check has an anchor,
and the real ids are built from them. The other four — `jobRow`, `jobRowStatus`, `filterCount`,
`selectionCheckbox` — wait on the verifications screen. Delete them from the list as it lands.

Writing the test corrected the estimate: six unapplied, not the twelve assumed.

---

## 4. Overriding one property of a type style — CLOSED 2026-08-28

`SmileTextStyle.with(...)` now takes `size`, `tracking`, `weight` and `lineHeight`, and the five
hand-rebuilt call sites use it.

**One trap worth keeping:** `with(size:)` rescales `lineHeight` by the token's ratio. Two call sites
need the design frame's own explicit line height instead, and pass it. Getting that wrong changes
only where wrapped text sits, so it shows at accessibility sizes and nowhere else — the AX5 golden is
what caught it. Pass `lineHeight` explicitly whenever the value comes from a `productsScreenType`-style
delta rather than from the token ramp.

---

## 5. Deep-link delivery is still unproven end to end

**Now:** link resolution is unit-tested (URL → router state) and that is solid. Delivery is not.
`simctl openurl` on a custom scheme raises a system "Open in?" prompt that swallows the link —
re-confirmed on iOS 26.5 during this stack's simulator pass.

**Why it compounds:** every screen adds a route and a deep link. The longer delivery goes unproven,
the more links are asserted only at the resolver.

**Plan:** one XCUITest that launches with a link and asserts the resulting screen id. It is owed for
the device pass regardless, and each new route then costs one line instead of a new harness.

---

## 6. The icon generator will meet a path command it does not support

`scripts/generate_ios_icons.py` supports M, L, H, V, C, Q, T and Z, absolute and relative — exactly
what today's 35 icons use. Anything else fails the run loudly, which is deliberate.

Enhanced KYC is still owed an icon and the nav icons may yet be adopted, so a mark exported with an
arc (`A`) or smooth curve (`S`) will stop the build. That is the right failure. Whoever hits it
should add the command to `emit_path`, **not** loosen the check — a skipped subpath is a mark that
renders wrong rather than not at all.

---

## Considered and rejected

- **Giving the SPM test target a host app so `UISwitch` renders its thumb.** The thumb is missing
  from the switch baseline because the offscreen render path skips its layer, and the strategy that
  would capture it needs a host application. That is a structural change to the package for one
  component's cosmetic coverage; the tracks still catch tint and state regressions, and the device
  pass covers the thumb.
- **Replacing the hand-rolled two-column grid with a lazy grid.** The host screen already scrolls, so
  the current rows are correct and cheaper.
- **Removing the backticks from "Tap `Hide from List` to confirm".** They render literally, but the
  Compose twin ships the same literal backticks, and copy is identical across the four apps by
  contract. Change it in all four or not at all.
