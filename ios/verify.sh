#!/usr/bin/env bash
# The definition of done for the iOS app: tokens, format, unit tests, UI tests, release build.
#
#   ios/verify.sh                  everything, which is what a developer runs and what "green" means
#   ios/verify.sh checks           everything except the navigation UI suite
#   ios/verify.sh ui <ClassName>   only that UI class
#   ios/verify.sh archive          the distributable archive and its IPA — not part of `all`
#
# The phases exist because the UI suite is most of the lane and CI can give each class its own
# runner. They are modes of this script rather than steps repeated in YAML, so the contract still
# lives in one place; `.github/workflows/ios.yml` names the classes and a test asserts that list is
# complete.
#
# `archive` is out of `all` because it needs a signing identity a fresh clone does not have, and
# because it is the only phase that leaves a publishable artefact. See
# docs/plan/app-store-release-ios.md §3.
set -euo pipefail

cd "$(dirname "$0")"
REPO_ROOT="$(cd .. && pwd)"

PHASE="${1:-all}"
UI_CLASS="${2:-}"
case "$PHASE" in
  all | checks | archive) ;;
  ui)
    if [ -z "$UI_CLASS" ]; then
      echo "verify.sh ui needs a test class name" >&2
      exit 2
    fi
    ;;
  *)
    echo "verify.sh: unknown phase '$PHASE' — expected all, checks, ui <ClassName> or archive" >&2
    exit 2
    ;;
esac

runs() {
  [ "$PHASE" = all ] || [ "$PHASE" = "$1" ]
}

SCHEME="${SCHEME:-UseSmileIDSample}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}"
RESULT_BUNDLE="${RESULT_BUNDLE:-build/uitest.xcresult}"

# Refused, not skipped: the resets below are simctl and would no-op in silence on a device.
# `archive` is exempt because it builds for generic/platform=iOS and runs nothing.
if [ "$PHASE" != archive ]; then
  case "$DESTINATION" in
    *"iOS Simulator"*) ;;
    *)
      echo "verify.sh runs on a simulator; '$DESTINATION' is not one." >&2
      echo "For a device see docs/plan/ios-device-verification.md §2.3 — it needs its own reset." >&2
      exit 2
      ;;
  esac
fi

if runs checks; then
  echo "==> design tokens are current"
  # SMILE_TOKENS_OPTIONAL downgrades a missing design system to a skip, for fork PRs that get no
  # secret — never set it locally, or vendored tokens drift from their source unnoticed.
  if [ -n "${SMILE_TOKENS_OPTIONAL:-}" ] && [ -z "${SMILE_DESIGN_SYSTEM:-}" ]; then
    echo "    SKIPPED — no design system available, so the vendored token output is unverified."
  else
    TOKEN_ARGS=(--all --check)
    if [ -n "${SMILE_DESIGN_SYSTEM:-}" ]; then
      TOKEN_ARGS+=(--design-system "$SMILE_DESIGN_SYSTEM")
    fi
    python3 "$REPO_ROOT/scripts/sync_design_tokens.py" "${TOKEN_ARGS[@]}"
  fi
fi

if runs checks; then
  echo "==> icons are current"
  # Generated from design/icons/, which lives in this repo rather than the design system, so this
  # needs no secret and always runs.
  python3 "$REPO_ROOT/scripts/generate_ios_icons.py" --check
  # The launcher mark too; a hand export once shipped without the platform badge.
  python3 "$REPO_ROOT/scripts/generate_app_icon.py" --check
fi

if runs checks; then
  echo "==> the listing App Store Connect receives"
  # Files only, so it needs no simulator and the archive phase can run the same check in seconds.
  python3 "$REPO_ROOT/scripts/check_store_listing.py" --check
fi

if runs checks; then
  echo "==> third-party notices are current"
  # Apache-2.0 §4 asks the notice to travel with the distribution, so the app ships the list rather
  # than linking it. Walked from the products the app links, which needs the graph resolved first.
  python3 "$REPO_ROOT/scripts/test_generate_ios_licenses.py" >/dev/null
  python3 "$REPO_ROOT/scripts/generate_ios_licenses.py" \
    --out SampleUI/Sources/SampleUI/Resources/licenses.json --check
fi

if runs checks; then
  echo "==> format"
  swiftformat --lint .
fi

# Not gated by phase: every phase that builds needs the project, and the generated one is not
# committed. Gating it as a "check" left the ui jobs with no project at all.
echo "==> project (generated from App/project.yml, so the pbxproj is never hand-edited)"
(cd App && xcodegen generate)

if runs checks; then
  echo "==> library unit tests (includes the library's half of the spec validation)"
  (cd SampleUI && xcodebuild test -scheme SampleUI -destination "$DESTINATION" -only-testing:SampleUITests -quiet)
fi

if runs checks; then
  echo "==> goldens, light and dark"
  # Baselines are pixel comparisons, so they are only meaningful on the simulator they were recorded
  # on — DESTINATION is pinned to the same iPhone 17 Pro the SDK repo's snapshot gate uses.
  # Re-record an intentional change with TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all (xcodebuild forwards only
  # TEST_RUNNER_ variables; the bare name records nothing) and commit what it writes.
  (cd SampleUI && xcodebuild test -scheme SampleUI -destination "$DESTINATION" -only-testing:SampleUIGoldenTests -quiet)
fi

if runs checks; then
  echo "==> shell unit tests (includes the route table's spec validation)"
  xcodebuild test \
    -project App/UseSmileIDSample.xcodeproj \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -quiet
fi

if runs ui; then
  echo "==> navigation UI tests (the only ones that drive the real shell)"
  # Deep links and the nav bar are only provable against a running app: the resolver is unit-tested,
  # delivery is not. Every later screen asserts its route here rather than adding a harness.
  #
  # A build under the pre-rename bundle id declares the same URL scheme, so on a long-lived simulator
  # it takes the deep links and every test reds as though routing were broken. CI never sees it.
  # Waited for, not assumed: a cold simulator makes the timing-sensitive tests flaky — the rotation
  # one reads the window frame right after asking for landscape. A serial run had already warmed it
  # on the earlier steps; a job that runs only this step has not.
  DEVICE="$(printf '%s' "$DESTINATION" | sed -n 's/.*name=\([^,]*\).*/\1/p')"
  if [ -n "$DEVICE" ]; then
    xcrun simctl bootstatus "$DEVICE" -b >/dev/null 2>&1 || true
  fi
  xcrun simctl uninstall booted com.usesmileid.sampleapps.ios >/dev/null 2>&1 || true
  # And the app's own store, because the suite addresses rows by position: `seedJobs` re-adds a row an
  # earlier test removed with a freshly computed date, so a store surviving an earlier session makes
  # the processing row the newest and inverts two verifications tests. CI never sees this one either,
  # its simulator being fresh — so locally the run has to start from one too. It takes the persisted
  # settings with it, the container holding both; each launch seeds the switches regardless.
  xcrun simctl uninstall booted com.usesmileid.sample.ios >/dev/null 2>&1 || true
  # A UI-test failure is a picture, not a message: without the bundle a red CI run cannot be read.
  # One bundle per class, or four jobs writing one path would overwrite each other's evidence.
  # Expanded with the `+` guard because macOS ships bash 3.2, where an empty array under `set -u` is
  # an unbound variable — which is the no-class run, the one a developer types.
  UI_ARGS=()
  BUNDLE="$RESULT_BUNDLE"
  if [ -n "$UI_CLASS" ]; then
    UI_ARGS+=(-only-testing:"UseSmileIDSampleUITests/$UI_CLASS")
    BUNDLE="${RESULT_BUNDLE%.xcresult}-$UI_CLASS.xcresult"
  fi
  rm -rf "$BUNDLE"
  xcodebuild test \
    -project App/UseSmileIDSample.xcodeproj \
    -scheme UseSmileIDSampleUITests \
    -destination "$DESTINATION" \
    -resultBundlePath "$BUNDLE" \
    ${UI_ARGS[@]+"${UI_ARGS[@]}"} \
    -quiet
fi

if runs checks; then
  echo "==> release build (the configuration consumption defects actually surface in)"
  xcodebuild build \
    -project App/UseSmileIDSample.xcodeproj \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "$DESTINATION" \
    -quiet
fi

if runs checks; then
  echo "==> release probes gate, and the App Review claim that needs no credential"
  # The argument exists only for release runs, so a debug pass proves nothing about it. The third test
  # is the compliance one: "all functionality is available without special access" is only true while
  # Simulate survives release, and a checklist line would rot where an assertion does not.
  xcodebuild test \
    -project App/UseSmileIDSample.xcodeproj \
    -scheme UseSmileIDSampleUITests \
    -configuration Release \
    -destination "$DESTINATION" \
    -only-testing:UseSmileIDSampleUITests/UseSmileIDSampleLaunchArgumentUITests/testWithoutTheArgumentTheCardFollowsTheBuild \
    -only-testing:UseSmileIDSampleUITests/UseSmileIDSampleLaunchArgumentUITests/testWithTheArgumentTheCardShowsOnAnyBuild \
    -only-testing:UseSmileIDSampleUITests/UseSmileIDSampleNavigationUITests/testSimulateLinksASessionAndTheProductsStripCountsItDown \
    TEST_RUNNER_USESMILEID_SAMPLE_CONFIGURATION=Release \
    -quiet

fi

# Deliberately not `runs archive`: that is true under `all`, and the bare script — the definition
# of done — would then demand a signing identity a fresh clone does not have.
if [ "$PHASE" = archive ]; then
  echo "==> the listing App Store Connect receives"
  python3 "$REPO_ROOT/scripts/check_store_listing.py" --check

  echo "==> archive (Release, generic device, for App Store distribution)"
  # Both refusals are here rather than in a workflow step, so a hand-built archive is held to the
  # same rule as a CI one. A build number App Store Connect has already seen for this marketing
  # version is rejected at upload, which is late and wastes an integer.
  # A lane with no credentials can still prove the shipped configuration builds and declares what
  # an upload is rejected for; only a real upload needs an identity.
  SIGNING_ARGS=()
  if [ -n "${ARCHIVE_UNSIGNED:-}" ]; then
    SIGNING_ARGS=(CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="")
    DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}"
  else
    : "${DEVELOPMENT_TEAM:?archive needs DEVELOPMENT_TEAM — it is never committed, see docs/plan/app-store-release-ios.md §3}"
  fi
  case "${BUILD_NUMBER:-}" in
    "" | *[!0-9]*)
      echo "archive needs a positive integer BUILD_NUMBER; the workflows pass git rev-list --count HEAD" >&2
      exit 2
      ;;
  esac
  [ "$BUILD_NUMBER" -gt 0 ] || { echo "BUILD_NUMBER must be positive" >&2; exit 2; }

  # Optional: unset keeps project.yml's hand-bumped value, which is what a local archive wants.
  VERSION_ARGS=()
  if [ -n "${MARKETING_VERSION:-}" ]; then
    # Anchored, not a glob: `[0-9]*.[0-9]*` matched `1.0; anything` and refused the bare `1`.
    if printf '%s' "$MARKETING_VERSION" | grep -Eq '^[0-9]+(\.[0-9]+){0,2}$'; then
      VERSION_ARGS+=(MARKETING_VERSION="$MARKETING_VERSION")
    else
      echo "MARKETING_VERSION '$MARKETING_VERSION' is not one to three dot-separated numbers" >&2
      exit 2
    fi
  fi

  ARCHIVE="${ARCHIVE_PATH:-build/UseSmileIDSample.xcarchive}"
  EXPORT_DIR="${EXPORT_PATH:-build/export}"
  rm -rf "$ARCHIVE" "$EXPORT_DIR"

  # The identity is the target's own Release setting, never an argument: a command-line one is
  # global and reaches SampleUI's resource bundle, which has no team and fails the whole archive.
  xcodebuild archive \
    -project App/UseSmileIDSample.xcodeproj \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE" \
    -allowProvisioningUpdates \
    DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    ${VERSION_ARGS[@]+"${VERSION_ARGS[@]}"} \
    ${SIGNING_ARGS[@]+"${SIGNING_ARGS[@]}"} \
    -quiet

  if [ -n "${EXPORT_ARCHIVE_ONLY:-}" ]; then
    # For a lane holding no distribution key: the archive is the whole of what it can prove.
    echo "==> export skipped (EXPORT_ARCHIVE_ONLY)"
    echo "OK"
    exit 0
  fi

  echo "==> export (IPA, or the upload when EXPORT_DESTINATION=upload)"
  # The committed plist carries no team, so the copy that does is built here and dies with the run.
  WORK="$(mktemp -d)"
  trap 'rm -rf "$WORK"' EXIT
  OPTIONS="$WORK/ExportOptions.plist"
  cp store/ExportOptions.plist "$OPTIONS"
  plutil -replace teamID -string "$DEVELOPMENT_TEAM" "$OPTIONS"
  plutil -replace destination -string "${EXPORT_DESTINATION:-export}" "$OPTIONS"

  # The API key authenticates the upload and lets automatic signing fetch a distribution profile,
  # which is what replaces a keychain this repository would otherwise have to carry. The path is
  # derived rather than passed: a workflow `env:` value is not a shell, so a `~` in one stays a
  # literal and xcodebuild reports a missing key that is sitting where it was put.
  AUTH=()
  if [ -n "${APP_STORE_CONNECT_KEY_ID:-}" ]; then
    KEY_PATH="${APP_STORE_CONNECT_KEY_PATH:-$HOME/.appstoreconnect/private_keys/AuthKey_$APP_STORE_CONNECT_KEY_ID.p8}"
    [ -f "$KEY_PATH" ] || { echo "no App Store Connect key at $KEY_PATH" >&2; exit 2; }
    AUTH=(
      -authenticationKeyPath "$KEY_PATH"
      -authenticationKeyID "$APP_STORE_CONNECT_KEY_ID"
      -authenticationKeyIssuerID "${APP_STORE_CONNECT_ISSUER_ID:?an API key needs its issuer id}"
    )
  fi

  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportOptionsPlist "$OPTIONS" \
    -exportPath "$EXPORT_DIR" \
    -allowProvisioningUpdates \
    ${AUTH[@]+"${AUTH[@]}"}
fi

echo "OK"
