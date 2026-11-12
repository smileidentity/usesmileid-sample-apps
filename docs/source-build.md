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
| `leadingDebugRows` | in the Settings DEBUG section, which debug builds show, above the shell's own rows (Network logs on Android and iOS), so an identity the rows below refer to comes first |
| `debugRows` | in the same section, below the shell's own rows |

**The order is a guarantee:** `onLaunch`, then `launchSession`, then autostart, then the flow hooks.
A unit test pins it on Android, Flutter and Expo with a recording extension; on iOS `App.init` runs
before SwiftUI builds the first scene, so no other member can be reached first.

## Identity

Android and iOS source builds carry their own URL scheme and label, which the build injects: the
`usesmileid.sample.sourceMode` Gradle property and the `USESMILEID_SAMPLE_SOURCE_MODE` build
setting. `spec/app-identity.json` records them under `sourceMode`, so the store app and a source
build can sit on one device without a link reaching the wrong one. Flutter and Expo source builds
keep the registry identity, so on one device it is one or the other.

## SDK snapshots and pins

`main` builds on recent snapshots of each Smile ID SDK between releases, so it can carry changes
that aren't released yet, and it is the only branch. Each app pins exact builds, never a range, and
pins njia, the SDKs' navigation engine, to the exact build its SDK snapshot was made against:

| Platform | Snapshot | Where an SDK change's snapshot version is printed |
|---|---|---|
| Android | `<version>-<date>.<time>-<n>`, from Central's snapshots repository; each module has its own `<n>` | the Publish Snapshot step's log in the SDK build that published it; pin the set from that one run |
| iOS | `<version>-SNAPSHOT.<timestamp>.<run>`, an ios-spm tag | the ios-spm tag ending in that SDK build's run id |
| Flutter | `<version>-SNAPSHOT.<run>`, on pub.dev | the SDK publish run's summary (`### snapshot <version>`) |
| Expo | `<version>-SNAPSHOT.<run>`, on npm | the SDK publish run's Publish to npm log (`+ @smileid/<package>@<version>`) |

Android pins the timestamped build because a bare `-SNAPSHOT` can resolve a build made against
another njia. Android and iOS publish a snapshot on every push to an SDK pull request and to the
SDK's `main`; Flutter and Expo publish one when their publish workflow is dispatched with
`channel=snapshot`.

**Only ready snapshots are pinned.** `main` pins a snapshot only when it is the final commit of an
SDK pull request that is approved and green, or a commit on an SDK's `main`. Never a pull request
that is still changing.

### A change that needs new SDK API

The app change merges first, and the SDK pull request pins the merged commit:

1. The SDK change is reviewed in its own pull request, from a branch in the SDK repository. Build the
   pair from source meanwhile: check out your branch of this repository in the SDK's `sample-apps/`
   submodule. This pull request may be open as a draft.
2. When the SDK pull request is approved, green, up to date with its `main` and finished, take the
   snapshot of its final commit (the table above).
3. Pin that snapshot here, update the branch from `main`, and merge it once every lane is green.
4. The SDK pull request pins the commit this one merged as, not the tip of `main` and never an open
   pull request's head, and then merges. No pin moves after that.
5. A later bump moves `main` to a snapshot of the SDK's `main`.

- One paired change per platform at a time, and a pin only moves to a snapshot that contains the
  code behind the pin it replaces. A second pair for the same platform waits until the first SDK
  pull request has merged.
- A pair that is dropped is reverted on `main` the same day.
- A bump that turns `main` red is reverted, not fixed forward.
- `main` requires no status check, so update a pull request from `main` and re-run its checks before
  merging it.

**Snapshots expire.** Central keeps a snapshot build for 90 days. ios-spm keeps its newest snapshots,
those from the last 14 days, and every one `main` resolves. An older commit on `main` may stop
building; use the newest commit or a `v*` tag.

### Releases

1. Once the SDKs' release-prep changes have merged, bump `main` to snapshots of those commits (for
   Flutter and Expo, dispatch a snapshot first). Green on all four lanes is the go signal.
2. The SDKs publish from those same commits.
3. One pull request here moves every pin from the snapshot to the release: the SDKs, njia, kamera
   where it is pinned, the lockfiles and the third-party notices. Squash it and tag the merged
   commit `v<version>`.
4. Production store builds (Play production, the App Store, AppGallery) run from that tag. Their
   first step, `scripts/release_pins.py`, refuses any other ref and any pin that isn't a plain
   `x.y.z`, lockfiles included; a lookup-only or dry run publishes nothing and skips it. Internal
   builds (Play internal testing, TestFlight) ship from `main` at any time.
5. `main` goes back to snapshots with the next change that needs one.

## The reserved `e2eScenario` argument

An SDK repository's add-on reads one launch argument, `e2eScenario`: the JSON name of one of the
scenarios its testing kit's public `UseSmileIDTestScenario` type offers (for example
`selfie-happy-path`), not every file the kit bundles. It arrives the way each platform delivers
launch arguments: an intent extra on Android, a launch argument on iOS, and a query parameter of the
cold-start link on Flutter and Expo. No shell parses it and `spec/launch-args.json` does not list
it, because the shells must not know the add-on exists; no shell argument may take the name.
