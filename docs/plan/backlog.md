# Backlog

Known work on the four sample apps that is not done yet. Each item says what is wrong or missing, and
what done looks like. Pick one up by opening a pull request that names it; remove the item in the same
pull request that finishes it.

## Testing

### Coverage: a 95% gate in every app

None of the four apps measures line coverage, so the 95% rule in AGENTS.md can't be checked. Measure
each app's current number, then gate it in its `verify.sh`. The number is one per app (the shell and
its `sample-ui` together), over every source file, generated files under `scripts/` left out:

- **Count untested files as zero.** `flutter test --coverage` and jest's `--coverage` report only the
  files a test loads. Add the missing `lib/` files to Flutter's lcov with zero hits, and pass
  `--collectCoverageFrom` for `src/` on the jest command line (the configs' `roots` point at
  `test/`). The report's file count must match the source file count.
- **Merge, then check once.** Collect coverage on the full runs from the command line, not in
  config, write lcov (or the platform's report), merge (`lcov -a` for Flutter and Expo,
  `xcrun xcresulttool merge` for iOS, JaCoCo's merged report for Android's `app` and `sample-ui`),
  and check the merged total with one script. jest's `coverageThreshold` checks only its own run, so
  it isn't the gate.
- **iOS runs:** merge the library's unit tests, its goldens and the shell's unit tests; leave out the
  UI suites, which CI runs as separate jobs, and the Release probe run.
- **Android:** the Gradle plugin's built-in `enableUnitTestCoverage` (JaCoCo, no new dependency)
  with a `JacocoCoverageVerification` threshold on the merged report.

Document the command per platform in `docs/` with the gate. The gate follows the ratchet in
AGENTS.md *Testing*: an app below 95% gates at its measured number. Done when every `verify.sh`
gates its measured coverage, at 95% once the app reaches it.

## UI and design fidelity

### Translations: a native speaker's review

The French, Arabic and Hebrew strings in `spec/l10n/app/` were written without a native speaker's
review. Have each language reviewed, and fix the strings in `spec/l10n/` so every platform picks them up.
Done when each language has been read in the running app by a native speaker.

### iOS: a language pick that applies at once

On iOS a pick in the Language sheet applies on the next launch, because the SDK reads its strings in the
language the process started with. Once an iOS SDK release ships `UseSmileIDStrings.language`, bump the
pin in `ios/App/project.yml` to that release and apply the pick at once as the other three apps do:

- `setLanguage` sets `UseSmileIDStrings.language` (nil for System) instead of writing `AppleLanguages`,
  and swaps `UseSmileIDSampleStrings.bundle` to the picked `.lproj`, through a public setter with a lock.
- At launch, set the override from the stored setting first, then remove any `AppleLanguages` value an
  earlier build wrote; the removal lands one launch late, so the override is what keeps that launch right.
- Delete `runningLanguage`, the `deviceLanguages(in:)` cache and its `device_languages` key; they only
  exist because `AppleLanguages` masks the device list.
- Apply `.environment(\.locale, …)` and `.environment(\.layoutDirection, …)` from the resolved language
  unconditionally, never behind an `if let`: toggling that branch changes the view's identity and drops
  navigation state. The `appLocale` launch argument keeps precedence over the pick.
- `catalogueLocale` and the verifications calendar follow the pick, not `Locale.current`, so API-translated
  names and day headers switch too.
- The sheet closes on a pick: drop `pending` and the "Applies the next time the app opens." line, remove
  `language_applies_on_relaunch` from `spec/l10n/app/*.json`, rewrite the `languageSheet` note in
  `spec/screens.json`, and update the iOS rows in `docs/localisation.md`.
- Tests: the settings UI test asserts a pick applies at once, on ids; delete the `pending: true` golden
  variants and record the plain sheet. On the simulator: pick fr → the SDK consent screen is French with
  no relaunch; pick ar → sample and SDK screens are right to left, noting which chrome does not mirror
  (navigation bars, the camera alert, the gallery picker); System → the device language.

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

### Flutter iOS: a UI test lane

Flutter's iOS app has no UI test at all: its flows run on Android only, and `flutter/verify.sh` builds
the iOS app without launching it. A cold link that reached the app as `/` went unnoticed because of it.
Done looks like a simulator XCUITest that cold-opens a link with launch arguments and asserts what they
do, run by `flutter/verify.sh` on the Mac.

## Spec and code health

### Android: replace the pinned njia and SDK snapshot builds with releases

`android/gradle/libs.versions.toml` pins njia to one snapshot build, `0.0.1-20261023.003202-6`, and the
SDK artifacts to the builds made against it (`12.3.0-20261023.083151-*`). A bare `0.0.1-SNAPSHOT` lost
Gradle's conflict resolution to the SDK snapshot's older njia, and an SDK built on another njia fails at
run time with `NoSuchMethodError`. Maven Central's snapshot repository deletes builds after about 90 days,
so once these go, a clean build can't resolve them. Done when both pins are releases, or newer matching
builds until then.

### Android: the system-bars test's sheet case idles through endless frames

`UseSmileIDSampleSystemBarsTest`'s sheet cases open Material 3's `ModalBottomSheet`, whose window
polls its position every frame (`withInfiniteAnimationFrameNanos`), so `ShadowLooper.idleMainLooper()`
runs frame after frame: a run of the class takes about eight minutes, and Robolectric's trace shadow
keeps every section those frames open. At the default 512 MB heap that ran out and stopped the
recomposer for the tests after it, so the app's tests now get 2 GB. Done when the sheet cases idle a
bounded number of frames, or a fixed span of the clock, and the class runs in seconds.

### Flutter iOS: retire the first-push launch listener

`UseSmileIDSampleColdLink` takes a cold link from the first route push within two seconds of the first
frame, because iOS used to launch the engine at `/`. The runner's `SceneDelegate` now seeds the link as
the initial route, so the listener runs only after an icon launch and does nothing a test relies on.
Done looks like the listener, its provider and its test removed, with the cold link proven on iOS first.

### Flutter iOS: profiles and the token session outlive an uninstall

Profiles and the token session are kept in the Keychain, which iOS keeps when the app is deleted. A
reinstall opens with the last install's profiles and an ended session instead of an empty app, which a
partner reading the sample will take for state the app made up. Done looks like the stores cleared on
the first launch after an install, on iOS, with a test for it.

### Back onto released SDKs with the next SDK release

`main` builds the four apps against SDK snapshots for test builds (#163), which AGENTS.md allows only
for released SDKs. The Android pins can stop resolving on their own: Central prunes snapshot builds
after its retention window, and every `main` build then fails until the pins move. Each piece goes
in the release bump:

- **Android:** `libs.versions.toml` back to one released version, and the snapshot repository in
  `settings.gradle.kts` and the strict `bridge` constraint in `sample-ui/build.gradle.kts` removed.
- **Flutter:** `usesmileid` released in `app` and `sample_ui`, the snapshot repository in
  `app/android/build.gradle.kts` removed, and `the SDK is resolved from the registry` test back to
  accepting `x.y.z` only.
- **iOS and Expo:** `ios-spm` and `@smileid/usesmileid*` back to released versions.

Done when `main` pins only released SDKs and no build reads a snapshot repository.

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
