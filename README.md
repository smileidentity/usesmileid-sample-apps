# Smile ID sample apps (v12)

Four sample apps (Android, iOS, Flutter and React Native with Expo) that integrate the
[Smile ID](https://smileid.com) v12 SDKs **exactly the way a partner does**. Every app resolves its SDK
from the public registry (Maven Central, Swift Package Manager, pub.dev, npm), never from a local
checkout.

That constraint is the point. It makes these apps both the reference integration partners copy and a
test of what we publish: a defect that exists only in the published SDK, such as a missing dependency,
a file absent from the package, or a keep rule that fails only under minification, shows up here first.

The Android and iOS apps are on Google Play and the App Store as **Smile ID**.

## What each app shows

- **Every v12 product**: SmartSelfie™ Enrollment and Authentication, Biometric KYC, Document
  Verification, Enhanced Document Verification and Enhanced KYC, each composed with the flow builder.
- **Token sessions**: link the app to a real account by scanning or pasting a v3 token, with no API key
  in the app. When the token already carries the user's details and consent, the app skips those steps.
- **Verifications**: every submitted job, stored on the device, with its status refreshed from
  `GET /v3/status`.
- **Profiles** for different partners or test users, and **dark mode** carried through to the SDK's
  screens.
- **Probes** for automation and debugging: a scenario drawer, an on-screen result card and callback
  counters.

Runs go to the Smile ID **sandbox** unless a linked token names production. **Simulate a successful
scan** on the scan sheet reaches every screen without a real token.

## Prerequisites

| Platform | Needs |
|---|---|
| Android | JDK 21 or newer, and an Android SDK with API 37 |
| iOS | Xcode 26, and [XcodeGen](https://github.com/yonaskolb/XcodeGen) |
| Flutter | The Flutter stable channel |
| Expo | Node 20.19 or newer, and pnpm 9 |

## Run an app

**Android**

```bash
cd android
./gradlew installDebug
adb shell am start -a android.intent.action.VIEW -d "usesmileid-sample-android://products"
```

**iOS**

```bash
cd ios/App && xcodegen generate && open UseSmileIDSample.xcodeproj
```

The Xcode project is generated from `ios/App/project.yml` and is not committed. In debug builds, shake
the device to read the app's own network traffic, with credentials redacted.

**Flutter**

```bash
cd flutter/app && flutter run
```

**Expo**

```bash
cd expo && pnpm install
cd app && pnpm prebuild && pnpm android    # or: pnpm ios
```

The Expo app needs `react-native-worklets/plugin` as the **last** Babel plugin
(`expo/app/babel.config.js`), or capture does not run.

Every route in `spec/routes.json` opens by deep link on each app's URL scheme:
`usesmileid-sample-android://`, `usesmileid-sample-ios://`, `usesmileid-sample-flutter://` and
`usesmileid-sample-expo://`.

## Check a change

Each platform has one script that is its definition of done, and CI runs the same script on every pull
request:

```bash
android/verify.sh
ios/verify.sh
flutter/verify.sh
expo/verify.sh
```

## Guides

| Guide | Answers |
|---|---|
| [Architecture](docs/architecture.md) | How the four apps are built and kept identical, and where the SDK is called |
| [Token sessions](docs/token-session.md) | How to run verifications from a v3 token instead of an API key |
| [Theming](docs/theming.md) | How the apps theme themselves and the SDK |
| [Testing](docs/testing.md) | How to test an integration like this one |
| [Submitting to the stores](docs/store-submission.md) | What the SDK means for your App Store and Google Play submission |
| [Releasing](docs/releasing.md) | How these apps reach the stores |
| [Backlog](docs/plan/backlog.md) | Known gaps, if you want to contribute |

The SDK reference is at [docs.smileidentity.com](https://docs.smileidentity.com).

## Layout

| Path | What lives there |
|---|---|
| `spec/` | The cross-app contract as data: scenarios, routes, launch arguments, result-card fields, test ids, design tokens |
| `android/` | The Android app (`app/`) and its `sample-ui` library |
| `ios/` | The iOS app (`App/`) and the `SampleUI` Swift package |
| `flutter/` | The Flutter app (`app/`) and the `sample_ui` package |
| `expo/` | The Expo app (`app/`) and the `sample-ui` TypeScript package |

Each platform splits into a thin **app shell** (the SDK dependency, native configuration and flow host)
and a **`sample-ui` library** holding every screen a partner sees. [`AGENTS.md`](AGENTS.md) is the full
contributor guide, for people and coding agents alike.

## Contributing and security

See [CONTRIBUTING.md](CONTRIBUTING.md). Report security problems privately, as
[SECURITY.md](SECURITY.md) describes, never in a public issue. Never commit a token, partner id or API
key.

## Licence

The code is MIT-licensed ([LICENSE](LICENSE)). Bundled fonts, icons and Smile ID marks keep their own
terms ([NOTICE](NOTICE)).
