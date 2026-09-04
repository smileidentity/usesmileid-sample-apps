# iOS port — where to pick up, and what to harden before the remaining screens

Written 2026-08-28, against the stack that finished U0–U2 and the first two U3 screens.

## Where to pick up

Do these in order. The first is a decision, not code, and it blocks the rest.

| # | Do this | Why it comes first | Ends when |
|---|---|---|---|
| 1 | **DONE 2026-08-31 — the pill won.** See §1. | The only open question that could invalidate finished work. | Ruled, built, and `TabView` gone. |
| 2 | **DONE 2026-08-31 — the stack is merged.** | Three PRs deep is the practical limit: this repo squash-merges, so each merge turns the branches above into a `rebase --onto`, not a plain rebase. | `main` carries all three. |
| 3 | **DONE 2026-09-01 — the harness runs in CI.** See §5. | Every new route was asserted only at the resolver. | `UseSmileIDSampleUITests` runs inside `verify.sh`; a link launches the app and the screen id is asserted. |
| 4 | **Continue U3** in `ui-work-plan.md`'s order — verificationDetails, userDetails, kycIdForm and both picker sheets (2026-09-01), then profiles, profileConfig and both profile sheets (2026-09-02), then scanToken with the session model behind it (2026-09-02, §8 and §9) are built; next the result card and the automation affordances. | Settled order; do not relitigate it. | All sixteen screens exist. |
| 5 | **DONE 2026-09-01 — a growth check, not the one §2 proposed.** See §2. | Would have started biting at U4, when the 38 states land. | A component that stops growing at the largest content size fails the build. |

**The stack that carried U0–U2 and the first two screens** — #40, #42, #43 — is merged. Each squash
turned the branches above it into a `rebase --onto`, which is the cost the three-deep limit buys.

**Owed before any TestFlight or App Store build — no fixture profiles by default.** Android's first Play
release shipped the design's three profiles because `UseSmileIDSampleProfiles` defaulted to them, and the
active one's organisation is what the SDK's consent screen shows as the partner. iOS's
`UseSmileIDSampleProfiles.swift` carries the same default and `UseSmileIDSampleNavigationUITests` asserts
on the names. Mirror Android: one empty `Default profile` by default, the three behind the `seedProfiles`
launch argument (`spec/launch-args.json`, the ninth name), the UI tests launching with it, and a unit test
on the plain default. It lands after the launch-arguments PR, which owns the parser and its spec test.

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

**The profiles baselines caught two more (2026-09-02).** At AX5 the toast's fixed-size action landed
on top of its wrapping message, and a profile row's organisation broke mid-word beside its avatar.
Both now stack at accessibility sizes, the switch `KeyValueEditRow` already makes; the settings
summary's AX baseline moved with the row. Neither assertion could see either — only the picture did.

**What it catches and what it does not.** It catches a component that *stops* growing — the
regression case, where a fixed frame or a line limit arrives and text begins clipping silently. It
does not catch one that was always capped; that one is declared instead, which makes the cap visible
and reviewable rather than invisible. Two carry the flag today and neither is a defect: a screen
scrolls, so the harness pins its frame and the content grows inside it.

## 3. A test id can be declared and never applied — CLOSED 2026-08-28

`UseSmileIDSampleTestIdUsageTest` scans `Sources/` for each declared id's symbol and asserts the
unused set matches a listed inventory exactly — so an id that stops being applied fails, and a stale
entry fails too.

Kept here because the inventory is a live to-do list: **thirteen ids are not yet on a view.** Nine
are prefixes (`productCardPrefix` through `profileConfigFieldPrefix`) and expected — they exist so
the spec check has an anchor, and the real ids are built from them. The other four — `jobRow`,
`jobRowStatus`, `filterCount`, `selectionCheckbox` — wait on the verifications screen, which is
still a seat. Delete them from the list as it lands.

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

## 5b. A filter ported literally opens empty — 2026-09-01

`localizedCaseInsensitiveContains("")` answers **false**; Kotlin's `contains("")` answers **true**.
Both pickers filter their list on the search field, so the literal port listed nothing until
something was typed. No assertion could have caught it — the sheet rendered its own empty state,
which reads as correct — and it was found by looking at the recorded baseline.

The filter now lives on the model (`UseSmileIDSampleCountry.matching(_:)`,
`UseSmileIDSampleIdType.of(_:matching:)`) where a unit test pins it. Every port doing a
string-contains against a possibly-empty query needs the same check.

## 6. The icon generator will meet a path command it does not support

`scripts/generate_ios_icons.py` supports M, L, H, V, C, Q, T and Z, absolute and relative — exactly
what today's 35 icons use. Anything else fails the run loudly, which is deliberate.

Enhanced KYC is still owed an icon and the nav icons may yet be adopted, so a mark exported with an
arc (`A`) or smooth curve (`S`) will stop the build. That is the right failure. Whoever hits it
should add the command to `emit_path`, **not** loosen the check — a skipped subpath is a mark that
renders wrong rather than not at all.

---

## 7. A deep link into a two-level route stops at its first level — FIXED 2026-09-02

**What it was:** `usesmileid-sample-ios://profiles/{id}` seats `profileConfig` under `profiles`. The
router assigned the whole path and its unit tests proved it, but the app landed on `profiles` and the
second level never arrived. It predated the nav container change and reproduced with a real screen on
the second level, which is when it was fixed.

**Why:** two nested `NavigationLink(isActive:)` levels cannot both activate in one update on the iOS
15 idiom — UIKit drops a push made while another transition is in flight, and the deeper link's push
lands exactly there. That is also why gating the deeper level on its parent's `onAppear` did nothing,
and it was re-proven here before the fix: `onAppear` fires *inside* the first push's transition, so
the push it triggers is the one UIKit drops, and the chain then has nothing left to retry.

**The fix stays on the idiom.** The router keeps the whole path but tracks how many levels have
*landed*; a link or a restore lands one, and each level lands the next when its transition has
*ended*. The signal for that is UIKit's `viewDidAppear`, which SwiftUI does not expose, so a zero-size
`UIViewControllerRepresentable` (`UseSmileIDSampleTransitionEnd`) sits behind every level and reports
it. Pushes a link makes run in a transaction with animations disabled; a tap still pushes one level,
animated. Three details a port should copy: a link lands from the deepest level it shares with what
is already showing, not from the root; a level carries its route as its identity, so a link that
swaps what a level shows re-appears it and the chain continues; and a tab coming on screen lands its
stack from the root again, because one tab is mounted at a time and a remount that activates two
links in one update is the same defect by another door. `testALinkOpensATwoLevelRouteInAnotherTab`
now asserts both levels and that Back lands on the first; three siblings cover the same link from
inside its own tab, over a level that is already showing or showing something else, and a two-deep
stack coming back with its tab.

**It was only the deep link.** Pushing the levels one at a time chained fine before — products → the
consent form → the ID form is asserted end to end by `testTheConsentFormGatesContinueThenPushesTheIdForm`.

## 8. Where the token lives — ruled 2026-09-02: the Keychain, ad-hoc signed

`token-session-android.md` §9 named the Keychain as the obvious iOS home and called the asymmetry with
Android's unencrypted DataStore fine. Ruled so, with one cost the ruling had to pay first:

- **An unsigned process has no keychain.** Every target here built with `CODE_SIGNING_ALLOWED: NO`, and
  under that `SecItemAdd` answers `-34018` (missing entitlement) on the simulator — measured, hosted by
  the app, before deciding. The targets now sign ad hoc (`CODE_SIGN_IDENTITY: "-"`), which needs no
  certificate or team and makes the same call answer `0`. The two test bundles generate an Info.plist
  because signing demands one. Nothing else in the lane changed.
- **The record is one Keychain item**, `UseSmileIDSampleStore` in `Data/`, holding the Android store's
  three keys: the raw token, the ended handle and the ended deadline. One item, one write, so the live
  half and the ended marker can never come from different writes — the invariant the retirement tests
  pin against the same synthetic token Android retires. The token is the whole record; the handle,
  deadline and bindings decode from it on every read, and a stored token that no longer decodes reads
  as no session.
- **What the Keychain buys and costs.** Encrypted at rest and never backed up
  (`WhenUnlockedThisDeviceOnly`); it survives the process deaths the camera causes, which is the property
  Android chose DataStore for. The one asymmetry: it also survives an uninstall, which the deadline
  bounds and sign-out clears.
- **Where each half is proven.** The record's semantics run in the SPM test target against an
  in-memory storage. The Keychain adapter itself is proven in the app-hosted `UseSmileIDSampleTests`,
  because an unhosted test bundle has no application identity and the adapter cannot be exercised there.
- **Settings are still not persisted on iOS.** The store's name and folder mirror Android's so that
  work lands in the same file when it comes; it is not part of this slice.

## 9. The scan screen — built 2026-09-02, and the three holes left open on purpose

The screen, its sheet, status pill and glyph mirror the Compose files name for name; the route, the
deep link (`usesmileid-sample-ios://token/scan`) and the five ids landed with it. The decode rules
are pinned by the same fixtures Android pins, in the same three test files. What the shell adds, and
what it deliberately does not:

- **Simulate is the device path, never Paste.** It mints the same unsigned fixture Android's minter
  does — span, environment, bindings — and the host links only what the real decoder reads back from
  it; a fixture the decoder refuses leaves the tap doing nothing rather than fabricating a session.
  The UI tests drive Simulate through link, countdown tick, the Expired span's retirement to the
  banner, relinking over it, a relaunch, and sign-out. What no test proves: a server accepting the
  token, and the QR itself.
- **The clock lives in the app state.** One `now`, ticking once a second while a session is live and
  stopping at the deadline, where the token is retired and only the handle and deadline stay. The ring,
  the card and the countdown all read it; nothing in a screen owns a timer. A cold start after expiry
  retires at once.
- **The QR reader is `AVCaptureMetadataOutput`, no dependency.** Its session preset is pinned to
  1920x1080 — the size Android's analyser needed once the dense token QR failed at 640x480 — and the
  session stops when the view is dismantled, so the SDK is never handed a camera the host still holds.
  Unproven here: the simulator has no camera, so the viewfinder is absent in every golden and every
  simulator run and the screen keeps the glyph, exactly as the Compose screen does with a null
  viewfinder. The reader has only been compiled, not pointed at a code.
- **`redirected` has no caller.** `UseSmileIDSampleScanReason.sessionEnded` exists, the shared UI
  owns its sentence, and the state is goldened — but `.sdkFlow` is a seat, there is no preflight gate,
  and the host passes no reason. The gate is the flow slice's; building it to give the state a caller
  would have been the wrong order.
- **The verifications screen is still a seat**, so `jobRow`, `jobRowStatus`, `filterCount` and
  `selectionCheckbox` stay in the unapplied inventory; `tokenEnvironmentPrefix` joins the prefixes.
- **Sign-out clears the session only.** Android also clears the forms and lands on Products; those
  belong with the settings slice and are not pretended here.

**Two things reading the goldens caught.** In a fixed-height screen the sheet was proposed a share of
the remaining height and its texts truncated at AX5 — it now takes its ideal height, the rule the app
bar already follows. And the Paste action beside the field broke the placeholder mid-word at AX5, so
it moves below the field at accessibility sizes, the switch the edit row already makes. One thing they
show that is not this slice's: the app bar title breaks mid-word at AX5 wherever the bar carries a
trailing action ("Sca / n / tok / en" here, "Veri / fica / tion" on the details screen, both
pre-existing). Fixing it means the shared bar and every screen's AX baseline, so it is a follow-up.

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
