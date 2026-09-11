# App Store Connect — the steps only an account holder can take

Everything else is in the repository. These four are account actions with no API this project uses,
and each one blocks the lane behind it. Do them in this order; the whole sequence is about twenty
minutes.

`docs/plan/app-store-release-ios.md` is the reasoning. This is the values.

## 1. The app record

**App Store Connect → Apps → + → New App.** Creating the record is what makes the bundle id
permanent, so read the values before typing them.

| Field | Value |
|---|---|
| Platform | iOS |
| Name | `UseSmileID Sample` |
| Primary language | English (U.S.) |
| Bundle ID | `com.usesmileid.sample.ios` |
| SKU | `usesmileid-sample-ios` |
| User access | Full Access |

**The bundle id must already exist as an identifier** before it appears in that menu. If it does not:
**Certificates, Identifiers & Profiles → Identifiers → + → App IDs → App**, description
`UseSmileID Sample`, explicit bundle id `com.usesmileid.sample.ios`, and **no capabilities** — the app
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
| Access | **App Manager** |

The `.p8` downloads **once** and cannot be downloaded again. Then add four repository secrets at
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
creates and fetches one, which is why the pipeline needs no keychain in CI.

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

The short version: **Yes**, the app collects data; nine data types; **no tracking on any of them**.

Privacy Policy URL: `https://smile.id/privacy-policy` — the one that serves the page. The
`usesmileid.com` variant returns 200 and redirects to the homepage, which is the defect Android's
release found.

## Then the lanes work

Once 1 and 2 are done, **Actions → Publish to TestFlight → Run workflow** archives, signs, uploads and
the build appears in TestFlight. **Publish to the App Store** does the same and gates the listing
first; attaching the build to a version and submitting it for review stays a Console action, as Play's
production promotion does.

Both lanes are `workflow_dispatch` only. Neither runs on a merge, which is deliberate while the first
upload is an owner action — adding `push` to the TestFlight lane later needs a path filter, or a
docs-only merge ships a build.
