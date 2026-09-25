---
description: How the sample apps are tested, and how to test your own Smile ID integration the same way — spec tests, goldens, layout predicates and device flows that assert on ids, never on screenshots.
---

# Testing

The pass/fail path never depends on a person or a model reading a screenshot. Every committed test is
deterministic, and it asserts on something the code exposes: a spec entry, a golden image, a layout
measurement, or an accessibility id. This page lists the layers, cheapest first, with what each one
catches.

## Prerequisites

Each platform's `verify.sh` runs everything below except the device flows:

```bash
android/verify.sh     # lint, unit tests, spec validation, goldens, minified release assemble
ios/verify.sh         # swiftformat and swiftlint, tests, release build
flutter/verify.sh     # format, analyze, test, release build
expo/verify.sh        # eslint, tsc --noEmit, test, release build
```

CI runs the same scripts on every pull request, so the local check and the gate cannot drift apart.

## 1. Spec tests: four apps, one contract

Each app has unit tests asserting that its scenarios, launch arguments, routes, result-card fields and
test ids match `spec/` exactly. They are the cheapest tests in the repository, and they are what keeps
four apps aligned.

Assert set equality **in both directions**: nothing undeclared, and nothing declared but missing. A
one-directional check cannot fail on an omission, which is how a declared id attached to no widget once
stayed green.

## 2. Goldens, in light and dark

Every screen state in `spec/screens.json` is recorded as a golden image in both light and dark, and a
test fails when a state has neither a golden nor a recorded reason for exemption.

| Platform | Tool |
|---|---|
| Android | Roborazzi |
| iOS | swift-snapshot-testing |
| Flutter | `matchesGoldenFile` |
| Expo | Skia-rendered pixel goldens under Jest |

**Record Flutter and Expo baselines on CI, never on a laptop.** Both are rasterised by the host, so a
baseline recorded on a Mac fails on the Linux runner, and glyph edges even differ between macOS versions.
Let the lane fail, then take the recorded images from its `flutter-goldens-recorded` or
`expo-goldens-recorded` artifact.

**Check that two states' baselines are not byte-identical.** Two identical images usually mean the
fixture never reached the state it names.

## 3. Structural predicates: checks that need no design reference

- **Text scale.** No clipping or ellipsis at the largest font scale and the narrowest width, measured
  on each layout. The predicate must be able to fail: a check that excludes the paragraphs able to
  report truncation passes forever.
- **Contrast.** Ink on every fill is chosen by WCAG relative luminance, and tested.
- **Status bars, in both presentations.** The SDK flow is presented both modally and pushed, and the
  status-bar result can differ between the two, so each is asserted.
- **Ids are attached.** Every declared `sample_*` id appears in source somewhere other than its
  declaration, across both the shell and `sample-ui`, because a sheet's id comes from the host that
  presents it.
- **Semantics.** A container must not absorb its children's accessibility nodes. An app bar that
  merges its back control and title into one node reads as one button to a screen reader, and no
  golden can see it.

## 4. Device flows: assert on ids

| Platform | Runner | Where |
|---|---|---|
| Android | Maestro, on a device or emulator | `android/maestro/` |
| iOS | XCUITest | `ios/App/UITests/` |
| Flutter | Maestro, on an emulator in CI | `flutter/maestro/` |
| Expo | Maestro, on an emulator in CI | `expo/maestro/` |

The rules every flow follows:

- **Assert on `si_*` (SDK) and `sample_*` (app) accessibility ids, and on the result card**, never on
  screenshots or coordinates.
- **Open every flow the same way**: launch, then the product list, then the SDK mounting. A packaging
  failure then fails conclusively at the start, not as a confusing timeout later.
- **Exactly one terminal result.** After any cancel or denial, including rapid re-entry, the result
  card must report exactly one result.
- **Stop at the capture screen.** Completing a capture needs frames injected into the camera, which is
  deliberately not part of this repository.
- **Start from a clean install when comparing branches.** Re-running a flow does not clear stored
  state, so a stale store can fake a pass.
- **Warm up first.** The first cold start after installing a release build can exceed the default
  assertion timeout.
- **Check the package under test.** Other Smile ID samples implement the same ids, so a leftover app in
  the foreground can satisfy an assertion meant for this one.

The token states (linked, counting down, expired) are reached through **Simulate a successful scan**,
which mints a synthetic token. No flow needs a real token.

## 5. The release build is where consumption defects show

Every platform builds a minified, resource-shrunk release in `verify.sh`, and the device flows also run
against release. A defect in the published SDK artefact — a missing resource, a stripped entry point,
a missing native library for one ABI — appears there and nowhere else. The planned next step, a lane
that resolves the published SDK and drives a journey on it, is in the [backlog](plan/backlog.md).

## Verify your integration

- [ ] Your spec or contract tests assert set equality in both directions.
- [ ] Goldens cover light and dark, and are recorded on the machine that verifies them.
- [ ] Your device flows assert on `si_*` ids and your own ids, never on coordinates.
- [ ] You run your flows against a release build.

## Common issues

| Symptom | Cause | Fix |
|---|---|---|
| A Flutter or Expo golden fails on CI but passes locally | The baseline was recorded on a Mac | Take the baseline from the CI artifact |
| A declared test id is missing on device, while every test is green | The spec test checked one direction only | Assert both directions, and that each id is attached |
| Two state goldens are identical | The fixture never reached the second state | Assert the pair differs |
| A device flow passes on the wrong app | A sibling sample was in the foreground | Assert the package first |
| The first assertion times out on a release build | Cold start after install is slow | Add a warm-start step |
| A flow is green on one branch and red on another, with no code change | Stored state from an earlier run | Uninstall and reinstall per branch |

## Next step

[`docs/architecture.md`](architecture.md) explains the rules these tests hold the apps to.
