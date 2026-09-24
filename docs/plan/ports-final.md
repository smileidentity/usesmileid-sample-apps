# Flutter and Expo ports: the final branch

**Status:** F1–F7 built 2026-09-24, on `feat/ports-final`; device pass and runner-recorded goldens owed (§4). One branch, one PR, both ports. It closes what
`token-session-ports.md` §6, `after-the-ports.md` Phase 4 and `port-priority-cut.md` §2 still list as
owed, after each item was re-checked against `main` at `0a8438eb`.

**Done means:** every product runs end to end on both ports with a result card a device flow can read,
nothing a user can tap does nothing, and the release build has been driven on a handset.

## 1. Confirmed open, in build order

| # | Item | Evidence on `main` | Work | Size | Status |
|---|---|---|---|---|---|
| F1 | **Result card** on both ports | Only the model exists (`flutter/sample_ui/lib/src/model/use_smileid_sample_result.dart`, `expo/sample-ui/src/model/use-smile-id-sample-result.ts`); no widget. iOS: `ios/SampleUI/Sources/SampleUI/Components/UseSmileIDSampleResultCard.swift` | Component per `spec/result-card.schema.json` + `spec/components.json` `ResultCard`, gated by the `probes` launch argument; flow host records each callback; goldens light/dark; the device flow asserts exactly one terminal result | M | built; goldens from the runner |
| F2 | **Profile callback URL** on both ports | Both hosts pass `callbackUrl: ''` (`flutter/app/lib/src/screens/use_smileid_sample_sdk_flow_tab.dart:152`, `expo/app/app/flow/[productId]/run.tsx:80`) | Profile field + the same build-time validation Android and iOS got in #118; the launch snapshot reads the active profile's value; a scanned session still wins | M | built |
| F3 | **Flutter link rows do nothing** | `_openNavRow` handles only `url == null` (`use_smileid_sample_settings_tab.dart`) | Open the URL with `url_launcher` (new dependency, approved 2026-09-24) | S | built |
| F4 | **Expo copy buttons are no-ops** | `onCopy={() => undefined}` at `expo/app/app/(tabs)/verifications/[jobId].tsx:71` | `Clipboard.setStringAsync`; `expo-clipboard` is already a dependency | S | built |
| F5 | **Flutter release APK is 116.6 MB** | No split or bundle config in `flutter/app/android` | ABI splits or an app bundle, per the Android ruling of 2026-08-27 | S | built — arm64 45.2 MB |
| F6 | **Android hashes the untrimmed token** for the handle | `android/sample-ui/.../UseSmileIDSampleTokenDecoder.kt:138` | Trim before `digest()`, plus a test that pads a token | S | built |
| F7 | **`holdCamera`** is parsed but has no consumer on either port | `use_smileid_sample_launch_args.dart`, `use-smile-id-sample-launch-args.ts` | **Close unfixed** (approved 2026-09-24): neither scanner package can bind a camera that outlives its view, and no lane needs it. Record the reason in `token-session-ports.md` §6 | S | closed |

## 2. Re-check, then fix or close

Verdicts from the code, 2026-09-24:

| Item | Verdict |
|---|---|
| Expo never loads the job store on a cold link | **Fixed here**: a cold link to `/verifications/:jobId` showed "No verification here" for a stored job, because only the list loaded the store. The details route loads it itself; the test failed first. |
| AsyncStorage failures unhandled | **Fixed here**: an unreadable store now reads as empty instead of leaving the list loading, and a failed write keeps the row for the launch. Both tests failed first. |
| Expo empty-state copy | **Fixed here**: now "No verifications yet" / "Nothing {filter}", as Android, iOS and Flutter say. |
| A settings write during the load window is undone | **Fixed here**: a toggle made while the stored values were being read kept its new value on disk but reverted on screen. Moved settings now survive the read, and an unreadable store still reports loaded. Both tests failed first. Flutter reads settings before the first frame, so it has no window. |
| `continueEnabled` ignores its test id | Fixed on `main`: the prop no longer exists. |
| Four Expo weight overrides bypass `atWeight` | Fixed on `main`: no `fontWeight` literal remains. |
| Flutter pickers partial against `fullSheet` | Fixed on `main`: pickers use the full-sheet helper. |
| `WidgetRef` used across an await | **Closed, not reproducible**: a delete whose write outlives the page completes cleanly on the old code, so no test can fail on it. |
| Notice overlay `width: '100%'` (C8) | **Closed**: it spans the same box as `left: 0, right: 0` when absolutely positioned, and the change would only churn snapshots. |
| Flutter cold link paints the empty state first | **Fixed here**, on Expo too: the page now waits for the store instead of claiming "No verification here" for a job it has not read. |
| Profile store reset a second time when the cold-start link resolves | **Fixed here** (Expo): the store is built once, from the link's own arguments. Flutter builds it once from a provider already. |
| The wrapped profile row drops the selected check | **Fixed here** (Flutter): both layouts draw one trailing mark. Expo has a single layout. |
| Two sources of truth for the four field labels | **Fixed here**: each port takes every label from its field spec, which holds the title once. No rendered text moved. |
| `sample_job_row_N` indexing | **Fixed here**: Expo numbered rows by store position, so a filter gave it different ids from the other three. It now numbers the list as drawn, and `spec/test-ids.json` says so. |
| The nine tests that cannot fail | **All fixed or confirmed**, each proved by breaking the code it names: the settings-footer test now reads the shipped footer (and found `screens.json` still carrying the superseded wording); the test-id spec test asserts both directions on Flutter and Android (and found two ids missing from Flutter's catalogue); the URL-scheme test asserts "only that one"; the 23-hour-day test runs in a zone with a clock change (and found the bug live on Flutter, Expo and Android); the cold-start link test was already fixed on `main`; the Expo filter-fallback, go-pill, licence and theme-provider tests now fail without the behaviour they name. Flutter's filter-fallback and licence tests could already fail. |
| SDK findings for the Flutter repo | Drafted, not filed: two missing `si_*` ids, `validate()` weaker than `build()` with a silent blank frame, and no document analyzer. |

## 3. Out of scope: owner rulings

These stay out of this branch until decided (`after-the-ports.md` Phase 1): whether profile defaults
seed the job form, whether "remember these details" saves anything, the active-profile edit, button
48 vs 52, glyph 21 vs 20, and the two shell ids.

## 4. Verification

- `flutter/verify.sh` and `expo` gates green. Goldens recorded on the runner, never on a Mac: the
  new result-card states and the moved profile-config and empty-list baselines come from the
  `flutter-goldens-recorded` and `expo-goldens-recorded` artifacts.
- Flutter's 2x predicate caught the callback row's placeholder clipping; the edit row now lets a
  hint wrap. Expo has no layout engine under jest, so its profile page at max text size is a device check.
- Device pass on the Oppo and the iPhone, release builds, covering this branch **and** #127's
  review-fix builds, which were only unit-tested. Ask which environment before scanning a token.
- The Expo storage-key rename in #127 drops a stored session on reinstall. Note it in the PR; there is no
  released build to migrate.
