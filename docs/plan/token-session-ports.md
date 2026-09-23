# Token session — Flutter and Expo, from a scanned QR to a submitted job

**Status:** built on both ports, 2026-09-23. Each app now links a session by QR, by pasted or typed
token, or by Simulate; runs every product under it; states how long it has left; retires it at its
deadline; sends a run the gate stopped to the scanner with the reason; and resumes that run when a
fresh session links. Both host forms are skipped when the token carries what they collect.
`token-session-android.md` is the reference for behaviour and layout, and
`token-binding-matrix-android.md` for what the bindings decide. This document records only what the
ports did differently, and why.

**The one-line goal:** the Android token session, on Flutter and Expo, with no behaviour a partner
could tell apart and the storage split iOS already made.

---

## 1. The work, against the Android items

| Android item | Flutter | Expo |
|---|---|---|
| TOK-A1 manual entry, paste, Simulate minting | built | built |
| TOK-A2 decode | `use_smileid_sample_token_decoder.dart` | `use-smile-id-sample-token-decoder.ts` |
| TOK-A3 session model | `use_smileid_sample_token_session.dart` | `use-smile-id-sample-token-session.ts` |
| TOK-A4 builder handoff | `use_smileid_sample_flow_builder_config.dart` | `use-smile-id-sample-flow-builder-config.tsx` |
| TOK-A5 the gate | `use_smileid_sample_flow_preflight.dart` | `use-smile-id-sample-flow-preflight.ts` |
| TOK-A6 honest countdown | built | built |
| TOK-A7 persisted jobs | already on `main` | already on `main` |
| TOK-A8 device coverage | `flutter/maestro/token-session.yaml` | `expo/maestro/token-session.yaml` |
| TOK-A9 the scanner | `mobile_scanner`, in the shell | `expo-camera`, in the shell |
| TOK-A10 | deleted on Android as unreachable; not ported | not ported |
| TOK-A11 redirect reason and resume | built | built |
| TOK-A12 `holdCamera` | **not built** (§6) | **not built** (§6) |
| ENV-A1 environment from `api_url` | built | built |

Everything in `token-session-android.md` §9 holds on both ports: bound user details are known by
presence only, consent is readable, a complete consent binding drops the consent screen, the ID
parameters are never relaxed by the SDK, and the ID number travels as its vault reference and is
never shown as a number.

## 2. `flowPlan` exists on the ports, and not yet on Android

`token-binding-matrix-android.md` §4 proposed one pure function in place of the five call sites that
each re-derived part of the binding decision. Android and iOS still spread that decision across the
journey, the builder config and the preflight. Both ports build the function the document describes,
with the same four fields (`userDetailsGap`, `showIdDetailsForm`, `declareConsentScreen`,
`passUserDetails`), and both enumerate the §7 truth table in full: three consent shapes, four
user-detail shapes and all six products. So the ports are ahead of the reference here. Android and
iOS owe the same refactor, and the ports' tests are the table they should pass.

## 3. Where the session lives

`port-patterns.md` left this as "the port's call, same rule". Both ports took the iOS split: the token
is a bearer credential and goes to the platform's secure store, and the switches are preferences.

| | Token session | Settings |
|---|---|---|
| Flutter | `flutter_secure_storage` — Keychain on iOS, Keystore-backed on Android | `shared_preferences` |
| Expo | `expo-secure-store`, device-only as on iOS | AsyncStorage |

What each port holds to, from the same table:

- **One record.** The token is the whole record. The handle, `iat`, `exp`, partner, environment and
  bindings all decode from it, so nothing is stored beside it that could disagree with it.
- **Retirement deletes the credential.** At the deadline the token is replaced by a marker holding
  only the handle and the deadline, as on Android (`token-session-android.md` §TOK-A5). A cold start
  after expiry takes the same path.
- **Expo holds first paint until the stored session loads.** A cold link into `/flow/:productId/run`
  therefore cannot take its entry snapshot before the token is read.

The dependencies, all four approved before they were added:

| Port | Scanner | Secure store | Clipboard |
|---|---|---|---|
| Flutter | `mobile_scanner` — bundled ML Kit on Android, Apple Vision on iOS, so no ML Kit pod | `flutter_secure_storage` | Flutter's own `Clipboard` |
| Expo | `expo-camera`, first-party and versioned with the Expo SDK | `expo-secure-store`, likewise | `expo-clipboard`, likewise |

## 4. The scanner

The scanner is the shell's, never `sample-ui`'s, which stays identity-agnostic and, on Expo, free of
native imports. The shell injects the preview into the scan screen.

- **Analysis resolution.** Android's scan-reliability gate failed because CameraX defaulted to
  640×480 (`token-session-android.md` §8). `mobile_scanner` has the same default on Android, so
  Flutter pins 1920×1080; the pin only takes effect on Android. `expo-camera`'s barcode analysis
  already asks for the highest resolution, so Expo needed nothing.
- **Releasing the camera is a host invariant.** Shown on the Oppo for Flutter with
  `dumpsys media.camera`: the scanner held back camera 0 and released it, then the SDK's selfie
  capture opened front camera 1 in the same process.
- **CameraX on Expo.** `expo-camera` declares CameraX 1.6.0 and the SDK brings 1.6.1. Gradle resolves
  1.6.1, so the scanner runs on the SDK's version, which is the direction Android pins on purpose.
- **Permissions.** Flutter's iOS `Info.plist` had no `NSCameraUsageDescription` at all. That was a
  latent crash for the SDK's own capture on iOS, which nothing had reached yet; it now has iOS's
  wording, and the Android manifest declares `CAMERA` with `camera.any` not required.

## 5. Divergences, each deliberate

- **The session card names no field groups.** `token-session-android.md` §4.2 said the card reads
  `Supplies name, contact, ID`. Android's card has not drawn that line since the composites pass, and
  neither has iOS's, so the ports follow the code. §4.2 is corrected in place. What still makes a
  skipped form visible is the `Provided by token` row on any form that does appear.
- **Expo pins our presence flags to the SDK.** The React Native SDK exports its token decoder, which
  the Android SDK does not. The ports keep their own decoder, for parity and for the claims the SDK
  does not model (`country`, `id_type`, `id_number`, `api_url`, `partner_id`). An Expo test asserts
  that our presence flags equal `decodeSmileIDToken(...).tokenPayload`, so the SDK cannot move its
  rules under us unnoticed.
- **Both ports compute the handle digest themselves.** Flutter in `sample_ui` and Expo in
  `use-smile-id-sample-token-bytes.ts`, the latter with its own base64url and UTF-8 too, because
  `sample-ui` has no native imports. A short SHA-256, checked against the standard test vector, rather
  than declaring a crypto package for one call.
- **Flutter's status refresh is real now.** The detail page's refresh used a stub that always
  reported no session. It is now a `GET /v3/status` source on `dart:io`'s `HttpClient`, so there is
  no HTTP package. It refreshes when the partner ids match (`port-patterns.md` §5).
- **Flutter's Sign out does something.** It was inert. It now clears the session and the forms and
  returns to Products, as Android's does.

## 6. Not built, and why

- **`holdCamera`** has no consumer on either port. On Android it counts frames delivered to a
  host-bound analyser alongside the SDK's own camera (`token-session-android.md` §7.1). Neither
  scanner package exposes a bind that outlives its own view, so a port would need a host camera
  session of its own. Owed if the argument earns a device lane.
- **A result card** still exists on neither port (`after-the-ports.md` Phase 4). So "exactly one
  terminal result" is observable only as where the run lands.
- **Flutter's release APK is 116.6 MB.** Bundled ML Kit ships a native library per ABI, and the APK
  packages four. Android's owner ruling of 2026-08-27 (ABI splits or an app bundle) applies here too,
  and is owed.

## 7. Testing

- **Unit, on both ports:** the decoder against the same fixture cases Android and iOS use
  (`granted: false` is not a binding, a non-string is not a binding, an empty consent object is no
  consent, and malformed, unsigned or `exp`-less tokens are rejected at entry); the environment host
  map; the handle; retirement; the countdown and progress at 15m, 1h and 8h; the `flowPlan` truth
  table; and the session record's link, retire and clear semantics, including a retirement racing a
  fresh link. The stores run against in-memory doubles, so which platform store holds the token is
  proven by the code and the device runs, not by a unit test.
- **Goldens, light and dark:** the scan screen in its default and redirected states, the scan status
  pill in each state, the expanded Simulate controls, and the user-details form with names bound.
  Flutter and Expo baselines come from the runner's `flutter-goldens-recorded` and
  `expo-goldens-recorded` artifacts, never from a Mac.
- **Device flows:** each port's `token-session.yaml` drives Simulate at 15m and 8h, the countdown,
  bound details skipping both host forms, Enhanced KYC under a consent-and-details binding landing on
  `si_processing_screen`, the ended banner, the expiry redirect with its reason, a relink resuming the
  interrupted run, and a deliberate scanner visit that explains nothing. They assert on `sample_*` and
  `si_*` ids only, never on the token. ColorOS refuses `clearState`, so on the Oppo each run started
  from a fresh install; the committed flows keep `clearState` for emulator lanes.

## 8. The device pass, 2026-09-23

**Real Portal token, end to end, on both ports and both phones.** An 8h production token binding
consent and every user-detail field was scanned from the Portal's QR into Flutter and Expo on the Oppo
(CPH2113, release) and the iPhone (14 Pro Max, signed release). Each ran Enhanced KYC to a stored job
reading **Clear · 200 OK · "Job completed" · production**. What only a real token could show:

- **The dense QR reads.** Flutter on the Oppo linked within five seconds of the scanner opening.
- **The countdown's hours part is right against a real `exp - iat`.** It read `7:55:21` minutes after
  minting.
- **Both host forms are skipped in practice.** The run went straight from Products to
  `si_processing_screen`: case 1 of `token-binding-matrix-android.md` §3.
- **The environment comes from `api_url`.** The job row records production, and no switch exists that
  could have said otherwise.
- **The status refresh works under a live session.** Pulling the detail page returned the verdict from
  `GET /v3/status`.
- **The SDKs hand back differently.** On iOS the React Native SDK ends on its own "Submission
  Complete" screen, which waits for Continue before returning to the host. Flutter returned
  straight to the job. Each is the SDK's own screen, and the host is correct either way.

**Same-device placement**, with `tools/verify/placement/`. The session card matches Android within
3 dp on the Oppo, and native iOS within 1 pt on the iPhone, on both ports. The scan screen did not match
at first. Both ports laid Paste out at its content size, so the manual-entry field came out 45 dp tall
against Android's 72, which made the preview taller and dropped the captions by about 20. Paste is now
laid out at the platform touch target (48 on Android, 44 on iOS; `port-patterns.md` §6 trap 14), and
the field, Paste, captions and Simulate now match on both phones. Native iOS tags the manual-entry
text rather than the whole field, which Android and both ports tag; the centres agree, so it is a
difference in which element carries the id, not in layout.

**Defects the pass found, all fixed on this branch:**

- **A retirement could overwrite a fresh link on Flutter.** A cold start with an expired live session
  stored let that session's zero-delay retirement race the first `link()`, and the retire write landed
  last, so a new Simulate read "Token session ended". Writes are now serialised, a retirement re-checks
  that its session is still the live one, and the session is read before the first frame. Expo had a
  close cousin: a stale retire could end a newer session. Both have tests that failed first.
- **The detail page's notice drew behind Android's navigation bar** on Flutter, which ignored the
  system inset. It now also reads Android's words, `Clear — Job completed`, rather than the message
  alone.
- **Two product-card mismatches beside Android.** Expo drew the arrow at the medium icon size; Flutter
  ran the card gradient left to right where Android and iOS run it corner to corner.
