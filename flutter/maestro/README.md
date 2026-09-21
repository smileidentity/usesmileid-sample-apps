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

**`scrollUntilVisible` needs `centerElement: true`.** It stops the moment a row enters the
viewport, and the floating nav bar is drawn *over* the bottom of every tab root, so the tap lands
on the pill and switches tab instead. The failure looks like a missing screen, not a missed tap.

**Undo has five seconds.** `useSmileIDSampleNoticeWindow` withdraws the removal confirmation on a
timer, and every assertion in front of the tap costs a hierarchy dump. Keep one dump inside the
window; four raced it, and a withdrawn toast reds as a missing element rather than as a timer.

**The job store survives the run.** It is `SharedPreferences`, and `seedJobs` is idempotent by id,
so a re-seed never brings back a row a previous run removed. Flows that remove open with
`clearState` — which on a handset also wipes the settings switches and the profile list, so a local
run costs whatever you had configured in the app.

**Four sibling sample apps implement the same `sample_*` ids**, and this app additionally shares
its application id with the Flutter SDK repo's own development sample (`spec/app-identity.json`,
2026-09-17 ruling) — a device holds one of the two at a time, so install one at a time. `APP_ID`
is passed explicitly rather than defaulted because the debug variant suffixes its application id
while both variants claim the same URL scheme, so a deep link with both installed raises a chooser
and the run hangs on a dialog no flow asserts.

**On an emulator, disable the keyguard first** (`adb shell locksettings set-disabled true`).

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

**The SDK.** Nothing here is consumption evidence yet: `usesmileid` is declared in
`flutter/app/pubspec.yaml` and imported by no Dart file, so the release APK this lane builds
contains no call into it and there is no `si_*` id to assert. The release configuration still
catches a shrink or a tree shake that breaks the app, and the launch still runs plugin
registration — but a green here says nothing about the published SDK until the flow host lands.

**Dark mode's appearance, and layout.** The testing contract forbids screenshot and coordinate
assertions inside a device flow, so both stay golden-lane concerns.

**The SDK flow itself.** `/flow/:productId/run` is claimed by no route yet.

**The scenario drawer's last two theme rows.** The floating nav bar is drawn over the bottom of
the sheet and eats their taps — a defect, recorded in `docs/plan/port-priority-cut.md` item 8, not
a limit of the lane.
