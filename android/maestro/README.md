# Android device flows

```bash
maestro --device <serial> test -e APP_ID=com.usesmileid.sampleapps.android.debug android/maestro
maestro --device <serial> test -e APP_ID=com.usesmileid.sampleapps.android       android/maestro
```

Both variants must pass. Release is the one that matters most — it is minified and resource-shrunk
with no app-side keep rules, which is where a consumption defect in the published SDK surfaces.

## Traps

**The first cold start after `adb install` outlives Maestro's default timeout.** ART warms the
minified release APK on its very first launch, and every flow failed spuriously on its opening
assertion until a warm relaunch. Each flow therefore opens with `runFlow: subflows/warm-start.yaml`
— a 120 s wait on the products root, defined once so a new flow cannot forget it; later assertions
keep the default timeout, so a missing screen still fails fast. `subflows/` is a subdirectory
deliberately: folder runs are non-recursive, so it never executes as a flow of its own.

**`APP_ID` has no default, deliberately.** In Maestro 2.8 a flow-level `env:` default WINS over `-e`
on the command line, so declaring one here would silently pin every run to a single variant and the
release lane would quietly test the debug build.

**Install one variant at a time.** Debug and release share the URL scheme — `debugSuffix` separates
the application ids, but the scheme is declared in the shared manifest. With both installed, a deep
link resolves to `android/com.android.internal.app.ResolverActivity` and the run hangs on a chooser
no flow asserts. Verified on a device; see `spec/app-identity.json` → `rationale`.

**An `offline` device in `adb devices` makes Maestro see NO Android devices at all.** It reports
`You have 0 devices connected` / `<serial> was requested, but it is not connected`, which reads like
a Maestro or serial-format problem and is not. Here the offline entry was a hung Gradle
managed-device emulator belonging to an unrelated project. Clear it before blaming anything else:

```bash
adb devices | grep offline        # if this matches, fix it first
pkill -9 -f qemu-system-aarch64   # or stop whatever owns the emulator
adb kill-server && adb start-server
```

**Some OEM builds refuse the shell commands flows usually lean on.** On ColorOS both fail with a
`SecurityException` — `pm clear` wants `CLEAR_APP_USER_DATA`, `settings put` wants `WRITE_SETTINGS`:

- `clearState` is unusable. Use `stopApp` and keep flows independent of persisted state.
- Rotation and font scale cannot be forced from the shell.

What does work:

```bash
adb shell cmd uimode night yes|no   # dark mode, and it drives activity recreation
```

For font scale, use the component gallery's own override
(`usesmileid-sample-android://debug/components`) rather than system settings — that is why it exists.

**The camera permission prompt is part of the SDK journey, and it cannot be pre-granted here.**
`sdk-flow` drives past the SDK's consent screen, and the SDK asks for camera permission on the way
to instructions. ColorOS refuses `pm grant` (`SecurityException: Neither user 2000 nor current
process has GRANT_RUNTIME_PERMISSIONS`), so Maestro's `launchApp: permissions:` cannot help and the
prompt is answered on screen. Two consequences:

- The tap is wrapped in `runFlow: when: visible:` because the grant **outlives both `stopApp` and
  the install**. An unconditional tap passes on a fresh install and fails every run after it.
- **A run aborted at the prompt leaves the dialog up, and it survives `stopApp`** — the dialog
  belongs to `com.android.permissioncontroller`, not to the app. The next run then fails on its
  *opening* assertion, which reads like a regression in the app and is not. Clear it first:

```bash
adb -s <serial> shell input keyevent KEYCODE_BACK   # dismisses without granting
adb -s <serial> shell dumpsys activity activities | grep mResumedActivity
```
