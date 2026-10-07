# Backlog

Known work on the four sample apps that is not done yet. Each item says what is wrong or missing, and
what done looks like. Pick one up by opening a pull request that names it; remove the item in the same
pull request that finishes it.

## Testing

### Coverage: a 95% gate in every app

None of the four apps measures line coverage, so the 95% rule in AGENTS.md can't be checked. Measure
each app's current number, then gate it in its `verify.sh`: `flutter test --coverage` with lcov,
jest's `coverageThreshold`, `xcodebuild -enableCodeCoverage YES` with `xccov`, and on Android the
Gradle plugin's built-in `enableUnitTestCoverage` (JaCoCo, no new dependency) with a
`JacocoCoverageVerification` threshold. Leave out the files `scripts/` generates. Done when every
`verify.sh` fails below 95%.

## UI and design fidelity

### Expo: the scenario drawer is not presented

Expo's Settings screen shows the scenario-drawer button only when a shell passes
`onOpenScenarioDrawer`, and no Expo route does, so the drawer and its `sample_scenario_drawer`,
`sample_scenario_item_*` and `sample_theme_item_*` ids exist nowhere on Expo. Present the drawer from
the Expo shell as the other three apps do, then drop the three excused ids from
`use-smile-id-sample-test-id-usage.test.ts`.

### Translations: a native speaker's review

The French, Arabic and Hebrew strings in `spec/l10n/app/` were written without a native speaker's
review. Have each language reviewed, and fix the strings in `spec/l10n/` so every platform picks them up.
Done when each language has been read in the running app by a native speaker.

### iOS: a language pick that applies at once

On iOS a pick in the Language sheet applies on the next launch, because the SDK reads its strings in the
language the process started with. Once the SDK takes a language override, apply the pick at once as the
other three apps do, and drop the next-launch note from the sheet.

## Tests and structural checks

### Words that cannot fit the narrowest phone at the largest type

Every Flutter predicate now shares one envelope (largest text scale, the real font, a non-zero inset),
but it runs at the design's 393 width, as Android's and Expo's do by default. Run at 320, the narrowest
phone both platform floors support, it finds a word broken mid-word on ten surfaces, among them:

- the top app bar title `Verification details`, and the products `SmartSelfie™` and `Enhanced SmartSelfie™` labels
- the email placeholder `name@company.com` on the user-details and verification-details screens
- the licence coordinate `shared_preferences`, and a long organisation name on the details screen

A word wider than its column cannot be fixed in code alone: the type steps down before it wraps (as the
product card title already does), or the break is accepted. Ask for a design ruling, then run the
envelope at 320 on all four apps and fix what it finds.

### iOS device lane: handle the camera permission prompt

The XCUITest device lane has a counterpart for every Android flow, with the opener and exactly-once
assertions. The camera permission prompt on a fresh install is the one case it does not yet drive.

## Spec and code health

### Android: a launch screen that matches a pinned appearance

With Light or Dark pinned against the device, the launch window still follows the device, so a cold
start flashes the opposite theme before the app draws. `UiModeManager.setApplicationNightMode` fixes it,
but it is API 31+ while the app's `minSdk` is 24, and Flutter and Expo would each need their own bridge.
Done looks like a pinned appearance that launches in its own theme on API 31+, on all three Android shells.

## Device suite and CI

### Document capture: the shutter and gallery by id

The capture-mode checks match the manual shutter by its accessibility label, "Capture document", because
the SDK publishes no `si_*` id for the shutter or the gallery button. When an SDK release publishes them,
swap the flows over to the ids and add a check that the gallery button appears with gallery upload on.

### iOS: shutter timing on a device

The capture-mode behaviour (shutter at once under manual, after 10 seconds under the default, never under
auto) is checked by Maestro on Android only. The iOS simulator has no camera, so the XCUITest stops at the
SDK's mount. Add the same three checks to the iOS device lane.

### Expo: the document form's flow stops before the SDK

`expo/maestro/document-options.yaml` enters the form by link and never types, because a focused field
ends the Expo flows (see `expo/maestro/README.md`). Once that is solved, drive it through consent to the
capture screen, as the Android and Flutter flows do.

### A registry-consumption lane that launches and drives the published SDK

These apps exist to consume the SDK exactly as a partner does, but no lane here resolves the published
SDK, builds release, launches and drives it. Most existing consumption checks elsewhere stop at
linking, which proves nothing about a missing runtime resource, a stripped entry point or a missing
native library.

One workflow per platform, in this repo, with four stages:

| Stage | Proves | Fails on |
|---|---|---|
| Resolve | the version exists and its manifest is coherent | a broken publish, a missing transitive |
| Build release | it survives minification with no app-side keep rules | keep-rule regressions, missing resources |
| Launch | the app reaches the product list | linkage failures, missing native libraries |
| Drive | a journey runs: SDK mount, capture entry, a terminal result | anything the first three cannot see |

- Two arms: **stable** (the latest release) and **snapshot** (the current pre-release). The snapshot
  arm resolves fresh every run, with no cache, and records the resolved build id.
- A companion arm: a host-initialised Sentry, and whatever the Flutter graph carries transitively.
- Harness rules: assert the package under test first, with a build id readable from the accessibility
  tree; clean-install by default; a mandatory warm start before the first assertion; read state from
  the accessibility tree, never from screenshots or polled logs.
- Every run writes the resolved version, the package it drove and the assertions it cleared to the job
  summary, so a green run says what it proved.
- Android first, then Flutter and Expo. iOS's launch-and-stay-up check is the reference.

## Store listings

### Expo: the template's app icon, and a splash with no mark

`app.config.ts` sets no `icon`, so the Expo app ships the Expo template's icon (the generated
`ic_launcher.webp` and `AppIcon.appiconset`), and its splash is a flat background with no logo. Done
looks like the Smile mark on both, from a first-party asset, and the `displayName` rename
`spec/app-identity.json` already records for Expo.

### Store art: the camera panel

The camera panel needs a device run on both platforms. The Android Maestro flow
(`android/maestro/store/store-shots.yaml`) and the output paths exist, and the composer has its slot.
The other panels are rendered, and their demo values come from `spec/store-art.json`.
