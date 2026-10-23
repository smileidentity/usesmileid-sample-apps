# Source builds

Each Smile ID SDK repository pins this repository as a git submodule and builds these same apps
against its own SDK source, so a public API change that would break an app fails in the SDK's pull
request, before it is released. The apps here never know which way they were built: a registry
build and a source build run the same shell and the same `sample-ui`. A source build changes three
things only: the SDK dependency, the app's identity on Android and iOS, and an optional developer
add-on that the shell reaches through one extension point.

## The extension point

A registry build has no extension. A source build may add one, and each shell finds it without
naming any SDK code:

| Platform | Declared in | How the shell finds it |
|---|---|---|
| Android | `android/app/…/extension/UseSmileIDSampleShellExtension.kt` | `ServiceLoader`, from a `META-INF/services` entry on the debug classpath |
| iOS | `ios/App/Sources/Extension/UseSmileIDSampleShellExtension.swift` | a conformance of `UseSmileIDSampleShellExtensionPoint` to `UseSmileIDSampleShellExtending` compiled into the app |
| Flutter | `flutter/app/lib/src/use_smileid_sample_shell_extension.dart` | passed to `useSmileIDSampleBootstrap(extension:)` by the source build's own `main` |
| Expo | `expo/app/src/use-smile-id-sample-shell-extension.ts` | Metro resolves `src/extension.ts` to the module `USESMILEID_SAMPLE_EXTENSION` names (`metro-shell-extension.js`) |

Every member is optional and does nothing by default:

| Member | The shell calls it |
|---|---|
| `onLaunch` | once per launch, before any other member (a recreation does not run it again; Expo, like its launch arguments, reads the cold-start link once per JavaScript process), with what the app was launched by: the intent on Android, the launch route on Flutter, the cold-start link on Expo (iOS passes nothing; it runs in `App.init`); it may finish asynchronously on Flutter and Expo, and a throw fails the launch, so a mistyped scenario never falls back to the camera: Android crashes, Flutter shows the error in place of the app, and Expo raises it as a render error; the shell sets no time limit, so an add-on bounds its own waits |
| `launchSession` | once, after `onLaunch` and before autostart; the shell links the session as if its token had been scanned, waits for it (Expo accepts a promise), and skips it if the call or the link fails |
| `customiseFlow` | each time it configures an SDK flow, after its own configuration, so the extension can replace any of it |
| `customiseNetwork` | last inside its network block, so the extension adds to that configuration |
| `debugRows` | in the Settings DEBUG section, which debug builds show |

**The order is a guarantee:** `onLaunch`, then `launchSession`, then autostart, then the flow hooks.
A unit test pins it on Android, Flutter and Expo with a recording extension; on iOS `App.init` runs
before SwiftUI builds the first scene, so no other member can be reached first.

## Identity

Android and iOS source builds carry their own URL scheme and label, which the build injects: the
`usesmileid.sample.sourceMode` Gradle property and the `USESMILEID_SAMPLE_SOURCE_MODE` build
setting. `spec/app-identity.json` records them under `sourceMode`, so the store app and a source
build can sit on one device without a link reaching the wrong one. Flutter and Expo source builds
keep the registry identity, so on one device it is one or the other.

## The `next` branch

`main` builds against released SDK versions only. A change that needs SDK API that is not released
yet lands on `next`, the one long-lived branch the SDK repositories pin, and is reviewed with the
linked SDK pull request's source-build lane green. This repo's own lanes build against the released
SDK, so they run red on `next` while it carries such a change; the SDK repositories' source-build
lanes are its gate. Everything else lands on `main`, which is merged
into `next` by whoever next works on `next`, and at least weekly by whoever owns the current SDK
release. `next` is only ever merged into, never rebased or force-pushed: released SDK versions pin
its commits. When an SDK version ships, `next` is merged into `main` and each SDK repository moves
its pin to the result.

The **Promote next** workflow (`promote-next.yml`) opens that merge, named for the release: run it
with the version that shipped. Its head is a copy of `next`, because merging a pull request deletes
its head branch and `next` must never be deleted. Once it merges, merge `main` back into `next`, then
run `bump_sample_apps.yaml` in each SDK repository to pin `main`. A promotion held open because `next`
needs a newer SDK is replaced when Promote next runs for that version. It runs in the `release`
environment, whose `PROMOTE_NEXT_TOKEN` is a token for this repository alone, with contents and pull
requests write: a pull request opened with the workflow's own token starts no checks.

## The reserved `e2eScenario` argument

An SDK repository's add-on reads one launch argument, `e2eScenario`: the JSON name of one of the
scenarios its testing kit's public `UseSmileIDTestScenario` type offers (for example
`selfie-happy-path`), not every file the kit bundles. It arrives the way each platform delivers
launch arguments: an intent extra on Android, a launch argument on iOS, and a query parameter of the
cold-start link on Flutter and Expo. No shell parses it and `spec/launch-args.json` does not list
it, because the shells must not know the add-on exists; no shell argument may take the name.
