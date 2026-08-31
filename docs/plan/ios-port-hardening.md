# iOS port — where to pick up, and what to harden before the remaining screens

Written 2026-08-28, against the stack that finished U0–U2 and the first two U3 screens.

## Where to pick up

Do these in order. The first is a decision, not code, and it blocks the rest.

| # | Do this | Why it comes first | Ends when |
|---|---|---|---|
| 1 | **DONE 2026-08-31 — the pill won.** See §1. | The only open question that could invalidate finished work. | Ruled, built, and `TabView` gone. |
| 2 | **DONE 2026-08-31 — the stack is merged.** | Three PRs deep is the practical limit: this repo squash-merges, so each merge turns the branches above into a `rebase --onto`, not a plain rebase. | `main` carries all three. |
| 3 | **Build the first XCUITest.** See §5. | Every new route is currently asserted only at the resolver. One file now makes each later screen self-verifying; deferring it accumulates fourteen screens of unproven navigation into one pass. | A link launches the app and the resulting screen id is asserted in CI. |
| 4 | **Continue U3** in `ui-work-plan.md`'s order — verifications, then verificationDetails, then the forms and pickers. | Settled order; do not relitigate it. | All sixteen screens exist. |
| 5 | **Close the truncation gap.** See §2. | Only starts biting at U4, when the 38 states land. Doing it sooner spends effort on a problem still readable by eye. | An automated check fails on clipped text. |

**The stack that carried U0–U2 and the first two screens** — #40, #42, #43 — is merged. Each squash
turned the branches above it into a `rebase --onto`, which is the cost the three-deep limit buys.

---

## 1. The nav container — ruled 2026-08-31: the floating pill

`UseSmileIDSampleNavBar` is what the shell renders; `TabView` is gone, and so are the `title` and
`testId` on `UseSmileIDSampleTab` that only its `tabItem` used. The pill sits inside the navigation
host, so a push covers it — the same visibility rule the Compose twin writes as `selectedTab != null`.

**The ruling turned on the token button.** The pill is three tabs *plus a detached token affordance*.
`TabView` cannot host that, so choosing it would have orphaned the app's token entry point rather
than deleting one component. Behaviour stays platform-native because the per-tab `NavigationView`
stacks below are untouched.

**Three things building it taught, all worth copying to a port rather than rediscovering:**

- **Only the showing tab can be mounted.** Keeping all three alive and hiding two is the obvious
  translation of what `TabView` did for free, and it does not work: a hidden stack still answers an
  id query. `accessibilityHidden` does not reach through the navigation host, and applying it inside
  still leaves a leaf that carries its own identifier; adding `accessibilityElement(children:
  .ignore)` then puts the UIKit-backed `UISwitch`es back as unlabelled elements. Mounting one tab is
  the only reliable answer. The path survives because it lives in the router; a scroll offset does not.
- **The bottom inset has to be applied inside the navigation host.** `safeAreaInset` on the view
  *wrapping* `NavigationView` never reaches the hosted scroll view. Content passing under the bar
  while scrolling is correct and not the symptom — check the last row at rest. It is applied at the
  root level only, deliberately: a push covers the bar, so a pushed screen has nothing to inset for.
- **State that must survive a tab switch cannot live in the screen.** One tab is mounted, so a
  screen's `@State` and `@FocusState` are torn down with it. Today's screens are read-only and it
  does not show, but the forms and pickers in U3's step 4 would lose part-entered input. Lift that
  state to the app state, where the paths already live, rather than meeting it screen by screen.

**How it got here, so it does not recur:** the component was built because it was on U2's list,
without checking what would consume it. Run the app on a simulator at the end of each slice.

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
