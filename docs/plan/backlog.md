# Backlog

Known work on the four sample apps that is not done yet. Each item says what is wrong or missing, and
what done looks like. Pick one up by opening a pull request that names it; remove the item in the same
pull request that finishes it.

## UI and design fidelity

### Pull to refresh on the verifications list

The design has a pull-to-refresh gesture and a `refreshing` state on the verifications list. Today
refresh exists only on a verification's detail screen, on all four platforms. A list-wide refresh
updates every row the current partner submitted, including rows from an expired session.

- The screen renders `refreshing` and calls the store. The store owns the refresh, not the screen.
- It is idempotent and cancellable: leaving the tab cancels it.
- Failure is a state, not a silent no-op. The design has no error frame yet, so ask for one.
- Add the platform binding and test id alongside the `refreshing` frame in `spec/screens.json`, and
  cover it with a device flow, since a refresh that never ends is the likely regression.

### Expo: the scenario drawer is not presented

Expo's Settings screen shows the scenario-drawer button only when a shell passes
`onOpenScenarioDrawer`, and no Expo route does, so the drawer and its `sample_scenario_drawer`,
`sample_scenario_item_*` and `sample_theme_item_*` ids exist nowhere on Expo. Present the drawer from
the Expo shell as the other three apps do, then drop the three excused ids from
`use-smile-id-sample-test-id-usage.test.ts`.

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

### Flutter: assert the SDK's consent screen by id once the SDK ships it

The Flutter SDK now publishes the same screen ids as the other SDKs (smileidentity/flutter#224):
`si_consent_screen`, `si_instructions_screen`, `si_capture_screen`, `si_document_back_instructions_screen`,
`si_camera_error_screen`, `si_preview_screen`, `si_document_preview_screen` and `si_processing_screen`.

The Flutter app still pins `usesmileid` 12.1.1 in `flutter/app/pubspec.yaml`, which publishes only
`si_preview_screen` and `si_processing_screen`. So the Flutter device flows match the consent screen by
its text:

- `flutter/maestro/sdk-flow.yaml`: the header comment and the consent step
- `flutter/maestro/profile-journey.yaml:38`
- `flutter/maestro/token-session.yaml:4`
- `flutter/maestro/README.md:65-68`, which says the SDK publishes only two ids

iOS (`ios/App/UITests/UseSmileIDSampleFlowUITests.swift`) and Expo (`expo/maestro/token-session.yaml`)
already assert `si_consent_screen`, so Flutter is the only platform left.

Done looks like:

- The Flutter app is bumped to the first `usesmileid` release that includes that change.
- The three flows assert the consent screen by id, `si_consent_screen`.
- The README paragraph and the comments that explain the text match are removed.
- All three flows pass on a device.

## Spec and code health

### Flutter: share the custom-button slots once the SDK exports their scope

Android, iOS and Expo keep their Custom continue and Custom cancel slots in `sample-ui`, beside the
buttons. Flutter cannot: `usesmileid` 12.1.1 does not export the slot's scope type, so a shared slot
constant has no type to name, and the app's flow builder writes each slot as a closure instead. Once
the SDK exports it, move the slots into `sample_ui` next to `UseSmileIDSampleCustomContinueButton` and
have the builder assign them, as the other three do.

### Expo: the consent and processing screens ignore the custom buttons on 12.1.1

`@smileid/usesmileid` 12.1.1 accepts consent's `allowButton` and `denyButton` and processing's
`continueButton` and `exitButton` on its builders, but does not pass them to the screens, so the
Expo app shows the SDK's own buttons there while Custom continue and Custom cancel are on. Only the
instructions screen shows "Custom continue". The Expo builder already sets every slot, as the other
three apps do. Once an SDK release draws them, bump to it and check the consent screen on a device;
nothing else in this app needs to change.

## Device suite and CI

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

## SDK features the sample does not show yet

### Exercise the SDK's document-capture options

`DocumentCaptureConfig` has six fields, and the sample exercises one. The rest ship as public API that
no reference host shows.

| Field | Default | Sample today |
|---|---|---|
| `documentType` | `null` | derived from the ID type, never chosen |
| `captureBothSides` | `true` | `true`, except `false` for a passport |
| `allowSkipBack` | `false` | `true` |
| `captureMode` | `AutoCaptureWithManualFallback(10s)` | never set |
| `allowGalleryUpload` | `false` | never set |
| `knownIdAspectRatio` | `null` | never set |

In priority order:

1. **Choose the document type directly** (Green Book, Passport, generic), independent of the ID-type
   field, on the ID-details form. Each case sets `hasBackSide`, `orientation` and `knownAspectRatio`
   differently, so this one control makes back-side capture, framing and aspect ratio observable.
   Choosing the generic case exposes its display name, back-side flag and orientation, plus
   `knownIdAspectRatio`, which exists for exactly that case.
2. **`captureBothSides` should follow `documentType.hasBackSide`.** Today the Green Book, which has one
   side, is asked for two. First check what the SDK does with that combination, then make the one-line
   fix and add a unit test.
3. **`captureMode` as a three-way Settings control** (auto, manual, auto with manual fallback). Assert
   it on the wire: it is sent as `auto_capture_enabled` (`auto_capture_only` / `manual` /
   `autocapture_default`). That assertion is debug-only, because release never logs traffic, so the
   release lane asserts the on-screen behaviour. Add a device check that the manual shutter appears
   after the fallback duration.
4. **`allowGalleryUpload`** as a Settings switch, with its permission consequence.

Each needs a `spec/` entry, test ids and goldens, on all four apps.

## Store listings

### Store art: the camera panel

The camera panel needs a device run on both platforms. The Android Maestro flow
(`android/maestro/store/store-shots.yaml`) and the output paths exist, and the composer has its slot.
The other panels are rendered, and their demo values come from `spec/store-art.json`.
