# Navigation plan — per platform, one route table

**Status:** ready to start, and it runs alongside the UI work rather than after it. Screens without
navigation are previews; navigation without screens is untestable. Build them together, per screen.

**The shared contract is `spec/routes.json`** — route ids, deep-link paths and typed arguments,
identical on all four platforms, with the platform binding named per route. Read it first; this
document explains the architecture and the traps.

**Library choices, and why each one:**

| Platform | Navigation | State | Why |
|---|---|---|---|
| Android | **Compose Destinations 2.3.0** (`io.github.raamcosta.compose-destinations`) over androidx.navigation 2.9.8 | ViewModel + `SavedStateHandle` | The SDK itself uses it (`@Destination<RootGraph>`, `DestinationsNavHost`), so the sample and the SDK share one mental model and one dependency set |
| iOS | **NavigationStack + a typed path router** | `@Observable` router + `@SceneStorage` | The SDK does not nest a `NavigationStack`, so a host stack is safe (see §3) |
| Flutter | **go_router ^17** | **flutter_riverpod ^3** | `StatefulShellRoute` gives per-tab back stacks for free; Riverpod's `ProviderScope` overrides turn launch arguments into deterministic test state with no test-only build (§4) |
| Expo | **expo-router** (already in the sample) | **zustand ^5** | Proven together on an internal integration probe; file routes map 1:1 to the route table |

---

## 1. Thirteen rules that apply to every platform

These are what keep four navigation implementations behaving the same. Most of them exist because a
specific defect was found on a device, not because they read well.

**R1 — Routes are data.** Every route in `spec/routes.json` exists on every platform with the same
id, path and arguments. A route added to one app without the table and the other three is a bug.

**R2 — The SDK flow is one opaque destination.** The SDK owns its own internal navigation: on
Android `UseSmileIDBuilder` hosts a nested `DestinationsNavHost` with its own `NavController`; on
iOS `UseSmileIDBuilder` renders a `FlowNavigationView` driven by its own `FlowNavigationManager`.
The host must never model consent, instructions, capture, preview or processing as its own routes,
never try to drive the SDK's back stack, and must let the SDK consume a back gesture **first**.

**R3 — That destination has two presentations.** Full-screen and nested in the navigation shell, from
the same route with a `route=fullscreen|shell` argument. This is not a nicety: the in-shell
presentation is the one that exposes host-chrome and inset defects, and the full-screen one is what
partners copy. Both must exist, and both must be reachable by deep link.

**R4 — After the result, replace rather than stack.** When the SDK returns, pop the flow *and* both
pre-flow forms, then land on `verificationDetails` in its processing state. Back from there goes to
the originating tab — never back into capture. Getting this wrong is how a user swipes back from a
result into a live camera.

**R5 — Hiding is not cancelling.** iOS makes this explicit: `FlowTeardownSentinel` delivers
cancellation on `deinit` only, because a `@StateObject` outlives mere hiding. So a flow parked in an
inactive tab, or retained by a sheet that stays in memory, is still running and still holding the
camera. To cancel, remove it from the hierarchy. Android's equivalent is leaving the destination so
the composition and its ViewModel are disposed. Never host the flow in a container that retains it.

**R6 — Anything the user typed survives recreation.** The Consent Details Form and ID-details form
values, the active scenario and theme, the selected tab, and each tab's back stack must survive
rotation, process death and the system killing the app behind the camera. Two specifics:

- Store the token session as an **absolute deadline**, never a ticking counter. A counter restarts at
  the wrong value after restoration; a deadline is correct by construction.
- Any identity key the host generates for the flow destination must be **saveable**. On Android this
  exact bug has already been found on a device: a key created with `remember { UUID.randomUUID() }`
  is regenerated on recreation, so the ViewModel behind it is never the one that was saved. Use
  `rememberSaveable`, or derive the key from the route arguments.

**R7 — Per-tab back stacks are preserved.** Switching tabs and returning keeps the stack. Deep links
into a tab's detail route build a sensible parent stack so back works.

A caveat that came out of R13: because a pushed screen carries no nav bar, you cannot switch tab from
one — you go back first. So the preserved stack is in practice the tab's root, and a flow cannot test
preservation by switching tabs from a detail screen the way the Android flow used to.

**R8 — Sheets are layers over their owner. CORRECTED: see `port-patterns.md` R12, which is the
rule.** This entry said the four sheets (profile switch, new profile, country, ID type) were
destinations. That arrangement **was fixed as a defect on 2026-08-26**: routing a sheet replaced the
screen it should have been covering, so its scrim dimmed a flat grey void. R12 records the fix and
the per-platform idiom — a boolean the owning screen holds, presented with the platform's own sheet.

What still holds from this rule, and what R12 already provides for: a sheet's deep link must
resolve, and a flow must be able to assert one. R12's mapping is how — the link resolves to the
OWNER's link plus a sheet request, which the owner consumes. `spec/routes.json` keeps the five sheet
paths for exactly that. The native behaviour this rule asked for — drag-to-dismiss, scrim tap, inset
handling — is a reason to use the platform's sheet rather than a routed one, not a reason to route.

Do not restore the routed arrangement from memory; it is the thing that was removed.

**R9 — Cold start is the test that matters.** Every route must open with the process not already
running. Cold-start deep links are where argument parsing, state restoration and "the tab bar isn't
built yet" break.

The corollary "warm start works by accident" needs a caveat on Android, measured on a device
2026-08-14 by logging the Activity identity, task id and intent across both starts.

A deep link delivered by `am start` — which is what adb and Maestro's `openLink` both do — carries
`FLAG_ACTIVITY_NEW_TASK`, and its intent does not match the root intent of the task the app is
already running in. The system's answer is to build a **second Activity instance** as the new root
of that same task, with `savedInstanceState` null. So every in-memory hoist goes: the launch
arguments, the scenario the drawer selected, the token session. `launchMode` does not change this —
it reproduces identically under `singleTop` and `singleTask`, which is why the app still declares
the simpler `singleTop`.

Two consequences worth carrying to the other three platforms:

- An adb- or Maestro-delivered deep link is **always effectively a cold start**, whatever the app
  was doing. It is not a warm-path test, and `ForwardNewIntentsTo` is not what serves it.
- Nothing looks wrong on screen when this happens, because the replacement renders the destination
  correctly. Only state that should have survived shows it. So a warm-start assertion has to be on
  **surviving state** — the result card's `activeScenario` is the cheapest one — and a flow that
  wants to observe launch arguments must reach its destination by tapping, not by deep link.

**R10 — A confirmation belongs to the screen the action returns to, not to the screen that fired it.**
Settled 2026-08-18 on the profile flow, where the design puts the "created" confirmation on the
profiles list rather than on the sheet that created the profile. Three consequences the other three
platforms inherit:

- The sheet cannot own it. It is dismissing, so anything anchored inside it dies with it. The
  creating call records the new id on the profiles store and the list reads it, which also survives
  the recreation R6 covers.
- The confirmation carries the follow-up action the design offers ("Make active"), because creating
  a profile deliberately does **not** activate it.
- ~~A deep link straight to the sheet returns to the graph's start destination, not to the list, so
  no confirmation appears.~~ **Does not survive R8's correction.** That was a property of the routed
  arrangement: only a sheet destination could strand the graph at its start. Under R12 a sheet link
  resolves to its owner plus a sheet request, so the list is already open underneath and the
  confirmation has somewhere to appear. A flow may reach the sheet by link or by tapping.

The profile flow this settles, end to end: settings PROFILE row → `/profiles` (the LIST, not the
active profile's page) → a row → `/profiles/:id`, titled with the profile's name, whose CTA both
saves the defaults and activates → or "Create new profile" → `/profiles/new` → back to `/profiles`
with the confirmation.

**R11 — Motion says what the route table says.** Settled 2026-08-18 on Android and owed by the other
three. The route table has two relationships and each gets its own motion, so the animation is never
decoration:

| Relationship | Motion |
|---|---|
| Push / pop a deeper route | Fade **through** — out in 100ms, in over 160ms after it — plus a travel of **one eighth** of the width toward the start, reversed on pop |
| Switch between the three tab roots | The same fade through, with no travel: siblings have no direction |
| A route that draws its own presentation (every sheet) | **None** — the sheet animates itself, and animating the destination too slides the scrim in before the sheet exists |
| The SDK flow | Fade only. It owns its own navigation (R2), so the host must not imply a direction |
| A bar arriving over a screen (snackbar, selection bar) | Rise 220ms with a 160ms fade, and the caller **holds** what the bar reads so it still has something to draw on the way out |

Three traps, each found on a device:

- **"Different parent graph" is not "tab switch".** A pushed route lives in the root graph, so
  comparing parents classified Settings → Profiles as a tab switch and cross-faded a push. Compare
  against the three tab **start routes** instead.
- **Cross-fading two dense screens reads as a rendering fault** — both are legible at once, at half
  opacity, so the old screen's text shows through the new one. Fade through instead: clear, then
  arrive. This is why the fade in carries a delay equal to the fade out.
- **A full-width slide is too much.** Reviewed on a device 2026-08-18: it announces the navigation
  instead of serving it. The apps people compare this against move a *fraction* of the width, fast,
  and the eye reads direction without following anything across the screen. An eighth of the width
  over 200ms, with the fade through on top, is the setting that survived review.
- **The nav bar must animate out with the screen that covers it**, and something must hold the last
  selected tab, or the bar redraws with no selection on its way off screen.

**R12 — A sheet route is a layer over the current destination, never a replacement.** A sheet that
replaces the destination beneath it has nothing behind its scrim, where the design shows the screen it
covers. This was broken on Android and correct on the other three by construction, because their
platforms present sheets over the presenter. The evaluated options and the recommendation are in
`sample-apps-plan.md` §8.2; the short version is that the presentation belongs to the navigator, and
the workaround that fakes it with a dialog destination costs the native sheet behaviour R8 asks for.

**Ruled 2026-08-24, and it is a rule rather than a recommendation: use Material 3's own practice.**
`androidx.compose.material3.ModalBottomSheet`, owned by the screen beneath it. The screen stays
composed by construction, so the scrim covers the right thing, and it needs no new dependency.
Destinations' `bottom-sheet` artifact would also fix it and was rejected: it depends on
`androidx.compose.material:material-navigation`, which ships a second Material library and themes the
sheets from M2 rather than the app's M3 (NAV-A6 rejected it on the same grounds).

The one cost is that M3's pattern gives up sheet-as-route, and `spec/routes.json` declares five sheet
routes with deep links. Keep the contract by making each sheet route resolve to **its parent screen
with the sheet open** — `/profiles/switch` navigates to Products with the switch sheet showing —
rather than to a destination of its own. The five paths keep working, the deep links keep working, and
the sheet becomes state on the screen that owns it. NAV-A5's revisit trigger does not fire: the sheets
still commit to the shared stores, so nothing moves into screen-local state. iOS, Flutter and React
Native already present sheets over the current screen and should be checked, not changed.

**BUILT 2026-08-26.** The five sheets are plain composables their owning screen renders behind an
`if`, and `UseSmileIDSampleSheetLinks` is where a sheet path becomes an owner plus a sheet:

| Path | Owner | Sheet |
|---|---|---|
| `/profiles/switch` | Products | `ProfileSwitch` |
| `/profiles/new` | Profiles | `NewProfile` |
| `/debug/scenarios` | Settings | `ScenarioDrawer` |
| `/flow/:productId/id-details/country` | ID details form | `CountryPicker` |
| `/flow/:productId/id-details/id-type` | ID details form | `IdTypePicker` |

Three decisions the mechanism turned on, none of them obvious before building it:

1. **The link is handed to the owner's own deep link**, not to a hand-built direction, so a sheet path
   lands on exactly the back stack its owner's path would — `/flow/x/id-details/country` behaves as
   `/flow/x/id-details` plus an open sheet, rather than inventing a stack of its own. When the owner is
   already the current destination, which is every cold link to a tab root, it is not re-handled: doing
   so would replace the very screen the sheet has to layer over.
2. **The request is held above the graph and consumed on sight.** The owner is not composed when the
   link arrives, so the sheet cannot be opened directly; the owner picks the request up keyed on its
   value rather than once, so arrival order does not matter, and consuming it stops a later return to
   the owner replaying the sheet.
3. **The sheet's own open/closed flag is saveable**, because a sheet destination survived rotation and a
   plain boolean would not have. That is the one behaviour the old shape got right for free.
4. **The query is dropped when a sheet path is rewritten.** `probes` is read off the launching intent
   as a launch argument, not off the route, so `/debug/scenarios?probes=true` still seeds the card.

The scenario drawer keeps one asymmetry worth stating: its Settings row is debug-only, but the layer is
not, because `/debug/scenarios` is how every device flow reaches it on a release build too.

**R13 — The nav bar belongs to the tab roots, and it floats.** Two halves, both found on a device
2026-08-18:

- **Shown on the three tab roots only.** A route living inside a tab's graph is not the same as being
  that tab: verification details sits in the verifications graph, and testing graph *membership* put a
  nav bar on a pushed screen that the design draws without one. Match the graph's **start
  destination**. Every pushed screen in the design is bar-less.

  Whether a screen carries a bar is a property of the **destination**, not of how you reached it — the
  predicate takes the current destination and nothing else, so it was never a deep-link-only fault. The
  device flows assert the absent bar on **both** arrival routes for that reason: `shell-navigation`
  covers the deep link and `verifications` covers the tap.
- **It floats over the content, not beside it.** The design draws a pill on a shadow with the list
  continuing underneath. Putting it in a bottom-bar slot insets the content instead, which drew a
  visible seam across the screen with the last row clipped against it — the bar read as its own
  section rather than as something over the page. The consequence to carry: the content is *not* inset
  by the bar, so a screen's own trailing spacer is what lets its last row scroll clear, and anything
  else anchored to the bottom of a screen has to clear the bar itself.

Select mode is the exception that proves the rule: its bar is opaque with a top edge, so it *replaces*
the bottom chrome and content does stop above it.

---

## 2. Android — Compose Destinations 2.3.0

Same library and version as the SDK, so KSP-generated typed destinations behave identically in both.
Build requirement: the sample app module needs the KSP plugin; it resolves the SDK from Maven, so it
does not have to match the SDK's Kotlin version, only supply its own.

- **Graph shape.** One `RootGraph`, one nested graph per tab, `DestinationsNavHost` at the app shell.
  Bottom-nav switching uses the standard `popUpTo(startDestination) { saveState = true }` +
  `restoreState = true` pattern, which is what satisfies R7.
- **Typed arguments.** Declare navigation arguments as the destination composable's parameters and
  let KSP generate the typed `…Destination(productId = …)` call. No manual string routes.
- **Deep links.** `@Destination(deepLinks = [DeepLink(uriPattern = "…")])` per route, with the scheme
  from `spec/app-identity.json`. Verify cold start; and note from R9 that an externally delivered
  deep link is a cold start even when the app was already running.
- **Hosting the SDK flow.** A single destination whose content is `UseSmileIDBuilder { … }`. Because
  that nests a `NavHost` inside a `NavHost`: give the inner controller the back gesture first (do
  not add a host-level `BackHandler` that swallows it), keep predictive-back enabled so the inner
  stack animates correctly, and never place this destination inside a tab that stays composed.
- **State.** Form state in a ViewModel with `SavedStateHandle`; transient UI state in
  `rememberSaveable`. Settings persist to `DataStore` so the SDK-step toggles survive restart.
- **Sheets.** A boolean the owning screen holds plus the platform's `ModalBottomSheet`, removed from
  composition when hidden — not a destination. See R8's correction and `port-patterns.md` R12.

## 3. iOS — NavigationStack with a typed path

- **Router.** An `@Observable` router holding `path: [Route]` where `Route: Hashable & Codable`, and
  `NavigationStack(path:)` with `navigationDestination(for: Route.self)`. Sheets are separate
  optional enum properties driven through `.sheet(item:)` / `.fullScreenCover(item:)`, which gives R3
  and R8 for free — presenting over the owner is what R8's correction requires, and iOS does it by
  construction.
- **Safe to wrap.** The SDK does **not** create a `NavigationStack` — it swaps views through its own
  `FlowNavigationManager` — so hosting it inside the app's stack does not produce the nested-stack
  problems (broken toolbars, double back buttons) that wrapping a stack-owning view would.
- **Teardown.** R5 matters most here. To cancel a flow, dismiss the cover or pop the path so the view
  deinits; hiding it is not enough, and holding a reference keeps the camera alive.
- **Restoration.** `@SceneStorage` for the selected tab and the encoded path. Because `Route` is
  `Codable`, restoration is a decode rather than bespoke logic.
- **Deep links.** `.onOpenURL` parses to `[Route]` and assigns the whole path at once, so a detail
  link restores its parent stack in one assignment.

## 4. Flutter — go_router + Riverpod

`StatefulShellRoute` gives per-tab navigators with preserved stacks, which is R7 without
hand-rolling. **Riverpod is chosen for a reason specific to this repo, not by popularity:**
`ProviderScope` overrides turn the launch arguments in `spec/launch-args.json` — scenario, theme,
sandbox, appLocale — into provider overrides applied once at app start. Automation gets deterministic
state with **no test-only build, no debug-only branch in shipped code**, and widget tests reuse the
same mechanism. It is also testable with no widget tree, which the spec-validation tests need, and its
store-plus-observers shape matches the ViewModel / observable-router / zustand choices on the other
three platforms, so the four apps stay structurally comparable.

Considered and rejected: **BLoC/Cubit** — excellent testability, but an event-driven paradigm would
make the Flutter app read differently from its three siblings for no gain at this size (revisit only
if the team later standardises on it); **vanilla `ChangeNotifier`** — matches the SDK's own internals
and adds no dependency, but a library avoids state dependencies because it must not impose a paradigm
on hosts, and an app has no such constraint; the repo's job is a *realistic* integration;
**signals_flutter** — smallest ecosystem, fewest partners would recognise it; **GetX** — service-locator
globals and poor testability.

- **Router shape.** `StatefulShellRoute.indexedStack` for the three tabs, each branch owning its
  routes; flow and profile routes above the shell so they cover the tab bar when full-screen.
- **No `build_runner` in this app** — neither `riverpod_generator` nor `go_router_builder`. A
  reference app should read without generated files standing between the partner and the wiring, and
  `flutter/verify.sh` stays a single step. The Flutter SDK repo's Pigeon churn is the cautionary
  precedent for generated-file drift.
- **Typed routes without codegen.** Hand-write one route-helper per route (`SampleRoutes.idDetails(productId)`)
  returning the path from `spec/routes.json`, and parse `state.pathParameters` into a typed args
  object in exactly one place — the route's builder. Call sites stay compile-safe, parsing happens
  once, and the "no stringly-typed arguments" rule in `spec/routes.json` still holds.
- **State shape.** `Notifier` / `AsyncNotifier` (the Riverpod 3 unified API), not the legacy
  `StateNotifier`/`StateProvider`. One notifier per concern: settings, active profile, the two forms,
  the session, the job list. `family` providers take route arguments so a screen's state is keyed by
  its route.
- **Persistence** through `shared_preferences`, which the SDK already brings transitively, behind a
  small repository the notifiers read. That is what makes "settings survive a restart" real rather
  than aspirational.
- **Session as an absolute deadline** in the provider, with the ticking done in the widget layer
  (R6). Never store a counting-down value.
- **Navigation side effects via `ref.listen`**, never from `build`. A `build` that navigates fires
  again on every rebuild.
- **Sheets from their owner** via `showModalBottomSheet`, not a route: R8's correction rules a sheet
  a layer over the screen that owns it. Its deep link resolves to the owner's link plus a sheet
  request, which is how the link still reaches it.
- **SDK flow.** A normal widget on its own route. Wrap it in `PopScope` and let the SDK handle the
  pop first (R2) rather than intercepting back at the route level.
- **Restoration.** Set `restorationScopeId`, and rebuild notifiers from persisted state so a cold
  start and a restored start converge on the same tree (R9).

## 5. Expo — expo-router + zustand

The sample already has expo-router, and pairing it with zustand is proven on an internal
integration probe, so that is the recommendation here too. File routes map 1:1 to the `expo` column of the route table.

- **Layout.** `app/(tabs)/_layout.tsx` for the three tabs; flow and profile routes outside the group
  so they present full-screen; `presentation: 'modal'` for sheet routes.
- **Route shadowing is a known trap here.** The sweep already lost a test to two routes resolving to
  the same name in different groups — the failure is silent. So route file names come from the route
  table, stay distinct, and the spec-validation test asserts every path in `spec/routes.json` resolves
  to exactly one screen.
- **SDK flow.** One screen rendering the SDK component, with `headerShown: false` for the
  full-screen presentation and the in-shell variant nested under `(tabs)`.
- **State.** A zustand store per concern (forms, settings, session), with the persist middleware over
  AsyncStorage for anything that must outlive a restart. Keep the session deadline, not a ticker.
- **Deep links.** The scheme comes from `app.json` and must match `spec/app-identity.json` — one
  scheme per app, because two apps sharing a scheme break automation silently.

---

## 6. How this lands alongside the UI work

Per screen, in the same PR as the screen: add its route to `spec/routes.json` if missing, wire the
route, wire the deep link, and add the `sample_*` ids the flow needs. A screen merged without its
route is a screen no test can reach.

Two milestones worth naming separately, because they are where the defects live:

- **N1 — the shell.** Tabs, per-tab stacks, deep-link parsing, cold-start restoration. Do this with
  the walking skeleton, before fidelity work.
- **N2 — the flow handoff.** Both presentations of the SDK route, the replace-don't-stack result
  transition (R4), cancellation semantics (R5), and recreation survival (R6). This is the riskiest
  part of the whole app and it deserves device verification on every platform, not just CI.
  What the flow route receives, and how — the argument contract N2 builds on — is §8.
  **Android and iOS have landed N2** (iOS 2026-09-08); what the iOS platform decided differently,
  including the two §7.3 assumptions that did not hold against the published SDK, is
  `ios-port-hardening.md` §16.

## 7. Result handling — settled from the SDK source (2026-08-13)

All three previously-open questions were answered by reading the four SDKs rather than guessing.

### 7.1 Threading — no marshalling needed on any platform

| SDK | Delivery | Evidence |
|---|---|---|
| Android | Main thread | `FlowNavigationManager` is a ViewModel; results are delivered from `viewModelScope.launch` (main dispatcher) and from `onCleared()`. `Dispatchers.IO` is used only for metadata and file sizing |
| iOS | Main actor | `FlowNavigationManager` is annotated **`@MainActor`**, so `configuration.onResult(result)` is already main-isolated |
| Flutter | Main isolate | flow logic is Dart-side (`flow_navigation_manager.dart`); no platform-channel hop on the result path |
| Expo | JS thread | flow logic is TypeScript-side (`flow_navigation_context.tsx`) |

So navigate directly from the callback. Do **not** add a `runOnUiThread` / `DispatchQueue.main.async`
wrapper — on iOS that would introduce a needless frame of delay in a `@MainActor` context.

### 7.2 Cancelled versus failed — three outcomes, and the SDK never conflates them

Every SDK exposes the same three-case result, so the host can branch on it directly:

| SDK | Type |
|---|---|
| Android | `UseSmileIDResult`: `Success<T>(value)` · `Failure(Throwable)` · `Cancelled` (data object) |
| iOS | `UseSmileIDResult<Success>`: `.success` · `.failure(Error)` · `.cancelled` (+ `isCancelled`, `onCancelled`) |
| Flutter | `UseSmileIDSuccess<T>` · `UseSmileIDFailure<T>(Exception)` · `UseSmileIDCancelled<T>` |
| Expo | `{status:"success",value}` · `{status:"failure",error}` · `{status:"cancelled"}` |

**Host behaviour (this settles R4):**

- `Success` → pop the flow and both forms, push `verificationDetails(jobId)` in its processing state.
- `Failure` → same destination, showing the error. iOS makes the intent explicit: closing a failed
  processing screen calls `exitFailedProcessing()`, which delivers the **pending failure rather than a
  synthesized cancellation**, so a failure must never be reported as a cancel.
- `Cancelled` → return to the originating tab. Create no job and no details entry.

Three delivery guarantees the host must respect rather than reimplement:

1. **Exactly-once.** Android guards with an `AtomicBoolean terminalDelivered`; iOS routes every path
   through `completeFlow(with:)` behind `guard !isFlowComplete`. Never synthesize a second result.
2. **Teardown already delivers `Cancelled`.** Android's `onCleared()` → `deliverTerminalOnTeardown()`
   emits `Cancelled` exactly once if nothing was buffered, and iOS exposes `cancelFlow()` for backing
   out. So popping the flow route *is* the cancel — the host must not also fire its own. Because the
   exactly-once flag is already set after a success, popping post-success produces no spurious cancel.
3. **A result can be buffered across recreation, and dropped if the host never comes back.** Android
   buffers into `pendingResult` when no composition is live and replays it on the next
   `updateDeliveryCallbacks`; if no further composition arrives, the result is **dropped with a
   warning log**. That is the hard requirement behind R6: if the host's flow-destination key changes
   on recreation, a *new* ViewModel is created, the old buffer is never replayed, and the job result
   is lost silently. Use a saveable key.

### 7.3 Deep-linking into `…/run` — allowed, gated by the SDK's own validator

Every SDK ships a **non-throwing** pre-flight check, so the route can guard itself instead of
trusting the caller:

- `validate(): ValidationState` exists on **all four** — Android `UseSmileIDBuilder.kt:297`
  (`FlowValidator.validateBuilder(...)`), iOS `UseSmileIDFlowBuilder.swift:160`
  (`FlowValidator.shared.validateBuilder(screens:)`), Flutter
  `use_smile_id_flow_builder.dart:141`, Expo `use_smile_id_flow_builder.ts:214`. Parity holds; call
  it on route entry. **Corrected 2026-09-08 against the published iOS 12.0.2:** the *builder* is not
  constructible outside `UseSmileIDBuilder`'s closure there — it has no public initialiser — so an
  iOS host calls `FlowValidator.shared` directly instead. Same object, same rules, reachable before
  the SDK mounts. Whoever ports Flutter or Expo should check which of the two their SDK allows.
- Android and iOS additionally expose per-payload validators for dynamically-sourced input —
  `validateConsent`, `validateUserDetails`, `validateBiometricKYCParams`,
  `validateDocumentVerificationParams`, `validateEnhancedDocumentVerificationParams`,
  `validateEnhancedKYCParams`. Use these when the form's values come from the profile store rather
  than the builder, which is exactly this app's case.
- `build()` is **internal** on both Android and iOS, so `validate()` is the intended partner-facing
  pre-flight check — not building and inspecting `FlowBuildResult`.

**Rule:** `…/run` is directly deep-linkable. On entry, validate; if the configuration is invalid for
want of user or ID details, redirect to the corresponding form route and keep the intended
destination so the form's Continue resumes the journey. Do not let an invalid configuration reach the
flow — submission-time validation throws, and a thrown builder error surfaces as
`Failure`, which is indistinguishable to a test from a real submission failure.

**One rule the validators cannot be asked for, found on iOS 2026-09-08:** every job type needs
consent, from an in-flow consent screen or from the token's own claim, and the validator that
enforces it takes a decoded token payload that no public overload accepts. So with the Consent screen
switch off and no consent binding, a run has neither source and the SDK refuses it — as a `Failure`
from inside its own render, which is exactly what this rule says must not happen. The host has to
state that rule itself. iOS does; **Android does not yet**, and the two other ports inherit the same
requirement.

**Incidental finding worth carrying to the products question:** iOS `buildJobRequest()` documents that
**the BVN job type is not supported and throws**. That strengthens the case for leaving `BVN` out of
the products grid (`spec/screens.json` → `openQuestions.productCoverage`) rather than filling the
empty slot with it.

---

## 8. Parameters into the flow route — the contract N2 builds on

The question N2 forces on every platform: when the host navigates to `…/run`, how does the flow
destination receive what it needs? The answer is one rule with two halves, and it is the same rule
on all four platforms:

> **The route carries identity. The stores carry payload. The SDK's validator gates entry.**

Identity is the two arguments `spec/routes.json` already declares for `sdkFlow` — `productId`
(which journey) and `route` (`fullscreen|shell`, R3). Payload is everything the user typed or
chose — the Consent Details Form values, the ID details, the active scenario and theme. Payload
travels through the persisted stores (R6) and is **snapshotted once at flow entry**; it never
appears in a URI or a navigation argument.

Three reasons, each already earned elsewhere in this document:

1. **R9 makes the route the only reliable carrier.** An externally delivered deep link is
   effectively a cold start — a second Activity instance with `savedInstanceState` null — so
   in-memory hoists are gone whatever the app was doing. On Android the two form stores are
   `rememberSaveable`-backed: they survive rotation and process death, **not** the R9
   replacement. Route arguments and disk-persisted state are what's left standing, which is
   exactly the split this rule makes.
2. **Payload is PII, and URIs leak.** Deep links transit `adb` command lines, Maestro flow files,
   logcat and system intent logs. The Security section's "no PII in logs" rule decides this
   without further debate: names, emails, phone numbers and ID numbers never become URI or route
   arguments.
3. **The spec stays small and stable.** `sdkFlow`'s two arguments are a four-platform contract.
   Every argument added to the route table must be implemented and tested four times; payload
   fields would multiply that for no reachability gain, since a cold link with empty stores is
   already handled by the §7.3 validator gate.

**The cold-link corollary (§7.3, restated as behaviour):** a link straight to
`…/flow/biometricKyc/run` with empty stores must not reach the SDK. On entry the route calls the
SDK's non-throwing `validate()`; when it reports missing user or ID details, redirect to the
form route for the same `productId` — and the journey resumes through the wizard's own linear
Continue chain (details → id-details → run), so no "return-to" token is needed in any route's
arguments. The wizard being linear per product is what keeps the route table free of
continuation state.

### 8.1 Android — Compose Destinations, concretely

**The args holder.** N2's flow host needs its arguments in a ViewModel (the buffered-result
replay in §7.2 requires the host's identity to be derivable from the route, R6). KSP already
generates a typed holder from the composable's parameters — verified in the generated output,
`SdkFlowScreenDestinationNavArgs(productId, route = Fullscreen)` exists today — and the generated
destination exposes `argsFrom(savedStateHandle)`, so the ViewModel needs no string keys and the
annotation needs no change:

```kotlin
@Destination<FlowGraph>(
    style = UseSmileIDSampleFlowTransitions::class,
    deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.SDK_FLOW)],
)
@Composable
fun SdkFlowScreen(navigator: DestinationsNavigator, viewModel: SdkFlowViewModel) { /* … */ }

class SdkFlowViewModel(savedStateHandle: SavedStateHandle) : ViewModel() {
    private val args = SdkFlowScreenDestination.argsFrom(savedStateHandle)
    // args.productId / args.route — same values on tap-navigation, cold deep link and recreation
}
```

Until the ViewModel exists (the placeholder screen today), the composable-parameter form the app
already uses generates the identical route. A hand-declared `navArgs = …::class` class is the
documented alternative for when arguments outgrow a parameter list — a style choice, not a
prerequisite.

**Call sites stay typed.** KSP generates an invoke per destination, so every hop of the wizard
passes identity forward without a string route anywhere:

```kotlin
// Products grid → wizard (UseSmileIDSampleDestinations.kt)
onProductClick = { navigator.navigate(ConsentDetailsFormScreenDestination(productId = it.id)) }

// Consent form → ID details, only when the product needs them
navigator.navigate(IdDetailsFormScreenDestination(productId = productId))

// ID form's Continue → the flow itself; route defaults to Fullscreen
navigator.navigate(SdkFlowScreenDestination(productId = productId))

// Automation autostart (UseSmileIDSampleShell.kt) — both arguments explicit
navigator.navigate(SdkFlowScreenDestination(productId = product.id, route = app.launchArgs.route))
```

**The enum binding — works today, but by a coincidence a test must pin.** The spec declares
`route: enum(fullscreen,shell)`; the Kotlin constants are `Fullscreen("fullscreen")` /
`Shell("shell")`. Compose Destinations parses enum arguments **case-insensitively** — verified in
the generated KSP output, where the route argument binds through the library's
`DestinationsEnumNavType` and its `valueOfIgnoreCase` parse path — so the spec URI
`…/run?route=shell` reaches `Shell` because, and only because, every constant's name equals its
`id` up to case. That is a naming coincidence, not a contract, and the serialize side emits the
constant name (`SdkFlowScreenDestination(…, route = Shell).route` ends in `?route=Shell`), which
any case-*sensitive* consumer of the shared paths would reject. Two consequences:

- The Android spec test asserts the invariant `name.lowercase() == id` for every constant, plus
  the spec's exact value list — `navigation-hardening-android.md` NAV-A1 item 4 has the
  assertions. No production code changes; the test is what makes the coincidence safe.
- If the invariant ever has to break, the boundary fix is `route: String = "fullscreen"` on the
  destination, mapped to the enum on the next line — one stringly-typed edge beats changing a URI
  value four platforms and the Maestro flows already encode.

**Entry snapshot — where payload joins identity.** Exactly one function assembles what the SDK
gets, so there is exactly one place to validate, log-safely, what the flow launched with:

```kotlin
/** Read once when the flow route enters; never re-read while the flow runs (R2 — the SDK owns it now). */
data class FlowLaunchSnapshot(
    val product: UseSmileIDSampleProduct,
    val route: UseSmileIDSampleFlowRoute,
    val userDetails: UseSmileIDSampleUserDetails,   // forms store — survives rotation, R6
    val idDetails: UseSmileIDSampleIdDetails,       // country / idType / idNumber, if product.needsIdDetails
    val scenario: UseSmileIDSampleScenario,         // drawer store — drives the run
    val theme: UseSmileIDSampleThemeScenario,
)

fun buildSnapshot(args: SdkFlowScreenDestinationNavArgs, app: UseSmileIDSampleAppState): FlowLaunchSnapshot? {
    val product = UseSmileIDSampleProduct.entries.firstOrNull { it.id == args.productId } ?: return null
    return FlowLaunchSnapshot(
        product = product,
        route = args.route,
        userDetails = app.forms.userDetails,
        idDetails = app.forms.idDetails,
        scenario = app.flowResult.scenario,
        theme = app.flowResult.theme,
    )
}
```

`null` product — a mistyped deep link — lands on the same redirect path as failed validation:
back to the products tab, never a crash and never the SDK. Then the gate and the handoff:

```kotlin
val snapshot = buildSnapshot(args, app) ?: return redirectToProducts()
// `applying` is the snapshot→builder mapping N2 introduces (host-side extension, not SDK API):
// product journey + userDetails + idDetails + theme onto the public UseSmileIDFlowBuilder DSL.
val validation = UseSmileIDFlowBuilder()
    .applying(snapshot)
    .validate()                  // non-throwing, §7.3 — the partner-facing pre-flight
when (validation) {
    is ValidationState.Valid -> { /* host the flow; deliver results per §7.2 */ }
    is ValidationState.Invalid -> navigator.navigate(
        ConsentDetailsFormScreenDestination(productId = args.productId),
    ) {
        // The graph, not just the flow: a deep link synthesizes a consent form beneath the
        // flow, and popping only the flow would stack the redirect's form on top of it.
        popUpTo(FlowNavGraph) { inclusive = true }
    } // the wizard resumes forward from here
}
```

**Identity keys the survival machinery.** §7.2's third guarantee — a buffered result is replayed
only to the *same* host — plus R6's device-found bug (`remember { UUID.randomUUID() }` keys a new
ViewModel every recreation) reduce to: derive the flow host's key from the arguments, nothing
else.

```kotlin
// Saveable by construction: same route arguments → same key → same restored host.
val flowKey = "${args.productId}/${args.route.id}"
```

**The exit carries identity too (R4).** The result's `jobId` is the only thing the landing route
needs, and the pop target is the wizard's graph, not a screen:

```kotlin
navigator.navigate(VerificationDetailsScreenDestination(jobId = jobId)) {
    popUpTo(FlowNavGraph) { inclusive = true }  // flow + both forms, however the wizard grows
}
```

### 8.2 The same rule on the other three platforms

One line each, because the mechanics differ but the contract must not:

| Platform | Identity travels as | Payload read from | The §7.3 gate runs |
|---|---|---|---|
| iOS | `case sdkFlow(productId: String, route: FlowRoute)` in the `Codable` `Route` enum — typed, `@SceneStorage`-restorable | the observable stores at view construction | in the route's view `onAppear`, before the builder renders |
| Flutter | path param `:productId` + query `route`, parsed **once** in the route's builder into a typed args object (§4's no-codegen rule) | Riverpod providers, `family`-keyed by `productId` | in the route builder's redirect, go_router's native mechanism for it |
| Expo | `useLocalSearchParams()` in the `…/run` screen, validated at the top of the component | zustand stores | before rendering the SDK component; `router.replace` to the form on failure |

Parity checks the spec tests own on every platform: the two argument names, the lowercase enum
values `fullscreen|shell`, and the default (`fullscreen` when absent). Carry §8.1's lesson to the
siblings with one asymmetry in mind: Android *parses* case-insensitively but *serializes* the
constant name, while the hand-written parsers on Flutter and Expo and the `Codable` decode on iOS
are case-sensitive unless written otherwise. So every platform's parser must accept the spec's
lowercase values, every spec test asserts with the *spec's* values rather than the platform's,
and nothing that emits a URI may rely on Android's case-forgiveness — normalise to the lowercase
id at every emit site.

### 8.3 What must never become a route argument

Recorded as a list because each one will be proposed eventually, and the answer is already no:

- **User details, ID number, consent** — PII in URIs (reason 2), and the §7.3 gate makes them
  unnecessary for reachability.
- **Scenario / theme** — they are launch arguments and drawer state with their own contract
  (`spec/launch-args.json`), and R9 already defines how automation delivers them. A second path
  through the route would let the two disagree.
- **A "return-to" continuation** — the wizard is linear per product; the Continue chain *is* the
  resume path.
- **The token session** — R6: it is an absolute deadline in the persisted store; a route argument
  would be a stale copy the moment it was written.
