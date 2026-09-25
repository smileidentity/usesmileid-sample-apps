# App Store Connect — the steps only an account holder can take

Everything else is in the repository. These four are account actions with no API this project uses,
and each one blocks the lane behind it. Do them in this order; the whole sequence is about twenty
minutes.

`docs/plan/app-store-release-ios.md` is the reasoning. This is the values.

## From merge to live, in order

Each phase is gated by the one before it. The account steps below are §1–§4; everything else is a
workflow dispatch or a device in hand.

| # | Phase | Who | Done when |
|---|---|---|---|
| 0 | **Merge this PR** with the two usage strings in it — one of them is an upload rejection (§6.6 of the plan) | reviewer | `main` carries it |
| 1 | **Account actions, §1–§4 below** — the app record, the API key as four secrets, the TestFlight group, the App Privacy form. ~20 minutes | account holder | the four secrets exist and the record shows `com.usesmileid.sample.ios` |
| 2 | **Actions → Publish to TestFlight → Run workflow.** Leave `build_number` empty the first time. Processing takes 10–20 minutes; export compliance is already answered by the plist, so the build goes straight to the internal group. GitHub only lists a `workflow_dispatch` workflow once its file is on `main`, so before the PR that adds it merges, the same upload is `EXPORT_DESTINATION=upload ios/verify.sh archive` from a Mac holding the key | anyone with the repo | the build shows *Ready to Test* and installs from the TestFlight app |
| 3 | **Test it on a phone, from TestFlight** — the checklist in §5 | a tester | §5 walked, defects filed |
| 4 | **Actions → Publish to the App Store → Run workflow**, `marketing_version` left empty — the version derives as `<yyyyMMdd>.<SDK>.<build>`, v11's scheme. It gates the listing first, then uploads a fresh build | anyone with the repo | the build appears under the version in App Store Connect |
| 5 | **Create the version in App Store Connect with the string the upload carried** (it is in the archive step's log and on the build in TestFlight), fill it from `ios/store/` (§1's table), attach the build, answer the review questions (§6), **Add for Review → Submit** | account holder | status *Waiting for Review*; expect 24–48 hours |
| 6 | **After approval** — release manually or on approval as chosen; then the follow-ups in the plan's §7.2 (camera panel, `push: main` with a path filter, pinning `storeshots`) | engineer | plan status set to SHIPPED, with what the release proved, as the Android plan's §7.3 does |

## 1. The app record

**App Store Connect → Apps → + → New App.** Creating the record is what makes the bundle id
permanent, so read the values before typing them.

| Field | Value |
|---|---|
| Platform | iOS |
| Name | `Smile ID` — freed by the v11 sample's rename to `Smile ID Legacy App (v11)`, released 2026-09-13. The public search index lags App Store Connect by a few hours; if the field still reports the name as taken, that is the lag, not a collision |
| Primary language | English (U.S.) |
| Bundle ID | `com.usesmileid.sample.ios` |
| SKU | `usesmileid-sample-ios` |
| User access | Full Access |

**The bundle id must already exist as an identifier** before it appears in that menu. If it does not:
**Certificates, Identifiers & Profiles → Identifiers → + → App IDs → App**, description
`Smile ID`, explicit bundle id `com.usesmileid.sample.ios`, and **no capabilities** — the app
uses the camera, which needs a usage string rather than an entitlement.

Then, on the app's **App Information** page:

| Field | Value |
|---|---|
| Subtitle | `Reference app for Smile ID` |
| Category, primary | Developer Tools |
| Category, secondary | Business |
| Content rights | Does not contain, show, or access third-party content |
| Age rating | 4+ — answer No to every questionnaire item |

And on the version page, from `ios/store/`:

| Field | File |
|---|---|
| Promotional Text | `promotional-text.txt` |
| Description | `description.txt` |
| Keywords | `keywords.txt` |
| What's New | `whats-new.txt` |
| Screenshots, 6.9" iPhone | the five PNGs in `ios/store/screenshots/` |

| Field | Value |
|---|---|
| Support URL | `https://docs.smileidentity.com` |
| Marketing URL | `https://smile.id` |
| Copyright | `2026 Smile Identity` |

**Screenshots go in the 6.9" slot only.** The app is phone-only
(`TARGETED_DEVICE_FAMILY = 1`), so no iPad slot is offered and none is owed.

## 2. The API key, and the three secrets it becomes

**Users and Access → Integrations → App Store Connect API → Team Keys → +.**

| Field | Value |
|---|---|
| Name | `usesmileid-sample-ios CI` |
| Access | **Admin** |

**Why Admin and not App Manager.** The pipeline signs with a cloud-managed distribution certificate
that Xcode creates and uses *through this key*, and App Store Connect grants that only to keys with
the Admin role. An App Manager key can read and upload but is refused at signing —
`403 FORBIDDEN_ERROR: You haven't been given access to cloud-managed distribution certificates` — and
the grant is on the key, not on the person who generated it, so a user's own permission does not
help. A key cannot be changed after it is generated, so the wrong role means a new key. The team's
existing CI keys are Admin for the same reason. The `.p8` downloads **once** and cannot be downloaded
again. Then add four repository secrets at
**Settings → Secrets and variables → Actions**:

| Secret | Where it comes from |
|---|---|
| `APP_STORE_CONNECT_ISSUER_ID` | the Issuer ID above the key list — one per team |
| `APP_STORE_CONNECT_KEY_ID` | the 10-character Key ID in the key's row |
| `APP_STORE_CONNECT_PRIVATE_KEY` | the whole `.p8` file, `-----BEGIN PRIVATE KEY-----` line included |
| `APPLE_DEVELOPMENT_TEAM` | the 10-character Team ID, from Membership details |

**None of these may be committed.** The team id is not confidential — it ships inside every
provisioning profile — but `AGENTS.md`'s never-commit list names team identifiers, and this repository
goes public.

**Do not create a distribution certificate by hand.** `-allowProvisioningUpdates` plus the API key
creates and fetches one, which is why the pipeline needs no keychain in CI. **Check there is room for
it first:** Apple allows three Apple Distribution certificates per team, and the first dispatch fails
with *maximum number of certificates generated* if the team is already at three. **Certificates,
Identifiers & Profiles → Certificates** — revoke one nothing uses before the first run, not after it
fails.

## 3. TestFlight internal testing

**TestFlight → Internal Testing → + → New Group**, named `Smile ID`, with the team members who should
get builds. Internal testers need no Beta App Review, so a build is installable within minutes of
processing.

**Nothing needs to be answered about export compliance.** `ITSAppUsesNonExemptEncryption` is `false`
in the built Info.plist, so every build skips the question that otherwise holds each one until a
human clicks through it.

## 4. App Privacy

**App Privacy → Get Started**, and fill it from `docs/app-store-privacy.md` — that page is the record
of what to enter and why each answer is what it is. Do not answer it from memory; the answers are
derived from what the app actually sends, and the derivation is written down.

The short version: **Yes**, the app collects data; twelve data types, one of them (Precise Location) declared because the SDK's manifest declares it; **no tracking on any of them**. The form is not complete until you press **Publish** — Apple checks the published state, not the saved one.

Privacy Policy URL: `https://smile.id/privacy-policy` — the one that serves the page. The
`usesmileid.com` variant returns 200 and redirects to the homepage, which is the defect Android's
release found.

## 5. What to test from TestFlight, before submitting

Ten minutes on a phone, from the TestFlight install and not from Xcode — a TestFlight build is signed
and provisioned the way the App Store build will be, and an Xcode install is not.

- Launch → products grid, no fixture profiles, and Settings says *No profile yet*
- Camera prompt fires on the first capture, with the Smile ID wording, and **no** location or photo
  prompt ever appears — the strings exist for the upload check, the SDK never asks
- Scan sheet → *Simulate a successful scan* → session card counts down → start a flow → reach the
  shutter → back out → the result card shows exactly one result
- The app holds portrait everywhere — rotate on the products grid and nothing happens — and document
  capture rotates to landscape and **holds** it, which is the SDK's mask being honoured
- Dark mode follows the system; Settings switches survive a relaunch
- `usesmileid-sample-ios://settings` from Notes opens Settings
- Verifications → seed nothing; the list is empty on a fresh install

## 6. What App Review will ask, and the answers

| Question | Answer |
|---|---|
| Does the app need an account? | No. Every screen is reachable on a fresh install; *Simulate* on the scan sheet reaches the session states |
| Why does it declare location? | The SDK reads a cached position when the host already has permission, for fraud prevention. This app never requests it — the string satisfies the binary check |
| Why does it declare photo library? | Document images can be imported through the system picker, which needs no permission; the string is for parity with the SDK's own declaration |
| Contact for review | the account holder's email, plus a phone number Apple can reach |

## Then the lanes work

Once 1 and 2 are done, **Actions → Publish to TestFlight → Run workflow** archives, signs, uploads and
the build appears in TestFlight. **Publish to the App Store** gates the listing, uploads, waits for
processing, attaches the build to a new version with the copy in `ios/store/`, and submits it for
review. Ticking **dry_run** instead signs and exports the IPA and reads App Store Connect, and
uploads nothing. A real run needs the `ASC_REVIEW_NAME`,
`ASC_REVIEW_PHONE` and `ASC_REVIEW_EMAIL` repository secrets. Releasing an approved version
by hand stays a Console action unless **release** is `after-approval`. Both lanes revoke the development certificate their
signing creates, at the end of the run, so the team's certificate list stays as it was.

Both lanes are `workflow_dispatch` only, as Play's are: running **Publish to the App Store** releases,
and ticking **dry_run** proves the lane without publishing. Neither runs on a merge, since a docs-only
merge would otherwise ship a build.
