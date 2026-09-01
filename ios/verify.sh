#!/usr/bin/env bash
# The definition of done for the iOS app: tokens, format, unit tests, UI tests, release build.
set -euo pipefail

cd "$(dirname "$0")"
REPO_ROOT="$(cd .. && pwd)"

SCHEME="${SCHEME:-UseSmileIDSample}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}"

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

echo "==> icons are current"
# Generated from design/icons/, which lives in this repo rather than the design system, so this
# needs no secret and always runs.
python3 "$REPO_ROOT/scripts/generate_ios_icons.py" --check

echo "==> format"
swiftformat --lint .

echo "==> project (generated from App/project.yml, so the pbxproj is never hand-edited)"
(cd App && xcodegen generate)

echo "==> library unit tests (includes the library's half of the spec validation)"
(cd SampleUI && xcodebuild test -scheme SampleUI -destination "$DESTINATION" -only-testing:SampleUITests -quiet)

echo "==> goldens, light and dark"
# Baselines are pixel comparisons, so they are only meaningful on the simulator they were recorded
# on — DESTINATION is pinned to the same iPhone 17 Pro the SDK repo's snapshot gate uses.
# Re-record an intentional change with SNAPSHOT_TESTING_RECORD=all and commit what it writes.
(cd SampleUI && xcodebuild test -scheme SampleUI -destination "$DESTINATION" -only-testing:SampleUIGoldenTests -quiet)

echo "==> shell unit tests (includes the route table's spec validation)"
xcodebuild test \
  -project App/UseSmileIDSample.xcodeproj \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -quiet

echo "==> navigation UI tests (the only ones that drive the real shell)"
# Deep links and the nav bar are only provable against a running app: the resolver is unit-tested,
# delivery is not. Every later screen asserts its route here rather than adding a harness.
xcodebuild test \
  -project App/UseSmileIDSample.xcodeproj \
  -scheme UseSmileIDSampleUITests \
  -destination "$DESTINATION" \
  -quiet

echo "==> release build (the configuration consumption defects actually surface in)"
xcodebuild build \
  -project App/UseSmileIDSample.xcodeproj \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "$DESTINATION" \
  -quiet

echo "OK"
