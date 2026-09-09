# iOS port — where to pick up, and what to harden before the remaining screens

Written 2026-08-28, against the stack that finished U0–U2 and the first two U3 screens.

## Where to pick up

Do these in order. The first is a decision, not code, and it blocks the rest.

| # | Do this | Why it comes first | Ends when |
|---|---|---|---|
| 1 | **DONE 2026-08-31 — the pill won.** See §1. | The only open question that could invalidate finished work. | Ruled, built, and `TabView` gone. |
| 2 | **DONE 2026-08-31 — the stack is merged.** | Three PRs deep is the practical limit: this repo squash-merges, so each merge turns the branches above into a `rebase --onto`, not a plain rebase. | `main` carries all three. |
| 3 | **DONE 2026-09-01 — the harness runs in CI.** See §5. | Every new route was asserted only at the resolver. | `UseSmileIDSampleUITests` runs inside `verify.sh`; a link launches the app and the screen id is asserted. |
| 4 | **Continue U3** in `ui-work-plan.md`'s order — verificationDetails, userDetails, kycIdForm and both picker sheets (2026-09-01), then profiles, profileConfig and both profile sheets (2026-09-02), then scanToken with the session model behind it (2026-09-02, §8 and §9), then the result card, the scenario drawer and the launch arguments that seed the card (2026-09-03, §10) are built. **The job store, the verifications list and the status refresh are built (2026-09-08, §12, §13 and §15)**, so `seedJobs` acts, the four waiting ids are applied and a processing row can be re-checked. **The flow host is built (2026-09-08, §16)**: the SDK is hosted in both presentations, the four recorders and `redirected` have their callers, `jobStore.add` has one too, and the launch-integrity opener runs. One screen remains — licenses, which waits on the generated notices asset, not the store. `autostart` and `holdCamera` follow the host in the same slice. | Settled order; do not relitigate it. | All sixteen screens exist. |
| 5 | **DONE 2026-09-01 — a growth check, not the one §2 proposed.** See §2. | Would have started biting at U4, when the 38 states land. | A component that stops growing at the largest content size fails the build. |

**The stack that carried U0–U2 and the first two screens** — #40, #42, #43 — is merged. Each squash
turned the branches above it into a `rebase --onto`, which is the cost the three-deep limit buys.

~~**Owed before any TestFlight or App Store build — no fixture profiles by default.**~~ **Done
2026-09-04 with the launch-arguments PR — see §11.** One empty `Default profile` by default, the design's
three behind `seedProfiles`, the UI suite launching with it, the plain default unit-tested and goldened.

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
- ~~**`redirected` has no caller.**~~ **Given one with the flow host — see §16.** The gate's
  session exit sends the run to the scanner with a `UseSmileIDSampleRunIntent`, the screen says why it
  opened, and relinking a *different* live token re-enters the run; a device test drives both halves.
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

## 10. The result card and the drawer — built 2026-09-03, with no producer yet

The card, its compact line, the five-state model behind them and the drawer sheet mirror the Compose
files name for name; the twelve `sample_result_*` ids and the drawer's three landed with them, and the
scenario and result models are pinned to `spec/scenarios.json` and `spec/result-card.schema.json` by
the same tests Android runs. What is decided here, and what is deliberately left with no caller:

- **Where the run's result lives — ruled, then narrowed.** `UseSmileIDSampleFlowResult` is a value on
  the app state and nowhere else, so it survives rotation and a tab switch and ends with the process.
  It was first mirrored into `@SceneStorage` as the `rememberSaveable` analogue, and CI falsified the
  assumption that carried: a run of the launch-argument suite restored the previous test's run over a
  launch that named `-scenario badRefresh`, so a scene restore across an XCUITest relaunch is
  intermittent, not absent, and a restored run overrides the one the launch asked for. What the mirror
  bought was small here — a scene the system killed took the hosted flow with it, so the restored
  counts could finish nothing — and what it cost was a card that could report a run nobody started.
  The app never writes the run to scene storage, UserDefaults, the Keychain or disk: every launch is
  a fresh run. `saved` and `init(saved:)` keep the Compose `Saver`'s shape, unit-tested and with no
  caller, like the recorders. The card's expanded/collapsed toggle is app state too, because one tab
  is mounted at a time.
- ~~**The recorders have no caller.**~~ **All four have one with the flow host — see §16.**
  `startFlow` runs when the gate passes, `recordBlocked` when it refuses, `recordResultCallback` on
  every delivery and `recordRefreshCallback` from the SDK's own token-refresh hook. The paragraph
  below is kept because it is the reasoning that put them there first. The same treatment `redirected` got in §9 — building a flow host to give them a
  caller would have been the wrong order. The compact line on products therefore never shows outside
  its golden; like the Compose twin, it is not gated by `probes`, only by a run being in flight.
- **Twelve ids inside one container.** The card carries its own id and eleven field ids, so it needs
  `.accessibilityElement(children: .contain)` immediately before its identifier — the lesson
  `sample_session_countdown` paid for — and `testTheResultCardPublishesEveryFieldAsText` proves every
  one is queryable on the simulator and reads its value as text: counters as `"0"`, an absent value as
  the em dash. It is queryable, not visible: a fixed-height screen proposed the card a share of the
  remaining height, so it takes its ideal height, the rule the app bar and the scan sheet follow.
- **The drawer is a debug sheet.** Settings shows its row under `#if DEBUG` only, the Compose twin's
  `BuildConfig.DEBUG`; the deep link `usesmileid-sample-ios://debug/scenarios` is not gated, because
  it is how every device flow reaches it, release included. A row selects without closing the sheet,
  and the selection is the card's at once because both read the app state. The sheet has no dismiss
  control, like the Compose drawer; the platform's swipe closes it.
- **`sdkVersion` is nil on iOS as well.** Checked against the published 12.0.2 package rather than
  the source: the `UseSmileID.swiftinterface` the XCFramework ships declares no public version symbol,
  `UseSmileIDMetadataFactory.sdkVersion` is internal, and the framework's own `Info.plist` carries
  `CFBundleShortVersionString` 1.0. So the field renders the em dash a flow asserts on, never the pin
  in `Package.swift` — the same ask the schema records against Android stands here.

**The launch arguments — built 2026-09-03, the card's one live producer.** All nine names in
`spec/launch-args.json` are read from the argument domain of `UserDefaults.standard` — where
`app.launchArguments = ["-scenario", "expiredToken"]` lands and nothing else does, so a value a later
feature persists under one of these plain names can never seed a run or reveal the card on a release
build. The parser lives in the shell because the mechanism does, and its spec tests mirror Android's.
The spelling with no arguments builds the spec's defaults and reads nothing; the launch is read by
naming its source, `init(reading:)`, because the two were once one overload apart and the shell picked
the wrong one. Which ones act:

- **Applied:** `scenario`, `theme` and `route` seed the run once, and the drawer's choice wins after
  that (`testTheDrawerWinsOverTheArgumentAndARelaunchIsAFreshRun` proves both halves, and that a
  relaunch with other arguments is a fresh run). `probes` reveals the card on a release build.
  `seedProfiles` swaps the one empty starter profile for the design's three, per launch, because
  profiles are in memory; two UI tests hold both halves on the device.
  `appLocale` is applied as `.environment(\.locale)` at the root, and that is all it reaches: SwiftUI
  formatting in the shell's own views, of which today there is none — the shell's copy is hard-coded
  English, and the SDK's strings resolve through its bundle, which follows `-AppleLanguages`, the
  platform's own launch argument. A flow that needs another language passes both.
- ~~**Read and dropped:** `autostart` and `holdCamera` wait on the flow host.~~ **Both act as of
  2026-09-08, with the host — see §16.** `autostart` opens the flow route once per launch, after the
  restore so the argument wins over what the last scene left; with empty forms the gate then
  redirects to the form, which is the gate working rather than the argument failing. `holdCamera`
  binds the product's own lens alongside the run and counts frames, because a probe that never
  acquired the camera passes vacuously — and on a simulator that is exactly what happens, so the
  contention itself is a phone-lane claim and the flow only proves the hold is inert, not harmful. `seedJobs` joined the applied list on 2026-09-08 — see §12.
- **`probes` rides the launch, not the link.** Android also reads it off the launching URI because a
  deep link there carries no extras; on iOS the argument reaches a running app, which every link is
  delivered to, so the sheet resolver already strips `?probes=` and nothing more is needed.

**The gate is proven on the release build, both halves.** `verify.sh` gained a last step: two UI tests
run against the Release configuration — without `-probes` the card must be absent, with it present.
The release step names its configuration to the runner, and there the test also asserts the Settings
DEBUG row is gone; anywhere else the row says which build this is, since it is compiled out of release
on every platform, so the same test asserts "always on" in the debug suite and "hidden" in the release
lane. Both halves caught a real defect before the PR opened: the shell's default argument built the
empty defaults instead of reading UserDefaults, so nothing seeded and `-probes` never reached a release
build. Falsified deliberately as well, by forcing `showProbes` true on release (the hide half fails)
and false on debug (both fail). Cost: the release app is already built by the step before, so the
added time is the runner.

## 11. No fixture profiles by default — done 2026-09-04, with the launch arguments

- ~~**Owed before any TestFlight or App Store build — no fixture profiles by default.**~~ **Done with
  the launch-arguments PR.** `UseSmileIDSampleProfiles` defaulted to UpTech Finance, Kazi Microlending
  and PesaLink, the same default Android's first Play release shipped, and the active one's
  organisation is what the SDK's consent screen will show as the partner. A plain launch now carries
  one empty `Default profile` whose row reads "No user details yet" until details are saved, at which
  point the first and last name become its person; the three sit behind `seedProfiles`, the ninth
  name in `spec/launch-args.json`, and the navigation suite launches with it wherever it asserts on a
  fixture. Two launch-argument UI tests hold the split on the device, the unit tests hold the plain
  default, the launch choice and the naming rule, and `profiles_first_run` is the starter's golden.
  The store's `forLaunch` takes the Bool rather than the arguments type, which lives in the shell:
  `SampleUI` cannot import it, and Android's store could only because its arguments live in `sample-ui`.

## 12. The job store — built 2026-09-08, on a file rather than a database

Android's rows live in Room, and Room is what the store's shape is written against: insert-ignore, a
delete that reports what it took, and one atomic status update. iOS has no equivalent that costs no
dependency — Core Data would add a model file to review and hand-rolled SQLite would add more code
than the store itself — so the rows are one JSON document in Application Support, replaced
atomically, behind the same storage protocol the session store uses (the real thing in an app, memory
in a test). The whole file is one document, which is what makes the decoding rule below matter.

- **An `actor`, and that replaces most of Android's concurrency machinery.** Android needs a `Mutex`
  for its in-flight guard, `NonCancellable` around the guard's release, and a process-lifetime write
  scope so a write outlives the composition that launched it. Actor isolation gives the first two for
  free, and the write scope is an unstructured `Task`: `.task` is cancelled with the view, a plain
  `Task` is not. That is the rule the store's own doc comment states, and a test proves it by
  cancelling the task that launched a write and asserting the row still landed.
- **A property's default value is not a column default.** Swift's synthesised `Decodable` ignores
  one, so a row written before the three `bound*` flags existed would fail to decode — and because
  the file is one document, one undecodable row is every row. Decoded key by key with
  `decodeIfPresent`, which is what Room's `defaultValue` says on the entity.
- **One deliberate divergence: an unknown id does not spend the undo.** Both stores guard the empty
  set, so an empty removal keeps the previous batch undoable. Android then overwrites the batch with
  whatever a lookup returned, so removing an id it has no row for silently discards the undo; iOS
  guards on what the removal actually took instead. Nothing reachable passes an unknown id — every
  caller's ids come from the list in front of it — so this is hardening, not a fix, and Android can
  follow whenever that file is next open.
- **The rows persist, and that shapes what a device flow can assert.** A seeded launch leaves its
  eleven rows behind for every later launch on the same simulator, which is the point (`seedJobs` is
  a precondition, not a fixture the app carries). A test that needs an empty list therefore has to
  uninstall first, so the plain-empty default is asserted by a unit test on the store rather than by
  a flow.
- ~~**`add` still has no caller.**~~ **Given one with the flow host — see §16**, on the app
  state so the write outlives the flow the result is tearing down. Its only producer is a Success,
  which needs a 202 from the server, so what reaches the list is proven on the phone lane rather than
  the simulator. It is unit-tested, including that a repeated delivery of the same job id cannot
  overwrite the row it already wrote.
- **A refresh was not in the store at first.** It landed with its adapter and its UI, in the slice
  §15 records, rather than sitting unreachable behind a seam nothing filled.

## 13. The verifications list — built 2026-09-08, and the four containers it had to choose

The rows, the chips and the bars were built in U2; this is the screen that consumes them, and every
choice below is one the Compose twin did not have to make.

- **A scroll view, not a `List`, so the swipe is ours.** `List` would have brought
  `swipeActions` — the platform's own gesture — but on the iOS 15 floor a `List`'s backdrop cannot be
  cleared (`scrollContentBackground` is iOS 16, and the appearance-proxy trick does not reach the
  collection view that backs it now), so it would paint the system background where every other
  screen paints `color.background`, off-white and near-black rather than white and black.
  `UseSmileIDSampleSwipeAction` mirrors the Compose file name instead: a trailing reveal of the trash
  glyph and "Hide", committed on the settled translation past the reveal width. Two things it paid
  for — the gesture has to be a `highPriorityGesture`, or the row's own button swallows the drag
  before it is recognised; and it needs a minimum distance, or the vertical drag never reaches the
  scroll view. A device test drags a row and asserts the confirmation, because neither is provable
  off-device.
- **The chips scroll rather than wrap.** `FlowRow` needs iOS 16's `Layout`. A plain row squeezes the
  widest chip into two lines as soon as the type or the language is wider — caught by reading the
  golden, where the harness's own padding makes the viewport 16pt narrower than the phone and
  "Attention" wrapped. A horizontal scroll is what iOS does with a filter row, and it is honest at
  every content size.
- **The list's UI state lives in the app state.** §1's rule, met for the first time by a screen that
  has state worth losing: one tab is mounted, so the filter and the selection would reset on every
  tab switch. `UseSmileIDSampleVerificationsScreenState` is the Compose holder, minus its `Saver` —
  scene restoration is deliberately not used for it, per §10's ruling on restoring what a launch seeded.
- **Select mode swaps the shell's bottom slot.** The pill and the selection bar are the same
  `safeAreaInset`, so the content inset cannot change when one replaces the other, and a device test
  asserts the pill's ids are gone rather than merely covered. The bar leaves with the tab: a link
  that lands on another tab while select mode is on ends it, since the pill is what got replaced.
- **One removal handler, for all three paths.** The swipe, the selection bar and the details screen's
  delete all call the app state's `removeJobs`, which is where the emptied-filter fallback to All
  lives. `spec/screens.json` records the rule and that Android had two copies of it; on iOS the
  details path goes through the same handler too, so a row hidden from the details screen also
  releases the filter.
- **A truncation fix the real screen exposed.** `UseSmileIDSampleJobRow` had no line limit, so
  "Enhanced Document Verification" wrapped where the Compose twin ellipsises at one line — invisible
  until eleven real rows rendered, and visible in the component's own baseline once looked for. One
  line each at the design's scale, unlimited once the badge stacks, and the baselines re-recorded.
- **The id inventory caught nothing, because it was matching loosely.** `sample_filter_chip` read as
  applied for months: the check looked for `.filterChip` anywhere in the sources and the colour token
  `colors.filterChip` matched it. It now looks for the qualified `UseSmileIDSampleTestIds.` form,
  which is how every screen names one.

## 14. The device lane the port still owes — see `ios-device-verification.md`

The suite is 43 XCUITest tests on the pinned simulator, which is the runner the contract asks for and
none of the scaffolding around it: no phone, no permission prompt, no proof of which build was
verified, no record of what the lane's reds were, and two Android flows with no counterpart (settings
waits on persistence, the SDK flow on the host). Written up separately because it outlives the port.

## 15. The status refresh — built 2026-09-08, and what a fixture row can prove

`GET /v3/status/{jobId}` is the partner's own call: the SDK stops at the 202 that creates the job.
The protocol lives in the library, the `URLSession` adapter in the shell, and the store owns the
sequence — read the row, take the environment and the partner FROM the row, ask the source, write
back atomically. What is decided here:

- **The gesture is the platform's, and it is inert on the floor.** `refreshable` drives a
  `ScrollView` only from iOS 16, so on iOS 15 there is no pull affordance at all. Ruled with the
  owner rather than worked around: hand-rolling a second pull gesture would put our thresholds where
  the platform's belong, and reinstating the "Check status" button would diverge from the Compose
  screen. The entry refresh below is what covers the floor, and it is the path that matters — only a
  processing row can change. Unlike the Compose twin the screen holds no `refreshing` flag: SwiftUI
  owns the indicator for as long as the action runs.
- **A fixture row makes the whole path assertable with no network.** A seeded row carries no session,
  so the outcome is `noServerJob` — "Not submitted under a scanned token" — deterministically. Two
  device tests key off that: entering the processing fixture refreshes itself and says why, and
  entering a settled row refreshes nothing until it is pulled. The real HTTP path is exercised only
  by the branch table, which is pure and unit-tested, exactly as on Android.
- **The entry refresh is silent unless something changed.** "Still processing" on every visit is
  noise, so that one outcome is swallowed there and reported when pulled.
- **Cancellation is not an outcome.** `refresh` throws only `CancellationError` — a `URLError`
  cancellation is mapped to it — so leaving the screen mid-request is not reported as a failure. The
  in-flight guard releases in a `defer`, which the actor runs on the way out either way; a test
  cancels a request mid-flight and proves the next one is not skipped.
- **A removal landing mid-request wins.** The only point another caller can reach the actor is the
  suspension the request is waiting on, which is precisely where the test removes the row: the write
  back reports that nothing was there and the row is not resurrected.
- **"Not loaded yet" is not "no row", and the entry refresh is where that bites.** The first cut
  refreshed whenever the rows were still nil, so a cold-start link into a settled row re-checked it
  and toasted on arrival — invisible from the list, because by then the rows are loaded. A device
  test opens the route by link with the app terminated, which is the only way to arrive before the
  store emits, and it was falsified by reinstating the defect and watching it fail.
- **Two ids the screen could not both carry.** The scroll view is the refresh container, so it takes
  `sample_details_refresh`; the screen's own id moved to the enclosing stack, which needs
  `.accessibilityElement(children: .contain)` or it swallows every child's — the lesson
  `sample_session_countdown` paid for, met again.
- **A field you never read can still fail a good response.** The response type first required
  `job_id`, `user_id` and `created_at` alongside the two fields the outcome actually uses, so a 2xx
  omitting any of them decoded to nil and reported a readable status as `HTTP 200`. The three are
  optional now; the Compose twin's `@Serializable` requires all five, so it has the same hole.
- **The id in the path is a deep link's, so it is encoded as one segment.** A stored id is the
  SDK's, but the route that reads one is `verifications/{jobId}`: interpolating it raw let a `/`,
  `?` or `#` change which request the session's token was sent with. Percent-encoded to the
  unreserved set, nil rather than a guess when nothing is left, and unit-tested against four hostile
  ids. Reachability today is nil — a refresh needs a row already in the store — which is exactly why
  it is worth holding before the flow host starts writing rows.
- **OPEN, and a four-app copy question rather than an iOS one:** a non-2xx drops the body, so a 401
  that explains itself reads as a bare code — the one case a partner most needs the server's words.
  Both apps do this; changing one of them would diverge an outcome string the flows key off.
- **`spec/screens.json` was stale and is corrected here** (owner-approved): it named
  `sample_details_check_status`, an id in no test-ids file, and described the button pull-to-refresh
  replaced on Android months ago. Android needed no code change; the entry now describes the gesture,
  the automatic entry refresh, and that the LIST's own pull is a different thing and still deferred.

## 16. The SDK flow host — built 2026-09-08, and the five things the platform decided

`.sdkFlow` is N2 in `navigation-plan.md`, and the riskiest screen in the app. The four launch units
mirror the Compose files name for name — `FlowLaunchSnapshot`, `FlowBuilderConfig`, `FlowPreflight`,
`TokenBindingRules`, plus `FlowJourney` and `SdkFlowScreen` — and the shell now depends on the
`ios-spm` registry at the same 12.0.2 `SampleUI/Package.swift` pins, adding the two Vision analyzer
products the SDK's `UseSmileID` product does not carry. What the platform, rather than the design,
decided:

- **R6 is met by what was already ruled, not by new machinery.** The forms, the scenario, the theme
  and the selected tab are app state; each tab's stack is `@SceneStorage`; the token session is an
  absolute deadline in the Keychain. The one thing R6 asks *of the flow host* — a saveable identity
  key, because Android regenerating one orphans a buffered result — has no iOS counterpart: the run
  is a `@StateObject` whose identity is the route, so a rotation or a re-render keeps it, and there is
  no buffer to orphan. See the next point.
- **`SdkFlowViewModel` has no counterpart, deliberately.** iOS has no per-back-stack-entry
  ViewModel, and `port-patterns.md` §2 puts screen state in a holder beside the screen, so the run
  is a `@StateObject` (`SdkFlowRun`) created once per entry. What Android's `SavedStateHandle` buys
  it — a run that survives process death, and with it §7.2's buffered-result replay — has nothing to
  survive here: the SDK's own `FlowNavigationManager` is a `@StateObject`, so a killed scene takes
  the run with it and there is no buffer left to orphan. §10 had already ruled every launch a fresh
  run for the same reason.
- **The gate runs when the push has landed, not in `onAppear`.** §7's lesson, met from the other
  side: `onAppear` fires *inside* the transition, and every gate exit is a path change. The flow host
  wires the same `UseSmileIDSampleTransitionEnd` representable the router uses. Two costs paid for
  this: the SDK is not mounted under a running animation, and the first frame is the app's own
  background rather than white. One thing it cost to learn — the signal never fired at first, because
  the host hung it on `.background()` of a view that is empty until the gate has run, and SwiftUI
  drops an empty view's background. It is a `ZStack` member now.
- **The two presentations differ by insets, and neither disables a gesture.** `fullscreen` ignores
  the safe area, which is the Compose twin's `contentWindowInsets = WindowInsets(0)`; `shell` leaves
  the flow inside the shell's own safe area, which is the presentation R3 exists to expose. Both are
  pushed levels, so one route table, one deep link and one result transition serve both. The pill is
  already covered by any push, so neither presentation has to hide it. What the simulator can show of
  this is which presentation a run launched in — the card's `route` field — and no more: every SDK
  screen it can reach paints its own background past the safe area anyway, so the difference only
  becomes visible on the capture screen, which is the phone lane's.
- **The result transition is one assignment, keyed on the flow's own tab.** `endFlow` clears the
  products stack — the flow and both pre-flow forms — and opens the landing route, so a repeated
  delivery cannot stack a second screen and nothing can swipe back into capture (R4). Keyed on the
  route rather than the showing tab because a teardown-delivered cancel arrives *after* the level is
  gone: that is what Android guards with its `composed` flag, and on iOS the key is the guard. The
  SDK completes by calling `dismiss()` on the host's context one update later, and the landing screen
  survives it — asserted, because the reverse would have been invisible in code.
- **A form's Continue pushes once.** `push` appends, so two taps stacked two flow levels, which is
  two runs and two terminal results for one journey. Found while writing the opener's rapid-tap half.
  The router's own test is where that is proven; the device test can only show that a tap landing on
  the mounted flow starts nothing, because the runner serialises its events.

**What the gate can and cannot ask the SDK, at 12.0.2.** §7.3 assumed `UseSmileIDFlowBuilder` was
constructible, as it is on Android. It is not: it has no public initialiser, so a host reaches it
only inside `UseSmileIDBuilder`'s closure — after the SDK has mounted. `FlowValidator.shared` is
public and is the same object the builder's `validate()` calls, so the gate goes through it: the
per-payload validators, with the token's bindings subtracted exactly as Android subtracts them, then
`validate(configuration:)` for the structural rules. Two consequences:

- **The per-job-type rules need a token payload the public API cannot pass.** The dispatching
  overload runs them, but with no `tokenPayload` it reports `userDetails is required` for a run whose
  token supplies the details — measured, not assumed. So the gate does not use it, and the structural
  overload plus the per-payload validators are what it runs.
- **One rule is therefore missing, on purpose.** Every job type needs consent, from the screen or
  from the token, and no host's gate checks it: Android's `validateBuilder` covers only an ML
  failure, a network failure and empty screens. So with the Consent screen switch off and no consent
  binding, a run reaches the SDK and comes back as a `Failure` from inside its own render — which
  §7.3 warns is indistinguishable from a real submission failure. iOS briefly stated the rule
  host-side and no longer does: **owner ruling 2026-09-08 is to hold the shared behaviour and fix all
  four together**, so a unilateral improvement does not diverge them. The current behaviour is pinned
  by `testAJourneyWithNoConsentAtAllStillReachesTheSdk`, so the next change to it has to be deliberate.
- **Both theme scenarios go through the SDK's public override, and the spec is why.** This was
  briefly shipped with `clashingHost` doing nothing, on the reasoning that Android swaps the *host's*
  `MaterialTheme` and SwiftUI hands the SDK no host palette to inherit. That reasoning read the wrong
  reference: `spec/scenarios.json` already says the scenario is "applied through the SDK's public
  theme override", forcing "values far from the SDK defaults" — so the mechanism is the same as
  `partnerOverride`'s and only the values differ. iOS does that now: a distant palette, a 24pt button
  radius and Courier, which is a system face and therefore always resolves. **Android is the
  divergence here**, and `spec/` outranks it.
- **`throwingCallback` is not expressible in Swift.** `onResult` is a non-throwing closure and Swift
  has no unchecked exception, so the only way to throw from it is to trap — which is the app dying,
  not the scenario's "must not take the app down". The id stays for spec parity and the card reports
  it; nothing throws.

**Two ids the pinned SDK does not give back.** The consent screen publishes `si_consent_screen`,
`si_allow_button` and `si_deny_button`, all queryable. The instructions screen puts
`si_instructions_screen` on a *container*, which overrides every control's own identifier — the
lesson `sample_session_countdown` paid for, met in the SDK — so the flow's cancel test addresses its
back control by label. The 12.1.0 source has `si_back_button` on it; at 12.0.2 it is unreachable.

**What the simulator proved, and what it could not.** Ten flow tests on the pinned iPhone 17 Pro:
the launch-integrity opener (launch → product list → SDK mounted), both presentations, Deny landing
on the details screen with exactly one result, a back-out cancelling with no row created, the cold
link redirected to the form, the ended-session redirect with its reason and the resume that follows
it, a rapid second tap starting nothing, a rotation keeping the same run, and both launch arguments
acting. Falsified by reinstating two defects: without clearing
the flow's tab the stacked form is caught, and the router test's own unguarded push is asserted.
What the lane cannot show: a **Success**, which needs a 202 and so a real Portal token, and with it
`jobStore.add` putting a row in the list — the path is wired and unit-tested, and the device lane
§2.3 owes is where it gets proven. Also not provable here: the interactive pop out of the flow.
XCUITest's synthesised drag does not drive `UIScreenEdgePanGestureRecognizer` — falsified against a
host screen, which did not pop either — so the swipe belongs to the phone lane, and the cancel path
this suite drives is the SDK's own back on its first screen.

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
