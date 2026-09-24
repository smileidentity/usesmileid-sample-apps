# Flutter and Expo ports: the final branch

**Status:** proposed 2026-09-24, on `feat/ports-final`. One branch, one PR, both ports. It closes what
`token-session-ports.md` §6, `after-the-ports.md` Phase 4 and `port-priority-cut.md` §2 still list as
owed, after each item was re-checked against `main` at `0a8438eb`.

**Done means:** every product runs end to end on both ports with a result card a device flow can read,
nothing a user can tap does nothing, and the release build has been driven on a handset.

## 1. Confirmed open, in build order

| # | Item | Evidence on `main` | Work | Size |
|---|---|---|---|---|
| F1 | **Result card** on both ports | Only the model exists (`flutter/sample_ui/lib/src/model/use_smileid_sample_result.dart`, `expo/sample-ui/src/model/use-smile-id-sample-result.ts`); no widget. iOS: `ios/SampleUI/Sources/SampleUI/Components/UseSmileIDSampleResultCard.swift` | Component per `spec/result-card.schema.json` + `spec/components.json` `ResultCard`, gated by the `probes` launch argument; flow host records each callback; goldens light/dark; the device flow asserts exactly one terminal result | M |
| F2 | **Profile callback URL** on both ports | Both hosts pass `callbackUrl: ''` (`flutter/app/lib/src/screens/use_smileid_sample_sdk_flow_tab.dart:152`, `expo/app/app/flow/[productId]/run.tsx:80`) | Profile field + the same build-time validation Android and iOS got in #118; the launch snapshot reads the active profile's value; a scanned session still wins | M |
| F3 | **Flutter link rows do nothing** | `_openNavRow` handles only `url == null` (`use_smileid_sample_settings_tab.dart`) | Open the URL with `url_launcher` (new dependency, approved 2026-09-24) | S |
| F4 | **Expo copy buttons are no-ops** | `onCopy={() => undefined}` at `expo/app/app/(tabs)/verifications/[jobId].tsx:71` | `Clipboard.setStringAsync`; `expo-clipboard` is already a dependency | S |
| F5 | **Flutter release APK is 116.6 MB** | No split or bundle config in `flutter/app/android` | ABI splits or an app bundle, per the Android ruling of 2026-08-27 | S |
| F6 | **Android hashes the untrimmed token** for the handle | `android/sample-ui/.../UseSmileIDSampleTokenDecoder.kt:138` | Trim before `digest()`, plus a test that pads a token | S |
| F7 | **`holdCamera`** is parsed but has no consumer on either port | `use_smileid_sample_launch_args.dart`, `use-smile-id-sample-launch-args.ts` | **Close unfixed** (approved 2026-09-24): neither scanner package can bind a camera that outlives its view, and no lane needs it. Record the reason in `token-session-ports.md` §6 | S |

## 2. Re-check, then fix or close

These come from `port-priority-cut.md` §2 and were not re-checked in code. Each gets a one-line
verdict in this doc before any work: fixed on `main`, fix here, or close with a reason.

- Cold start: Flutter paints the empty state first on a cold deep link; Expo never loads the store; the
  profile store resets twice; the settings store's `loaded` flag is never read.
- `WidgetRef` used across an await; AsyncStorage failures unhandled; `continueEnabled` ignores its test
  id; the wrapped profile-row layout drops the selected check.
- Two sources of truth for the four field labels.
- The nine asserted tests that cannot fail (`port-review-findings.md`).
- `sample_job_row_N` indexing on Expo, and its sentence in `spec/test-ids.json`.
- Expo empty-state copy, four weight overrides bypassing `atWeight`, Flutter pickers against `fullSheet`.
- The notice overlay's `width: '100%'` (C8).

Already fixed on `main`, so not in scope: sign-out on both ports, Flutter's DEBUG section (debug builds
only), the Flutter profile sheet routes, and Expo's dark mode, `seedJobs` and `noticeWindow` wiring.

## 3. Out of scope: owner rulings

These stay out of this branch until decided (`after-the-ports.md` Phase 1): whether profile defaults
seed the job form, whether "remember these details" saves anything, the active-profile edit, button
48 vs 52, glyph 21 vs 20, and the two shell ids.

## 4. Verification

- `flutter/verify.sh` and `expo` gates green. Goldens recorded on the runner, never on a Mac.
- Device pass on the Oppo and the iPhone, release builds, covering this branch **and** #127's
  review-fix builds, which were only unit-tested. Ask which environment before scanning a token.
- The Expo storage-key rename in #127 drops a stored session on reinstall. Note it in the PR; there is no
  released build to migrate.
