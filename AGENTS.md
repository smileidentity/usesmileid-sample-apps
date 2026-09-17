# UseSmileID Sample Apps (v12) — Agents Guide

## What This Repo Is

**Four sample apps for the Smile ID v12 SDKs** — Android (Compose), iOS (SwiftUI), Flutter and
React Native (Expo) — each consuming the SDK **from its public registry**, exactly as a partner
integration does. Smile ID provides digital KYC, identity verification and onboarding across
Africa; these apps are the reference integration partners read and copy from.

They have a second job that shapes every rule below: they are the **consuming host our CI owns**.
An SDK repo's own sample resolves the SDK by path, so it can never catch a defect that lives in the
*published* artifact — a missing dependency, a file absent from the package, keep rules that only
fail under release minification. These apps can, because they consume the published form. Treat a
change that weakens that property as a defect, not a convenience.

## Repo Status — internal now, public later

This repository is **internal today** so the foundations can land, and is intended to **go public**
once the four apps are complete.

Two consequences that must shape what you commit *now*, not at flip time:

1. **Making a repo public publishes its entire git history.** Deleting a file before the flip does
   not unpublish it. Anything that must never be public must never be committed here at all — see
   the never-commit list in *Security & Credentials*.
2. **Internal-only context is allowed, but must be marked** so it can be found and removed before
   the flip. Use the flag convention in *Going Public* below. An unmarked internal reference is a
   bug: it will either leak or block the flip while someone audits by hand.

## Golden Rules

- These rules encode decisions already made — don't relitigate them per change. If a rule
  genuinely shouldn't apply, say so and ask; never silently deviate.
- Precedence when sources disagree: **this file > `docs/` > `spec/` > existing code**. Code that
  violates a rule is debt, not licence to imitate.
- Never claim something works or passes unless you actually ran it; list exactly what you couldn't
  run.
- **Registry-only SDK dependencies, permanently.** Maven Central, the `ios-spm` Swift package,
  pub.dev, the `@smileid` npm scope. No path dependencies, no `dependency_overrides`, no
  `mavenLocal()`, no `workspace:*` for SDK packages, no hand-patched Podfiles. If a build only
  works with an override, that is a finding to file against the SDK — not something to work around
  here. Version bumps arrive as PRs, which makes every bump a free consumption test.
- **Release builds are first-class.** Every platform must have a minified, resource-shrunk release
  lane with no app-side keep rules, because that configuration is where consumption defects
  actually surface. Debug-only verification proves very little.
- **`sample-ui` imports only public SDK API.** Never reach into an internal type, and never depend
  on the SDK's source layout. This is what lets each SDK repo compile this UI against its own HEAD
  as a free API-compatibility gate.
- **`spec/` is the contract, and it is data.** Scenarios, launch arguments, result-card fields and
  test IDs live there once; each app implements them and a unit test asserts the app matches the
  spec. Adding a scenario to one app without adding it to `spec/` and the other three is a bug.
- **Probe affordances are product features here.** The scenario drawer, the on-screen result card
  and the callback counters are how both a human and an automated flow observe what the SDK did.
  They stay in the shipped app; they are honest debug surfaces, not test-only scaffolding.
- **Fixture data is opt-in, per launch.** Example profiles, seeded verifications and any other made-up
  record reach a screen only through a `spec/launch-args.json` argument (`seedJobs`, `seedProfiles`),
  never as a store's default: a launch with no arguments shows a partner nothing that is not theirs,
  and the active profile's organisation is what the SDK's consent screen names as the partner. Each
  platform's unit test asserts the plain default.
- **Design tokens come from the Smile ID design system, generated — never hand-copied.** The apps are
  Smile ID branded and dark mode follows the same colour schemes the SDK uses, because both resolve
  from one token source (three-tier DTCG with pre-generated per-platform output). Consume semantic
  tokens by default and component tokens when building that named component; never a primitive, never
  a raw hex. A hex literal in app code is a review failure. `spec/design-tokens.json` records the
  source, the per-platform consumption and any deltas. Separately, the SDK's public
  `ThemeConfiguration` override is what the theme *scenarios* drive — that is theming behaviour, not
  where token values come from.
- **Uniform visuals, native behaviour.** The design is the same on all four platforms, but
  insets/safe areas, the system back affordance, presentation style (sheet vs dialog vs pushed) and
  keyboard avoidance stay platform-native. A hand-rolled back button that ignores the iOS back
  swipe is the classic way a pixel-perfect port ships a defect.
- **`sample-ui` is identity-agnostic.** The same library runs under eight application identities —
  the four apps here and the four development samples in the SDK repos — so nothing in it may read
  or hard-code an application id, bundle id, URL scheme or app-level resource. Identity lives in the
  shells and in `spec/app-identity.json`; branching on it inside the shared UI breaks one of the
  eight silently.
- **Never claim an id or URL scheme reserved by an SDK repo's sample.** `spec/app-identity.json`
  lists them. Two apps sharing an application id cannot be installed side by side, and two apps
  sharing a URL scheme break automation — a chooser prompt on Android, last-installed-wins on iOS.
- **No changelog in this repo.** Nothing here is published to a registry, so release notes belong
  to the SDK repos. Describe user-visible changes in the PR instead.

## Layout & Where Code Lives

```
spec/                  the cross-app contract as data (see spec/README.md)
docs/plan/             architecture, phases and roadmap for this repo
android/  app/         shell: entry point, navigation host, DI, SDK dependency
          sample-ui/   every screen a partner sees (Gradle library module)
ios/      App/         shell
          SampleUI/    Swift package
flutter/  app/         shell
          sample_ui/   pub package, consumed by path — never published
expo/     app/         shell
          sample-ui/   pure TypeScript package — no native code, no config plugin
```

**Shell vs `sample-ui`.** The shell owns everything that differs between hosts: the SDK dependency,
native configuration, and app wiring. `sample-ui` owns the journey — screens, scenario drawer,
result card, counters, theming. Dev-only surfaces (API scratchpads, component galleries) belong to
a shell, not to `sample-ui`.

**Why the split exists.** Each Smile ID SDK repo pins this repository as a **git submodule** and
maps only its platform's `sample-ui` into its own development sample, substituting the registry SDK
dependency for its local project. One UI source, two consumers:

- this repo's shell resolves the **published** SDK → catches defects in the published form
- an SDK repo's shell resolves the SDK **from source** → catches a broken public API before release

Neither is redundant, and `sample-ui` is **never published** as an artifact — source consumption in
both places is what keeps them from drifting apart.

**Unreleased SDK API.** `main` here must always build against released SDK versions. When SDK work
needs new UI, branch here, let the SDK PR pin its submodule at that branch's SHA (its path shell
compiles this UI against SDK HEAD), and merge to `main` only after the SDK release ships.

## `spec/` — the shared contract

`spec/README.md` is authoritative; the short version:

| File | Owns |
|---|---|
| `scenarios.json` | Every scenario the drawer offers, flow and theme, with stable IDs |
| `launch-args.json` | Canonical automation argument names + the per-platform mechanism |
| `result-card.schema.json` | The result card's fields and types |
| `test-ids.json` | The `sample_*` accessibility IDs flows assert on |
| `screens.json` | Screen inventory, each with its design source and `designVersion` |
| `components.json` | Every component with its owner, tokens, states and the build order |
| `routes.json` | The route table — ids, deep-link paths, typed args, per-platform binding |
| `app-identity.json` | Application ids, display names and URL schemes; plus the ids the SDK repos reserve |
| `design-tokens.json` | The design-system source, per-platform consumption, and recorded deltas |

Two hard rules: **`si_*` IDs belong to the SDK** — reference them, never redefine them here; and
every `spec/` change lands with the four app-side updates, or with an explicit note in the PR
saying which platform is following and why.

## Commands

All four platforms have apps. Each platform exposes one script that is the
definition of done for that platform, mirroring the per-PR CI gate:

```bash
scripts/sync_design_tokens.py --all           # vendor design tokens for every platform present
scripts/sync_design_tokens.py --check         # fail if any vendored token file is stale
python3 scripts/test_sync_design_tokens.py    # tests for the token generator

android/verify.sh     # lint + unit tests + spec validation + release assemble
ios/verify.sh         # swiftformat/swiftlint + tests + release build
flutter/verify.sh     # format + analyze + test + release build
expo/verify.sh        # eslint + tsc --noEmit + test + release build
```

Until then, state plainly in the PR what you could and could not run. Publishing is not this
repo's job; there is nothing here to publish.

**All four platforms run in CI on every PR** (`.github/workflows/android.yml`, `ios.yml`,
`flutter.yml`, `expo.yml`). Each workflow runs that platform's `verify.sh` itself rather than
repeating its steps, so the local contract and the gate cannot drift apart. The Flutter lane runs on
macOS because a Flutter golden is host-rasterised, so a baseline recorded on a Mac and verified on
Linux reds the lane for reasons unrelated to the UI.

`expo/verify.sh` takes a phase, as `ios/verify.sh` does: `all` (the default) is checks plus the
production bundle, and `native` builds the minified release APK on top of a regenerated prebuild. The
prebuild output is never committed, which is what keeps a hand-patched Podfile or Gradle file from
surviving a run.

The iOS project is generated from `ios/App/project.yml` by XcodeGen, so the bundle id, URL scheme and
deployment target stay reviewable and no `.pbxproj` is ever hand-edited; `ios/verify.sh` regenerates
before it builds, and the generated project is not committed.

Two things the token step needs. `--check` compares the vendored output against the design system,
which lives in a **private** repo, so CI checks it out with a secret and points the script at it
through `SMILE_DESIGN_SYSTEM`. A fork PR gets no secrets: there `SMILE_TOKENS_OPTIONAL=1` downgrades
that one step to a logged skip and the run carries a warning saying tokens went unverified. Never set
that variable locally — a silent pass is how vendored tokens drift from their source.

## Conventions

- **Commits: a single conventional-commit subject line** — `type: summary`, e.g.
  `feat: add scenario drawer to the Android shell`. No body, no description paragraphs, no AI
  attribution trailers or "generated with" lines. Small, focused commits.
- **PR titles lead with an emoji and describe the outcome**, matching the SDK repos:
  `<emoji> <scope>: <what changed — why it matters>`. Vary the emoji per change (🧰 tooling,
  📝 docs, 🐛 fix, 🎨 UI, 🔌 wiring, 📦 packaging, ♿ accessibility, 🔒 hardening).
- **Agents: open and update PRs through the `create-pr` skill, never by hand.** It runs the pre-PR
  review, takes the description's rationale from the author rather than the diff, and keeps internal
  context out of what reviewers read.
- **A PR is not finished when it is opened.** Pull its review comments and fix what is real. Who
  left the comment decides what happens next, and this gets skipped often enough to be worth
  spelling out:
  - **A review bot** (`prfectionist`) — fix the valid findings, ignore the false positives, and
    resolve every thread once done. **Do not reply**: nobody reads it, and a thread left open reads
    as unaddressed work. Say in your own summary which findings you rejected and why.
  - **A person** — reply saying what changed and how you verified it, then resolve the thread. Say
    so plainly when a comment is wrong, with the reasoning; silence reads as unaddressed.
- **The doc comment is the documentation; inline comments are the exception.** Every type,
  function and non-obvious property carries a `///` doc comment of **one line** — that is where a
  reader looks, and it is what the formatter enforces on declarations. Inside a body, prefer no
  comment at all: name the thing so the code reads for itself. An inline `//` is earned only by
  something the code cannot say — a measured constraint, a platform trap, an order that looks
  arbitrary and is not, a value that must not change and why. "What this line does" is never a
  reason; if a comment would restate the code, delete it or rename the code instead.
- **One line, and the long form goes elsewhere.** No multi-line commentary anywhere. The reasoning
  behind a decision belongs in `docs/plan/`, which is reviewed, searchable and read on purpose — a
  paragraph above a function is none of those and goes stale where nobody looks. This applies to
  what you add *and* to what you touch: trim a verbose comment on the way past.
- Mirror structure across the four platforms. Same screen, same file name adjusted only for
  platform casing conventions, same relative folder. If you add a screen to one app, add it to the
  other three or explain in the PR why it is platform-specific.
- Naming: this app's own test IDs are `sample_*`. Scenario IDs are `lowerCamelCase` and identical
  across platforms because tests and flows key off them.

## Testing

The pass/fail path never depends on an LLM. Agents author and triage; committed tests are
deterministic.

- **Spec validation** — a unit test per app asserting its scenario list, launch arguments and
  result-card fields match `spec/` exactly. Cheapest test in the repo and the one that keeps four
  apps aligned.
- **Golden/screenshot tests** per platform for each screen, light and dark.
- **Device flows** (Maestro on Android, XCUITest on iOS) asserting on `si_*` and `sample_*` IDs and
  on the result card — never on screenshots or coordinates. Public flows in this repo drive up to
  the capture screen; completing a capture needs frame injection, which is deliberately not part of
  this repository.
- **Structural UI predicates**, which need no design reference to be checkable: no clipping or
  ellipsis at maximum font scale, and status-bar contrast asserted in **both** presentations (modal
  and pushed — one proves nothing about the other, and the result can invert per platform).
- **Registry & companion builds** (candidate lane, not yet implemented) — each app builds with
  its SDK consumed from the public registry only, alongside the companions real partner apps
  bring (a host-initialised Sentry on iOS; whatever the Flutter graph carries transitively).
  Conflicting shared-dependency versions fail before compiling and dyld defects only fail at
  launch, so the lane must end by launching the app, not linking it.
- **Launch integrity and exactly-once results** — every device flow opens with launch → product
  list → SDK-mount assertions so packaging failures fail conclusively, and after any cancel/deny
  exit the result card must report exactly one terminal result, including re-entry via rapid taps.

## Security & Credentials

**Never commit, in any branch, at any time** — this list survives the public flip because history
does:

- partner IDs, API keys, tokens, `.env` files, signing keys or keystores
- production credentials of any kind; automation and local runs use **sandbox only**
- camera replay fixtures or any recorded biometric media
- internal test playbooks, red-team notes, or unfixed vulnerability detail
- real user data, PII, or captured images from any device run

Sandbox credentials reach CI as repository secrets, never as tree contents. Because forked PRs get
no secrets, lanes that need them run on schedule, on release dispatch, or manually — never on
`pull_request` from a fork.

## Going Public — the pre-flip checklist

**The flag convention.** Anything committed that must not survive the flip gets a marker so it is
greppable:

```markdown
<!-- INTERNAL-ONLY:START reason=roadmap-dates -->
...internal-only prose...
<!-- INTERNAL-ONLY:END -->
```

Inline, prefix the item: `- **[INTERNAL-ONLY]** references the internal CI repository`.
In code or config, use a line comment containing `INTERNAL-ONLY` and the reason.

Use it for internal *context* — roadmap and dates, internal repository or tool names, plans for
unreleased SDK features, internal process notes. Do **not** use it as a way to commit anything on
the never-commit list above; no marker can unpublish history.

**Before flipping visibility to public, all of these must be true:**

- [ ] `grep -rn "INTERNAL-ONLY" --exclude-dir=.git --exclude=AGENTS.md .` returns nothing, every
      hit having been removed or rewritten for a public audience. `AGENTS.md` is excluded because it
      documents the convention itself — it is the one expected match, and the section stays.
- [ ] no reference remains to internal-only repositories, internal planning documents, or internal
      tracker items — this repo's docs must stand alone
- [ ] **jargon sweep** — the `INTERNAL-ONLY` grep cannot catch internal shorthand nobody marked, so
      grep explicitly for the terms that mean nothing to a partner: internal probe-app and codename
      references, private repo names, internal tracker prefixes, and any team-only abbreviation. One
      such leak (an internal probe codename used to justify a library choice) was caught in review
      rather than by the marker grep, which is why this line exists
- [ ] history audit: no secret, credential, fixture, biometric media or internal playbook appears
      in **any** commit (`git log --all --stat` for suspicious paths, plus a secret scan). If one
      does, the flip waits on a history rewrite or a fresh-history re-publish
- [ ] all four apps build from the registry with no override, in debug **and** release
- [x] `LICENSE` chosen and added — **MIT**, matching all five sibling repos (2026-08-13). Third-party
      asset licences still to be confirmed as redistributable
- [ ] every credential in CI is sandbox-scoped, and no workflow exposes a secret to a fork PR
- [ ] README, `docs/plan/` and `AGENTS.md` read correctly to an outside partner engineer — no
      unexplained internal shorthand
- [ ] issue templates and repo settings reviewed (branch protection, who can push, discussions)
- [ ] a colleague other than the author has re-read the diff of everything the flip publishes

## Definition of Done

- ⚠️ **Ask first:** adding a new dependency to any app; changing an SDK version; changing anything
  in `spec/` that four apps already implement; adding a native module.
- 🚫 **Never:** commit secrets or fixtures; add a path/override SDK dependency; publish
  `sample-ui`; skip the release lane because debug worked; reference an internal planning doc in a
  committed file without an `INTERNAL-ONLY` marker.

Before finishing any change:

- [ ] The platform's `verify.sh` is green, or you state exactly what you could not run and why
- [ ] `spec/` and the four apps still agree, or the PR says which platform follows and when
- [ ] UI change → goldens updated, light and dark, plus the font-scale and contrast predicates
- [ ] New scenario, screen or affordance → `spec/` updated in the same PR, IDs stable
- [ ] Nothing added to the never-commit list; anything internal-only carries the marker
- [ ] Declarations carry a one-line doc comment; inline comments are gone unless the code cannot
      say what they say
- [ ] The PR's bot findings are fixed or explicitly rejected, and every thread is resolved
- [ ] A launch with no arguments shows no fixture data; anything made up sits behind a launch argument
- [ ] Self-review the diff in priority order: security (no secrets, no PII in logs) → correctness
      (does the release build behave like debug) → consistency across the four apps → readability.
      Don't flag style nits the formatter owns; if you cannot describe a concrete failure scenario,
      don't flag it.

## What agents should NOT do

- Do not add an SDK dependency by path, override or local artifact — the whole repo exists to avoid
  that.
- Do not copy screens between `sample-ui` and a shell, or between platforms, when the shared spec
  or the library should own them.
- Do not introduce camera, ML or networking libraries of your own; the SDK owns capture and
  submission, and a sample that reimplements them stops being a sample.
- Do not add capture-completion tooling, frame injection or fixtures here.
- Do not flip repository visibility, or relax a workflow's secret handling, without the checklist
  above being complete.
