---
description: How the four sample apps are built and kept identical — the shell and sample-ui split, spec/ as the contract, navigation, persistence, and the rules each platform follows.
---

# Architecture

Four apps (Android, iOS, Flutter and Expo) show one design and one journey. They stay identical
because the parts that must match are written down once, as data, and every app is tested against
them. This page explains that structure, and why each rule exists. Most of the rules were learned by
finding a defect on a device.

## Prerequisites

Read the root [README](../README.md) first. [`AGENTS.md`](../AGENTS.md) is the full contributor guide,
and it wins where this page is shorter.

## 1. The SDK comes from the registry, always

Each app consumes its SDK exactly as a partner does: Maven Central, the `ios-spm` Swift package, pub.dev
and the `@smileid` npm scope. There are no path dependencies, overrides or local artefacts.

An SDK repository's own sample resolves the SDK from source, so it can never catch a defect that exists
only in the **published** artefact: a missing transitive dependency, a file absent from the package, a
keep rule that only fails under release minification. These apps can, and that is half of what they
are for. Every platform also builds a minified, resource-shrunk release with no app-side keep rules,
because that is where those defects show.

## 2. Shell and `sample-ui`

| Part | Owns | Examples |
|---|---|---|
| **Shell** (`app/`, `App/`) | Everything that differs between hosts: the SDK dependency, native configuration, navigation host, the flow host, the QR scanner, persistence wiring | `FlowBuilderConfig`, `FlowPreflight`, `SdkFlowScreen`, the scanner |
| **`sample-ui`** (`sample-ui/`, `SampleUI/`, `sample_ui/`) | Every screen a partner sees: the journey, components, theme, stores' logic | products, verifications, settings, profiles, the scan sheet |

`sample-ui` imports **only public SDK API**, and is identity-agnostic: nothing in it reads an
application id, bundle id or URL scheme. Both rules let the same UI compile inside a second host, a
development sample that builds the SDK from source, so a broken public API fails there before release.
`sample-ui` is never published.

## 3. `spec/` is the contract

The cross-app contract is data, not prose. Each app has a unit test asserting it matches:

| File | Owns |
|---|---|
| `scenarios.json` | Every scenario the drawer offers, with stable ids |
| `launch-args.json` | Automation argument names, and how each platform receives them |
| `routes.json` | Route ids, deep-link paths and typed arguments, with the per-platform binding |
| `test-ids.json` | The `sample_*` accessibility ids that device flows assert on |
| `screens.json`, `components.json` | The screen and component inventory, with design sources |
| `design-tokens.json` | The design-system source, per-platform consumption, and recorded gaps |
| `result-card.schema.json` | The result card's fields |
| `app-identity.json` | Application ids, names and URL schemes, and the ones the SDK samples reserve |

A change to `spec/` lands with all four app-side updates, or says in the PR which platform follows.
`si_*` ids belong to the SDK: the apps reference them and never define their own.

## 4. Navigation

| Platform | Navigation | State |
|---|---|---|
| Android | Compose Destinations 2.3.0 over androidx.navigation | ViewModel and `SavedStateHandle` |
| iOS | `NavigationStack` with a typed path router | observable app state |
| Flutter | `go_router` (`StatefulShellRoute` for per-tab back stacks) | Riverpod, whose `ProviderScope` overrides turn launch arguments into test state |
| Expo | `expo-router`, file routes mapping 1:1 to the route table | zustand |

The rules all four follow:

1. **Routes are data.** Every route in `spec/routes.json` exists on every platform.
2. **The SDK flow is one opaque destination.** The SDK runs its own navigation. The host never models
   consent, capture or processing as its own routes, and lets the SDK consume a back gesture first.
3. **That destination has two presentations**: full screen, and nested in the tab shell. The in-shell
   one is what exposes host-chrome and inset defects. The full-screen one is what partners copy.
4. **After a result, replace rather than stack.** Returning from the SDK pops the flow and its forms.
5. **Hiding is not cancelling.** A flow that leaves the screen without a result is reported as a
   cancel exactly once.
6. **Typed input survives recreation.** Form values outlive a rotation or process death.
7. **Per-tab back stacks are kept** across tab switches.
8. **Cold start is the test that matters.** Every route must open with the app not already running. On
   Android, an intent sent to a live task rebuilds the Activity and resets launch arguments, so
   automation force-stops the app first.
9. **A sheet is a layer over the current destination, never a replacement.** On Flutter it is
   presented on the root navigator, so the scrim covers the nav bar and dismissing gives it back. Android
   still replaces the destination (see the [backlog](plan/backlog.md)).
10. **The nav bar floats over the tab roots only**, and screens measure its height rather than
    hard-coding it.
11. **A confirmation belongs to the screen the action returns to**, not the one that fired it.

## 5. Persistence

| Platform | Verifications | Settings | Profiles and the token session |
|---|---|---|---|
| Android | Room | DataStore | DataStore, profiles sealed with an Android Keystore key |
| iOS | SwiftData | `UserDefaults` | Keychain, `WhenUnlockedThisDeviceOnly` |
| Flutter | `shared_preferences` | `shared_preferences` | `flutter_secure_storage` |
| Expo | AsyncStorage | AsyncStorage | `expo-secure-store` |

Nothing syncs or backs up off the device: Android sets `android:allowBackup="false"`, and the Keychain
items are this-device-only. One unreadable stored row is dropped or replaced with a default, never
allowed to erase the rest. Every store has a unit test for that path.

**Fixture data is opt-in.** Example profiles and seeded verifications appear only through the
`seedProfiles` and `seedJobs` launch arguments. A plain launch shows nothing that is not yours, because
the active profile's organisation is what the SDK's consent screen names as the partner.

**iOS runs at 17, above the SDK's 15**, because its verifications store is SwiftData. The floor is on
`SampleUI`'s package manifest, not only the app target.

## 6. Where the SDK is called

| | Android | iOS | Flutter | Expo |
|---|---|---|---|---|
| Builder configuration | `app/…/flow/FlowBuilderConfig.kt` | `App/Sources/Flow/FlowBuilderConfig.swift` | `app/lib/src/flow/use_smileid_sample_flow_builder_config.dart` | `app/src/flow/use-smile-id-sample-flow-builder-config.tsx` |
| Which screens a product composes | `app/…/flow/FlowJourney.kt` | `App/Sources/Flow/FlowJourney.swift` | `app/lib/src/flow/use_smileid_sample_flow_plan.dart` | `app/src/flow/use-smile-id-sample-flow-journey.ts` |
| The flow host | `app/…/flow/SdkFlowScreen.kt` | `App/Sources/Flow/SdkFlowScreen.swift` | `app/lib/src/screens/use_smileid_sample_sdk_flow_tab.dart` | `app/app/flow/[productId]/run.tsx` |
| Gate before a run | `app/…/flow/FlowPreflight.kt` | `App/Sources/Flow/FlowPreflight.swift` | `app/lib/src/flow/use_smileid_sample_flow_preflight.dart` | `app/src/flow/use-smile-id-sample-flow-preflight.ts` |

Paths are relative to each platform's folder. [`docs/token-session.md`](token-session.md) covers the
token side.

## 7. Porting between platforms

The design is the same everywhere, and behaviour stays native: insets, the system back affordance,
sheet versus dialog, and keyboard avoidance follow each platform. A hand-rolled back button that ignores
the iOS back swipe is the classic way a pixel-perfect port ships a defect.

The build order was the same on every platform: design tokens, then primitives, then composites, then
screens, each with goldens in light and dark before the next layer. Where two ports disagreed, one of
them had a defect, and the other's implementation was the test.

## Verify your integration

- [ ] Each app's spec test passes, so its scenarios, routes, ids and launch arguments match `spec/`.
- [ ] The release build runs a flow with no app-side keep rules.
- [ ] A cold deep link to every route opens it.

## Common issues

| Symptom | Cause | Fix |
|---|---|---|
| A sheet's scrim covers a blank window | The sheet route replaced the screen beneath it | Present sheets over the current destination |
| The floating nav bar takes taps meant for a sheet | The sheet was shown on the tab's navigator, under the bar | Present it on the root navigator |
| A launch argument is ignored on Android | An intent to a live task rebuilt the Activity | Force-stop before sending the intent |
| A fixture profile names the wrong partner on the consent screen | Fixture data was a store's default | Seed only behind a launch argument |
| A release build crashes where debug works | A published artefact is missing a resource or keep rule | That is an SDK finding. Do not add an app-side keep rule |

## Next step

[`docs/testing.md`](testing.md) shows how each of these rules is tested.
