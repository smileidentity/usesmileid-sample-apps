# Android device flows

```bash
maestro --device <serial> test -e APP_ID=com.usesmileid.sample.android.debug android/maestro
maestro --device <serial> test -e APP_ID=com.usesmileid.sample.android       android/maestro
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

**A populated verifications list is a precondition you have to ask for.** The app seeds no rows — a
stored row claims a verification was submitted, and the eleven design fixtures never were — and no UI
path creates one without a successful submission, which needs a real token and a valid sandbox
identity. So a flow that taps `sample_job_row_0`, or covers the filters, select mode or removal, opens
with `launchApp: arguments: seedJobs: true`. Seed once per file: the rows are in Room, so they survive
the `stopApp`s that follow, and re-seeding is a no-op because the rows are keyed by job id. `deep-links`
has no `launchApp` of its own, so it takes a seeded launch first and then starts deep-linking.

**The design's three profiles are a precondition too, and they are never stored.** A plain launch has
no profile: the active profile's organisation is what the SDK's consent screen shows as the partner, so
the fixtures never ship by default. A flow that asserts on `Kwame Asante · active` or
`sample_profile_row_p-4` opens with `launchApp: arguments: seedProfiles: true`, and does so on every
launch that needs them, unlike `seedJobs`: a seeded launch holds them in memory only, so a `stopApp` or
a cold start by link returns to what the device stored.

**A flow that types user details stores nothing.** The form's save switch ships on and would keep what
was typed as a profile, which then prefills the next pass (`inputText` appends) and outlives the run,
since `clearState` is unusable. So every such flow runs `subflows/keep-nothing.yaml` before Continue.

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

**The camera permission prompt is part of the SDK journey, and it cannot be pre-granted here.** The
SDK asks for it between consent and instructions. ColorOS refuses `pm grant` (`SecurityException:
Neither user 2000 nor current process has GRANT_RUNTIME_PERMISSIONS`), so `launchApp: permissions:`
cannot help and `sdk-flow` answers the prompt on screen. Two consequences:

- The tap is wrapped in `runFlow: when: visible:` because the grant **outlives both `stopApp` and
  the install**. An unconditional tap passes on a fresh install and fails every run after it.
- **A run aborted at the prompt leaves the dialog up, and it survives `stopApp`** — the dialog
  belongs to `com.android.permissioncontroller`. The next run then fails on its *opening* assertion,
  which reads like an app regression and is not. Clear it first:

```bash
adb -s <serial> shell input keyevent KEYCODE_BACK   # dismisses without granting
adb -s <serial> shell dumpsys activity activities | grep mResumedActivity
```
