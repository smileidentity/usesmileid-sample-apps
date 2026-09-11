# App Privacy — the answers, and why they are these answers

The App Privacy questionnaire lives in App Store Connect and has no file representation, so this is
the record of what to enter and what it was derived from. Fill it from this page rather than from
memory, and update this page in the same change as any behaviour that moves an answer.

This page and `ios/App/PrivacyInfo.xcprivacy` are two halves of one declaration: the manifest is what
the build ships, this is what a person types into the form. They must agree.

Verified 2026-09-11 against the v12 app as built.

## The answers

**Does this app collect data?** Yes.

| Data type | Collected | Linked to the user | Used for tracking | Purpose |
|---|---|---|---|---|
| Contact Info → Name | Yes | Yes | No | App Functionality |
| User Content → Photos or Videos | Yes | Yes | No | App Functionality |
| Sensitive Info | Yes | Yes | No | App Functionality |
| Identifiers → User ID | Yes | Yes | No | App Functionality |
| Identifiers → Device ID | Yes | No | No | App Functionality, Analytics |
| Usage Data → Product Interaction | Yes | No | No | Analytics |
| Diagnostics → Crash Data | Yes | No | No | App Functionality |
| Diagnostics → Performance Data | Yes | No | No | App Functionality |
| Diagnostics → Other Diagnostic Data | Yes | No | No | App Functionality |

**Tracking:** No. The app does not link its data to third-party data for advertising or a data
broker, and it does not use App Tracking Transparency because it has nothing to ask for.

## Why these are the answers

These are Play's answers, mapped rather than re-derived. The behaviour behind each one is the same on
both platforms — same SDK, same Sentry, same submission path — so `docs/play-data-safety.md` is the
source and this is the translation:

| Play data type | App Store equivalent |
|---|---|
| Personal info — Name | Contact Info → Name |
| Personal info — Other info (ID number, date of birth) | Sensitive Info, and Identifiers → User ID |
| Photos and videos — Photos | User Content → Photos or Videos |
| Device or other IDs | Identifiers → Device ID |
| App activity — Other actions | Usage Data → Product Interaction |
| App info and performance — Crash logs | Diagnostics → Crash Data |
| App info and performance — Diagnostics | Diagnostics → Performance Data, Other Diagnostic Data |

Three points worth keeping, because each is a place the answer could be got wrong.

**The selfie is Sensitive Info, not only a photo.** Apple's definition of sensitive information
includes biometric data, and the selfie is compared against a face rather than stored as a picture.
Declaring it only as Photos or Videos would understate what the app sends.

**The local job database is not a collection fact.** Apple asks about data transmitted off the
device. On-device storage that never egresses is outside the definition, exactly as it is outside
Play's. The verifications list is SwiftData on the device and has no cloud-backup path off it.

**The diagnostic rows are Sentry, and only Sentry.** They come from the SDK's bundled
`sentry-cocoa`, which declares them in its own privacy manifest. If Sentry is ever removed from the
SDK, the three Diagnostics rows and the Analytics purpose on Device ID stop being true and this page
has to change before the next release.

## What the privacy manifest declares, and what it deliberately does not

Xcode merges every dependency's `PrivacyInfo.xcprivacy` into the privacy report, so the app's own
manifest declares the app's own behaviour and repeats nobody.

| Package | Ships a manifest | Declares |
|---|---|---|
| `lottie-spm` 4.6.1 | yes | FileTimestamp (C617.1) |
| `sentry-cocoa` 9.26.1 | yes | UserDefaults (CA92.1), SystemBootTime (35F9.1), FileTimestamp (C617.1); crash, performance and diagnostic data |
| `ios-spm` 12.1.1 | **no** | — |
| `kamera-spm` 1.0.6 | **no** | — |

**The app's own required-reason API usage is exactly `UserDefaults`**, at two call sites — the launch
arguments' domain and the six settings switches — both of which read the app's own container, which
is reason **CA92.1**. Nothing in `ios/App/Sources` or `ios/SampleUI/Sources` touches any other
required-reason API: file timestamps, disk space, system boot time and active keyboards return no
hits.

**The two Smile ID packages shipping no manifest is a finding against the SDK.** It does not block
this release — a first-party app declares its own data collection, and every required-reason API in
the binary is declared by whoever calls it. It does block a partner who embeds the SDK and is asked
for a complete privacy report, which is why it is worth filing rather than working around.

## App Review

**No account required, and no special access.** Every screen is reachable on a fresh install, and the
token session states are reached through the scan sheet's Simulate affordance, which is a product
feature rather than a debug gate. The claim is asserted rather than remembered:
`UseSmileIDSampleAppStoreListingTest` fails if Simulate stops surviving release configuration.

Review notes should say exactly that: no credentials, and Simulate on the scan sheet is how a
reviewer reaches a linked session, its countdown and its expiry.

## Recurring checks

| Check | Cadence | Last done |
|---|---|---|
| Answers still match what the app sends | Every release that changes submission, analytics or storage | 2026-09-11 |
| The dependency graph still ships the manifests this page assumes | Every SDK version bump | 2026-09-11 |
| `ios-spm` and `kamera-spm` still ship no manifest | Every SDK version bump — remove the finding when they do | 2026-09-11 |
