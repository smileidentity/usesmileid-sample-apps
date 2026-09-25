# Expo device flows

```bash
maestro --device <serial> test -e APP_ID=com.usesmileid.sample.expo expo/maestro
```

Run against the release APK, which is minified and resource-shrunk with no app-side keep rules —
where a consumption defect in the published SDK surfaces. Build it with the bundle forced, because a
release APK can otherwise ship the previous JS even when the build says it rebuilt one:

```bash
cd expo/app/android && ./gradlew :app:createBundleReleaseJsAndAssets --rerun :app:assembleRelease \
  -Pandroid.enableMinifyInReleaseBuilds=true -Pandroid.enableShrinkResourcesInReleaseBuilds=true
```

## Traps

**Launch arguments arrive as a LINK here, not as intent extras.** The shell reads them once from
`Linking.getInitialURL()` at cold start, so Maestro's `launchApp: arguments:` — which the Android
twin uses — is ignored entirely and every argument silently takes its default. Use
`openLink: "usesmileid-sample-expo://?seedJobs=true"` after a `stopApp`, or the link reaches a live
app and the hook, by design, refuses to re-seed from it.

**The first cold start after an install outlives Maestro's default timeout** while ART warms the
minified APK, so every flow opens with `runFlow: subflows/warm-start.yaml`.

**Four sibling sample apps implement the same `sample_*` ids** and render the same SDK screens, so a
leftover sibling in the foreground can satisfy an assertion meant for this app. Force-stop them and
confirm with `adb -s <serial> shell dumpsys activity activities | grep -m1 topResumedActivity`.

**On an emulator, disable the keyguard first** (`adb shell locksettings set-disabled true`), and hide
error dialogs (`adb shell settings put global hide_error_dialogs 1`). A device that locks mid-session
fails the opening assertion against lock-screen content, and a SystemUI "isn't responding" dialog sits
over the app and fails it the same way — both read as an ordinary assertion failure rather than as
infrastructure. Two `main` runs died on the second of those with the app already `Displayed` in
logcat. Hiding error dialogs hides this app's crash dialog too, not its evidence: a red whose app
crashed carries `logs/crash-report.txt` beside `device-logcat.txt`.

**The undo offer is a race, so the flow widens the window.** `noticeWindow` exists for this: the
product window is short enough not to outlive its cause, and on a loaded runner Maestro's first
hierarchy poll after `Hide from List` landed after the toast had dismissed itself. The offer is
consumed on dismissal, so there is no second chance to retry.

**Each ML provider resolves its native module at import time**, so importing the other platform's
takes the whole JS bundle down — the app exits to the launcher with no crash log and only a single
`ReactNativeJS: Cannot find native module …` line. The flow host requires the platform's provider
rather than importing both, and `sdk-flow.yaml`'s cold link at `/flow/:productId/run` is what
catches a regression: it is the only assertion that loads that import graph.

**One emulator stopped reporting any app's hierarchy once a text field was focused**, and did not
recover when the keyboard closed — `uiautomator` still saw every field. It hit the Flutter sample
too, and `main`'s own APK, so it was that machine rather than either app; the same flows type
correctly on a handset. `sdk-flow.yaml` reaches the flow host by a cold link rather than by filling
the form, which needs no keyboard at all and so cannot meet it. `hideKeyboard` is a back press on
Android and will pop the route when the keyboard is already down.

**`uiautomator dump` is unreliable on the ColorOS handset** — it is killed silently and serves
whatever a previous run left at that path. Maestro drives its own on-device driver and is unaffected,
which is a second reason the contract routes id assertions through it rather than through a dump.

## What this lane does not cover

Dark mode's appearance. The testing contract forbids screenshot and coordinate assertions inside a
device flow, and a theme change carries no id-based signal, so it stays a golden-lane concern.
