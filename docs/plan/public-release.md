# Making the repository public

**Status:** reviewed 2026-09-25, and T1's scans have run. The flip waits on D1's revision being
approved, and on every row of §6 having a destination. This doc executes the pre-flip checklist in
`AGENTS.md` § Going Public. Where the two disagree, update the checklist. This doc is the last file in
`docs/plan/` to go: it is deleted by the final PR (T11), not by T4, because T8 to T11 still need it,
and it fails its own jargon sweep.

**The one-line goal:** a partner engineer can clone, read and build all four apps, and nothing in the
tree, the history, the PRs or the Actions logs exposes a credential, personal data, internal-only
context, or anything that helps a fraudster. **Nothing unfinished is lost on the way.** Every open
item in `docs/plan/` has a named destination before the folder is deleted.

## 0. What the 2026-09-25 review changed

- **D1 is revised from delete to migrate** (§2). The plans hold the traps that the planned partner
  skills need, so their knowledge moves into partner docs and decision records first, and only then
  does the folder go.
- **An open-item register (§6) now gates the deletion.** A keyword scan cannot find open work in 38
  documents, so the register was built by reading every status line and every work-item, follow-up and
  owed section. Items the code has since closed are marked closed, and the others are marked
  verified-open or unverified.
- **Twelve findings the first audit missed** (P12 to P23), two of them real defects outside this
  plan's scope (P20, P21).
- **T1 ran.** gitleaks found no secret, and the publish-lane logs are clean. D2 stands.
- **The store-submission guide is a partner deliverable** (§3, D9), written here and mirrored in the
  partner docs. It is not an internal runbook.

## 1. What the audit found

First pass 2026-09-24 (tree, full history, 127 PRs, 149 comments). Re-verified and extended
2026-09-25.

**Clean:**

- **gitleaks 8.30.1 over all 348 commits** (`gitleaks git --log-opts="--all"`) found 3 hits, all
  false positives: two header-redaction fixtures in `ios/App/Tests/UseSmileIDSampleLoupeTest.swift`
  (`0123456789abcdef`, a truncated `eyJ…` literal) and a Figma `fileKey` in `spec/screens.json`, which
  is a pointer to an access-controlled file, not a credential.
- No keystore, provisioning profile or `.env` was ever committed. `upload.jks` at the root is ignored.
- Token fixtures are synthetic (`iat` 1760000000). There is no real partner id, job id or user data.
- Every image is a golden, an app icon or store art. There are no captured faces or documents.
- No machine-local paths, and no private tracker links. PR bodies and comments contain no tokens and
  no image attachments.
- No thresholds or defence detail. "Frame injection" appears only as a statement that it is out of scope.
- **Publish-lane logs** (all 12 runs of the four `publish-*` workflows) print the App Review contact
  only as `***`. No signing identity, team id or issuer id appears unmasked.
- The review phone number and the review contact's name appear in no commit.

**To fix:**

| # | Finding | Where | Action | Severity |
|---|---|---|---|---|
| P1 | `docs/plan/` is 38 internal working documents: owner rulings by name, device models, sibling-SDK defects not yet filed, process retrospectives | `docs/plan/*` | D1 and §5 | HIGH |
| P2 | Ten `INTERNAL-ONLY` blocks in seven files, not five in six as first counted | `integration-skill.md`, `ios-device-verification.md`, `play-release-android.md` ×3, `sample-apps-plan.md` ×2, `sdk-size-story.md`, `ui-feedback-pass.md`, this doc | Close each by doing what it describes (file the defect, rename the repo) or by deleting it. The checklist grep must return nothing | HIGH |
| P3 | A personal email as a script default | `scripts/asc_publish.py:233` | Require `ASC_REVIEW_EMAIL`, with no default. **Done on this branch** | MEDIUM |
| P4 | Anyone with write access can dispatch the publish workflows, and none uses an `environment:`. An **unused `GH_PAT` repository secret** is also stored. No workflow reads it | `publish-*.yml` ×4, repo secrets | Add a `release` environment with required reviewers and move the store secrets into it. Delete `GH_PAT` | MEDIUM |
| P5 | Machine-local tooling referenced | `tools/verify/…` in `expo/maestro/README.md:29` and four plans | Replace with the in-repo command, or drop the line. **README done on this branch** | LOW |
| P6 | A staff first name in prose | `android-u4-screen-state-goldens.md:173`, `ui-work-plan.md:359`, `ios-port-hardening.md:1093` | Goes with D1 | LOW |
| P7 | Dependabot assigns every PR to a personal login | `.github/dependabot.yaml` ×3 | Drop the `assignees:` blocks and add `CODEOWNERS` → `@smileidentity/mobile`, as the SDK repos do, so review goes to the team. **Done on this branch** | LOW |
| P8 | Hygiene files missing | — | `SECURITY.md` (GitHub private vulnerability reporting, with no public issues for vulnerabilities), `CONTRIBUTING.md`, issue and PR templates, `CODEOWNERS`: **done on this branch**. Enabling private reporting is a T10 setting. **`CODE_OF_CONDUCT.md` is an owner call**: it needs an enforcement contact, and none of the public Smile ID repos has one to copy | MEDIUM |
| P9 | **Corrected.** Fork PRs would run the macOS and Flutter-Android lanes on **Blacksmith** runners, which are paid and third-party, not GitHub-hosted. **`DESIGN_SYSTEM_TOKEN` was never created**, so the token-drift check is skipped on every PR, same-repo ones included, with a warning. It is fail-open, not fail-closed | `ios.yml`, `flutter.yml`, `release-check.yml`, `publish-*.yml`; the token step in all four platform workflows | Require approval for **all** outside collaborators, not first-time ones only. Check Blacksmith's fork-PR policy rather than assuming it. Create the secret, or make the step fail when a same-repo PR lacks it | MEDIUM |
| P10 | The token-drift step names a private repo (`smileidentity/claude-skills`) | `android.yml:35`, `expo.yml:35`, `flutter.yml:39`, `ios.yml:66` | Keep the check, which is fork-safe. Move the repo name into a repository variable, and describe the source as "the Smile ID design system" in public docs | LOW |
| P11 | The root README is stale. It says three platforms "have not started" and links `docs/plan/` as the architecture | `README.md` | Rewritten in T2 | HIGH |
| P12 | **`docs/plan/` is load-bearing outside itself.** 32 references in code comments, scripts, error strings and spec | `AGENTS.md` ×3, `README.md` ×2, `spec/README.md` ×2, `spec/screens.json` ×4, `spec/design-tokens.json`, `ios/verify.sh` ×3, `ios/App/project.yml`, `ios/SampleUI/Package.swift`, `ios/store/render-store-art.sh`, `UseSmileIDSampleStoreArtTest.swift`, `flutter/app/pubspec.yaml` ×2, `scripts/asc_publish.py`, `scripts/test_sync_design_tokens.py`, `docs/app-store-manual-steps.md`, four Android sources, four Maestro flows | Each gets its §5 destination (usually a decision record) or loses the pointer. `git grep docs/plan` returns only this doc before T4 closes | HIGH |
| P13 | **`spec/*.json` carries internal narrative**: `OWNER RULING`, `OPEN 2026-08-25`, `CORRECTED 2026-09-08`, a Figma `fileKey` | `spec/screens.json`, `spec/design-tokens.json` | Sweep it in T5, then run all four spec tests, which read these files | MEDIUM |
| P14 | **Actions history becomes public**: about 1,000 PR-lane runs and 133 artifacts. The publish lanes are clean (§1). The PR lanes were not swept | Actions | T1: script a log sweep (emails, `+\d{10,}`, key, issuer and team ids, `Bearer`), or delete runs older than the flip. Artifacts expire on their own retention | MEDIUM |
| P15 | Five remote branches go public with their content, three of them stale feature branches | `feat/expo-dark-mode-theme`, `feat/expo-notice-window`, `feat/expo-seed-jobs-cold-start` | Delete each after diffing it against `main` (T10) | LOW |
| P16 | `auto-author-assign.yml` runs on `pull_request_target` | `.github/workflows/auto-author-assign.yml` | Reviewed and kept: the action is SHA-pinned, it checks out nothing, and its token has `pull-requests: write` only. Recorded so a reviewer sees it was considered | INFO |
| P17 | Wiki and Projects are enabled and empty | repo settings | Disable both (T10) | LOW |
| P18 | **The store docs speak to our account holder, not to a partner.** They carry owner rulings, dates and plan references, and their answers are this app's, presented as the only answers | `docs/app-store-manual-steps.md`, `docs/app-store-privacy.md`, `docs/play-data-safety.md` | D9: a partner guide (`docs/store-submission.md`, **done on this branch**), plus this app's answers kept as a worked example in `docs/releasing.md` (T2) | HIGH |
| P19 | **`AGENTS.md` sends rationale to `docs/plan/`** (lines 87, 211, 297), so deleting the folder breaks the repo's own comment rule | `AGENTS.md` | D7, landed with T4 | HIGH |
| P20 | **Not a public-release defect, but found here.** The Flutter iOS release binary references `CLLocationManager` and the Photos picker, because the Flutter SDK depends on `geolocator` and `image_picker`. `flutter/app/ios/Runner/Info.plist` declares only the camera string, so an App Store upload would fail ITMS-90683, as the native app's first upload nearly did. The native iOS app carries both strings | `flutter/app/ios/Runner/Info.plist` | A separate fix before any Flutter iOS submission. Expo is unverified: `expo-location` is an optional peer, so `nm -u` a release build before its first upload | HIGH for the port |
| P21 | **Partner docs overstate the TrueDepth declaration.** They say it applies to Flutter and React Native iOS targets. The Flutter 12.1.1 release binary links no ARKit (checked with `otool -L`), and neither SDK's iOS sources reference ARKit | the partner docs' mobile setup page | Corrected in docs-v3#39, with the store guide's mirror | MEDIUM |
| P22 | **The SDK repos are internal.** Only `ios`, `ios-spm` and `kamera-spm` are public, so a public page cannot link `android`, `ios-v12`, `flutter` or `react-native-expo`. The tree links only the public ones today, and SECURITY.md routes SDK reports through this repo | `AGENTS.md` prose, the docs set | Keep every public link on a registry page or a public repo. Add it to T5's sweep | MEDIUM |
| P23 | Commit author emails are public with history | git metadata | Accepted, as on every public repo. Stated so it is a decision, not an oversight | INFO |

**Not run yet:** the PR-lane log sweep (P14), and `trufflehog` as a second scanner. gitleaks is one
rule set, so a second tool with verified-credential checks is cheap insurance before T11.

## 2. Decisions

Approved 2026-09-24 unless marked. **D1 is revised and needs the owner's approval again.**

- **D1 (revised 2026-09-25): migrate `docs/plan/`, then delete it.** The first version deleted it
  and relied on history. That keeps nothing a reader can find: once the repo is public, history is
  public but unread, and the public skills this repo is meant to seed (D8) need the traps these
  documents record. So every document gets one disposition in §5:
  - **Distil.** The durable knowledge (a trap, a measured constraint, a reason a choice was made)
    moves into a partner page from §3 or into a decision record (D7). It is rewritten for a partner,
    not copied.
  - **Carry.** Each unfinished item goes to the destination §6 names, before the document is deleted.
  - **Drop.** Process retrospectives, review ledgers and work-in-progress narrative stay in history
    only.

  The folder is deleted only when every row of §5 and §6 is closed. The old versions stay in history,
  which is acceptable because the audit found nothing sensitive there.
- **D2: make this repo public, rather than republishing it with fresh history.** History has no
  secret, PII or fraud-relevant content, only internal narrative, and the review trail is engineering
  worth sharing. Republishing would lose 127 PRs and every link to them. T1 confirmed it on
  2026-09-25. Revisit only if the P14 sweep or a second scanner finds a secret.
- **D3: the agent files stay.** Once P2 is done, `AGENTS.md` is the contributor guide. `CLAUDE.md` is
  a one-line pointer. Both help partners who build with coding agents.
- **D4: the docs speak to partners, in the voice of the public docs.** The repo exists to show how a
  partner integrates the v12 SDKs, so every page follows the partner docs' page structure:
  frontmatter intro, prerequisites, steps, "Verify your integration", a symptom / cause / fix table,
  and a next step. Keep them direct, prerequisites first, copy-paste ready, and readable by a coding
  agent. Use the public docs' terms (token session, `/v3/token`, flow builder, `theme { }`) and link
  to docs.smileidentity.com for SDK reference rather than restating it. Each page explains *why* the
  sample does what it does, not only what, because that is what a partner can't get from the SDK docs.
- **D5: a generic root README, and a detailed one per app.** The root is short and the same for
  everyone. Each app's README carries the platform detail and links back.
- **D6: the second read.** The checklist requires a colleague other than the author.
- **D7 (new, needs approval): after the flip, reasoning lives in `docs/decisions/`.** These are
  numbered records (`NNNN-slug.md`: context, decision, consequences), written for a partner from the
  first line and reviewed like code. They are the new target for every comment that now says "see
  `docs/plan/…`". Work-in-progress planning does not live in the public tree: small items become
  issues, and cross-SDK or unreleased-feature plans stay in the team's private planning. `AGENTS.md`'s
  one-line comment rule then points at `docs/decisions/`, and its Layout block drops `docs/plan/`.
- **D8 (new, needs approval): this repo is the skills' source material, not the skills' home.**
  `integration-skill.md` §7.2 already decided that partner skills go in a born-public skills repo
  (Expo's `expo/skills` model, many narrow skills). This repo feeds it, so the docs are written
  to convert. Every page has a one-sentence frontmatter `description`, which becomes a skill trigger.
  Every "Common issues" row carries the symptom a partner's agent will see, the cause, the fix and
  the SDK version it was observed on, which is the gotcha shape §3.3 of that plan specifies. Every
  snippet traces to a file in this repo. What a skill must not contain is exactly what this repo must
  not contain, so the D1 migration doubles as the skills' clean-room pass.
- **D9 (new): the store-submission guide is public and partner-facing.** Our two store submissions
  taught what the SDK contributes to a partner's App Privacy, privacy-manifest, usage-string and Data
  safety answers, and what App Review asks about it. Every partner needs that, so it is written for
  them (`docs/store-submission.md`) and mirrored on the partner docs' mobile section. This app's own
  answers are the worked example, not the instructions.

**One question for the owner, not decided here.** The App Review notes on file describe the selfie
step's face tracking at blend-shape level: which two coefficients are read, and that the value times
the shutter. That is what a reviewer needed, but it describes the capture trigger. The public guide
keeps the level the partner docs already publish (face orientation and expression, processed on the
device, nothing depth-derived stored or transmitted), and leaves the coefficient detail out. Confirm,
or rule that the detail may be published.

## 3. The documentation set

| Page | Audience question it answers | Built from |
|---|---|---|
| `README.md` (root) | What is this, which app do I open, what do I need | Rewritten: four apps and what each shows, the registry-only rule and why, the prerequisites common to all, links to the four app READMEs and the guides, licence, security contact |
| `android/README.md` | How do I run it, and where is the integration | Build, run, deep links, device flows. **Where the SDK is called**: a file map covering builder config, flow host and result handling. Android-specific notes: ML Kit vs Huawei, R8 rules, min/compile SDK |
| `ios/README.md` | The same, for iOS | XcodeGen, SPM resolution, signing for a device, the iOS 17 app floor against the SDK's 15, XCUITest ids |
| `flutter/README.md` | The same, for Flutter | pub.dev resolution, ML provider plugins, the Android ABI split, the Maestro lane |
| `expo/README.md` | The same, for Expo | pnpm workspace, prebuild, the mandatory worklets Babel plugin, one ML provider per platform, the Maestro lane |
| `docs/integration.md` | What a real integration looks like end to end | One product traced across all four apps, tabbed: build the flow, run it, receive the result, store the job, poll `GET /v3/status`, and why each step sits where it does |
| `docs/token-session.md` | How do I avoid shipping an API key | Scanning a QR or pasting a token, what the token binds (consent, user details, environment), the countdown and expiry, and why the gate sends a run back to the scanner. From `token-session-android.md`, `token-binding-matrix-android.md` and `environment-from-token-android.md`, without internal item codes |
| `docs/theming.md` | How do I make the SDK look like my app | §4 |
| `docs/architecture.md` | How the four apps are kept identical | `spec/` as the contract, the `sample-ui` vs `app` split, the navigation model, persistence. From `sample-apps-plan.md`, `port-patterns.md`, `navigation-plan.md` and `offline-storage.md` |
| `docs/testing.md` | How do I test my own integration like this | Goldens in light and dark and at font scale, layout predicates, device flows on `si_*`/`sample_*` ids (never coordinates or screenshots), the registry-consumption lane. From `device-suite-cycle-time.md`, `android-u4-screen-state-goldens.md`, `ios-device-verification.md` and the Maestro READMEs |
| **`docs/store-submission.md`** | **What does the SDK mean for my App Store and Play submission** | **Done on this branch (D9).** From both store plans, the three store docs, the review notes and both review rounds. Mirrored in the partner docs |
| `docs/releasing.md` | How do these apps reach the stores | This repo's runbook for maintainers. The three existing store docs folded in, rewritten without rulings or dates, secrets named but never valued, and this app's form answers kept as the worked example the partner guide links to |
| **`docs/decisions/`** | **Why is it built this way** | D7. Seeded by T4 with the decisions that code comments point at today: registry-only, the `sample-ui` split, `spec/` as data, per-platform navigation libraries, the iOS 17 app floor (SwiftData), phone-only, flows stopping at the capture screen, `versionCode` from the commit count |

Every page follows D4, and every "Common issues" table follows D8's row shape.

## 4. Theming best practices (`docs/theming.md`)

What this repo does, written as advice a partner can copy:

1. **Two layers, kept apart.** The host app has its own theme. The SDK flow gets its colours through
   the flow builder's `theme { }` override, and the sample never styles SDK screens any other way.
   Show the override on all four platforms, tabbed (`FlowBuilderConfig.kt`,
   `use_smileid_sample_flow_builder_config.dart`, `use-smile-id-sample-flow-builder-config.tsx`, the
   iOS equivalent), and show the two theme scenarios in `spec/scenarios.json`.
2. **One token source, generated per platform.** Colours, type ramp, spacing, radii and shadows come
   from one design-token set. `scripts/sync_design_tokens.py` vendors it into Kotlin, Swift, TS and
   Dart, and a CI check fails when the vendored copy drifts. Until P9's secret exists, that check does
   not run, so the page must not claim it does. Advice: never hand-edit generated tokens; change the
   generator instead.
3. **Semantic roles, not raw values.** Screens read `primary`, `surface` and `onSurface`, never a hex
   value. Light and dark are paired per role, so dark mode is a lookup, not a second stylesheet.
4. **Dark mode follows the system until the user overrides it.** That includes the system bars
   (#125), and the SDK override receives the matching palette.
5. **Contrast is computed, not eyeballed.** Ink on a fill is chosen by WCAG relative luminance. That
   is true on Android, Flutter and Expo. iOS still uses a perceptual grey (§6, A6), so either fix iOS
   first or state the exception.
6. **Text scales.** Layouts are tested at the largest font scale and the narrowest width. Measure
   chrome such as the floating nav bar instead of hard-coding its height.
7. **Fonts are bundled and licensed.** DM Sans ships under the OFL and appears on the licences screen.
8. **Prove it with goldens.** Every themed state is recorded in light and dark, and the recording
   happens on CI, never on a laptop.
9. **Common issues.** An override that is ignored because it was set after `build()`. Dark-mode
   screens with light system bars. Clipped labels at 200 % text. Baselines recorded on a Mac that
   differ from CI.

Before writing, confirm each claim against the code, and cut any point this repo does not actually do.

## 5. Disposition of `docs/plan/`

One row per document. **Distil** names the page or decision record that absorbs its durable
knowledge, **carry** points at §6, and **drop** means history only. A document is deleted when its
row's distil target exists and its §6 items are closed.

| Document | Disposition | Distil into | Carries (§6) |
|---|---|---|---|
| `after-the-ports.md` | carry, drop | — (the sequencing lessons are internal process) | B1–B5, S2 |
| `android-u4-screen-state-goldens.md` | distil, drop | `docs/testing.md`: the state-to-golden table and its exemptions | — |
| `app-store-release-ios.md` | distil, carry | `docs/store-submission.md` (done), `docs/releasing.md`, decision: phone-only | A12, A13, A14, O2 |
| `device-suite-cycle-time.md` | carry, distil | `docs/testing.md`: the flakiness guard | A15 |
| `document-capture-options.md` | carry | — | A16 |
| `environment-from-token-android.md` | distil, drop | `docs/token-session.md`: environment from `api_url` | — (ENV-A11 cut, the rest shipped) |
| `improve-expo-shell-wiring.md` | drop | — | — (done) |
| `improve-expo-structural-checks.md` | carry | — | A5 |
| `improve-flutter-job-store-contract.md` | drop | — | — (done) |
| `improve-plans-index.md` | drop | — | — (A5 carried) |
| `improve-port-store-restore-tolerance.md` | drop | — | — (done) |
| `integration-skill.md` | carry | its §3.3 gotchas go into the "Common issues" tables (D8) | S1 |
| `ios-device-verification.md` | distil, carry | `docs/testing.md`: the XCUITest opener and exactly-once assertions | A17 |
| `ios-network-loupe.md` | distil, drop | `ios/README.md`: what the shake-to-inspect loupe shows and what it redacts | — |
| `ios-port-hardening.md` | distil, drop | `docs/architecture.md` and the iOS README: the iOS traps it records | — (its list is done) |
| `navigation-hardening-android.md` | distil, drop | decision: result-back stays out of navigation (NAV-A5), and the rejected features list (NAV-A6) | — |
| `navigation-plan.md` | distil, drop | decision: per-platform navigation libraries (`flutter/app/pubspec.yaml` points here), `docs/architecture.md` | — |
| `offline-storage.md` | distil, carry | decision: the iOS 17 app floor for SwiftData (`project.yml` and `Package.swift` point here) | A18 |
| `play-release-android.md` | distil, carry | `docs/store-submission.md` (done), `docs/releasing.md`, decision: `versionCode` from the commit count | A12, A13, A19, A20, O1, O3, C1 |
| `port-adversarial-review.md` | drop | — | — (its open items live in `port-priority-cut.md`) |
| `port-comment-rationale.md` | drop | — | — |
| `port-gaps-backlog.md` | carry | — | A1–A4, A6, B1–B2 |
| `port-patterns.md` | distil, drop | `docs/architecture.md` (`scripts/test_sync_design_tokens.py` points here) | — |
| `port-priority-cut.md` | carry | — | A7–A9, B4. Item 6 (fail-closed gates) is P9 and O4 |
| `port-review-findings.md` | carry | — | A10, A11 |
| `ports-final.md` | carry | — | C2 |
| `products-visual-refresh-android.md` | drop | — | — (built) |
| `profiles-ux.md` | drop | — | — (done) |
| `public-release.md` | this plan | — | deleted in T11 |
| `registry-consumption-e2e.md` | carry, distil | `docs/testing.md`: what the registry lane must prove | A21 |
| `sample-apps-plan.md` | distil, carry | `docs/architecture.md`, decisions: registry-only, the `sample-ui` split, `spec/` as data, flows stop at the capture screen (Maestro flows point at its §6) | A22, A23 |
| `sdk-size-story.md` | carry | — | S3 |
| `sheet-nav-bar-layering.md` | distil, drop | `docs/architecture.md`: a sheet belongs to the root navigator | — |
| `stacked-pr-sequencing.md` | drop | — | — |
| `token-binding-matrix-android.md` | distil, drop | `docs/token-session.md` | — |
| `token-session-android.md` | distil, drop | `docs/token-session.md` | — |
| `token-session-ports.md` | distil, drop | `docs/token-session.md`: the per-port storage and scanner table | — |
| `ui-feedback-pass.md` | drop | — | — (F50 and F51 carried as A22 and A23) |
| `ui-work-plan.md` | distil, drop | `docs/architecture.md`: the build order `spec/README.md` points at | — |

## 6. Open-item register

Built 2026-09-25 by reading every document's status line and its work-item, follow-up, owed and
open-question sections. **Verified** means this pass checked the code or GitHub. **Unverified** means
the plan says it is open and nothing here confirmed or refuted that. Check an unverified item against
the code before carrying it. The item text is the carry. The document it came from is deleted.

**Destinations.** **A** becomes a GitHub issue here, written for a public reader, because it goes
public with the repo. **B** is a product ruling, which goes to the team's private tracker and is never
named in a committed file. **C** is a sibling-SDK finding, filed in that SDK's repo, which is how the
`INTERNAL-ONLY` block that hid it closes. **O** is an owner or account action. **S** belongs to
cross-SDK planning, not to this repo.

**Checked and closed on 2026-09-25**, so none of these is lost by omission: Sign out is wired on Expo
(`settings.tsx:71`) and Flutter (`use_smileid_sample_settings_tab.dart:88`), and Flutter's DEBUG section is
gated on `kDebugMode`. Flutter matches `/profiles/switch` and `/profiles/new` before `/profiles/:profileId`
(`use_smileid_sample_routes.dart:140`). The active-profile edit (B2) appears fixed. `improve-plans-index.md`'s
owed `sample_env_chip` is inside A7. ENV-A10's other half went with the visual refresh, which is built.
Everything `ports-final.md` §1 and §2 lists is built, fixed or closed there.

### A. Engineering backlog: GitHub issues

| # | Item | Source | State |
|---|---|---|---|
| A1 | "Tap \`Hide from List\` to confirm" renders its backticks literally on Android and iOS; baselines move | `port-gaps-backlog.md` §2 | **verified open** (`UseSmileIDSampleSelectionBar.kt:79`, `.swift:88`) |
| A2 | The Android job row's secondary line should take the board's caption; row height moves | `port-gaps-backlog.md` §2 | unverified |
| A3 | Android's `UseSmileIDSampleStatusBadge` doc comment is stale about the soft badge pairs | `port-gaps-backlog.md` §2 | unverified |
| A4 | Id spec tests should assert both directions on Android and Flutter, and Android and Expo need the id-attached check that iOS (`TestIdUsageTest`) and Flutter have | `port-gaps-backlog.md` §2, `port-priority-cut.md` §2 | unverified |
| A5 | Expo lacks the two structural checks (declared ids attached to something, containers not absorbing children's semantics), and its app-bar title has no header role | `improve-expo-structural-checks.md` (TODO in its index) | unverified |
| A6 | iOS picks ink by perceptual grey (`UIColor.getWhite`), where the others use WCAG luminance; 12 of 51 colours differ. Check the 12 against WCAG AA, and fix the function if any fails | `port-gaps-backlog.md` §2 | **verified open** (`UseSmileIDSampleColorMath.swift:8`) |
| A7 | One owner table in `spec/README.md` for spec debt: the two shell ids no app implements, `sample_env_chip`, `sample_license_link`, the licences wording, button 48 vs 52, glyph 21 vs 20, `screens.json`'s internal contradiction, and whether `components.json` is informative or checked | `port-priority-cut.md` §2 | unverified |
| A8 | A dead-export check: `knip` on the Expo workspace, unused-code rules on Flutter | `port-priority-cut.md` §2 | unverified |
| A9 | An envelope-pumping helper for layout predicates: narrowest width, largest scale, real font, non-zero inset | `port-priority-cut.md` §2 | unverified |
| A10 | Flutter's text-scale predicate cannot fail on truncation, because `didExceedMaxLines && maxLines != 1` excludes every paragraph able to report | `port-review-findings.md` #8 | unverified |
| A11 | The Flutter nav-bar clearance test sweeps five text scales against one tab root | `port-review-findings.md` #12 | unverified |
| A12 | The camera store panel on both stores needs a device run (the flow and output path exist) | `play-release-android.md` REL-A9, `app-store-release-ios.md` §7.2 | unverified |
| A13 | The `verification_details` store panel is sparse without the debug result card: ship it, drop to four panels, or swap in a denser state | both store plans | open by choice |
| A14 | Lift the store-art demo literals (organisation, initials, session id, countdown) into `spec/`, so the two stores' art cannot drift | `app-store-release-ios.md` §7.2 | unverified |
| A15 | Device-suite cycle time: relevance-based flow selection, debug-only per PR with release on `main` and on packaging changes, sharding, and requiring AC power for a full run | `device-suite-cycle-time.md` (proposed, nothing built) | unverified |
| A16 | Document-capture options the sample does not exercise: direct document-type selection, `captureBothSides` following the type, capture mode as a setting asserted on the wire, gallery upload, known aspect ratio (DOC-A0 to A8) | `document-capture-options.md` | unverified |
| A17 | iOS device lane: the camera permission prompt is the one §2.3 bullet left | `ios-device-verification.md` §2.3 | unverified |
| A18 | Android's job-store undo silently discards when asked to remove an id it has no row for; iOS guards on what the removal took | `offline-storage.md` | unverified |
| A19 | Make the Play internal lane run on `push: main`, with a path filter so a docs-only merge does not publish | `play-release-android.md` §7.4 | unverified |
| A20 | Derive `versionCode` from Play's highest code + 1, as iOS now does with `asc_publish.py next-build`, to end the same-ref double-dispatch collision (weighed and deferred once) | `play-release-android.md` §7.4 | open by choice |
| A21 | The registry-consumption lane in this repo: a build-id surface, clean install, resolve → release build → launch → drive, a snapshot arm, the job-summary contract, a companion arm, triage doc, and ports (CON-A1 to A9). CON-A7 needs the SDK repos' agreement | `registry-consumption-e2e.md` | unverified |
| A22 | Every sheet route replaces the screen beneath it on Android, so the scrim covers a bare window. The recommendation is an overlay presentation, adopted with Navigation 3 | `sample-apps-plan.md` §8.2, `ui-feedback-pass.md` F50 | unverified |
| A23 | Pull-to-refresh on the verifications list: unblocked (a refresh matches the partner, not the session), with the shape §8.1 lists | `sample-apps-plan.md` §8.1, `ui-feedback-pass.md` F51 | unverified. `spec/screens.json` says Android replaced the button; check each platform |
| A24 | The Flutter iOS app needs `NSLocationWhenInUseUsageDescription` and `NSPhotoLibraryUsageDescription` before its first upload. `nm -u` the Expo iOS release build too | P20 | **verified open** |

### B. Product rulings: the team's private tracker

| # | Question | Source | State |
|---|---|---|---|
| B1 | Should a profile's stored defaults seed the job form, and should "remember these details" remember anything? | `port-gaps-backlog.md` §4, `after-the-ports.md` Phase 1 | unverified since `profiles-ux.md` (DONE 2026-09-25) |
| B2 | The active-profile edit | same | **appears closed**: iOS reads "Save changes" when the profile is active (`ProfileConfigScreen.swift:109`). Confirm on all four, then close |
| B3 | Button height 48 vs 52, and card glyph 21 vs 20: the spec and the design disagree | `after-the-ports.md` Phase 1 | unverified |
| B4 | The two shell ids in `spec/test-ids.json` that no app implements: build them or delete them | `after-the-ports.md` Phase 1, `ports-final.md` §3 | unverified |
| B5 | May `expo/app` declare `expo-router/testing-library` (test-only) to assert a cold deep link's navigation state? | `port-gaps-backlog.md` §4 | unverified |

### C. Sibling-SDK findings: file in the SDK's repo

| # | Finding | Source | State |
|---|---|---|---|
| C1 | The defect in a sibling repo recorded under `INTERNAL-ONLY reason=defect-in-a-sibling-repo-not-yet-reported` | `play-release-android.md` §3.1 | not filed. Filing it is what closes the block |
| C2 | Flutter SDK: two `si_*` ids missing against Android, `validate()` weaker than `build()` with a silent blank frame, `FlowBuildResult` not exported, and no document analyzer | `ports-final.md` §2, `after-the-ports.md` Phase 4 | drafted, not filed |

### O. Owner and account actions

| # | Action | Source |
|---|---|---|
| O1 | Upload the taller store panels and feature graphic to the Play Console by hand | `play-release-android.md` §7.4 |
| O2 | The next App Store version carries the taller panels and the manifest with the email and phone rows | `app-store-release-ios.md` §7.2 |
| O3 | The `targetSdk` floor check is due each August; last done 2026-08-28 | `play-release-android.md` §7.4 |
| O5 | This app's published Play form marks the crash and diagnostics rows *shared, not collected*. The partner guide and Play's own definition read them as *collected*, and a service provider acting on the app's behalf as *not sharing*. Decide, then correct the form or the guide | `docs/play-data-safety.md`, `docs/store-submission.md` |
| O4 | Create `DESIGN_SYSTEM_TOKEN` (P9), delete `GH_PAT` (P4), and allow merge commits (`after-the-ports.md` Phase 0; squash-only merging is what cost the stacked PRs their approvals) | P4, P9, `after-the-ports.md` |

### S. Cross-SDK planning, not this repo

| # | Item | Source |
|---|---|---|
| S1 | The partner skills: skeleton, recipes, gotcha set with observed-on versions, a snippet compile harness, the append ritual, and a born-public skills repo (SKL-1 to SKL-9) | `integration-skill.md` |
| S2 | Wiring `sample-ui` into the SDK repos' development samples as a submodule, which the iOS SDK Sample's floor change rides with | `offline-storage.md`, `sample-apps-plan.md` §9.1 |
| S3 | The SDK size story (SIZ-1 to SIZ-8), which is published from the SDK repos | `sdk-size-story.md` |

## 7. Tasks, in order

1. **T0 (done 2026-09-25)** The review, §5 and §6.
2. **T1 (partly done)** gitleaks ran clean over all history, and the publish-lane logs are clean.
   Still to do: the PR-lane log sweep (P14) and a second scanner. Reopen D2 on any hit.
3. **T2** Write the documentation set in §3 and §4 to D4's standard, with D8's row shape. Score every
   page against the partner docs' self-review rubric (accuracy, completeness, tab parity, copy-paste
   readiness, readable by an agent, link integrity); no page ships below 4. `docs/store-submission.md`
   is done on this branch.
4. **T3 Carry §6.** File every A row as an issue, put every B row in the private tracker, file C1 and
   C2 in their repos, and hand the O rows to the owner. Tick each row with its issue or tracker link
   **in this doc**, so the register is the audit trail. **T4 cannot start until every row is ticked.**
5. **T4 Distil, then delete.** Write `docs/decisions/` and the distil targets §5 names, re-point the 32
   references (P12), land D7 in `AGENTS.md`, then `git rm` every plan except this one. `git grep
   docs/plan` must return only this doc.
6. **T5** P2, P5, P6, P10, P13: clear the `INTERNAL-ONLY` blocks, local-tool references and private repo
   names, and do the jargon sweep. The sweep covers `spec/*.json`, code comments and test names as
   well as docs. The terms: "Oppo", "CPH2113", "owner ruling", "ruled", item codes (`TOK-A*`, `ENV-A*`,
   `REL-*`, `PVR-*`, `F1`, `C1`…), `prfectionist` and other internal tool names, and staff names.
7. **T6** P3, P7, P8: done on this branch, except enabling private vulnerability reporting (T10).
8. **T7** Third-party asset licences for the fonts, `svgs/`, `design/` and store art. Record each in
   `NOTICE` or on the licences screen.
9. **T8** CI for a public repo: P4, P9, P14 and P16. Fork-PR approval for all outside collaborators,
   every secret sandbox-scoped or in the release environment only, and no job echoing a secret or
   uploading one as an artifact.
10. **T9** Build all four apps from the registry in debug and release with no override. Then follow
    each app README's steps verbatim on a clean checkout. A step that needs something unwritten is a
    doc bug.
11. **T10** GitHub settings: branch protection on `main`, push rights, private vulnerability
    reporting, Discussions, Wiki and Projects off (P17), the P15 branches pruned, description and
    topics.
12. **T11 Final gate.** Rerun the `AGENTS.md` checklist greps and T1, and get the second read (D6) on
    everything the flip publishes. Delete this doc in that PR, then change the visibility. **The flip
    is outward-facing and irreversible, so only the owner does it.**

**One PR, `chore/public-release`**, carries T2 to T8 as they land, with this review and the store
guide first. T1, T9 and T10 are checks and settings, not commits. The partner-docs mirror of the
store guide (D9) and the P21 correction are one PR in that repo.
