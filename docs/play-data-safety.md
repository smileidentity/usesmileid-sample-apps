# Play Data safety — the answers, and why they are these answers

The Data safety form lives in Play Console and has no file representation, so this is the record of
what to enter and what it was derived from. Fill it from this page rather than from memory, and update
this page in the same change as any behaviour that moves an answer.

Verified 2026-08-28 against the v12 app as built.

## The answers

**Does the app collect or share any of the required user data types?** Yes.

**Verified against the published form on 2026-09-17** by reading
`play.google.com/store/apps/datasafety?id=com.usesmileid.sample.android`, which is what users see. The
published answers differ from the derivation below in two places and the table now records what is
published: the personal-info and photo rows carry **Account management** alongside App functionality,
and **Device or other IDs** is published under fraud prevention, security and compliance rather than
analytics, and is not published as shared. **Owner ruling 2026-09-17: the published identifier answer
is the correct one**, and the derivation below was wrong to call it shared — Play's "shared" means a
transfer for the recipient's own purposes, which a crash reporter processing on our behalf is not.
Read the live page before trusting this table again: it records a form filled by hand, not a generated
artefact.

| Data type | Collected | Shared | Processed ephemerally | Required | Purpose |
|---|---|---|---|---|---|
| Personal info — Name | Yes | No | No | Required | App functionality |
| Personal info — Email address | Yes | No | No | Required | App functionality, Account management |
| Personal info — Phone number | Yes | No | No | Required | App functionality, Account management |
| Personal info — Other info (ID number, date of birth) | Yes | No | No | Required | App functionality |
| Photos and videos — Photos | Yes | No | No | Required | App functionality, Account management |
| Device or other IDs | Yes | No | No | Required | Fraud prevention, security, and compliance |
| App activity — Other actions | No | Yes | No | Optional | Analytics, crash reporting |
| App info and performance — Crash logs | No | Yes | No | Optional | Crash reporting |
| App info and performance — Diagnostics | No | Yes | No | Optional | Analytics, crash reporting |

**Security practices**

- Data is encrypted in transit: **Yes**
- Users can request that data be deleted: **Yes**
- Committed to the Play Families Policy: not applicable, this app is not designed for children
- Independent security review: not claimed

## Why these are the answers

The behaviour behind every one of them is the same in v11 and v12, so v12 answers as v11 answers. That
was checked rather than assumed, question by question:

| Form question | v11 | v12 | Same? |
|---|---|---|---|
| Collects Personal info | yes | yes — user details go to the API with a submission | yes |
| Collects Photos and videos | yes | yes — selfies and document images | yes |
| Collects Device or other IDs | yes | yes — collected, not shared; see the ruling above | yes |
| Shares App activity, App info and performance | yes | yes — both SDKs bundle Sentry (v11 8.37.1, v12 8.53.0) | yes |
| Encrypted in transit | yes | yes | yes |
| Deletion can be requested | yes | yes | yes |

Two points worth keeping, because both have been got wrong once already:

**The local job database is not a data-safety fact.** Play's form asks about data *collected*, meaning
transmitted off the device, and data *shared* with third parties. On-device storage that never egresses
is outside both definitions. `AndroidManifest.xml` also sets `android:allowBackup="false"`, so the Room
database has no cloud-backup path off the device either. An earlier draft of the release plan said this
might change an answer. It does not.

**Stored profiles are not one either.** The names, emails and phone numbers a profile holds sit in a
DataStore sealed with an Android Keystore key, under the same `allowBackup="false"`, and leave the device
only inside a job submission — which the Personal info rows already declare. Checked 2026-09-25.

**Sharing is Sentry, and only Sentry.** It is what backs the *shared* column, and it is present in both
SDK versions, which is why v11's sharing answers carry over. If Sentry is ever removed from the SDK, the
three shared rows above stop being true and this page has to change before the next release.

## App access

**All functionality is available without special access.** No reviewer credentials, no access
instructions.

This is true because Simulate is a product feature rather than debug scaffolding: on a release build a
reviewer mints a fixture token from the scan sheet and reaches the token session, its bindings, the
countdown, the expiry state and the flow handoff, alongside every host screen — none of which needed a
credential to begin with. The app's only debug gates are the result card, the scenario drawer and SDK
logging, and none of them gates a feature.

That claim is load-bearing for a compliance answer, so it is asserted rather than remembered:
`UseSmileIDSamplePlayListingTest` fails the build if a debug or probes gate appears on the Simulate
wiring, and `UseSmileIDSampleSimulateAffordanceTest` fails if the scan sheet stops offering it.

## Recurring checks

| Check | Cadence | Last done |
|---|---|---|
| `targetSdk` still meets Play's floor for new releases and updates | Annually — Google raises it around August, with a grace period after | 2026-08-28: `targetSdk = 37` accepted |
| Data safety answers still match what the app sends | Every release that changes submission, analytics or storage | 2026-09-25 |

`targetSdk` cannot be checked from CI without querying Play, so it is a calendar item rather than a
gate. What CI does enforce is that the value does not drift downward unnoticed, because `compileSdk`
and `targetSdk` are declared together in `android/app/build.gradle.kts`.
