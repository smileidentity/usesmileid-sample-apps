# iOS device verification — the lane the port owes before it is finished

**Status 2026-09-10: half done.** §2.1 and §2.2 are closed — every Android flow has an iOS
counterpart, and the opener and exactly-once assertions landed with the flow host. §2.3 and §2.4
are untouched. Written 2026-09-08 the day the verifications slice landed, when the suite was 45
XCUITest tests; it is 62 now.

**The problem in one line:** iOS has the runner the contract asks for and none of the scaffolding
around it, so a green iOS suite proves the app works on one simulator, launched one way, by one
lane nobody records.

**What that costs today, measured rather than asserted:** the workspace ledger holds 199 judged runs
and **not one of them is iOS**, so its 61% green describes Android. Nothing can say what the iOS
lane's pass rate is, or which of its reds were environmental. That is §2.4, and it is why §2.4 comes
before the phone.

`AGENTS.md` §Testing already decides the stack — Maestro on Android, XCUITest on iOS, assertions on
`si_*` / `sample_*` ids, never on screenshots or coordinates. Nothing here re-opens that. This is
the list of what is missing underneath it.

---

## 1. What exists today

`ios/verify.sh` runs these suites on the pinned iPhone 17 Pro simulator, and per-PR CI runs the same
script rather than repeating its steps:

| Suite | Covers |
|---|---|
| `UseSmileIDSampleNavigationUITests` (26) | the shell, both link levels, the pill, profiles, the token session, the scenario drawer, the result card |
| `UseSmileIDSampleVerificationsUITests` (12) | select mode, both removal paths, the undo, the counts, the emptied-filter fallback, the bottom inset, both refresh paths |
| `UseSmileIDSampleFlowUITests` (10) | the opener, deny, back-out, both presentations, the gate's three exits, a rapid re-entry, and exactly-one-result after each |
| `UseSmileIDSampleLaunchArgumentUITests` (9) | every argument that acts, plus the release-build probes gate |
| `UseSmileIDSampleSettingsUITests` (5) | the shipped defaults, the capture mutex from the UI, a flip surviving a relaunch, a seeded switch persisting nothing, and sign-out clearing the forms |

Counts are hand-maintained and were wrong within two days of being written, so read them as of
2026-09-10 and re-count rather than trust them: `grep -cE '^\s*func test' ios/App/UITests/*.swift`.

What that suite can already do, so a new check does not need a new mechanism: launch arguments as
preconditions (`-seedJobs`, `-seedProfiles`, `-probes`, `-scenario`), a deep link to any route in
`spec/routes.json`, id assertions from `spec/test-ids.json`, `press(forDuration:thenDragTo:)` for a
gesture, a frame comparison for a layout rule (the last row against the floating bar), and
`waitForNonExistence` for the negative half of a claim.

What it cannot do: run on a phone, meet a permission prompt, survive a rotation, or say which build
it verified.

## 2. The gaps, in the order worth closing them

### 2.1 Flow-set parity with the Android suite

The Android flows are the contract to mirror, screen for screen. **Closed 2026-09-10: every row has
a counterpart.** The table stays because the per-flow mapping is the useful artefact, not the tick —
it is what a Flutter or Expo port reads to know which of its own flows it still owes:

| `android/maestro/` | iOS counterpart | State |
|---|---|---|
| `shell-navigation.yaml` | `NavigationUITests` | covered |
| `deep-links.yaml` | `NavigationUITests` | covered |
| `launch-args.yaml` | `LaunchArgumentUITests` | covered |
| `profiles.yaml` | `NavigationUITests` | covered |
| `token-session.yaml` | `NavigationUITests` | covered, minus the scanned-token flow a camera would need |
| `verifications.yaml`'s refresh steps | `VerificationsUITests` | covered against a fixture row, which needs no network |
| `verifications.yaml` | `VerificationsUITests` | covered |
| `settings.yaml` | `SettingsUITests` | covered 2026-09-10, by preconditions rather than the Android flow's open-and-close walk: the switches persist now, and every launch in the suite passes them at their shipped defaults — `ios-port-hardening.md` §20 |
| `sdk-flow.yaml` | `FlowUITests` | covered on the simulator up to the shutter (2026-09-08): deny, back-out, both presentations, the gate's three exits and a rapid re-entry. A **Success** and the interactive pop out of the flow are not provable here — see §2.3 |

### 2.2 The opener every device flow owes

`AGENTS.md` asks every device flow to open with launch → product list → SDK-mount assertions, so a
packaging failure fails conclusively instead of looking like a UI defect, and to assert exactly one
terminal result after any cancel or deny — including re-entry by rapid taps.

**Both halves landed with the flow host, 2026-09-08.**
`UseSmileIDSampleFlowUITests.testTheOpenerLaunchesToTheProductListAndAProductMountsTheSdk` is the
opener; the exactly-once assertion is on `sample_result_result_count` after a deny, after a back-out
and after a rapid second tap. One caveat to carry: the rapid-tap half is weaker than the Android
flow's, because XCUITest serialises its events, so the second tap lands *after* the push rather than
beside it. That two pushes of the same route keep one level is proven in the router's unit test
instead.

### 2.3 A physical-device lane

Everything above runs on a simulator, which cannot show a camera, a permission prompt, a thermal
throttle or a real orientation change. The lane needs, in this order:

- signing that lets `xcodebuild test -destination 'platform=iOS,id=<udid>'` install on the phone
- the system-alert path: `XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts` on a
  device, `simctl privacy booted grant camera <bundle-id>` as the simulator's precondition
- proof of which build was verified. Version and build number are identical across rebuilds, so a
  stale install passes silently
- a foreground guard. The four sample apps implement the same `sample_*` ids and render the same SDK
  screens, and on iOS a shared URL scheme is last-installed-wins, so a deep link can land in a
  sibling app and satisfy an assertion meant for this one

Two things the flow host added to this list on 2026-09-08:

- **a Success, and with it the store's `add` reaching the list.** Every terminal result the simulator
  can reach is a cancel or a failure; a 202 needs a real Portal token, so the one path that writes a
  row is unproven end to end.
- **the interactive pop out of a running flow.** XCUITest's synthesised drag does not drive
  `UIScreenEdgePanGestureRecognizer` — falsified against a host screen, which did not pop either — so
  the swipe that leaves a flow mid-capture cannot be asserted on this runner at all.

It cannot run on a hosted CI runner, so it is a local lane triggered per PR by hand, or a device
cloud — not part of `ios/verify.sh`.

### 2.4 Recorded runs

An iOS run currently leaves no trace beyond its exit code, so nothing can say what the iOS lane's
pass rate is, which of its reds were environmental, or which finding is still owed a regression
check — all of which the Android lane can answer.

<!-- INTERNAL-ONLY:START reason=machine-local-tooling -->
The machine-local harness at `v12/tools/verify/` already has the pieces: `run.sh` is
runner-agnostic (`run.sh <label> <device> -- xcodebuild test …`) and classifies an infrastructure
red, and `fresh-install.sh` already fingerprints an iOS bundle container for §2.3's install proof.
What is missing is an iOS call site for `run.sh` and an iOS counterpart to `foreground.sh`, which
reads the Android activity manager and has no equivalent. Tracked in that harness's own idea ledger.
<!-- INTERNAL-ONLY:END -->

## 3. What stays out, and why

- **Frame injection and any recorded capture media.** Public flows stop at the shutter; this repo
  goes public and its history survives the flip.
- **Coordinate taps and screenshot diffs inside a flow.** Goldens are their own lane. Driving the app
  by coordinates is how an agent *authors* a check — a 1200px swipe from the centre of the screen
  invoked the home gesture and dismissed the app while this document's own screens were being read,
  which is the argument in one line.
- **A model in the pass/fail path.** Agents author and triage; the committed test replays with no
  model in the loop and reports a real exit code.

## 4. Order — two of the four are done

1. ~~§2.1's two blocked rows, as the screens they wait on land.~~ **Closed**: the last one
   (`settings.yaml`) on 2026-09-10, by preconditions rather than a walk.
2. ~~§2.2 with the flow host, in that change rather than after it.~~ **Closed 2026-09-08**, in that
   change as intended.
3. **§2.4 next**, and it was always meant to be first: it is the cheapest, and until an iOS run is
   recorded every later claim about the lane is unmeasurable.
4. **§2.3 last**, and only once there is something on a phone that a simulator cannot show. Note
   what that now means in practice: the two things §2.3 exists for — a Success, and the interactive
   pop out of a flow — are blocked on something a phone does not fix. `f091` in the workspace ledger
   records a real Portal-minted, consent-bound sandbox token sitting on `si_processing` for four
   minutes with no terminal state and no error, on Android. A device lane will reach the same wall,
   so build it for the permission prompt, the rotation and the install proof, and do not expect it
   to deliver the Success by itself.
