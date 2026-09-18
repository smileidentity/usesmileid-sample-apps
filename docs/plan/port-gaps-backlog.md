# Flutter and Expo port: decisions taken, and what is still owed

The Flutter and Expo ports were built against specs the Android and iOS apps had already settled, so
most of what follows is not port work. It is debt the ports *surfaced* — cases the first two apps
never exercised, and places where the two originals already disagree with each other. Recorded here
so the ports could land without stopping for each one.

Items in §1 are settled and implemented. Items in §2 onward are open, and none of them block a port.

## 1. Decisions taken during the ports

Each of these was a real fork in the road. They were decided rather than deferred, and each is cheap
to reverse if the call was wrong.

| # | Question | Decision | Why |
|---|---|---|---|
| 1 | Flutter cold-start deep link: the `app_links` package, which the navigation plan names, or the platform's own initial route | Platform initial route | It *is* the link, it is available before the first frame, it needs no dependency, and it satisfies the ruling's stated reason — that a Dart-first SDK should not need a native shim. The plan named a package; its rationale described an outcome. |
| 2 | Re-selecting the already-active tab | Pops that tab to its root | Matches iOS. Android does nothing today. Unobservable until a pushed screen exists to re-select from. |
| 3 | Which tab owns the non-root routes (profiles, scanner, flow) | Above the tabs, as Android does | It gives a cold deep link a simpler synthesised back stack than iOS's per-tab assignment. iOS is the outlier and is listed in §2. |
| 4 | Nav-bar clearance when the bar grows with the text scale | **Measure the bar** — reversed; see below | Scaling the token term scaled the one term that is constant and omitted the one that varies, the label's line count. The row sat under the bar at 320dp at default text size. |
| 5 | Where Flutter's preference store lives | Interface in `sample_ui`, plugin-backed implementation in the shell | A plugin is a platform binding and `sample_ui` runs under eight hosts. Android keeps the whole store in its UI module; that does not port. The keys are Android's, so a device carries one set of preferences, not four. |
| 6 | The job row's secondary line | The board's caption | Spec-directed: the spec records this as an open divergence and says a port should take the board while Android follows. Android now owes the change (§2). |
| 7 | The literal backticks in `Tap \`Hide from List\` to confirm` | Removed on Flutter | They render as backticks to a user. Android and iOS carry the same string and now owe the same fix (§2). |
| 8 | Merging a stacked PR set in a squash-only repo | Collapse the remainder into the top PR | Squash rewrites the commit, so the branch above loses ancestry with `main` — producing both a conflict and an inflated diff. The base retarget then dismisses the approval. Re-approval per PR is unavoidable; collapsing spends one instead of four. |

**Decision 4, reversed.** The shell mounts the bar in Scaffold's bottom slot under `extendBody`,
which publishes the laid-out height to the body as bottom padding in the same frame; a screen
reserves that plus `spacingMd`. This matches Android's `onSizeChanged` and iOS's `.safeAreaInset`
rather than diverging from both. Measured on the widget lane: the computed formula left the last row
7dp under the bar at 320dp × 1.0, 15.5dp at 1.75× and 13dp at 2×, and was 99dp short at 3×. The
measured reserve clears the bar at every one of those, 3× included, so the ceiling the old decision
recorded no longer applies.

## 2. Owed by Android and iOS

These are defects in the shipped apps that the ports matched or corrected. Flutter and Expo are
currently the odd ones out in each case, which is a parity divergence until the twins follow.

- **The `Hide from List` backticks** render literally on Android and iOS. One-word fix each, but both
  need golden baselines re-recorded, which is why the ports did not reach into them.
- **The job row's secondary line** should become the board's caption on Android, per the spec's own
  instruction. Changes the row height, so Android's baselines move.
- **The iOS ink calculation.** iOS picks foreground ink with `UIColor.getWhite`, a perceptual grey,
  where Android uses WCAG relative luminance against the 0.179 crossover. 12 of 51 delta colours
  differ, and in every one of them Android chooses white where iOS chooses dark. Android is right.
- **Android's `UseSmileIDSampleStatusBadge` doc comment is stale.** It says only the saturated
  `badge.<role>.*` pairs have landed, but `softBadgeTokens()` wires the soft fills from the deltas and
  that is what the app draws. A one-line fix.
- **Android's id spec test only asserts one direction.** It checks that nothing undeclared exists,
  where Expo asserts the set in both directions. That asymmetry is why the missing-id gap below went
  unnoticed, and it is the more valuable of the two fixes: a one-directional set assertion cannot fail
  on an omission.

- **The top app bar's semantics need checking on Android and iOS.** Flutter's had `header: true` on
  the row's container, which absorbed and reordered its children. With no trailing action — the
  configuration most screens use — the whole bar collapsed into a single node labelled `Back` then
  the title and flagged as a button, so a screen reader announced the title as part of the back
  control and neither could be reached alone. With an action, the title was traversed before the back
  control despite being visually to its right. Fixed on Flutter by moving the flag to the title,
  where it belongs. **No pixel changed and no golden moved**, so the twins' baselines cannot rule this
  out either — it needs a semantics test on each, not a look.

  iOS has a documented sibling trap already: `.accessibilityElement(children: .contain)` must come
  before the id or child ids go unreachable. Same class of defect — a container swallowing its
  children — so iOS is the likelier of the two to carry it.

- **A declared test id can be attached to nothing, and both existing checks pass.** Flutter's
  `sample_scenario_drawer_button` was declared in the app's id list, present in `spec/test-ids.json`,
  and set on no widget. The spec test asserts every declared id exists in the spec — the other
  direction — so it was green, and a golden cannot see an accessibility identifier, so the pictures
  were green too. A Maestro or XCUITest flow keying off the spec would have been the first thing to
  find it, at which point the id looks like a spec error rather than a missing call site.

  The check that finds it is three lines: read the declarations, read every source file in the repo's
  two packages, and assert each declared name appears somewhere other than its own declaration. It has
  to span both packages, because a sheet's id is supplied by whichever host PRESENTS the sheet, and
  only a host sees both halves — scoped to the shared UI package alone it reports four false
  positives. iOS already has this assertion (`TestIdUsageTest` greps every declared id in source);
  Android and Expo do not, and both should.

## 3. Design-system and spec debt

Not port defects — the value is identical across the generated schemes, so there is nothing for a
port to choose.

- **The disabled button keeps its light fill in dark mode.** The design system carries no dark role
  for it. Identical on Flutter and Android.
- **Button height 48 against 52**, and **the card glyph at 21 against 20** — the spec and the design
  disagree and no app has been told which wins.
- **Two shell ids in `spec/test-ids.json` are implemented by no app**: the pair distinguishing a flow
  started full-screen from one started nested. A repo-wide search finds them only in the spec. They
  are either dead entries or an owed feature; no port added them, so no app is the odd one out.
- **`DESIGN_SYSTEM_TOKEN` has never existed as a secret**, so the design-token drift check has never
  actually run in CI. It reports itself skipped, which reads as a pass.

- **`spec/` and the design both understate what the consent form requires.** The spec lists only the
  two name fields as required; Android additionally requires a contact because the SDK rejects a
  submission without one, and the design labels both contact rows optional. All three cannot be right.
  The SDK's constraint is the binding one, so the apps require a contact and the spec and the design
  labels are the things owed a correction. Recorded because a form that passes its own validation and
  then fails inside the SDK is the expensive version of this bug: the failure surfaces far from its
  cause, and the spec would have been cited as evidence the form was correct.

- **`spec/screens.json` describes the licences screen in Android's terms, and two platforms cannot
  follow it.** It specifies two sections — open-source components, and artifacts under Google's own
  terms whose row opens a page — plus a `sample_license_link` id. Those exist because the Android
  release classpath carries ML Kit and Play Integrity, which declare terms-of-service pages rather
  than a licence. Flutter's notices come from the toolchain and contain no such artifact, so there is
  no second section and no link row; the id has no Flutter call site. iOS is the same shape today
  with a single section. The spec should describe the property (a notice whose text cannot travel
  links the page instead) rather than Android's specific section names, and say the second section is
  present only where the platform graph produces one.

## 4. Product questions

These need an owner's answer rather than an engineer's. Neither blocks anything.

- Should a profile's stored defaults seed the job form, and should the "remember these details"
  switch remember anything? Today it persists nothing.
- Should `expo/app` declare `expo-router/testing-library` so a cold deep link's navigation state can
  be asserted? It is a test-only dependency.

- **An edit to the already-active profile cannot be saved, on every platform.** The profile page's
  only write both saves the details and activates the profile, and its CTA reads "Make this profile
  active" — so on the profile that is already active the button is disabled, and any edit made there
  is silently discarded on leaving. Flutter matches the twin here deliberately rather than diverging,
  because the fix is a product decision and not an engineering one: either the screen needs a second,
  always-enabled Save, or the CTA needs to change its label and meaning when the profile is already
  active. Worth deciding before a partner hits it, since the failure is silent.

## 5. Harness and environment notes

Worth having written down before the next port run rather than rediscovered.

- **A Flutter device flow must put launch arguments in the link's query.** Android's mechanism is
  intent extras, so `am start --ez seedJobs true` works there and does nothing on Flutter. Only three
  arguments are read on Flutter so far; the rest are owed.
- **The token session is deliberately absent from Flutter's persistence.** Android's store also holds
  the whole token record and an ended-session marker; both belong with the scanner that produces them.
- **Two CI lanes flake rather than fail.** Flutter's `flutter_tools` Gradle build can fail resolving
  `org.gradle.kotlin.kotlin-dsl`, and the iOS `UseSmileIDSampleVerificationsUITests` slice can exit 74.
  Both passed on re-run with no code change; treat a single red on either as infra until reproduced.
- **A green test can prove nothing.** Three cases this run, all found on a device and all sharing one
  shape — no test put two features in the same room:
  - Flutter's launch-argument provider existed with plain defaults and no code fed it, while every test
    passed because the tests override that provider directly.
  - Every widget test built the router with an explicit initial location, which is the one path a real
    deep link never takes.
  - The read the verifications screen watched was also doing the fixture seeding, so a removal
    invalidated it, re-ran the seed and re-inserted the row just deleted. The seeded tests only counted
    rows; the removal tests seeded by hand with the argument off. The tell on the device was the row's
    clock moving, which says re-created rather than undeleted.

  The regression tests for these call the app's own start-up path rather than arranging their own
  world. A fixture that no caller uses proves only that the fixture is self-consistent.

- **Two device-capture traps, both of which produced a wrong reading before being caught.**
  - A screen capture pulled between two tool calls arrives after a five-second confirmation window has
    closed, and the resulting picture cannot distinguish a working Undo from an action that never
    fired — both show the same count. Captures either side of the tap must be taken device-side in a
    single command.
  - On the ColorOS handset a green circle with a person glyph sits at a fixed screen position and
    overlaps whatever row is beneath it. It is a floating system overlay, not app UI: it does not move
    when the list scrolls, and it is absent from the goldens of the same screen.

- **A component with no caller is a third way a green suite proves nothing**, distinct from the two
  already listed. The app bar had goldens for eight months and no caller until the detail page; the
  pictures were green because pictures cannot see semantics. The other two were a fixture disagreeing
  with its caller, and two features never tested in the same room. All three are the same root
  question: what does this test actually exercise?

- **`wm dismiss-keyguard` does not always clear the lock screen** — an earlier note in the device
  ledger over-promised and has been superseded rather than edited, so the over-promise stays visible.
  It works only while the screen is already on and the keyguard is not demanding authentication. Read
  the distinguishing state before blaming the dismiss: `mScreenState`, `mWakefulness`, and
  `deviceLocked` from `dumpsys trust`. A keyguard reporting `deviceLocked=1, trusted=0,
  trustManaged=0` after a confirmed wake needs a human unlock and no adb command will bypass it.

- **Always pass an explicit `-s <serial>` to adb.** An unrelated `emulator-5554` appeared mid-session
  and was confirmed a genuinely different device rather than a second transport of the handset.

- **`LicenseRegistry` is empty under `flutter test`, whatever the build bundles.** The test binding
  overrides `initLicenses()` to a no-op so a suite does not pay to parse 1.4 MB. The bundle really is
  there — `build/unit_test_assets/NOTICES.Z` decompresses to the full set — so the emptiness reads
  like a missing asset and is not. Consequences: a screen backed by the registry cannot have its real
  content asserted in a unit test, every golden must pose a fixture, and the only place the true list
  can be seen is a device. There is a test asserting the registry IS empty, so that if Flutter ever
  changes this the suite says so rather than the screen quietly becoming testable and nobody noticing.

- **A non-vacuous check has to be proved against the thing it protects, not against a plausible
  input.** A test named "a signature matches across a line break" passed with the whitespace
  normalisation deleted, because `LicenseEntryWithLineBreaks` had already collapsed the newline before
  the code under test saw it — the test exercised the constructor, not the normaliser. Rewritten
  against a custom `LicenseEntry` that chooses its own paragraph boundaries, it reds without the
  normalisation. The tell was cheap and worth repeating on any predicate: delete the line it defends
  and confirm the test notices.

- **A row that has only just scrolled into view is not tappable when a bar floats over the list.**
  `scrollUntilVisible` stops the moment the target enters the viewport, which puts it under the
  floating nav bar, and the tap lands on the bar — reported as a hit-test warning and then as a
  missing widget two assertions later, which reads like a wiring bug. Drive to the foot of the list
  instead. The app side is a different question and should be asserted separately: with the screen
  fully scrolled, is the last control above the bar? On Flutter it is, because the screen reserves the
  clearance, and that is now a test. Android and iOS ship the same floating bar over the same long
  settings list and neither asserts it.

## 6. A branch with no pull request is invisible to every check

The Expo screen-state tranche sat finished on a branch for hours after the rest of its port merged. It
was named in the PR body of the tranche below it and in three separate hand-offs, and still went
unnoticed — because every verification anyone ran was scoped to pull requests, and this branch had
none. What found it was a content check across all remote branches during cleanup; a prune keyed on
"is there a merged PR for this branch" would have deleted it instead.

**How to apply:** track owed work where the work lives, not in prose. A branch with no PR is owed one
the moment its dependency merges, and before deleting any branch, diff it against `main` rather than
trusting the PR list.

## 7. The semantics predicate every platform owes

The Flutter fix is one line; the check that finds it is what ports. The property is not about an app
bar at all: **a container must not absorb its children's semantics nodes, and traversal order must
follow visual order rather than tree order.** Any composite that groups controls can break it.

**What the Flutter test asserts.** It enumerates every semantics node carrying a label, with two
flags each — is it a button, is it a header — and checks three things:

1. **With no trailing action**, back and title are two nodes: `['Back', 'Verification details']` in
   that order, the first a button, the second a header and not a button.
2. **With a trailing action**, all three are separately reachable and in visual order:
   `['Back', 'Verification details', 'Hide verification from the app list']`.
3. **No node's label contains a newline.** That is the collapse's signature: merged labels arrive as
   `'Back\nTitle'` on one node, so this catches the shape without naming the strings.

Assert all three. **A platform can carry one failure mode without the other** — Flutter had the full
collapse only when there was no trailing action, and with one it still inverted traversal order, so a
test written against the with-action case alone would have passed while the common configuration was
broken.

**What it does not catch.** Nothing about hit targets, focus order under a real screen reader, or
whether the labels are the right words. It is a structural predicate: the controls are separable and
ordered. It also says nothing about a container that merges correctly but labels itself badly.

**What is Flutter-specific, so the recipe does not port verbatim:**

- The cause was `Semantics(header: true)` on the row's container absorbing its children. The flag
  belongs on the title. Other toolkits will have their own absorbing construct — on iOS the
  documented sibling is `.accessibilityElement(children: .contain)`, which must come before the id or
  child ids go unreachable.
- Enumerating the tree needs `tester.binding.pipelineOwner.semanticsOwner`, which is deprecated with
  no working replacement in a widget test — `rootPipelineOwner` holds no semantics owner there. The
  Flutter test carries an ignore and says why.
- `tester.ensureSemantics()`'s handle must be disposed **inline**, not in a tear-down: flutter_test
  verifies no handle is live before its tear-downs run, so a deferred dispose fails the test it was
  meant to clean up after. This is the same shape as the painting-flag trap already in these notes.

**Why a golden cannot stand in for it.** The Flutter fix moved no pixel and no baseline changed, so
every screenshot on every platform is green either side of the defect. That is the whole reason this
needs its own test rather than a look.
