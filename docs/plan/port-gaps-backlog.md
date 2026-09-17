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
| 4 | Nav-bar clearance when the bar grows with the text scale | Scale the token term, pinned by a test that measures the rendered bar | A constant reserve was 39pt short of the bar at 2x and clipped the row it exists to protect. Bounded at the harness's declared `maxTextScale`; 3x still fails, and would need the bar measured and published rather than computed. |
| 5 | Where Flutter's preference store lives | Interface in `sample_ui`, plugin-backed implementation in the shell | A plugin is a platform binding and `sample_ui` runs under eight hosts. Android keeps the whole store in its UI module; that does not port. The keys are Android's, so a device carries one set of preferences, not four. |
| 6 | The job row's secondary line | The board's caption | Spec-directed: the spec records this as an open divergence and says a port should take the board while Android follows. Android now owes the change (§2). |
| 7 | The literal backticks in `Tap \`Hide from List\` to confirm` | Removed on Flutter | They render as backticks to a user. Android and iOS carry the same string and now owe the same fix (§2). |
| 8 | Merging a stacked PR set in a squash-only repo | Collapse the remainder into the top PR | Squash rewrites the commit, so the branch above loses ancestry with `main` — producing both a conflict and an inflated diff. The base retarget then dismisses the approval. Re-approval per PR is unavoidable; collapsing spends one instead of four. |

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

## 4. Product questions

These need an owner's answer rather than an engineer's. Neither blocks anything.

- Should a profile's stored defaults seed the job form, and should the "remember these details"
  switch remember anything? Today it persists nothing.
- Should `expo/app` declare `expo-router/testing-library` so a cold deep link's navigation state can
  be asserted? It is a test-only dependency.

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
- **A green test can prove nothing.** Two cases this run: Flutter's launch-argument provider existed
  with plain defaults and no code fed it, while every test passed because the tests override that
  provider directly; and every widget test built the router with an explicit initial location, which
  is the one path a real deep link never takes. Both were only found on a device.
