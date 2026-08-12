# Plan — four sample apps, one journey

**Status:** proposed; nothing here is built yet. This document is the shared plan for building this
repository, so a colleague or an agent can pick up any piece without re-deriving the reasoning.
`AGENTS.md` holds the rules; this holds the *why* and the order of work.

---

## 1. Why this repo exists

Two jobs, and the second one is why the constraints are strict.

**Job one — the reference integration.** Partners ask for a realistic integration: a navigation
shell, state management, theming, a real journey. A minimal demo does not answer their questions.

**Job two — the consuming host our CI owns.** An SDK repo's own sample resolves the SDK *by path*.
That means the sample compiles against library sources, minification runs with the repo's own keep
rules, and dependency resolution never behaves the way a partner's build does. A whole class of
defect is therefore invisible in the SDK repo no matter how good its tests are:

| Class | What it looks like | Why an in-repo sample cannot see it |
|---|---|---|
| Delivery | A dependency the SDK links but the published package never ships; a package missing native folders; a library product never linked | The path build resolves it from the checkout — the packaged form is never exercised |
| Consumer toolchain | Release minification stalls a flow; a partner's default lint fails on our guidance; a dependency version ceiling nobody hits internally | Lint sees library sources, minification runs with repo keep rules, resolution differs from a partner's |
| Host interaction | Vertical space lost to host chrome; status-bar contrast that passes in one presentation and fails in the other; a camera not released after navigating away | The in-repo sample is a friendly host — no clashing theme, no nested navigation |
| Runtime contract | "The result callback fires exactly once"; token refresh is single-flight | Nothing counts the callbacks, so nobody can assert it |

Every rule in `AGENTS.md` — registry-only dependencies, mandatory release lanes, the result card,
the counters, the two entry routes — exists to make one of those observable. Weakening one is not a
convenience; it removes coverage that nothing else provides.

---

## 2. Architecture — one UI, two shells

The journey UI is written **once**, as a `sample-ui` library per platform. An app is that library
plus a thin shell whose only real job is answering *where does the SDK come from*.

```
             sample-ui  (this repo — the ONLY copy of the journey UI)
                     │                                          │
               consumed here                         + as a pinned submodule
                     │                                          │
  ┌──────────────────▼─────────────────┐     ┌──────────────────▼─────────────────┐
  │ THIS repo's shell                  │     │ an SDK repo's shell                │
  │   android/app, ios/App,            │     │   android/sample, ios-v12/Sample,  │
  │   flutter/app, expo/app            │     │   flutter/sample, sample-expo      │
  │                                    │     │                                    │
  │ SDK from the REGISTRY              │     │ SDK from SOURCE                    │
  │   Maven Central · ios-spm          │     │   project(":usesmileid") etc.      │
  │   pub.dev · npm @smileid           │     │                                    │
  │                                    │     │                                    │
  │ → what a partner really gets       │     │ → compiles this UI vs SDK HEAD     │
  │ → catches published-form defects   │     │ → catches API breaks pre-release   │
  └────────────────────────────────────┘     └────────────────────────────────────┘
```

Neither shell is redundant. The left one cannot see an API break until after release, because it
consumes the last published version. The right one cannot see a delivery defect at all, because it
never touches a published artifact. Running both over one UI is the whole point — and it is why
`sample-ui` is **never published**: a binary compiled against release *N* cannot compile against
SDK HEAD, and compiling against HEAD is the right-hand shell's entire job.

**Wiring per platform.** Each SDK repo pins this repo as a submodule and substitutes the registry
SDK dependency for its local one:

| Platform | `sample-ui` form | Substitution in the SDK repo |
|---|---|---|
| Android | Gradle library module | include by `projectDir` + `dependencySubstitution` mapping `com.usesmileid:*` to local projects; `sample-ui` applies plugins unversioned so each host supplies AGP/KGP |
| iOS | `SampleUI` Swift package depending on the `ios-spm` package | local path reference; the SDK dependency flips by environment because the local package identity differs from the published one — **spike this first, it is the only unknown in the wiring** |
| Flutter | `sample_ui` pub package, path-only | path dependency + `dependency_overrides` (overrides belong to the SDK-repo shell, never to this repo) |
| Expo | pure-TS `sample-ui`, SDK as `peerDependencies` | add the submodule path to the workspace; peers resolve to the in-repo packages, so no substitution machinery is needed |

**Rules that keep it honest:** public-API-only imports; never published; pinned SHAs advanced by
PR; and `main` here always builds against a released SDK, so UI for unreleased API waits on a
branch (see `AGENTS.md`).

---

## 3. The contract lives in `spec/`

Four apps agree because they read the same data, not because four reviewers were careful. See
`spec/README.md`. The scenario list, launch arguments, result-card fields and `sample_*` IDs are all
there, and each app validates itself against them in a unit test — the cheapest test in the repo and
the one that keeps the apps aligned.

---

## 4. Build order

Fidelity work is the slowest part of building four apps, and none of the CI value depends on it. The
lanes assert on the *affordances* — drawer, result card, counters, launch arguments, routes — so the
order below deliberately front-loads those and lets pixel work run behind them.

```
  Design file (uniform across all four platforms)
        │
        │  F0  freeze pages, record each screen        F1  extract tokens, once
        ▼      + node URL in spec/screens.json             ▼
   spec/screens.json ───────────────────────────────→  spec/design-tokens.json
   (screen ⇄ design node ⇄ states ⇄ designVersion)     (SDK token refs + additions)
        │                                                 │  generated per platform,
        │                                                 │  never hand-copied
        ▼                                                 ▼
   F2  WALKING SKELETON ×4 — every screen present, unstyled, affordances wired
        │   exit criteria are behavioural, not visual:
        │     registry-only release build green ×4
        │     result card + drawer + counters + launch args + both entry routes
        │     one device flow per platform asserting on IDs and the card
        ├──────────────────────────────────────────────────────────┐
        ▼                                                          ▼
   F3  FIDELITY, per platform, per screen               CI LANES START HERE
        │   Android reference first, then the three      consumption · release
        │   ports; uniform visuals, native behaviour     spec validation · flows
        ▼                                                size · lint-on-host
   F4  hostile-host tail: theme scenarios, dark mode, font-scale and contrast
        │   invariants, tablet, nested-navigation insets
        ▼
   F5  goldens per platform; design review at PR time using the node URL from spec/
```

**F0–F1** (~3 days, once): inventory and tokens. Tokens are extracted once and *generated* into
four theme sources; see the anti-drift rule in `spec/design-tokens.json`.

**F2** (~1 week per platform, parallelizable): the milestone worth defending. Deliberately ugly.

**F3** (~1–2 weeks for the reference, ~1 week per port): the design is uniform, so ports carry no
redesign — but insets, system back, presentation style and keyboard avoidance stay native. A
hand-rolled back button that ignores the iOS back swipe is how a pixel-perfect port ships a defect.

**F4–F5** (~3–4 days per platform): the theme scenarios plus the two invariants that need no design
reference — no clipping at maximum font scale, and contrast asserted in **both** presentations.

**Agent leverage:** one screen, four platforms is the natural shape for parallel agent work with a
human arbiter — the reference implementation and `spec/` settle anything ambiguous. Agents author and
triage; humans review and merge; committed tests stay deterministic.

---

## 5. CI lanes this repo owns

| Lane | Asserts | Cadence |
|---|---|---|
| Consumption | All four apps resolve from the registry and build, **debug and release** | every PR + on SDK release |
| Spec validation | Each app matches `spec/` exactly | every PR |
| Goldens | Screens unchanged, light and dark | every PR |
| Device flows | Journey up to the capture screen, asserting on IDs and the result card | every PR (emulator/simulator) |
| Structural predicates | Font-scale clipping, status-bar contrast in both presentations | every PR |
| Consumer-measured size | Release artifact size, with and without the SDK, per platform | on release + weekly |
| Lint on the consuming host | Partner-default lint and release gates pass on a consuming app | every PR |

Two notes that will save a debugging session. Forked PRs get no secrets, so any lane needing
sandbox credentials runs on schedule, release dispatch or manual trigger only. And size measurement
is quota-limited upstream, which is why it is release-plus-weekly rather than per-PR.

---

## 6. What this repo deliberately does not own

- **Completing a capture.** Driving a flow past the capture screen needs synthetic camera frames.
  That tooling and its fixtures live elsewhere, privately, and must never be added here — see
  `AGENTS.md`. Flows in this repo stop at the capture screen, which still covers layout, chrome,
  insets, permissions, cancellation and every pre-capture contract.
- **Publish-time validation of the SDKs.** Package linting, publication dry-runs and release
  canaries belong to the SDK repos, next to the thing being published.
- **Release notes.** Nothing here is published to a registry.

<!-- INTERNAL-ONLY:START reason=dependency-status-of-unreleased-tooling -->
- **[INTERNAL-ONLY]** Capture-completion lanes are sequenced *after* this repo's own milestones:
  the injection tooling is still being fixed in its own library and those changes are not yet in
  the SDKs. Plan F2–F5 as if capture completion does not exist; adopt it later as an additive lane
  in the private CI repo, not here.
<!-- INTERNAL-ONLY:END -->

---

## 7. Status and next steps

| Step | State |
|---|---|
| Repo conventions (`AGENTS.md`), `spec/` scaffolding, this plan | in this branch |
| `spec/screens.json` + `design-tokens.json` filled from the design file (F0–F1) | next |
| Walking skeleton per platform (F2) | after F0–F1; parallelizable across platforms |
| SDK repos wired to `sample-ui` as a submodule | after the first platform's skeleton, per platform |
| Fidelity, hostile-host tail, goldens (F3–F5) | concurrent with CI lanes, never in front of them |

<!-- INTERNAL-ONLY:START reason=internal-repo-and-visibility-plan -->
**[INTERNAL-ONLY]** This repository is internal until the four apps are complete; the pre-flip
checklist in `AGENTS.md` gates the visibility change. The private CI repository that adds
capture-completion lanes on top of these apps is a separate, internal-only home — do not name it in
anything committed here once this block is removed.
<!-- INTERNAL-ONLY:END -->

## 8. Open decisions

1. **iOS `SampleUI` dependency switching** — environment-switched package manifest versus aligning
   the local package identity with the published one. Spike before wiring the iOS SDK repo; the
   other three platforms have no equivalent unknown.
2. **One cross-platform automation entry point** — a deep link would work identically on all four
   platforms; native launch arguments are already proven on two. Decide when the second app lands
   (see `spec/launch-args.json`).
3. ~~App display name and the four bundle/application IDs~~ — **settled**, see
   `spec/app-identity.json`: display-name family `UseSmileID Sample`, id root
   `com.usesmileid.sampleapps`, one id and one URL scheme per platform. A separate root rather than
   a suffix under `com.usesmileid.sample`, because that space is fully taken by the SDK repos'
   development samples, an id nested under another app's id means "app extension" on iOS, and
   renaming those samples would break four repos' E2E workflows that hard-code them.
4. **Licence** — required before the repository can go public.
