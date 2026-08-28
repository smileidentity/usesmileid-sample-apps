# UseSmileID Sample Apps (v12)

Four sample apps — Android, iOS, Flutter and React Native (Expo) — that integrate the
[Smile ID](https://smileid.com) v12 SDKs **exactly the way a partner does**: every app resolves the
SDK from its public registry (Maven Central, Swift Package Manager, pub.dev, npm), never from a
local checkout.

That single constraint is the point of this repo. It makes these apps both the reference
integration we hand to partners and the consuming host our CI can test, which is a class of
coverage the SDK repos structurally cannot provide from their own in-repo samples.

## Status

**In progress.** The Android app is a running navigation shell — three tabs with preserved
back stacks, every route in the contract reachable by deep link, and the design tokens driving
light and dark. Its screens are still placeholders. The other three platforms have not started.

- Repo conventions and rules for humans and AI agents: [`AGENTS.md`](AGENTS.md)
- The plan, the architecture and the phased build order: [`docs/plan/`](docs/plan/)
- The cross-app contract each app validates against: [`spec/`](spec/)

## Running the Android app

Needs a JDK 21 or newer (Android Gradle Plugin 9 requires it) and an Android SDK with API 37.

```bash
cd android
./gradlew installDebug                      # or assembleRelease for the minified lane
./verify.sh                                 # the definition of done: tokens, lint, tests, release

adb shell am start -a android.intent.action.VIEW \
  -d "usesmileid-sample-android://products"  # every route in spec/routes.json opens like this

# the device flows; APP_ID picks the variant and has no default on purpose
maestro --device <serial> test -e APP_ID=com.usesmileid.sample.android.debug maestro
```

## Layout

| Path | What lives there |
|---|---|
| `spec/` | The shared contract as data — scenarios, launch arguments, result-card fields, test IDs, design tokens. Consumed by all four apps and their tests. |
| `android/` | Android app (`app/`) + the shared `sample-ui` library module |
| `ios/` | iOS app (`App/`) + the `SampleUI` Swift package |
| `flutter/` | Flutter app (`app/`) + the `sample_ui` package |
| `expo/` | Expo app (`app/`) + the `sample-ui` TypeScript package |

Each platform is split into a thin **app shell** (entry point, navigation host, native config, SDK
dependency) and a **`sample-ui` library** holding every screen a partner sees. The library is the
only copy of that UI: the Smile ID SDK repos consume it as a pinned submodule for their own
development samples, so the surface never has to be maintained twice. `AGENTS.md` explains the
contract; `docs/plan/` explains why.

## Credentials

Automation and local runs use **sandbox credentials only**. Never commit a partner ID, API key or
any production credential to this repository — see the security rules in `AGENTS.md`.
