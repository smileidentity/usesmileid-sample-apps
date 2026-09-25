---
description: How the sample apps run a verification from a v3 token instead of an API key — what the token carries, what the app reads from it, which steps it lets the app skip, and how expiry is handled.
---

# Token sessions

A partner app never ships an API key. Its backend mints a short-lived **v3 token** (`POST /v3/token`)
and hands it to the app, and the SDK runs the verification with that token. The sample apps show the
same thing end to end: you link a session by scanning or pasting a token, and every run until it
expires uses it.

The SDK decides what a token allows, and the app follows. This page explains the app's side of that:
what it reads, what it skips, and why.

## Prerequisites

- Any of the four apps, built from this repository.
- A v3 token. Use one your backend mints, one shown as a QR code in the Smile ID Portal, or none:
  **Simulate a successful scan** on the scan sheet mints a synthetic token, so every screen on this page
  is reachable without a real partner.

## 1. Link a session

Open the scan sheet from the products screen, then:

- **Scan** a QR code that encodes the raw JWT. The QR holds the token itself, not a URL or JSON.
- **Paste** or type the token.
- **Simulate** a scan with a fixture token. It is marked as simulated, and no real partner exists behind it.

The app decodes the token and refuses it if the segments, `iat`/`exp` or `api_url` do not read. The
refusal names the claim that failed, never a value.

## 2. What the app reads from the token

| Claim | What the app does with it |
|---|---|
| `exp`, `iat` | The countdown. `exp − iat` is the session's full length, so the ring is honest for a 15-minute token and an 8-hour one alike |
| `partner_id` | The partner every job runs as. It wins over the active profile's partner id |
| `api_url` | **The environment.** The app parses the URL's **host** and maps `testapi.smileidentity.com` to sandbox and `api.smileidentity.com` to production. A whole-string comparison fails on a real token, which carries a `/v3` path. A token with no `api_url`, or an unknown host, is refused rather than defaulted, because a silent sandbox fallback sends a production token to the wrong host and fails later as an unexplained 401 |
| `payload` user details | **Presence only.** Name, email, phone and ID number arrive as opaque vault references, never the values. The app can learn that a field is bound, never what it is. Only `country` and `id_type` are plaintext |
| `payload` consent | All or nothing. A partial consent object is a malformed token, not a partial relaxation |

So **nothing can be prefilled from a token.** A form shows a bound field as *Provided by token*, not
as a value.

## 3. What the token lets the app skip

The SDK relaxes two things for a token that binds them: the user details it would otherwise require,
and its own consent screen. It never relaxes the ID parameters. The app mirrors that in one pure function
per platform (`TokenBindingRules`), so all four decide identically:

| The token binds | Host user-details form | SDK consent screen | Builder `userDetails` |
|---|---|---|---|
| consent and all required user details | skipped | omitted | `null` |
| consent only | shown | omitted | collected values |
| all required user details only | skipped | shown | `null` |
| nothing | shown | shown | collected values |
| consent and some user details | shown, only the gap editable | omitted | collected values |
| some user details only | shown, only the gap editable | shown | collected values |
| part of the consent object | the run does not start, and the app names the missing fields | — | — |

The SDK's user-details rule is **both names plus one contact** (email or phone). The app subtracts
whatever the token binds from that rule. So a token with both names but no contact still asks for a
contact, and a bound email does not grey out the phone row.

**Pass `null`, never blanks, for bound fields.** Blank strings silence the SDK's own per-field errors.

**The ID form follows its own rule.** It is skipped only when the product needs ID details *and* the
token binds all of them (`country`, `id_type`, and the ID number reference). A partial ID binding still
shows the form, and the token's values override what is typed, because the server overwrites them from
the token anyway. Document Verification needs both `country` and `id_type` bound, because the form is
where the document type is chosen.

With everything bound, a product tap goes straight into the SDK. For Enhanced KYC that means landing on
the processing screen, which looks abrupt and is correct: there is nothing left to ask.

## 4. Expiry

- **The gate runs before every flow.** An expired session sends the run to the scanner rather than to a
  form, and says why. A fresh scan resumes the run it interrupted.
- **Refreshing a stored job matches the partner, not the session.** A status read works with any
  session token of the same environment, and fails across environments with a 401. So a new session for
  the same partner can still refresh the jobs an expired one created.

## 5. Keeping the token safe

The token is a live bearer credential minted against a real API key.

- It is never logged, and never in a crash report, an error message, a test artifact or a view with a
  test id (device flows dump the view hierarchy on failure).
- The result card shows the session handle and the time left, never the token or a prefix of it.
- Fixture tokens are synthetic and unsigned. A real token is never committed.

Where each app stores the session:

| Platform | Storage |
|---|---|
| Android | DataStore, with `android:allowBackup="false"` |
| iOS | Keychain, `WhenUnlockedThisDeviceOnly` |
| Flutter | `flutter_secure_storage` (Keychain on iOS, Keystore-backed on Android) |
| Expo | `expo-secure-store`, device-only |

## Where the code is

| | Android | iOS | Flutter | Expo |
|---|---|---|---|---|
| Decode the token | `sample-ui/…/state/UseSmileIDSampleTokenDecoder.kt` | `SampleUI/…/State/UseSmileIDSampleTokenDecoder.swift` | `sample_ui/lib/src/state/use_smileid_sample_token_decoder.dart` | `sample-ui/src/state/use-smile-id-sample-token-decoder.ts` |
| Binding rules | `app/…/flow/TokenBindingRules.kt` | `App/Sources/Flow/TokenBindingRules.swift` | `app/lib/src/flow/use_smileid_sample_token_binding_rules.dart` | `app/src/flow/use-smile-id-sample-token-binding-rules.ts` |
| The expiry gate | `app/…/flow/FlowPreflight.kt` | `App/Sources/Flow/FlowPreflight.swift` | `app/lib/src/flow/use_smileid_sample_flow_preflight.dart` | `app/src/flow/use-smile-id-sample-flow-preflight.ts` |
| QR scanner | `app/…/scan/UseSmileIDSampleQrScanner.kt` (CameraX, bundled ML Kit) | `App/Sources/Scan/UseSmileIDSampleQrScanner.swift` | `app/lib/src/scan/use_smileid_sample_qr_scanner.dart` (`mobile_scanner`) | `app/src/scan/use-smile-id-sample-qr-scanner.tsx` (`expo-camera`) |
| Simulate | `app/…/flow/UseSmileIDSampleFlowTokens.kt` | `App/Sources/Flow/UseSmileIDSampleFlowTokens.swift` | `app/lib/src/flow/use_smileid_sample_flow_tokens.dart` | `app/src/flow/use-smile-id-sample-flow-tokens.ts` |

The scanner lives in each app's shell, not in `sample-ui`. The SDK owns capture, so the shared UI adds
no camera of its own.

## Verify your integration

- [ ] A token with no `api_url`, or an unknown host, is refused with a message naming the claim.
- [ ] A fully bound token takes a product tap straight into the SDK, with no host forms.
- [ ] A token binding both names but no contact still asks for a contact.
- [ ] An expired session sends the next run to the scanner, and a fresh scan resumes it.
- [ ] Nothing in logs, the result card or the view hierarchy contains the token.

## Common issues

| Symptom | Cause | Fix | Seen on |
|---|---|---|---|
| Every job 401s after linking a production token | The environment was derived from a setting or a string comparison of `api_url`, not its host | Map the parsed host, and refuse unknown hosts | SDK 12.0.x |
| The app asks for a name the token already bound | The form ignored the bindings | Subtract the bindings from the SDK's rule, and pass `null` for bound fields | SDK 12.0.x |
| Continue is enabled, then the SDK refuses the build for a missing contact | The form's rule was "first and last name", not the SDK's "both names plus one contact" | Use the SDK's rule | SDK 12.0.x |
| A run returns to the product list with no explanation | The token carries part of the consent object | Report the SDK's message naming the missing consent fields | SDK 12.0.x |
| Jobs from an expired session can no longer be refreshed | The refresh guard matched on the session, not the partner | Match on `partner_id`, and scope by environment | SDK 12.0.x |

## Next step

[`docs/architecture.md`](architecture.md) shows where the flow host sits in each app, and
[`docs/testing.md`](testing.md) how the token states are tested without a real token.
