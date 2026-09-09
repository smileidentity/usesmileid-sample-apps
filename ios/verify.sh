#!/usr/bin/env bash
# The definition of done for the iOS app: tokens, format, unit tests, UI tests, release build.
#
#   ios/verify.sh                  everything, which is what a developer runs and what "green" means
#   ios/verify.sh checks           everything except the navigation UI suite
#   ios/verify.sh ui <ClassName>   only that UI class
#
# The phases exist because the UI suite is most of the lane and CI can give each class its own
# runner. They are modes of this script rather than steps repeated in YAML, so the contract still
# lives in one place; `.github/workflows/ios.yml` names the classes and a test asserts that list is
# complete.
set -euo pipefail

cd "$(dirname "$0")"
REPO_ROOT="$(cd .. && pwd)"

PHASE="${1:-all}"
UI_CLASS="${2:-}"
case "$PHASE" in
  all | checks) ;;
  ui)
    if [ -z "$UI_CLASS" ]; then
      echo "verify.sh ui needs a test class name" >&2
      exit 2
    fi
    ;;
  *)
    echo "verify.sh: unknown phase '$PHASE' — expected all, checks or ui <ClassName>" >&2
    exit 2
    ;;
esac

runs() {
  [ "$PHASE" = all ] || [ "$PHASE" = "$1" ]
}

SCHEME="${SCHEME:-UseSmileIDSample}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}"
RESULT_BUNDLE="${RESULT_BUNDLE:-build/uitest.xcresult}"

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
  # Re-record an intentional change with SNAPSHOT_TESTING_RECORD=all and commit what it writes.
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
  # its simulator being fresh — so locally the run has to start from one too.
  xcrun simctl uninstall booted com.usesmileid.sample.ios >/dev/null 2>&1 || true
  # A UI-test failure is a picture, not a message: without the bundle a red CI run cannot be read.
  # One bundle per class, or four jobs writing one path would overwrite each other's evidence.
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
    "${UI_ARGS[@]}" \
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
  echo "==> release probes gate (the card hides without -probes and shows with it, on the release build)"
  # The argument exists only for release runs, so a debug pass proves nothing about it. Two tests, on the
  # build the step above produced; the rest of the suite is configuration-blind and runs once, above.
  xcodebuild test \
    -project App/UseSmileIDSample.xcodeproj \
    -scheme UseSmileIDSampleUITests \
    -configuration Release \
    -destination "$DESTINATION" \
    -only-testing:UseSmileIDSampleUITests/UseSmileIDSampleLaunchArgumentUITests/testWithoutTheArgumentTheCardFollowsTheBuild \
    -only-testing:UseSmileIDSampleUITests/UseSmileIDSampleLaunchArgumentUITests/testWithTheArgumentTheCardShowsOnAnyBuild \
    TEST_RUNNER_USESMILEID_SAMPLE_CONFIGURATION=Release \
    -quiet

fi

echo "OK"
