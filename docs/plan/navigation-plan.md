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

## 1. Nine rules that apply to every platform

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

**R8 — Sheets are routes, not booleans.** All four sheets (profile switch, new profile, country, ID
type) are destinations, so a deep link can open one and a flow can assert it. They keep the
platform's native sheet behaviour — drag-to-dismiss, scrim tap, inset handling.

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
- **Sheets.** The library's sheet destinations (or a `dialog`/sheet destination in androidx nav) so
  R8 holds.

## 3. iOS — NavigationStack with a typed path

- **Router.** An `@Observable` router holding `path: [Route]` where `Route: Hashable & Codable`, and
  `NavigationStack(path:)` with `navigationDestination(for: Route.self)`. Sheets are separate
  optional enum properties driven through `.sheet(item:)` / `.fullScreenCover(item:)`, which gives R3
  and R8 for free.
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
- **Sheets as routes** via a `pageBuilder` returning a modal page, so R8 holds and deep links reach
  them.
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
  it on route entry.
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

**Incidental finding worth carrying to the products question:** iOS `buildJobRequest()` documents that
**the BVN job type is not supported and throws**. That strengthens the case for leaving `BVN` out of
the products grid (`spec/screens.json` → `openQuestions.productCoverage`) rather than filling the
empty slot with it.
