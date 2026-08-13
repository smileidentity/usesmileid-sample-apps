# Android device flows

```bash
maestro --device <serial> test -e APP_ID=com.usesmileid.sampleapps.android.debug android/maestro
maestro --device <serial> test -e APP_ID=com.usesmileid.sampleapps.android       android/maestro
```

Both variants must pass. Release is the one that matters most — it is minified and resource-shrunk
with no app-side keep rules, which is where a consumption defect in the published SDK surfaces.

## Traps

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
