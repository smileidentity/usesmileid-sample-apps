# Backlog

Known work on the four sample apps that is not done yet. Each item says what is wrong or missing, and
what done looks like. Pick one up by opening a pull request that names it; remove the item in the same
pull request that finishes it.

## UI and design fidelity

### Literal backticks in the selection bar hint on Android and iOS

With rows selected, the selection bar reads ``Tap `Hide from List` to confirm``, with the backticks
drawn on screen. Flutter and Expo show `Tap "Hide from List" to confirm` without them.

- Android: `UseSmileIDSampleSelectionBar.kt:79`
- iOS: `UseSmileIDSampleSelectionBar.swift:88`

Fix the string on both platforms, and re-record the selection-bar goldens in light and dark.

### Android: job row caption and a stale status-badge comment

- The job row's secondary line should use the board's caption style, as `spec/components.json` says
  for JobRow. The row gets taller, so its goldens move.
- `UseSmileIDSampleStatusBadge`'s doc comment says only the saturated `badge.<role>.*` pairs have landed
  and the soft fills are pending. The soft fills are what the app draws (`softBadgeTokens()`). Make the
  comment say so.

### iOS: pick text colour by WCAG luminance, as the other three apps do

iOS chooses the ink on a fill with `UIColor.getWhite`, a perceptual grey
(`UseSmileIDSampleColorMath.swift:8`). Android, Flutter and Expo use WCAG relative luminance against the
0.179 crossover. 12 of the 51 delta colours come out differently, and in each case Android chooses white
where iOS chooses dark.

Check the 12 pairs against WCAG AA first. If any fails, switch the function to relative luminance, and
re-record the affected goldens.

### Android: sheets cover a blank window instead of the screen beneath

Every sheet route (`profileSwitch`, `newProfile`, `countryPicker`, `idTypePicker`, `scenarioDrawer`)
replaces the destination underneath it, so the scrim dims an empty window where the design shows the
screen it covers.

Present sheet routes as an overlay on the current destination, not a replacement. Navigation 3's
overlay support is the intended route. The dialog-destination workaround gives the right backdrop but
changes the keyboard, inset and dismissal behaviour a bottom sheet should keep. iOS, Flutter and Expo
already present sheets over the current screen: check them rather than change them. Do not paint the
window to look intentional.

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

## Spec and code health

### One table for spec debt in `spec/README.md`

Spec entries that no app implements, or that disagree with the design, are recorded in several places
and an allowlist. Put them in one owner table in `spec/README.md`, each with a decision:

- the two shell ids in `spec/test-ids.json` that no app implements, `sample_env_chip` and `sample_license_link`
- the licences-screen wording, and the consent form's required contact field
- button height 48 against 52, and the card glyph at 21 against 20
- the contradiction inside `spec/screens.json`
- whether `spec/components.json` is informative, or owed a check

### A dead-code check for Expo and Flutter

Run `knip` over the Expo workspace, and enable the unused-code lints on Flutter, in each platform's
`verify.sh` so CI enforces them.

### Android: removing an unknown job id discards the undo

Android's job store silently drops the undo when asked to remove an id it has no row for. iOS guards on
what the removal actually took. Nothing reachable passes an unknown id today, so this is hardening:
match iOS, and add a test.

### Android: enforce a resource prefix on `sample-ui`

`android/sample-ui` declares no `resourcePrefix`, so its icons are prefixed `sample_ic_*` by hand and
nothing stops an unprefixed resource from colliding with a host's. The same library runs inside the SDK
repos' development samples, so a collision there is silent. Set `resourcePrefix = "sample_"` in
`android/sample-ui/build.gradle.kts` and rename whatever lint then flags.

### List the bundled font and icons on the licences screens

The four licences screens list the registry dependencies, but not the assets bundled in the tree: DM Sans
(SIL Open Font License 1.1) and the Material Symbols stand-ins (Apache 2.0). `NOTICE` records both. Add
them to each app's licences screen, from one shared source so the four do not drift.

### Android: store the token session encrypted

Android keeps the linked session's token in DataStore unencrypted, where iOS, Flutter and Expo use
the platform's secure storage. The trade was made when only sandbox tokens could be scanned. Production
tokens can be scanned now, so seal it with an Android Keystore key, as the profiles already are.

## Device suite and CI

### Make the device suite fast enough to run on every PR

Measured on Android: `verify.sh` takes 1.5–3 minutes and CI about 12, but the Maestro suite takes
36–53 minutes in debug and 36–42 in release, and on the day it was measured it found nothing across
four runs. In order of payoff:

1. **Measure transport first.** Time one flow on a local emulator against a wireless-adb phone, before
   buying anything.
2. **Choose flows by what changed.** Map paths to flows, fall back to the full suite for an unmapped
   path, and offer a label that forces everything. Run debug on every PR, and release on merge to
   `main`, nightly, and on PRs that touch packaging (Gradle files, proguard rules, the manifest,
   dependency versions).
3. **Shard across two emulator instances** off one AVD, if RAM allows. It costs no disk.
4. **Run the full suite nightly**, on the physical device or a device cloud, off the PR path.
5. **Refuse a full-suite run on battery**, which removes the class of runs that collapse part-way.

Move work down the pyramid where a widget or unit test can see the same thing, and batch assertions
into fewer flows rather than repeating launches.

### Play publishing: an internal build on every merge, and a collision-proof versionCode

- **Run `publish-play-internal.yml` on `push` to `main`**, with a path filter, so a docs-only merge
  does not publish a build or spend a versionCode.
- **Derive `versionCode` from Play's highest code plus one**, as the App Store lane does with
  `asc_publish.py next-build`. The commit count gives two workflows dispatched on one commit the same
  code, and the second upload is rejected. A branch behind `main` gives a lower one, which Play refuses.

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
| `captureBothSides` | `true` | hard-coded `true` |
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

### Store art: camera panel, a sparse details panel, shared demo data

- **The camera panel** needs a device run on both platforms. The Android Maestro flow
  (`android/maestro/store/store-shots.yaml`) and the output paths exist, and the composer has its slot.
- **The `verification_details` panel is sparse** once the debug result card is hidden, which it must
  be, because a release install cannot show it. Keep it, drop to four panels, or choose a denser state.
- **Lift the demo literals into `spec/`**: the organisation, its initials, the session id and the
  countdown value. Both store-art tests currently carry them separately.
