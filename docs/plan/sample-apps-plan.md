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
| Repo conventions (`AGENTS.md`), `spec/` scaffolding, this plan | done |
| `spec/` filled from the design file (F0–F1) | done — screens, components, routes, tokens, test ids |
| Android walking skeleton and screens (F2–F3) | done — shell, 8 primitives, 25 composites, all 14 screens |
| Android result card, callback counters, launch arguments | done |
| Android per-PR CI lane | done |
| Android SDK flow handoff (N2) | done — both presentations, the §7.3 entry gate, exactly-once results on the card |
| Android token session, environment-from-token, Settings, visual refresh | done |
| `appLocale` and `holdCamera` consumers | **owner ruling 2026-08-27: build both on Android before the ports.** `holdCamera` became implementable once the app owned a camera; `appLocale`'s recorded blocker — "no strings for it to affect" — is wrong in the way that matters, because the SDK ships its own localized text and a host override is the better probe against it |
| iOS, then Flutter and Expo | **next** — iOS first: SwiftUI is the nearest idiom to Compose so it validates the translation table most cheaply, it is the parity sibling, it is the only port carrying a structural unknown (§9.1) and better to hit that now than after two ports assume it away, and under §9.2 it needs no new argument mechanism |

<!-- INTERNAL-ONLY:START reason=roadmap-dates-and-work-in-progress -->

### Resume point — paused 2026-08-15

**[INTERNAL-ONLY]** Everything below is working state, not a public roadmap. Delete this whole
subsection before the visibility flip.

Open on `feat/android-result-card`, **PR #12**, nine commits, green and mergeable: the result card,
the callback counters, all seven launch arguments, the design's icon set, and the product cards in
their real hues. Consider splitting it before merge — it is coherent as "the products screen and its
evidence surface", but it is four subjects for one reviewer.

**Pick up here, in this order:**

1. **N2 — the SDK flow handoff: DONE 2026-08-18** (`feat/android-n2-flow-handoff`). Both
   presentations, replace-don't-stack on result, cancellation, recreation survival, the §7.3 entry
   gate, `startFlow()` / `recordResultCallback` / `recordRefreshCallback` wired, and `sandbox`
   consumed by the network handoff. Still owed from step 6's list: consumers for `appLocale` and
   `holdCamera` — each is its own mechanism (in-app locale override; a camera-contention probe) and
   neither blocks the ports.
2. **Port to iOS, Flutter and Expo**, in the same order Android went. `ui-work-plan.md` §4 has the
   port rules; the decisions a port must copy rather than re-take are recorded in `spec/`, not here.
3. **The tail Android still owes**: no launcher icon (§5 item 16 of `ui-work-plan.md`), and the
   `sample-ui` resources have no `resourcePrefix` — the icons are hand-prefixed `sample_ic_*`, which
   the build does not enforce.

**Needs someone else, and none of it blocks N2:**

- **A `DESIGN_SYSTEM_TOKEN` repository secret.** The token `--check` reads the design system from a
  private repo. Until the secret exists that one CI step skips with a warning and the vendored token
  output goes unverified on every run.
- **From design:** the profile→hue list; confirmation of the Enhanced KYC hue and icon, which are
  derived here and marked `origin: DERIVED HERE` in `spec/design-tokens.json`; and whether the nav
  bar takes the three icons that are imported but unused.
- **From the design system:** six recorded gaps, all in `spec/design-tokens.json` → `deltas`. Soft
  badge variants, `color.border` and `color.text.muted` not changing in dark,
  `button.disabled.background` pointing at a primitive, no selected-surface token, the product hues
  existing nowhere in the token source, and Body Strong being 14px in the design file against 16px
  in the token source.
- **From the SDK:** a runtime accessor for its own version, so the result card's `sdkVersion` stops
  being null. See `sdkVersion.blocked` in `spec/result-card.schema.json`.

**Two traps worth re-reading before resuming.** A deep link delivered by `am start` rebuilds the
Activity and discards every in-memory hoist, so a warm-start assertion must be on surviving state
and a flow that wants to observe launch arguments has to tap its way in — R9 in `navigation-plan.md`.
And the device's adb address is DHCP and moves; read it back rather than trusting a remembered one,
and prefer USB, because the wireless link dropped four times during one Maestro pass.

**[INTERNAL-ONLY]** This repository is internal until the four apps are complete; the pre-flip
checklist in `AGENTS.md` gates the visibility change. The private CI repository that adds
capture-completion lanes on top of these apps is a separate, internal-only home — do not name it in
anything committed here once this block is removed.
<!-- INTERNAL-ONLY:END -->

## 8. Deferred work, with the shape it should take

Both of these are design-conformance gaps found on Android and owed by all four platforms. Neither is
a bug in what ships; each needs a decision the code cannot make on its own.

### 8.1 Pull to refresh on the verifications list

The design draws a pull-to-refresh affordance on the verifications list and a `refreshing` state for
it (`spec/screens.json` → `verifications`), and no platform implements either.

It is deferred on purpose rather than forgotten: the list is seeded in memory, so "refresh" has
nothing to fetch, and a spinner that waits a fabricated interval and then re-renders the same rows
teaches a partner the wrong thing about the SDK. **Build it with the first real API call**, which is
when the gesture starts meaning something.

**That trigger has now fired, and it is still not ready — for a different reason (2026-08-25).**
`GET /v3/status/{jobId}` landed through `RetrofitJobStatusSource`, so the original blocker is gone.
But `UseSmileIDSampleJobStore.refresh` returns `SessionMismatch` for any row not submitted under the
*current* token session, so a list-wide pull would refresh only that session's rows and report a
mismatch for the rest — a gesture that visibly does nothing for most of the list, which is worse than
one that is absent. The shape this needs first is a decision about whether a refresh spans sessions at
all, and that is a token question rather than a list one. Written here so the next reader does not
unblock it on the strength of the API call existing. When that lands:

- The gesture belongs to the list, and the refresh belongs to whatever owns the jobs — the store, not
  the screen. The screen renders `refreshing` and calls a suspend function; it does not own a timer.
- A refresh must be idempotent and cancellable: leaving the tab mid-refresh has to cancel it, or the
  result arrives against a disposed screen.
- Failure is a state, not a silent no-op. The design has no error frame for it yet, so ask for one
  rather than inventing a toast.
- The `refreshing` frame is already in `spec/screens.json`; add the platform binding and the test id
  in the same change, and assert it in a device flow — a refresh that never ends is the classic
  regression here and only a flow catches it.

### 8.2 Rendering the screen behind a sheet's scrim

**The defect.** Every sheet route (`profileSwitch`, `newProfile`, `countryPicker`, `idTypePicker`,
`scenarioDrawer`) replaces the destination underneath it, so nothing is composed behind the sheet.
The scrim therefore covers a bare window instead of the screen it belongs to, where the design shows
that screen dimmed through it. Confirmed on a device by reaching the sheet by tapping, so it is not
an artefact of deep-linking straight to one.

**Why it happens.** A sheet is modelled as a route, and a route swap is a replacement: navigation
composes the target and disposes the previous entry once the transition ends. A `ModalBottomSheet`
then paints its own scrim over whatever the window happens to show, which is nothing.

**What well-built apps do.** Every one of them treats a sheet as a layer over the current screen
rather than a screen of its own:

| Approach | Who works this way | What it costs |
|---|---|---|
| The sheet is UI state owned by the screen beneath it — the screen stays composed and renders its own sheet | The common answer in production Compose apps, and what Material's own catalog does | Gives up the sheet being a route: no deep link to a sheet, and a flow cannot open one directly |
| The sheet is a route, but the navigator draws it as an **overlay** above the current destination rather than in place of it | UIKit and SwiftUI natively (`.sheet` presents over the presenter); Navigation 3 on Android models this explicitly as an overlay scene | Needs a navigator that has the concept. Compose Destinations 2.x does not; androidx Navigation 3 does |
| Keep the route, wrap the whole host in one sheet container, and let the route only choose the container's content | How the older Accompanist `navigation-material` bottom-sheet navigator worked, and what Compose Destinations 1.x wrapped | One sheet container for the whole app: every sheet shares one state, and nesting or stacking two is awkward |
| Present the route as a dialog destination, which keeps the destination underneath composed | Available today in Compose Destinations 2.x (`DestinationStyle.Dialog`) | Two stacked windows — the platform dialog plus the sheet's own — which brings a second dim to suppress and makes IME and inset behaviour unreliable. The new-profile sheet has five text fields, so this is the riskiest option, not the cheapest |

**Recommendation.** Take the second row, and take it once for all four platforms: a sheet is a route
whose presentation is an **overlay over the current destination**, never a replacement. Concretely on
Android that means adopting the overlay/scene support in androidx Navigation 3 when this repo moves to
it, rather than bending Compose Destinations 2.x into it now — the dialog-destination workaround buys
the correct backdrop at the price of the exact behaviour (keyboard, insets, dismissal) that
`spec/components.json` → BottomSheet promises is the platform's. iOS, Flutter and React Native already
present sheets over the current screen, so they should be checked rather than changed; the fix is
Android's alone, and the rule belongs in the navigation plan so nobody re-derives it.

**Do not** work around it by painting the window background to look intentional. That hides the
symptom, and a reviewer comparing against the design would report it again.

## 9. Open decisions

1. **iOS `SampleUI` dependency switching** — environment-switched package manifest versus aligning
   the local package identity with the published one. Spike before wiring the iOS SDK repo; the
   other three platforms have no equivalent unknown. Still open, and it is a spike rather than a
   ruling: the published identity is package `UseSmileID` from the SPM distribution repo, while the
   SDK's own repo has no root `Package.swift` and builds through its source layer, so the sample has
   to resolve one package two ways. Answering it by running it beats answering it by choosing.
2. ~~**One cross-platform automation entry point**~~ — **settled 2026-08-27: delivery stays
   per-platform, and that is not a compromise.** (`spec/launch-args.json` changed with this ruling and has
   no app-side counterpart yet: Flutter and Expo have no apps, so the spec rule's four-app note is
   "both follow when their apps land" — say so in the PR rather than leaving it looking unaddressed.) `spec/launch-args.json` already states the contract
   that matters — the argument *names* are identical everywhere and only delivery differs — and the
   names are what keep four apps honest. The deciding evidence is the trap this repo already measured
   on a device: an intent into a live task rebuilds the Activity and resets every argument to its
   default, and flows already deep-link mid-run to reach the scenario drawer. Making deep links carry
   arguments would put those two on a collision course in all four apps, and the fix would be a
   subtle "only the first link counts" invariant replicated four times. So Android keeps intent
   extras and iOS keeps launch arguments, both immune to the drawer link; Flutter and Expo take a
   cold-start deep link, because a native shim in the two Dart-and-TypeScript-first SDKs contradicts
   the thing those SDKs are for.
3. ~~App display name and the four bundle/application IDs~~ — **settled**, see
   `spec/app-identity.json`: display-name family `UseSmileID Sample`, id root
   `com.usesmileid.sampleapps`, one id and one URL scheme per platform. A separate root rather than
   a suffix under `com.usesmileid.sample`, because that space is fully taken by the SDK repos'
   development samples, an id nested under another app's id means "app extension" on iOS, and
   renaming those samples would break four repos' E2E workflows that hard-code them.
4. ~~**Licence**~~ — **settled**: MIT, committed with the scaffold. This entry was stale.
