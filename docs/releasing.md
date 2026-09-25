---
description: How the sample apps reach Google Play and the App Store — the publish workflows, signing, version numbers, store art, and the privacy answers each store holds for this app.
---

# Releasing the apps

The Android and iOS apps are published to Google Play and the App Store from CI, by workflow dispatch.
Nothing publishes on a merge, so a docs-only change never ships a build. This page is the runbook for
maintainers, and a worked example for partners: [`store-submission.md`](store-submission.md) is the
general guide to what the SDK means for your own submission.

## Prerequisites

- Write access to this repository, to dispatch the workflows.
- The repository secrets below. Their names are in the workflows. **Their values are never committed.**

| Store | Secrets |
|---|---|
| Google Play | `UPLOAD_KEYSTORE` (base64 keystore), `UPLOAD_KEYSTORE_PASSWORD`, `PLAY_STORE_SERVICE_ACCOUNT_JSON` |
| App Store | `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_PRIVATE_KEY` (the whole `.p8`), `APPLE_DEVELOPMENT_TEAM`, `ASC_REVIEW_NAME`, `ASC_REVIEW_PHONE`, `ASC_REVIEW_EMAIL` |

## The four workflows

| Workflow | Does | Inputs |
|---|---|---|
| **Publish to Play (internal)** | Builds the signed release bundle and uploads it to the internal testing track | none |
| **Publish to Play (production)** | The same, to production | none |
| **Publish to TestFlight** | Archives, signs and uploads a build that TestFlight distributes to the internal group | `build_number` (empty: one above the highest App Store Connect holds) |
| **Publish to the App Store** | Checks the listing, uploads, waits for processing, attaches the build to a new version with the copy in `ios/store/`, and submits it for review | `dry_run`, `build_number`, `marketing_version`, `release` (`manual` or on approval) |

`dry_run` signs and exports the build and reads App Store Connect, and uploads nothing. Use it to prove
the lane.

## Google Play

**Signing.** The release is signed with the upload key from `UPLOAD_KEYSTORE`, and Play re-signs it for
distribution. Both lanes set `REQUIRE_UPLOAD_SIGNING=true`, so a missing keystore or version code fails the build
instead of producing a debug-signed bundle that only Play would reject.

**Version code.** Both Play workflows derive `versionCode` from `git rev-list --count HEAD`. Play requires
each upload's code to exceed every earlier upload across **all** tracks, so both tracks must use the same
scheme. Two consequences:

- Dispatching both workflows on one commit gives both the same code, and the second upload is refused.
  After an internal release, **promote it in the Play Console** rather than dispatching production on
  the same commit.
- Dispatching from a branch behind `main` gives a lower code, which Play refuses.

**Version name.** Patch bumps only (`1.0.1` → `1.0.2`), set in `android/app/build.gradle.kts`.

**Release notes.** Every publish uploads `android/play/whatsnew/` as it stands, so update it before you
dispatch. Stale notes ship silently.

**Listing.** `android/play/` holds the title, short and full description, icon, feature graphic and
screenshots. The Console takes the text and images by hand. A listing edit cannot change the launcher
label, because that is in the binary.

**Review.** Internal testing is not fully reviewed, so a release there goes live within minutes. The full
review starts on the first promotion to closed testing or production.

## App Store

**Signing.** The workflows sign with the App Store Connect API key alone, and need no keychain or
certificate in CI. `exportArchive -allowProvisioningUpdates` fetches a cloud-managed distribution
certificate through the key.

- **The key must have the Admin role.** An App Manager key uploads fine but is refused cloud signing
  (`403 … cloud-managed distribution certificates`). The grant is on the key, not the person, and a
  key cannot be changed after it is generated, so the wrong role means a new key.
- Each run creates an Apple Development certificate for the archive step, and revokes it at the end.
- Apple allows three distribution certificates per team. Check there is room before a first run.

**Version.** When `marketing_version` is empty, the version derives as
`<yyyyMMdd>.<SDK version without dots>.<build>`, for example `20260913.1211.103`. The build number is one
above the highest App Store Connect holds (`scripts/asc_publish.py next-build`). Never reuse a number App
Store Connect has already seen for a version.

**Export compliance.** `ITSAppUsesNonExemptEncryption` is `false` in the built `Info.plist`, so builds
skip the question.

**Before submitting, test from TestFlight on a phone.** A TestFlight build is signed as the App Store
build will be, and an Xcode install is not. Walk through: launch with no fixture profiles; the camera
prompt on first capture and no location or photo prompt ever; Simulate a scan, start a flow, back out,
and check the result card shows exactly one result; portrait everywhere except document capture, which
rotates and holds landscape; dark mode; a deep link from Notes; an empty verifications list on a fresh
install.

**Review notes.** `ios/store/review-notes.txt` is the text on the version (4,000-character limit):
reviewer access, why the location and photo strings exist, and the TrueDepth answers. It is what got the
app approved, and [`store-submission.md`](store-submission.md) explains each paragraph.

**Resubmitting after an information request.** Reply in App Review's thread, run `scripts/asc_publish.py
apply --build <n>` to carry the updated notes to the rejected version, then `submit`. The script marks the
rejected review item resolved before it submits. Without that, Apple answers *Version is not ready to be
submitted yet*. No new binary is needed.

**Listing.** `ios/store/` holds the name, subtitle, description, keywords, promotional text, What's New,
screenshots and review notes. `scripts/check_store_listing.py` asserts each field's length, because App
Store Connect truncates silently. The app is iPhone-only (`TARGETED_DEVICE_FAMILY = 1`), so only the 6.9"
screenshot set is owed.

## Store art

Both stores' screenshots are rendered from golden-test frames, not from a device, except the camera
panel.

- Android: `android/play/render-store-art.sh` (`--frames` re-records the frames with Roborazzi first).
- iOS: `ios/store/render-store-art.sh`. `ios/store/panels.lock` holds the hash of each panel, so a
  changed frame is noticed.

What cost real time:

- A rendered frame is not a screenshot. It needs a **status-bar inset**, or the device frame's cutout
  lands on the app bar. iOS needs a larger one for the Dynamic Island.
- Use **one layout** for the whole set. Varying it makes the device a different size in each panel.
- Keep **only store art** in the screenshots directory. The review strip is RGBA, and a store rejects it.
- **Review the rendered panels, not the frames.** Both layout bugs above were invisible in the frames.
- Never show a state a release build cannot reach. The debug result card stays hidden in store art.

## The privacy answers this app declares

The App Privacy and Data safety forms live in each store's console and have no file form. These are the
answers this app has published. Update them in the same change as any behaviour that moves an answer.

**App Store: App Privacy.** Collected, not used for tracking:

| Data type | Linked | Purpose |
|---|---|---|
| Contact Info → Name, Email Address, Phone Number | Yes | App Functionality |
| User Content → Photos or Videos | Yes | App Functionality |
| Sensitive Info (the selfie is biometric) | Yes | App Functionality |
| Identifiers → User ID | Yes | App Functionality |
| Identifiers → Device ID | No | App Functionality, Analytics |
| Usage Data → Product Interaction | No | Analytics |
| Diagnostics → Crash Data, Performance Data, Other Diagnostic Data | No | App Functionality |
| Location → Precise Location | Yes | App Functionality |

Precise Location is declared because the SDK's privacy manifest declares it: this app never asks for
location, so the value is always absent here. The app's own `PrivacyInfo.xcprivacy` declares only its
`UserDefaults` use (reason `CA92.1`). Each dependency's manifest declares the rest.

**Google Play: Data safety.**

| Data type | Collected | Shared | Purpose |
|---|---|---|---|
| Personal info → Name, User IDs, Other info (ID number, date of birth) | Yes | No | App functionality |
| Personal info → Email address, Phone number | Yes | No | App functionality, Account management |
| Photos and videos → Photos | Yes | No | App functionality, Account management |
| Device or other IDs | Yes | No | Fraud prevention, security, and compliance |
| App activity → Other actions | No | Yes | Analytics, crash reporting |
| App info and performance → Crash logs, Diagnostics | No | Yes | Crash reporting, analytics |

Data is encrypted in transit, and users can request deletion.

**Two published answers differ from the partner guide**, and are being reconciled: Device ID on the App
Store (not linked, where the guide says linked), and the crash and diagnostics rows on Play (shared, not
collected, where the guide says collected). The guide follows each store's own definitions.

**Stored data is not a collection fact.** Verifications, settings, profiles and the token session stay on
the device, with no backup path off it.

**App access.** No account and no special access: every screen is reachable on a fresh install, and the
token session states are reached through Simulate, which is a product feature. Tests fail the build if
Simulate disappears from a release build.

**Read the live pages before trusting these tables.** The forms are filled in by hand:
`play.google.com/store/apps/datasafety?id=com.usesmileid.sample.android`, and the App Store listing.

## Recurring checks

| Check | When |
|---|---|
| `targetSdk` still meets Play's floor | Every August, when Google raises it |
| Privacy answers still match what the app sends | Every release that changes submission, analytics or storage |
| The SDK's privacy manifests, and its binary's privacy-sensitive references (`nm -u`), still match the usage strings | Every SDK version bump |

## Common issues

| Symptom | Cause | Fix |
|---|---|---|
| Play upload refused: *Version code N has already been used* | Both Play workflows ran on one commit | Promote in the Console instead |
| `exportArchive` fails with *Cloud signing permission error* | The API key is not Admin | Generate an Admin key |
| The archive fails in CI with *No Accounts* | The archive step had no key to authenticate with | Pass the key to the archive as well as the export |
| The first dispatch fails with *maximum number of certificates generated* | The team already has three distribution certificates | Revoke an unused one first |
| A workflow on a branch cannot be dispatched | GitHub lists a dispatchable workflow only once its file is on `main` | Merge the workflow first, or run the same step locally |
| The built app reports the wrong build number | A version was passed as a build setting, not written into `Info.plist` | Assert the number in the built artefact |

## Next step

[`store-submission.md`](store-submission.md) covers what the SDK adds to any app's submission.
