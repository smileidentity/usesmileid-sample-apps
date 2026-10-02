# App size

What Smile ID adds to an app's size, for SDK 12.2.0. The [README](../README.md#app-size) has the
short version.

- **Download** is what a user's phone downloads from the store, compressed.
- **On device** is the space the app takes once installed, which is always larger.

## Every platform

Each SDK measures its platform's new, empty project, then adds Smile ID's packages. The difference is
what Smile ID costs your app.

| Platform | What you add | Download | On device |
|---|---|---|---|
| Android | Starting point: a new Android Studio project | 0.65 MB | 1.33 MB |
| Android | Selfie (`usesmileid` + `usesmileid-mlkit-face`) | +2.85 MB | +5.43 MB |
| Android | Selfie and documents (+ `usesmileid-mlkit-document`) | +9.87 MB | +20.17 MB |
| iOS | Starting point: a new Xcode project | 0.01 MB | 0.08 MB |
| iOS | Selfie (`UseSmileID` + `UseSmileIDVisionFace`) | +4.29 MB | +10.30 MB |
| iOS | Selfie and documents (+ `UseSmileIDVisionDocument`) | +4.31 MB | +10.41 MB |
| Flutter, Android | Starting point: a new `flutter create` project | 7.16 MB | 15.54 MB |
| Flutter, Android | Selfie | +3.57 MB | +8.06 MB |
| Flutter, Android | Selfie and documents | +10.98 MB | +23.79 MB |
| Flutter, iOS | Starting point: a new `flutter create` project | 6.05 MB | 14.16 MB |
| Flutter, iOS | Selfie | +3.20 MB | +8.89 MB |
| Flutter, iOS | Selfie and documents | +3.55 MB | +9.81 MB |
| Expo, Android | Starting point: a new `create-expo-app` project | 9.39 MB | 24.62 MB |
| Expo, Android | Selfie | +8.05 MB | +22.68 MB |
| Expo, Android | Selfie and documents | +15.16 MB | +37.93 MB |
| Expo, iOS | Starting point: a new `create-expo-app` project | 8.20 MB | 27.73 MB |
| Expo, iOS | Selfie | +8.64 MB | +22.53 MB |
| Expo, iOS | Selfie and documents | +8.67 MB | +22.70 MB |

## A complete app, for comparison

These apps are a complete integration: every product, selfie and document capture, and their own
screens, fonts and token scanner. That is the most an app adds.

| App | Download | On device |
|---|---|---|
| Android, version 1.0.3 | 14.29 MB | 29.38 MB |
| iOS, on SDK 12.2.0 | 5.48 MB | 13.62 MB |

## Why the numbers differ

- **Document capture on Android carries a model.** ML Kit's document detection ships inside the app,
  which is most of that column. ML Kit's face model downloads separately through Google Play services,
  so it is not counted.
- **iOS needs no model.** Apple's Vision framework is part of iOS, so documents add almost nothing
  over selfie.
- **React Native brings its own peers.** Much of each Expo row is packages the SDK needs alongside it,
  such as Lottie. An app that already ships them pays less.
- **You never pay twice.** An app that already uses Compose, CameraX or the same peers pays less than
  these figures. Add only what you use: a selfie-only app needs no document package.

## How it is measured

[`scripts/app_size.py`](../scripts/app_size.py) measures these apps the way the SDKs measure theirs.
Android is bundletool's figure for an arm64 phone on Android 14 at 480 dpi, which is what Google Play
delivers to that phone. iOS is the release build's size on disk, with a zip of it standing in for the
App Store's compressed download. The apps were measured on 1 October 2026, and the release check
reports the Android figure on every run.
