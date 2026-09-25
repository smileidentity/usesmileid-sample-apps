---
description: What the Smile ID v12 SDK adds to an App Store or Google Play submission — usage strings, privacy manifest, App Privacy and Data safety answers, and what App Review asks about face capture.
---

# Submitting an app that uses the Smile ID SDK

Both stores ask what your app collects, why, and whether a reviewer can reach every feature. The SDK
answers part of that for you, and it is the part partners most often get wrong, because the SDK's
behaviour is not visible in your own code. This page lists what the SDK contributes to each answer,
and why. It comes from submitting this repository's apps to both stores.

Your own app's collection is still yours to declare. Treat everything below as rows to **add** to
your answers, not as the whole form.

> **Checked against SDK 12.1.x** on Android, iOS and Flutter, with React Native (Expo) read from
> source. Re-check on every SDK version bump: the commands in each section take a minute, and a
> store's form is only as current as the build it describes.

## Prerequisites

- An integration that runs end to end in a **release** build. See [Setup](https://docs.smileidentity.com/developer-resources/sdks/mobile/setup).
- A **privacy policy URL that serves the policy itself**, not one that redirects to a homepage. It must
  cover face images and biometric data. Both stores check the link, and a redirect reads as a missing
  policy.
- A way for a reviewer to reach the verification flow **without your production credentials**: a
  sandbox path, a demo account, or written instructions (see [Reviewer access](#reviewer-access-both-stores)).

## What the SDK sends

Every answer below derives from this table, so start here.

| Data | When | Why |
|---|---|---|
| Selfie and liveness frames, as JPEG images | Every product with a selfie step | Face comparison and liveness. The selfie is biometric data, not just a photo |
| Document images | Document products | Document verification |
| The user details you pass to the builder: name, ID number, date of birth, email, phone | Per job, when you set them | The verification itself |
| Server-issued user and job ids | Every job | Linking a job to its result |
| Device metadata, including device identifiers | Every job | Fraud prevention |
| The device's **last-known location** | Only when **your app already holds** a location permission. The SDK never asks for one | Fraud prevention |
| Crash reports and diagnostics from the SDK | When the SDK itself errors | The SDK bundles Sentry for its own crash reporting |

All of it travels over HTTPS to the Smile ID API. **What your app stores on the device is not a
collection fact** on either store's form: both ask about data that leaves the device. Local
databases and Keychain or Keystore entries only change an answer if they sync or back up off the
device.

## iOS: App Store

### 1. Usage strings

App Store Connect refuses an upload (ITMS-90683) when the binary **references** a privacy-sensitive
class and the Info.plist has no purpose string for it. The check is on the reference, not on the
call, so a string can be required for a permission your app never asks for.

| Key | Required when | Native iOS SDK | Flutter SDK | React Native (Expo) SDK |
|---|---|---|---|---|
| `NSCameraUsageDescription` | Always. Without it, the first capture terminates the app | required | required | required |
| `NSLocationWhenInUseUsageDescription` | The binary references `CLLocationManager` | **required**: the SDK reads a cached location, and never prompts | **required**: the SDK depends on `geolocator` | only if you install the optional `expo-location` peer |
| `NSPhotoLibraryUsageDescription` | The binary references the Photos library APIs | recommended: the document picker is `PHPicker`, which needs no permission | **required**: the SDK depends on `image_picker` | check with `nm`: the SDK depends on `expo-image-picker`, whose config plugin can write the string |
| `NSFaceIDUsageDescription` | The app evaluates a biometric policy | not needed: the SDK checks availability and never prompts | not needed | not needed |

Check the binary rather than trusting this table. Flutter and CocoaPods link plugins **statically into
the app binary**, so check the app binary as well as the embedded frameworks:

```bash
APP=build/Release-iphoneos/YourApp.app   # the .app inside your archive
EXE=$(/usr/libexec/PlistBuddy -c 'Print CFBundleExecutable' "$APP/Info.plist")
for bin in "$APP/$EXE" "$APP"/Frameworks/*.framework/*; do
  [ -f "$bin" ] && nm -u "$bin" 2>/dev/null | grep -oE '_OBJC_CLASS_\$_(CLLocationManager|PHPhotoLibrary|PHPickerViewController|LAContext)' | sed "s|^|$(basename "$bin"): |"
done | sort -u
```

Match each printed class to its row in the table. `LAContext` needs no string, because nothing prompts.

### 2. Export compliance

The SDK uses only the operating system's HTTPS. If your app has no other encryption, set
`ITSAppUsesNonExemptEncryption` to `false` in the Info.plist. Every build then skips the
export-compliance question that otherwise holds it in processing until someone answers it.

### 3. Privacy manifest

Every SDK XCFramework ships its own `PrivacyInfo.xcprivacy`. The main `UseSmileID` framework
declares Precise Location, Photos or Videos, and User ID (all linked to the user, none used for
tracking), Crash Data and Other Diagnostic Data, and the `UserDefaults` required-reason API (CA92.1).
Its bundled Sentry declares its own. Xcode merges them all.

Your app's manifest declares only what **your** code does. Then compare the merged result with your
App Privacy answers: **Organizer → select the archive → Generate Privacy Report**. A form that omits
something the report shows is the mismatch a reviewer is looking for.

### 4. App Privacy

These are the rows the SDK adds. Add them to whatever your app already declares.

| Data type | Linked to the user | Used for tracking | Purpose | Why |
|---|---|---|---|---|
| Contact Info → Name, Email Address, Phone Number | Yes | No | App Functionality | Only the fields you pass to the builder |
| User Content → Photos or Videos | Yes | No | App Functionality | Selfie and document images |
| **Sensitive Info** | Yes | No | App Functionality | The selfie is biometric data. Declaring it only as a photo understates what is sent |
| Identifiers → User ID | Yes | No | App Functionality | Server-issued user id, and the ID number if you pass one |
| Identifiers → Device ID | No | No | App Functionality, Analytics | Device metadata for fraud prevention, and the SDK's crash reports |
| Usage Data → Product Interaction | No | No | Analytics | The SDK's crash reports carry the steps leading up to an error |
| Location → Precise Location | Yes | No | App Functionality | The SDK's manifest declares it. Declare it even when your app holds no location permission, because the privacy report shows it |
| Diagnostics → Crash Data, Performance Data, Other Diagnostic Data | No | No | App Functionality | The SDK's bundled Sentry |

**Tracking: No.** The SDK does not link its data with third-party data for advertising, and needs no
App Tracking Transparency prompt.

**Press Publish.** Apple checks the published answers, not the saved ones. An unpublished form blocks
submission with *"You must have published answers to your app's data usages."*

### 5. What App Review asks about face capture

On devices with a TrueDepth camera, the **native iOS SDK** runs an ARKit face-tracking session during
the selfie step. Its face orientation and expression are processed on the device, and nothing
depth-derived is stored or transmitted: the upload is the same JPEG images on every device. App Review
notices the TrueDepth API and asks about it under **Guideline 2.1, Information Needed**.

Two rounds of questions reached us, and both are worth answering before they are asked:

1. **What TrueDepth data the app collects, why, and whether it is shared.** Use the answers in
   [Submitting to the App Stores](https://docs.smileidentity.com/developer-resources/sdks/mobile/submitting-to-the-app-stores),
   and cite the sections of your privacy policy that cover face data.
2. **Which features use it, and who the app is for.** Name the steps of your own flow that capture a
   selfie, and say plainly that the rest do not. Describe your real audience.

Put both answers in the version's **App Review notes** before you submit, so the question never
arrives.

**Flutter builds do not link ARKit** (checked on a 12.1.1 release build), and the React Native (Expo)
SDK's 12.1.1 sources reference none. Check your own build with
`otool -L YourApp.app/YourApp | grep ARKit`. If App Review asks anyway, say so.

### 6. iPad

An iPhone-only app (`TARGETED_DEVICE_FAMILY = 1`) owes no iPad screenshots, but **App Review may
still test it on an iPad**, in compatibility mode. Our first review ran on an iPad. Run the flow
once on an iPad, or in an iPad simulator, before you submit.

## Android: Google Play

### 1. Permissions

The SDK's manifest merges `CAMERA` and `ACCESS_NETWORK_STATE` into your app. It declares no location
permission and never asks for one.

### 2. Data safety

These are the rows the SDK adds. Add them to your app's own answers.

| Data type | Collected | Purpose | Why |
|---|---|---|---|
| Personal info → Name, Email address, Phone number | Yes | App functionality | Only the fields you pass to the builder |
| Personal info → Other info | Yes | App functionality | ID number and date of birth, if you pass them |
| Personal info → User IDs | Yes | App functionality | The server-issued user id each job carries |
| Photos and videos → Photos | Yes | App functionality | Selfie and document images |
| Device or other IDs | Yes | Fraud prevention, security, and compliance | Device metadata |
| App activity → Other actions | Yes | Analytics | The SDK's crash reports carry the steps leading up to an error |
| App info and performance → Crash logs, Diagnostics | Yes | Crash reporting, Analytics | The SDK's bundled Sentry |
| **Location → Approximate or Precise** | **Only if your app holds a location permission** | Fraud prevention, security, and compliance | The SDK attaches the last-known location when your app is already allowed to read it |

Security practices: data is **encrypted in transit**. Whether users can request deletion depends on
your own process, so answer for it.

Play treats a transfer to a service provider that processes data on your behalf as **not sharing**.
Decide the "Shared" column by that definition and by your own agreements, not by whether bytes leave
your servers. The table above follows Play's definitions. This repository's own published form
answers the crash and diagnostics rows differently, and is being reconciled.

**Read the published page before you trust your notes.** What users see is
`play.google.com/store/apps/datasafety?id=<your.application.id>`. The Console form is filled by hand,
so it drifts from whatever document it was filled from.

### 3. Target API level

Play raises its `targetSdk` floor for new apps and updates each year, around August, with a grace
period. The SDK's own `compileSdk` requirement is in
[Setup](https://docs.smileidentity.com/developer-resources/sdks/mobile/setup). Put the yearly
`targetSdk` check in your calendar: no build fails when you fall behind.

### 4. Review timing

**Internal testing is not fully reviewed**, so a release there goes live in minutes even while the
app is still a draft. The full review starts on the first promotion to closed testing or production.
Do not read a fast internal release as review approval.

## Reviewer access: both stores

Both stores ask whether any feature needs an account. If a reviewer cannot reach the verification
flow, they cannot review it.

- **Best:** make the flow reachable with no credentials, for example against the **sandbox**
  environment, and say so in the review notes.
- **Otherwise:** give a working demo account and the exact steps to reach the selfie.
- **Keep the story consistent.** If the review notes say no account is needed, nothing else you tell
  the reviewer, such as a reply about your audience, may imply that one is. A contradiction reads as
  a missing demo account.

## Flutter and React Native (Expo)

The stores see a native app, so the iOS and Android sections above apply unchanged. Only where you
write each value differs:

| Value | Flutter | Expo |
|---|---|---|
| Info.plist keys | `ios/Runner/Info.plist` | `expo.ios.infoPlist` in `app.json` or `app.config.ts` |
| Android permissions | `android/app/src/main/AndroidManifest.xml` | `expo.android.permissions` |
| iOS privacy manifest | `ios/Runner/PrivacyInfo.xcprivacy`, added to the Runner target | `expo.ios.privacyManifests` |

Run the `nm -u` check on the built app, not on your source. Dependencies decide the answer:
`geolocator` and `image_picker` are why a Flutter app owes the location and photo strings.

## Verify your submission

- [ ] `nm -u` over the release app binary and its frameworks prints nothing without a matching usage string
- [ ] `ITSAppUsesNonExemptEncryption` is set, or you have answered export compliance
- [ ] Xcode's privacy report and your App Privacy answers name the same data types, and the form is **published**
- [ ] The Data safety form includes the SDK's rows, including Location if your app holds a location permission
- [ ] The privacy policy URL serves the policy and covers face and biometric data
- [ ] App Review notes answer the TrueDepth questions (native iOS) and describe reviewer access
- [ ] A reviewer can reach the selfie step without your production credentials
- [ ] The flow works on an iPad, even if the app is iPhone-only

## Common issues

| Symptom | Cause | Fix | Seen on |
|---|---|---|---|
| Upload rejected: *ITMS-90683: Missing purpose string in Info.plist … NSLocationWhenInUseUsageDescription* | The SDK binary references `CLLocationManager`, even though it never prompts | Add the string. The system never shows it unless your app itself asks | iOS SDK 12.1.1; Flutter SDK 12.1.1 through `geolocator` |
| Review returns *Guideline 2.1 – Information Needed* about the TrueDepth API | The native iOS SDK's selfie step uses ARKit face tracking | Answer in the review thread and in the review notes (§5). Do not deny the usage: the reviewer's scanner is right | iOS SDK 12.1.1 |
| You replied to App Review days ago, and nothing has happened | A reply alone does not put the submission back in the queue | Resubmit the **same build**. An information request needs no new binary | App Store Connect, September 2026 |
| Resubmitting fails with *Version is not ready to be submitted yet, please try again later* | The rejected review item has not been marked resolved. It is not a timing problem | In App Store Connect, use **Resubmit to App Review**. Through the API, mark the rejected review item `resolved` first, then submit | App Store Connect API, September 2026 |
| Submit is blocked: *You must have published answers to your app's data usages* | The App Privacy form was saved but not published | Open App Privacy and press **Publish** | App Store Connect |
| A reviewer flags that the privacy answers do not match the app | The form omits a type the merged privacy manifest declares, usually Precise Location or Email and Phone | Generate the privacy report from the archive and declare every type it lists | iOS SDK 12.1.1 |
| The privacy policy link is reported as missing | The URL redirects to a homepage | Use the URL that serves the policy page itself | Both stores |
| Play upload rejected: *Version code N has already been used* | Two uploads derived the same `versionCode`, for example two workflows run on one commit | Promote the existing release in the Console, or make `versionCode` come from Play's highest code plus one | Google Play |
| The Data safety form omits Location, but the app holds a location permission | The SDK attaches the last-known location whenever your app is allowed to read it | Declare Location for fraud prevention | Android SDK 12.1.x |

## Next step

This repository's own answers, and how its apps reach both stores, are in
[`app-store-privacy.md`](app-store-privacy.md), [`play-data-safety.md`](play-data-safety.md) and
[`app-store-manual-steps.md`](app-store-manual-steps.md). Read them as a worked example: your app's
collection decides your answers.
