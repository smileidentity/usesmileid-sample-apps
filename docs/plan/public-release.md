# Making the repository public

**Status:** proposed 2026-09-24. Starts after `ports-final.md` merges. It carries out the pre-flip
checklist in `AGENTS.md` § Going Public; where this doc and that checklist disagree, update the checklist.

**The one-line goal:** a partner engineer can clone, read and build all four apps, and nothing in the
tree, the history, the PRs or the Actions logs exposes a credential, personal data, internal-only
context, or anything that helps a fraudster.

## 1. What the audit found (2026-09-24, tree + all history + 127 PRs + 149 comments)

**Clean:**

- No credential in any commit. A pattern scan of the full `git log --all -p` found no private key,
  cloud key, Sentry DSN or signing password. The two hits are documentation (a `.p8` description in
  `docs/app-store-manual-steps.md`) and a placeholder `sk_live_abcdefgh`.
- No keystore, provisioning profile or `.env` was ever committed. `upload.jks` at the root is ignored.
- Token fixtures are synthetic (`iat` 1760000000). No real partner id, job id or user data.
- Every image is a golden, an app icon or store art. There are no captured faces or documents.
- No machine-local paths, and no private repo or tracker links. PR bodies and comments contain no
  tokens or image attachments.
- No thresholds or defence detail. "Frame injection" appears only as a statement that it is out of scope.

**To fix:**

| # | Finding | Where | Action | Severity |
|---|---|---|---|---|
| P1 | `docs/plan/` is 36 internal working documents: owner rulings by name, device models, sibling-SDK defects not yet filed, process retrospectives | `docs/plan/*` | See D1 | HIGH |
| P2 | Five `INTERNAL-ONLY` blocks still present | `AGENTS.md`, `integration-skill.md`, `ios-device-verification.md`, `play-release-android.md` ×3, `sample-apps-plan.md` | Remove or rewrite; the checklist grep must return nothing | HIGH |
| P3 | Personal email as a script default | `scripts/asc_publish.py:229` | Require `ASC_REVIEW_EMAIL`, with no default | MEDIUM |
| P4 | Publish workflows can be dispatched by anyone with write access, and none uses an `environment:` | `publish-*.yml` ×4 | Add a `release` environment with required reviewers and move the store secrets into it | MEDIUM |
| P5 | Machine-local tooling referenced | `tools/verify/…` in `expo/maestro/README.md:29`, `device-suite-cycle-time.md`, `integration-skill.md`, `ios-device-verification.md`, `token-session-ports.md` | Replace with the in-repo command, or drop the line | LOW |
| P6 | Staff first name in prose | `android-u4-screen-state-goldens.md:173`, `ui-work-plan.md:359` | Covered by D1; otherwise "the owner" | LOW |
| P7 | Dependabot reviewer is a personal login | `.github/dependabot.yaml` ×3 | Use a team handle, and add `CODEOWNERS` to match | LOW |
| P8 | Hygiene files missing | — | `SECURITY.md` (private disclosure route, no public issues for vulnerabilities), `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, issue and PR templates, `CODEOWNERS` | MEDIUM |
| P9 | Fork PRs will run macOS lanes | `flutter.yml`, `ios.yml`, `release-check.yml` | Require approval for first-time contributors. `DESIGN_SYSTEM_TOKEN` already skips on forks — confirm it fails closed on same-repo PRs | LOW |
| P10 | The token-drift step names a private repo (`smileidentity/claude-skills`) | `android.yml:35`, `expo.yml:35`, `flutter.yml:39`, `ios.yml:66` | Keep the check, which is fork-safe. Move the repo name into a variable, and describe the source as "the Smile ID design system" in public docs | LOW |
| P11 | The root README is stale: it says three platforms "have not started" and links `docs/plan/` as the architecture | `README.md` | Rewritten in T5 | HIGH |

**Not run yet:** no secret scanner was installed on this Mac (`gitleaks`, `trufflehog`). The pattern
scan above is a floor, not a proof. Run `gitleaks detect --log-opts="--all"` before the flip (T1).

## 2. Decisions (approved 2026-09-24)

- **D1 — delete `docs/plan/` and replace it with partner documentation.** The plans record how the apps
  were built. A public repo needs to show how to integrate. The old versions stay in history, which is
  acceptable because the audit found nothing sensitive there.
- **D2 — make this repo public, rather than republishing it with fresh history.** History has no
  secret, PII or fraud-relevant content, only internal narrative, and the review trail is engineering
  worth sharing. Republishing would lose 127 PRs and every link to them. Revisit only if T1 finds a
  secret.
- **D3 — agent files stay.** `AGENTS.md` is the contributor guide once P2 is done. `CLAUDE.md` is a
  one-line pointer. Both help partners who build with coding agents.
- **D4 — the docs speak to partners, in the voice of the public docs.** The repo exists to show how a
  partner integrates the v12 SDKs, so every page follows the partner docs' page structure: frontmatter
  intro, prerequisites, steps, "Verify your integration", a symptom / cause / fix table, and a next
  step. Keep them direct, prerequisites first, copy-paste ready, and readable by a coding agent. Use
  the public docs' terms (token session, `/v3/token`, flow builder, `theme { }`) and link to
  docs.smileidentity.com for SDK reference rather than restating it. Each page explains *why* the
  sample does what it does, not only what. That explanation is what a partner can't get from the SDK
  docs.
- **D5 — a generic root README, and a detailed one per app.** The root is short and the same for
  everyone. Each app's README carries the platform detail and links back.
- **D6 — who gives the second read.** The checklist requires a colleague other than the author.

## 3. The documentation set

| Page | Audience question it answers | Built from |
|---|---|---|
| `README.md` (root) | What is this, which app do I open, what do I need | Rewritten. Four apps and what each shows, the registry-only rule and why, prerequisites common to all, links to the four app READMEs and the guides, licence, security contact |
| `android/README.md` | How do I run it and where is the integration | Build, run, deep links, device flows; **where the SDK is called** (file map: builder config, flow host, result handling); Android-specific notes (ML Kit vs Huawei, R8 rules, min/compile SDK) |
| `ios/README.md` | same, for iOS | XcodeGen, SPM resolution, signing for a device, the iOS 15 floor, XCUITest ids |
| `flutter/README.md` | same, for Flutter | pub.dev resolution, ML provider plugins, Android ABI split, Maestro lane |
| `expo/README.md` | same, for Expo | pnpm workspace, prebuild, the mandatory worklets Babel plugin, one ML provider per platform, Maestro lane |
| `docs/integration.md` | What does a real integration look like end to end | One product traced across all four apps, tabbed: build the flow, run it, receive the result, store the job, poll `GET /v3/status`. Why each step is where it is |
| `docs/token-session.md` | How do I avoid shipping an API key | Scanning a QR or pasting a token, what the token binds (consent, user details, environment), the countdown and expiry, why the gate sends a run back to the scanner. From `token-session-android.md` and `token-binding-matrix-android.md`, without internal item codes |
| `docs/theming.md` | How do I make the SDK look like my app | See §4 |
| `docs/architecture.md` | How are the four apps kept identical | `spec/` as the contract, `sample-ui` vs `app` split, the navigation model, persistence. From `sample-apps-plan.md` and `port-patterns.md` |
| `docs/testing.md` | How do I test my own integration like this | Goldens light/dark and font scale, layout predicates, device flows on `si_*`/`sample_*` ids (never coordinates or screenshots), the registry-consumption lane. From `device-suite-cycle-time.md` and the Maestro READMEs |
| `docs/releasing.md` | How do the apps reach the stores | The existing `docs/app-store-*.md` and `docs/play-data-safety.md` folded into one runbook, secrets named but never valued |

## 4. Theming best practices (`docs/theming.md`)

What this repo does, written as advice a partner can copy:

1. **Two layers, kept apart.** The host app has its own theme. The SDK flow gets its colours through
   the flow builder's `theme { }` override. The sample never styles SDK screens any other way. Show
   the override on all four platforms, tabbed (`FlowBuilderConfig.kt`,
   `use_smileid_sample_flow_builder_config.dart`, `use-smile-id-sample-flow-builder-config.tsx`, the
   iOS equivalent), and the two theme scenarios in `spec/scenarios.json`.
2. **One token source, generated per platform.** Colours, type ramp, spacing, radii and shadows come
   from one design-token set. `scripts/sync_design_tokens.py` vendors it into Kotlin, Swift, TS and
   Dart, and a CI check fails when the vendored copy drifts. Advice: never hand-edit generated tokens,
   and change the generator instead.
3. **Semantic roles, not raw values.** Screens read `primary`, `surface` and `onSurface`, never a hex
   value. Light and dark are paired per role, so dark mode is a lookup, not a second stylesheet.
4. **Dark mode follows the system until the user overrides it.** That includes the system bars (#125),
   and the SDK override receives the matching palette.
5. **Contrast is computed, not eyeballed.** Ink on a fill is chosen by WCAG relative luminance.
6. **Text scales.** Layouts are tested at the largest font scale and the narrowest width. Measure
   chrome such as the floating nav bar instead of hard-coding its height.
7. **Fonts are bundled and licensed.** DM Sans ships under the OFL, and it appears on the licences
   screen.
8. **Prove it with goldens.** Every themed state is recorded light and dark, and the recording
   happens on CI, never on a laptop.
9. **Common issues.** An override that is ignored because it was set after `build()`. Dark-mode
   screens with light system bars. Clipped labels at 200 % text. Baselines recorded on a Mac that
   differ from CI.

Before writing, confirm each claim against the code, and cut any point this repo does not actually do.

## 5. Tasks, in order

1. **T1** Install `gitleaks` and scan the full history. Stop and reopen D2 on any hit.
2. **T2** Write the documentation set in §3 and §4 to D4's standard. Score every page against the
   public docs' self-review rubric (accuracy, completeness, tab parity, copy-paste readiness, readable
   by an agent, link integrity); no page ships below 4.
3. **T3** Delete `docs/plan/`, then fix every link that pointed into it (`git grep docs/plan`, in code
   comments too).
4. **T4** P2, P5, P6, P10: clear the `INTERNAL-ONLY` blocks, local-tool references and private repo
   names, and do the jargon sweep. The sweep covers "Oppo", "CPH2113", "owner ruling", item codes
   (`TOK-A*`, `F1`, `C1`…), `prfectionist` and other internal tool names, in code comments as well as
   docs.
5. **T5** P3, P7, P8: the script default, `CODEOWNERS`, dependabot reviewers, and `SECURITY.md`,
   `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, issue and PR templates.
6. **T6** Third-party asset licences for fonts, `svgs/`, `design/` and store art. Record each in
   `NOTICE` or on the licences screen.
7. **T7** CI for a public repo: P4 and P9, the fork-PR approval setting, every secret sandbox-scoped or
   in the release environment only, no job echoing a secret or uploading one as an artifact.
8. **T8** Build all four apps from the registry in debug and release with no override. Then follow each
   app README's steps verbatim on a clean checkout. A step that needs something unwritten is a doc bug.
9. **T9** GitHub settings: branch protection on `main`, push rights, Discussions, description and topics.
10. **T10** Final gate: rerun the `AGENTS.md` checklist greps and T1, and get the second read (D6) on
    everything the flip publishes. Then change the visibility. **The flip is outward-facing and
    irreversible: owner only.**

One PR for T2–T7 (`chore/public-release`). T1, T8 and T9 are checks and settings, not commits. This doc
is itself deleted by T3.
