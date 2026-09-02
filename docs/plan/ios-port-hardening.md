# iOS port — where to pick up, and what to harden before the remaining screens

Written 2026-08-28, against the stack that finished U0–U2 and the first two U3 screens.

## Where to pick up

Do these in order. The first is a decision, not code, and it blocks the rest.

| # | Do this | Why it comes first | Ends when |
|---|---|---|---|
| 1 | **DONE 2026-08-31 — the pill won.** See §1. | The only open question that could invalidate finished work. | Ruled, built, and `TabView` gone. |
| 2 | **DONE 2026-08-31 — the stack is merged.** | Three PRs deep is the practical limit: this repo squash-merges, so each merge turns the branches above into a `rebase --onto`, not a plain rebase. | `main` carries all three. |
| 3 | **DONE 2026-09-01 — the harness runs in CI.** See §5. | Every new route was asserted only at the resolver. | `UseSmileIDSampleUITests` runs inside `verify.sh`; a link launches the app and the screen id is asserted. |
| 4 | **Continue U3** in `ui-work-plan.md`'s order — verificationDetails and userDetails are built (2026-09-01); next kycIdForm and the two picker sheets. | Settled order; do not relitigate it. | All sixteen screens exist. |
| 5 | **DONE 2026-09-01 — a growth check, not the one §2 proposed.** See §2. | Would have started biting at U4, when the 38 states land. | A component that stops growing at the largest content size fails the build. |

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

## 2. The truncation gap — closed 2026-09-01, by a different route than this section proposed

**What shipped:** `assertSurvivesMaxDynamicType` asserts a component gets *taller* at the largest
content size, with a `growsWithContentSize: false` flag for the ones whose height is fixed. Growth is
the only truncation signal SwiftUI leaves, and the shape is the one §3 already uses: declare the
exceptions, and fail when the set changes — a stale flag fails too. Proven by capping a component and
watching the assertion fire, rather than assumed from a green run.

**Both options this section proposed were tried and neither works.** Worth recording so a port does
not spend the same afternoon:

- *Bounded against unbounded height.* A view that caps its own height reports the cap as its ideal
  size, so measuring it against itself returns the same number whether its text fits or is clipped.
  Measured: a `Text` needing 807pt inside a 40pt frame reports 40pt.
- *The bottom row of the render is background.* The golden host pads the component and paints the
  background behind it, so that row is background whatever the component did.

**Reading a baseline caught what neither assertion could.** On the details screen the app bar title
ellipsised at AX5 while the component's own baseline wrapped it in full: above a scroll view in a
fixed-height screen the wrapping title is the flexible child, so the stack compresses it.
`UseSmileIDSampleTopAppBar` now takes its ideal height, which changed no existing baseline. Two
things a port should take from it: the width check passes and growth is declared `false` on a
screen, so neither fires; and a screen's AX baseline is only readable if its pinned viewport is tall
enough to show the rows.

**What it catches and what it does not.** It catches a component that *stops* growing — the
regression case, where a fixed frame or a line limit arrives and text begins clipping silently. It
does not catch one that was always capped; that one is declared instead, which makes the cap visible
and reviewable rather than invisible. Two carry the flag today and neither is a defect: a screen
scrolls, so the harness pins its frame and the content grows inside it.

## 3. A test id can be declared and never applied — CLOSED 2026-08-28

`UseSmileIDSampleTestIdUsageTest` scans `Sources/` for each declared id's symbol and asserts the
unused set matches a listed inventory exactly — so an id that stops being applied fails, and a stale
entry fails too.

Kept here because the inventory is a live to-do list: **eight ids are not yet on a view.**
`productCardPrefix`, `settingNavPrefix`, `detailFieldPrefix` and `detailCopyPrefix` are expected —
they exist so the spec check has an anchor, and the real ids are built from them. The other four —
`jobRow`, `jobRowStatus`, `filterCount`, `selectionCheckbox` — wait on the verifications screen,
which is still a seat. Delete them from the list as it lands.

Writing the test corrected the estimate: six unapplied, not the twelve assumed.

**`sample_details_refresh` is deliberately not declared yet** — pull-to-refresh needs the job store
and the status source, and an id waiting on a mechanism is not the same kind of debt as one waiting
on a caller.

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

## 5. Deep-link delivery — PROVEN 2026-09-01

`UseSmileIDSampleUITests` launches the app, opens a link and asserts the screen id. Delivery uses
`XCUISystem.open`, which is why that target alone has a 16.4 floor; `simctl openurl` raises the
system confirmation the test takes when a runtime still shows one. The suite also holds the
accessibility-isolation assertion the nav change was restructured for, so that fix cannot silently
regress. It runs inside `verify.sh`, so the local contract and the gate stay identical.

**One trap it cost a run to find.** A stale build under an old bundle id (`com.usesmileid.sampleapps.ios`,
from before the rename to `com.usesmileid.sample.ios`) declared the *same* URL scheme and the same
display name, so the system handed the link to the wrong app and every link test failed as if
routing were broken. The helper now asserts the app reached the foreground, which says which half
broke. Uninstall the stale build on any simulator that has both.

## 6. The icon generator will meet a path command it does not support

`scripts/generate_ios_icons.py` supports M, L, H, V, C, Q, T and Z, absolute and relative — exactly
what today's 35 icons use. Anything else fails the run loudly, which is deliberate.

Enhanced KYC is still owed an icon and the nav icons may yet be adopted, so a mark exported with an
arc (`A`) or smooth curve (`S`) will stop the build. That is the right failure. Whoever hits it
should add the command to `emit_path`, **not** loosen the check — a skipped subpath is a mark that
renders wrong rather than not at all.

---

## 7. A deep link into a two-level route stops at its first level

**Now:** `usesmileid-sample-ios://profiles/{id}` seats `profileConfig` under `profiles`. The router
assigns the whole path and its unit tests prove it, but the app lands on `profiles` with a back
button and the second level never arrives.

**It predates the nav container change** — reproduced on `main`'s `TabView` shell too, so mounting
one tab at a time did not cause it. Two nested `NavigationLink(isActive:)` levels cannot both
activate in one update on the iOS 15 idiom, and gating the deeper level on its parent's `onAppear`
does not help.

**Recorded rather than fixed** because the fix is a change of navigation mechanism, not a nudge, and
the iOS 15 floor rules out `NavigationStack`. Nothing depends on it yet: `profiles` and
`profileConfig` are both seats, and the other multi-level routes are pickers U3 has not built. Fix
it alongside the profiles screens, when there is something to land on.
`testALinkOpensATwoLevelRouteInAnotherTab` holds the repro as an expected failure, so it fails
loudly the moment the defect goes.

**It is only the deep link.** Pushing the levels one at a time chains fine — products → the consent
form → the ID form is asserted end to end by `testTheConsentFormGatesContinueThenPushesTheIdForm`,
so the flow's forward wiring is not blocked by this; only a link naming both levels at once is.

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
