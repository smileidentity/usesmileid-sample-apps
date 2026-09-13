# App Privacy — the answers, and why they are these answers

The App Privacy questionnaire lives in App Store Connect and has no file representation, so this is
the record of what to enter and what it was derived from. Fill it from this page rather than from
memory, and update this page in the same change as any behaviour that moves an answer.

This page and `ios/App/PrivacyInfo.xcprivacy` are two halves of one declaration: the manifest is what
the build ships, this is what a person types into the form. They must agree.

Verified 2026-09-14 against the v12 app as built and the shipped 12.1.1 frameworks.

## The answers

**Does this app collect data?** Yes.

| Data type | Collected | Linked to the user | Used for tracking | Purpose |
|---|---|---|---|---|
| Contact Info → Name | Yes | Yes | No | App Functionality |
| Contact Info → Email Address | Yes | Yes | No | App Functionality |
| Contact Info → Phone Number | Yes | Yes | No | App Functionality |
| User Content → Photos or Videos | Yes | Yes | No | App Functionality |
| Sensitive Info | Yes | Yes | No | App Functionality |
| Identifiers → User ID | Yes | Yes | No | App Functionality |
| Identifiers → Device ID | Yes | No | No | App Functionality, Analytics |
| Usage Data → Product Interaction | Yes | No | No | Analytics |
| Diagnostics → Crash Data | Yes | No | No | App Functionality |
| Diagnostics → Performance Data | Yes | No | No | App Functionality |
| Diagnostics → Other Diagnostic Data | Yes | No | No | App Functionality |
| Location → Precise Location | Yes | Yes | No | App Functionality |

**Tracking:** No. The app does not link its data to third-party data for advertising or a data
broker, and it does not use App Tracking Transparency because it has nothing to ask for.

**Precise Location is declared because the SDK declares it, not because this app collects it.** The
SDK reads the device's cached location only when the host app already holds the permission, and never
asks; this app never asks either, so on this app the value is always absent. But Xcode's privacy report
for the archive merges the SDK's manifest, which declares Precise Location, and a form that omits what
the report shows is the mismatch a reviewer is looking for. Declared, with this note as the reason.

## Why these are the answers

These are Play's answers, mapped rather than re-derived. The behaviour behind each one is the same on
both platforms — same SDK, same Sentry, same submission path — so `docs/play-data-safety.md` is the
source and this is the translation:

| Play data type | App Store equivalent |
|---|---|
| Personal info — Name | Contact Info → Name |
| — (not on Play's form; see below) | Contact Info → Email Address, Phone Number |
| Personal info — Other info (ID number, date of birth) | Sensitive Info, and Identifiers → User ID |
| Photos and videos — Photos | User Content → Photos or Videos |
| Device or other IDs | Identifiers → Device ID |
| App activity — Other actions | Usage Data → Product Interaction |
| App info and performance — Crash logs | Diagnostics → Crash Data |
| App info and performance — Diagnostics | Diagnostics → Performance Data, Other Diagnostic Data |

**Email and phone are collected, and Play's form does not say so.** The user-details form has both
fields and `FlowBuilderConfig` hands them to the SDK as the job's `email` and `phoneNumber`, so they
travel with a submission whenever the user fills them in. The first draft of this page mapped Play's
answers and inherited Play's omission; the App Store form was corrected to twelve types on 2026-09-14
before submission, and Play's Data safety form owes the same two rows — recorded in the Android plan's
follow-ups. The privacy manifest carries both too, from the build after 103.

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
manifest declares what the app itself does and leaves each dependency's declaration to its own file.

| Package | Ships a manifest | Declares |
|---|---|---|
| `lottie-spm` 4.6.1 | yes | FileTimestamp (C617.1) |
| `sentry-cocoa` 9.26.1 | yes | UserDefaults (CA92.1), SystemBootTime (35F9.1), FileTimestamp (C617.1); crash, performance and diagnostic data |
| `ios-spm` 12.1.1 — `UseSmileID` | yes | UserDefaults (CA92.1); Precise Location, Photos or Videos and User ID (linked); Crash Data, Other Diagnostic Data |
| `ios-spm` 12.1.1 — `Bridge`, `VisionFace`, `VisionDocument` | yes | `NSPrivacyTracking: false` only |
| `kamera-spm` 1.0.6 | no | nothing to declare: its binary references no required-reason API and links no privacy-sensitive framework |

**The app's own required-reason API usage is exactly `UserDefaults`**, at two call sites — the launch
arguments' domain and the six settings switches — both of which read the app's own container, which
is reason **CA92.1**. Nothing in `ios/App/Sources` or `ios/SampleUI/Sources` touches any other
required-reason API: file timestamps, disk space, system boot time and active keyboards return no
hits.

**The app repeats what it itself hands the SDK** — name, photos, the ID number — and leaves the rest
to the manifests that own it. An earlier draft of this page said the SDK shipped no manifest; it does,
in every XCFramework slice, and the draft had searched the wrong directory. Corrected 2026-09-13.

## The usage strings the binary owes

App Store Connect rejects an upload whose binary references a privacy-sensitive class with no purpose
string in the Info.plist — on the reference, not the call. Read out of the shipped frameworks with
`nm -u`:

| Reference | Purpose string | Shipped |
|---|---|---|
| `CLLocationManager` (`UseSmileID`) | `NSLocationWhenInUseUsageDescription` | yes — required, the upload fails without it |
| `PHPickerViewController` (`UseSmileID`) | `NSPhotoLibraryUsageDescription` | yes — not required for PHPicker, shipped for parity with every Smile ID sample |
| `LAContext` (`UseSmileIDBridge`) | `NSFaceIDUsageDescription` | no — it never prompts, no Smile ID sample ships it, and v11 is live with the same reference |
| `CMMotionManager` (`UseSmileID`) | none exists | — |

## App Review

**No account required, and no special access.** Every screen is reachable on a fresh install, and the
token session states are reached through the scan sheet's Simulate affordance, which is a product
feature rather than a debug gate. The claim is asserted rather than remembered: `ios/verify.sh` runs
`testSimulateLinksASessionAndTheProductsStripCountsItDown` under Release configuration, so Simulate
disappearing from the shipped build fails the lane.

Review notes should say exactly that: no credentials, and Simulate on the scan sheet is how a
reviewer reaches a linked session, its countdown and its expiry.

## Recurring checks

| Check | Cadence | Last done |
|---|---|---|
| Answers still match what the app sends | Every release that changes submission, analytics or storage | 2026-09-11 |
| The dependency graph still ships the manifests this page assumes | Every SDK version bump | 2026-09-11 |
| The SDK binaries' privacy-sensitive references still match the usage strings shipped | Every SDK version bump — `nm -u` the device slices | 2026-09-13 |
