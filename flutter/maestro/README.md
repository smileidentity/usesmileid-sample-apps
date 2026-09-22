# Flutter device flows

```bash
maestro --device <serial> test -e APP_ID=com.usesmileid.sample.flutter flutter/maestro
```

Run against the release APK, which is minified and resource-shrunk with no app-side keep rules:

```bash
cd flutter/app && flutter build apk --release
```

On an emulator, add `--target-platform android-x64`; the CI lane does, because compiling the engine
and the AOT snapshot for all four ABIs is wasted minutes when only one of them is ever installed.

## What this lane is for

Four flows, not a port of the Android suite — that one was measured at 36–53 minutes returning
nothing across four runs. These cover what a **hostless** Flutter test structurally cannot reach:

- **`licenses.yaml`** — `LicenseRegistry` is empty under `flutter test` by design, so no widget test
  can see the notices screen with content in it. Only a real build writes `NOTICES.Z` into the
  bundle, and only a running app decompresses it. The flow names engine C++ components, which exist
  in the registry and in no package graph. The Android twin covers this inside its `settings.yaml`;
  here it is the screen the lane exists for, so it gets its own flow.
- **`launch-args.yaml`** — every widget test overrides the launch-args provider directly, which is
  how `seedJobs` stayed wired to nothing while all of them passed (#101).
- **`deep-links.yaml`** — `spec/routes.json` requires every route to open cold **and** warm.
- **`verifications.yaml`** — the three behaviours #101 shipped with widget tests only, because the
  handset's keyguard blocked its device pass.

## Traps

**Launch arguments arrive as a COLD-START LINK, not as intent extras.** `main()` reads
`PlatformDispatcher.defaultRouteName` once, before the first frame. `am start --ez seedJobs true`
does nothing and Maestro's `launchApp: arguments:` is ignored entirely, so every case is a
`stopApp` followed by an `openLink` — `subflows/cold-start.yaml`. A link delivered to a *live* app
navigates and carries its query, but re-seeds nothing, by design.

**`scrollUntilVisible` needs `centerElement: true` and a raised timeout.** It otherwise stops the
moment the row counts as visible, and `visibilityPercentage` measures screen bounds, not occlusion:
on the pixel_5 geometry the first swipe parks the row exactly behind the floating nav bar (row
y 2068–2244, pill 2073–2230), Maestro logs it 100% visible, and the centre tap lands on the pill's
Verifications segment. The Android twin's `visibilityPercentage: 80` is not a substitute — measured
0/5 here for that reason; centring moves the row clear of the pill. The default 20s budget is what a
loaded runner outruns: on 35720237160 the scroll ran out and the flow had already been swiped onto
products (locally the scroll takes ~3s). Assert the tab root again after any scroll, or a swipe that
reached the pill arrives as a missing row two steps later.

**Undo has five seconds unless the link widens it.** `useSmileIDSampleNoticeWindow` withdraws the
removal confirmation on a timer, and every assertion in front of the tap costs a hierarchy dump, so
on a loaded runner the tap lands after the withdrawal and reds as a missing element rather than as a
timer. Pass `noticeWindow` in the cold-start link, as `verifications.yaml` does.

**The job store survives the run.** It is `SharedPreferences`, and `seedJobs` is idempotent by id,
so a re-seed never brings back a row a previous run removed. Flows that remove open with
`clearState` — which on a handset also wipes the settings switches and the profile list, so a local
run costs whatever you had configured in the app. **ColorOS refuses `pm clear`**, which is what
`clearState` runs, so every one of those flows dies on its first command there; reset the handset
arm with an uninstall and reinstall instead, and drop the command for a local run.

**The SDK's own screens are not all addressable here.** This SDK publishes two semantics
identifiers — `si_preview_screen` and `si_processing_screen` — where the Android SDK also publishes
`si_consent_screen` and `si_instructions_screen`. `sdk-flow.yaml` therefore asserts the consent
screen by its own text. The SDK's camera permission is requested when the CAPTURE screen mounts,
not on the way out of consent, so a conditional grant belongs after the instructions step.

**Four sibling sample apps implement the same `sample_*` ids**, and this app additionally shares
its application id with the Flutter SDK repo's own development sample (`spec/app-identity.json`,
2026-09-17 ruling) — a device holds one of the two at a time, so install one at a time. `APP_ID`
is passed explicitly rather than defaulted because the debug variant suffixes its application id
while both variants claim the same URL scheme, so a deep link with both installed raises a chooser
and the run hangs on a dialog no flow asserts.

**On an emulator, disable the keyguard first** (`adb shell locksettings set-disabled true`), and
hide error dialogs (`adb shell settings put global hide_error_dialogs 1`): a system ANR dialog
covered all four flows on one runner. That hides this app's crash dialog too, not its evidence — a
red whose app crashed carries `logs/crash-report.txt` beside `device-logcat.txt`, and Maestro's own
message only says the element was missing.

**The first tap after a cold start can land before the window takes input.** On a starved
runner the engine publishes its semantics tree while the activity is still behind its splash window,
so Maestro sees `sample_products_screen`, taps, and the system drops the touch
(`InputDispatcher: … NO_INPUT_CHANNEL`, measured 7.6s to Displayed). That tap therefore carries
`retryTapIfNoChange: true`: it retries only when nothing changed, and each one is idempotent.

**The toolchain pin is load-bearing here.** `licenses.yaml` names engine components by id, and
which ones the bundle carries is decided by the Flutter version — pinned in `flutter.yml` and
`flutter-device.yml`, which must agree.

## What Expo's lane has and this one does not

`expo/maestro/` opens every flow with a 60-second `warm-start` subflow because its first cold start
after an install outlives Maestro's default timeout while ART warms the minified APK. That does not
transfer: measured here, a Flutter release cold start is **~0.7s** (`am start -W`), first launch
after install included. `subflows/cold-start.yaml` still carries a tolerance, as headroom for a CI
emulator rather than for this app.

## What this lane does not cover

**Anything past the SDK's consent screen.** `sdk-flow.yaml` asserts the flow host mounted the SDK and
stops there; a capture needs a camera, which no public flow in this repo drives.

**Dark mode's appearance, the system bars, and layout.** The testing contract forbids screenshot and
coordinate assertions inside a device flow, so the appearance stays with the goldens and the bar
contrast with `use_smileid_sample_system_bars_test.dart`.
