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
confirm with `tools/verify/foreground.sh <serial> com.usesmileid.sample.expo`.

**On an emulator, disable the keyguard first** (`adb shell locksettings set-disabled true`). A device
that locks mid-session fails the opening assertion against lock-screen content, which reads as an
ordinary assertion failure rather than as infrastructure.

**`uiautomator dump` is unreliable on the ColorOS handset** — it is killed silently and serves
whatever a previous run left at that path. Maestro drives its own on-device driver and is unaffected,
which is a second reason the contract routes id assertions through it rather than through a dump.

## What this lane does not cover

Dark mode's appearance. The testing contract forbids screenshot and coordinate assertions inside a
device flow, and a theme change carries no id-based signal, so it stays a golden-lane concern.
