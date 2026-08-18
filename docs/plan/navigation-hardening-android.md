# Navigation hardening — Android, audited against Compose Destinations 2.x

**Status:** NAV-A1, NAV-A2 and NAV-A4 landed 2026-08-18 (`chore/android-nav-hardening`);
NAV-A3's remaining code items land with the N2 flow-handoff work by design; NAV-A5/A6 are
decision records. Source: a 2026-08-18 audit of `android/app`'s navigation against the Compose
Destinations 2.x documentation (https://composedestinations.rafaelcosta.xyz/v2/), read page by
page against the code as merged on `main`.

**Audit verdict first, so nobody re-litigates the healthy parts:** the implementation is current
(2.3.0 is the latest release on Maven Central) and uses the 2.x idioms the docs recommend —
`@Destination<Graph>` generics, one nested graph per tab, the documented bottom-bar
save/restore pattern, `NavHostAnimatedDestinationStyle` + per-destination `Animated` styles,
warm-intent forwarding into `handleDeepLink`, optional args as query params, and
`DestinationsNavigator` (not `NavController`) in every screen. The items below are the gaps and
the deliberate non-adoptions worth recording; none is a behaviour bug shipping today.

Companion reading: `navigation-plan.md` §8 (what travels in the flow route vs in the store — the
design these items implement) and §6 (the N1/N2 milestones these items land against).

---

## The items

| Id | What | Priority | Lands |
|---|---|---|---|
| NAV-A1 | Spec test: `spec/routes.json` ↔ generated destinations | **P1 — a contract hole today** | Own PR, no dependencies |
| NAV-A2 | Group the pre-flow wizard into a nested `FlowGraph` | P2 | Before or with the N2 flow-handoff work |
| NAV-A3 | Typed flow params: `navArgs` class + `SavedStateHandle`, enum binding fixed | P2 | With N2 (same PR as A2 is fine) |
| NAV-A4 | Drop `rememberNavHostEngine()` | P3 | Rides along with any of the above |
| NAV-A5 | Decision record: result-back stays out | Decision, no code | This document |
| NAV-A6 | Skip list: docs features evaluated and rejected | Decision, no code | This document |

---

## NAV-A1 — a spec test for `spec/routes.json` (the one real gap)

`spec/routes.json` declares 15 routes with paths, argument names, types and optionality. Nothing
asserts the Android app matches it. `sample-ui` has spec tests for scenarios, launch args, the
result card and test ids; **the `app` module has no test source set at all**, and
`UseSmileIDSampleDeepLinks.kt` is hand-written strings. Two drifts this permits today:

- A hand-written `{jobId}` placeholder must exactly match the composable parameter name. Rename
  the parameter and that deep link dies at runtime with no compile error and no failing test.
- The `route` argument is declared `enum(fullscreen,shell)` in the spec while the Kotlin
  constants are `Fullscreen` / `Shell`. This **works today** — verified in the KSP output
  (`app/build/generated/ksp/*/…/navtype/EnumCustomNavTypes.kt`), Compose Destinations parses
  enum arguments **case-insensitively** — but it works by a one-case coincidence: the constants
  happen to differ from the spec ids only by case. A constant renamed or added without a matching
  lowercase id breaks spec-conformant URIs with no compile error. The invariant belongs in a test
  (item 4 below), not in reviewers' memories.

Everything this test relies on was verified against the generated code, not assumed: each
generated `…Destination` object exposes `route` (the full pattern), `baseRoute`,
`arguments: List<NamedNavArgument>`, `deepLinks: List<NavDeepLink>`, `argsFrom(Bundle)` /
`argsFrom(SavedStateHandle)`, and a typed `invoke(…): Direction`. Re-verify by reading any file
under `app/build/generated/ksp/debug/kotlin/com/ramcosta/composedestinations/generated/destinations/`
after a build.

**Where:** `android/app/src/test/kotlin/com/usesmileid/sampleapps/android/UseSmileIDSampleRoutesSpecTest.kt`.
It must live in `app`, not `sample-ui`, because the generated `…Destination` objects it asserts
against are produced by the shell's KSP pass. `android/verify.sh` needs no change — its unit-test
step is `./gradlew test`, which picks up a new `app` test source set automatically. Keep the test
JVM-pure (no `Bundle`, no Robolectric): everything below is assertable from the generated
objects' properties and plain JSON parsing, and the spec tests must stay the cheapest thing in
the repo.

**What it asserts, per route in the spec:**

1. **A destination exists for the id.** Maintain one explicit map in the test — spec id →
   generated destination — so an unmapped id is a failure with a readable message, not a reflection
   guessing game:

   ```kotlin
   private val bindings = mapOf(
       "products" to ProductsScreenDestination,
       "verificationDetails" to VerificationDetailsScreenDestination,
       "sdkFlow" to SdkFlowScreenDestination,
       // … all 15
   )
   ```

2. **The deep-link pattern matches the spec path.** Translate the spec's `:arg` to androidx's
   `{arg}`, prefix the scheme from `spec/app-identity.json`, append the spec's optional args as
   `?name={name}`, and compare against the destination's registered deep links via the generated
   `deepLinks` property:

   ```kotlin
   val expected = "usesmileid-sample-android://" +
       route.path.removePrefix("/").replace(Regex(":([A-Za-z]+)")) { "{${it.groupValues[1]}}" } +
       route.optionalArgs().joinToString("&", prefix = "?") { "${it.name}={${it.name}}" }.ifBlank { "" }
   assertThat(destination.deepLinks.mapNotNull { it.uriPattern }).contains(expected)
   ```

3. **Arguments agree** — name, required/optional, and default. The generated destination's
   `arguments: List<NamedNavArgument>` carries name, nullability and default presence; assert each
   spec arg appears with matching optionality, and no undeclared **required** arg exists (an extra
   optional arg is a spec violation too under R1 — flag it, don't allowlist it).

4. **The enum invariant that makes spec URIs parse.** Compose Destinations parses enum
   arguments case-insensitively (verified: the generated
   `navtype/EnumCustomNavTypes.kt` binds through the library's `DestinationsEnumNavType`, whose
   parse path is `valueOfIgnoreCase`), so the spec URI `…/run?route=shell` reaches the `Shell`
   constant only because the constant name and the spec id differ by nothing but case. Pin that
   coincidence as a rule, without Robolectric:

   ```kotlin
   // Spec ids and enum ids agree exactly…
   assertThat(UseSmileIDSampleFlowRoute.entries.map { it.id })
       .containsExactlyElementsIn(sdkFlowRoute.enumValues()) // ["fullscreen", "shell"]
   // …and every constant is its id up to case, which is what case-insensitive parsing binds on.
   UseSmileIDSampleFlowRoute.entries.forEach { assertThat(it.name.lowercase()).isEqualTo(it.id) }
   // The serialize side: a Direction the app builds carries a value the spec pattern accepts.
   assertThat(SdkFlowScreenDestination(productId = "biometricKyc", route = Shell).route)
       .endsWith("?route=Shell") // constant name; parsers must accept it case-insensitively (§8.2)
   ```

   The default in the spec (`fullscreen` when absent) is covered by asserting the generated
   argument's default: `SdkFlowScreenDestination.arguments` exposes it as a `NamedNavArgument`.

5. **The app's extras are intentional.** Assert the set of destinations not covered by the spec
   equals the explicit dev-only allowlist (`ComponentGalleryScreenDestination` — documented in
   `UseSmileIDSampleDeepLinks.kt` as deliberately outside `spec/routes.json`). A new route added
   to the app without a spec entry then fails the test, which is R1 enforced by machine instead
   of review.

**What it deliberately does not assert:** graph membership and transition styles. The spec owns
identity and reachability; how a route animates or which tab graph nests it is per-platform
design (`R11`, `R13`) and is covered by goldens and device flows, not by the route table.

**Verification:** `android/verify.sh` green with the new test in its unit-test step; then mutate
one deep-link string locally and confirm the test fails (a spec test that cannot fail is
decoration).

---

## NAV-A2 — a nested `FlowGraph` for the pre-flow wizard

Today `ConsentDetailsFormScreen`, `IdDetailsFormScreen`, both pickers and `SdkFlowScreen` sit
directly on `RootGraph`. The plan's R4 requires that on a result "the flow *and* both pre-flow
forms" are replaced. Flat on root, that pop is a chain anchored to whichever screen happens to be
the wizard's first — `popUpTo(ConsentDetailsFormScreenDestination) { inclusive = true }` — and it
silently breaks the day the wizard gains or reorders a screen. A nested graph makes the pop
structural:

```kotlin
// UseSmileIDSampleGraphs.kt
/** The pre-flow wizard plus the flow itself: one popUpTo target, per R4. */
@NavGraph<RootGraph>
annotation class FlowGraph
```

```kotlin
// UseSmileIDSampleDestinations.kt — membership moves, deep links do not
@Destination<FlowGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.CONSENT_DETAILS_FORM)])
@Composable
fun ConsentDetailsFormScreen(productId: String, navigator: DestinationsNavigator) { /* unchanged */ }
```

and the R4 exit becomes:

```kotlin
navigator.navigate(VerificationDetailsScreenDestination(jobId = jobId)) {
    popUpTo(FlowNavGraph) { inclusive = true } // wizard + flow gone, whatever the wizard grew into
}
```

**What does not change, verified against the current code before writing this:**

- **Deep links** — the URI patterns are hand-written constants bound to destinations, so nesting
  changes no path. NAV-A1 pins this.
- **Nav-bar visibility** — R13's predicate matches the three tab graphs' *start destinations*,
  not graph membership, so a new graph cannot re-introduce the bar-on-pushed-screen defect.
- **Transitions** — per-destination styles stay on the destinations. If the whole wizard should
  share the flow fade, `@NavGraph(defaultTransitions = …)` exists, but R11 gives the forms the
  push motion and only the flow the fade, so per-destination remains correct here.

**What does change, deliberately: the deep link's synthesized back stack.** androidx places each
parent graph's start destination on the stack it synthesizes for a URI deep link — cold, and
equally warm through `ForwardNewIntentsTo`'s `handleDeepLink` — with the intermediate
destination's arguments filled from the URI. So a link to `…/flow/{productId}/run` now puts
`ConsentDetailsFormScreen(productId)` beneath the flow: back from a deep-linked flow previously
landed on Products (the root's start destination) and now lands on the consent form. That is the
wizard journey the §7.3 validator redirect implies anyway — an entry with empty stores was always
going to route through the form — but any device flow asserting back-from-deep-linked-flow
behaviour must expect the form, not Products.

**Considered and rejected: graph-level `navArgs` carrying `productId`.** Compose Destinations
supports arguments on the graph itself, which would stop the pickers re-declaring a `productId`
they never read. Rejected because the spec paths bind `:productId` **per route** — the deep-link
placeholder must match a destination argument for a cold link straight to a picker to parse — and
because four platforms share those paths, the per-route declaration is the parity-preserving
shape. The unused-looking parameter is load-bearing; the annotation comment should say so.

**Verification:** `android/verify.sh`; the `deep-links` Maestro flow (a cold deep link to each
wizard route still lands) plus `shell-navigation` for the warm path; after N2 wires the real pop,
a device pass proving back from `verificationDetails` reaches the originating tab, never capture
(R4's actual point).

---

## NAV-A3 — typed parameters into the flow route

The design and the detailed examples live in `navigation-plan.md` §8 so the other three platforms
inherit the same rule; this item is the Android work list:

1. **Give the N2 flow host its args through the `SavedStateHandle`.** KSP already generates
   `SdkFlowScreenDestinationNavArgs(productId, route = Fullscreen)` from the composable's
   parameters — no annotation change is needed to get a typed holder. The flow-host ViewModel
   reads `SdkFlowScreenDestination.argsFrom(savedStateHandle)` (generated, verified present),
   which is what the buffered-result replay requires: the host's identity derivable from the
   route on every arrival path (§7.2, R6). A hand-written `navArgs = …::class` class is an
   optional style choice for when the args outgrow the parameter list, not a prerequisite.
2. **Pin the enum binding with NAV-A1 item 4, change no code.** Parsing is case-insensitive and
   spec URIs work today; the test turns the name↔id coincidence into an invariant. Only if that
   invariant ever has to break (a route value whose Kotlin name can't match its id up to case)
   does a boundary fix become necessary — then prefer `route: String` at the destination edge,
   mapped to the enum on the next line, over fighting the library's native enum support.
3. **Keep payload out of the route.** User details, ID details and consent never become nav args
   or URI params. §8.1 carries the reasons (PII in system logs; R9 makes external links cold
   starts so in-memory form state is gone anyway; spec stability); the entry gate for a cold link
   is the SDK's own `validate()` (§7.3), not a fatter URI.

**Verification:** NAV-A1's assertions green; the `deep-links` flow drives `…/run?route=shell`
cold and asserts the in-shell presentation via the result card's `route` field.

---

## NAV-A4 — drop `rememberNavHostEngine()`

`UseSmileIDSampleShell.kt` builds an engine only to ask it for a controller. In 2.x the engine
exists for engine *customisation*; every docs example, including the multi-module page, uses
plain `rememberNavController()`:

```kotlin
val navController = rememberNavController()          // androidx.navigation.compose
val navigator = navController.rememberDestinationsNavigator()
```

Two lines become one and an unused abstraction goes away. No behaviour change; rides along with
any other PR here.

---

## NAV-A5 — decision record: result-back stays out

Compose Destinations ships `ResultBackNavigator` / `ResultRecipient` — typed results delivered
exactly once to the previous screen, with a distinct cancelled path. Two candidate uses were
evaluated; **neither adopts it**, and this record exists so the next audit doesn't reopen the
question without new facts.

- **The pickers and sheets** (country, ID type, profile switch, new profile, scenario drawer)
  commit to the app-state stores and `navigateUp()`. That is deliberate: the stores are what
  survive recreation (R6), the confirmation pattern reads from the store on the screen the action
  returns to (R10), and all four platforms share the store-write shape — a recipient-based
  Android implementation would be the odd sibling out. Tap-outside-to-dismiss needs no cancelled
  signal because nothing was committed.
- **The flow result** looked like the textbook case, but R4 settles it the other way: a result
  navigates **forward** (replace with `verificationDetails`), it does not return a value to the
  previous screen. Delivery guarantees (exactly-once, cancel-on-teardown, buffering across
  recreation) are the SDK's, per §7.2 — the host records to the jobs/result stores and navigates.
  A `ResultBackNavigator` would add a second delivery channel to a mechanism whose entire design
  is that there is one.

**Revisit trigger:** if form state ever moves off the shared stores into screen-local state,
the pickers' return path must switch to result-back in the same change, because at that point a
recreation would otherwise drop the selection.

---

## NAV-A6 — evaluated against the 2.x docs and deliberately not adopted

Recorded with reasons so future doc-vs-code audits skip them:

| Docs feature | Why not here |
|---|---|
| `FULL_ROUTE_PLACEHOLDER` deep links | Auto-derives URIs from generated routes, so args can never drift — but the URIs must match `spec/routes.json`, which four platforms share. Hand-written patterns + NAV-A1 as the compensating control. |
| `DestinationStyleBottomSheet` (`bottom-sheet` artifact) | Rides on Material (M2) navigation; the design system is M3 and sheets are already destinations that animate themselves (R8, R11). |
| `DestinationStyle.Dialog` for the sheets | A dialog window would satisfy "sheet as route" but costs the native sheet behaviour R8 requires (drag-to-dismiss, insets). Known consequence of the current shape: predictive back renders the route's `None` transition, a hard cut, not a sheet slide — accepted. |
| `@NavHostGraph(defaultTransitions = …)` | Moves the host default from a `DestinationsNavHost` parameter to the annotation. Both are documented; the runtime parameter keeps every transition decision in one file (`UseSmileIDSampleTransitions.kt` + the shell), which is worth more than the co-location. |
| Centralised custom annotations (e.g. `@SheetDestination`) | Would collapse five repeated `style = …SheetTransitions::class` params, at the cost of a meta-annotation indirection every reader must chase. Five params don't clear that bar. |
| `dependenciesContainerBuilder` | The composition locals (`LocalUseSmileIDSampleAppState`, `LocalUseSmileIDSampleChrome`) already scope app state, and screens stay callable from previews without a destinations dependency. Revisit only if graph-scoped ViewModels arrive (see NAV-A5's trigger). |

---

## Landing order

1. **NAV-A1** first, alone — pure test, no production change, and it converts today's
   working-by-coincidence enum binding into an asserted invariant before N2 starts relying on it.
2. **NAV-A2 + NAV-A3** together, before or with the N2 flow-handoff work — they are the
   structural half of N2 and are cheap while `SdkFlowScreen` is still a placeholder.
3. **NAV-A4** rides along with whichever lands first.
4. A5/A6 are this document.

Every PR: `android/verify.sh` green, and any claim about deep-link behaviour verified on a
device via the `shell-navigation` flow — R9 says cold start is the test that matters, and every
defect this plan guards against is invisible warm.
