#!/usr/bin/env bash
# Renders the App Store screenshots from the committed frames. --frames re-records the five
# off-device panels first; the capture panel comes from ios/App/UITests on a real device.
set -euo pipefail

cd "$(dirname "$0")/.."
REPO_ROOT="$(cd .. && pwd)"
FRAMES="store/frames"
OUT="store/screenshots"   # exactly the panels App Store Connect receives
PRESET="ios-phone"
BG="#151F72"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}"

STORESHOTS=(npx --yes -p storeshots-mcp storeshots)

if [ "${1:-}" = "--frames" ]; then
  echo "==> recording the five off-device panels"
  before="$(shasum -a 256 "$FRAMES"/*.frame.png 2>/dev/null || true)"
  # Record mode always exits non-zero, so the status cannot distinguish it from a compile error,
  # a missing simulator or a crashed host. Whether the frames actually moved can.
  # TEST_RUNNER_ prefixed, or xcodebuild drops it and the run verifies instead of recording.
  (cd SampleUI && TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all xcodebuild test \
    -scheme SampleUI \
    -destination "$DESTINATION" \
    -only-testing:SampleUIGoldenTests/UseSmileIDSampleStoreArtTest \
    -quiet) || true
  after="$(shasum -a 256 "$FRAMES"/*.frame.png 2>/dev/null || true)"
  if [ -z "$after" ]; then
    echo "the recorder wrote no frames — it failed before rendering" >&2
    exit 1
  fi
  if [ "$before" = "$after" ]; then
    echo "note: --frames rewrote nothing, so the screens are unchanged since the last record" >&2
  fi
fi

# Cleared, or a panel whose frame went missing keeps the previous run's PNG and is re-locked as current.
rm -rf "$OUT"

mkdir -p "$OUT"
skipped=""

# Wordless since 2026-09-14, and storeshots cannot compose without a headline — hence the local composer.
compose() {
  local name="$1"
  if [ ! -f "$FRAMES/$name.frame.png" ]; then
    skipped="$skipped $name"
    return 0
  fi
  echo "==> $name"
  node "$REPO_ROOT/scripts/compose-store-panel.mjs" \
    --preset "$PRESET" \
    --bg "$BG" \
    --screenshot "$FRAMES/$name.frame.png" \
    --output "$OUT/$name.png"
  "${STORESHOTS[@]}" validate --preset "$PRESET" "$OUT/$name.png"
}

compose products
compose token_session
compose capture
compose verifications
compose verification_details
compose settings

if [ -z "$(ls -A "$OUT"/*.png 2>/dev/null)" ]; then
  echo "no frames to render; run with --frames" >&2
  exit 1
fi

# A level above the panels: App Store Connect rejects a listing whose screenshot set carries
# anything that is not a screenshot, and the strip validates as one.
echo "==> showcase strip, for review in a PR"
"${STORESHOTS[@]}" showcase --output store/showcase.png \
  $(for n in products token_session capture verifications verification_details settings; do
      [ -f "$OUT/$n.png" ] && printf '%s ' "$OUT/$n.png"
    done)

# The panels are rendered from the frames, and nothing else notices when a frame moves under them.
# Same shape as scripts/app-icon.lock: the hash is committed, and the listing test fails on a drift.
echo "==> lock"
(cd "$FRAMES" && shasum -a 256 ./*.frame.png | sed 's| \./| |') > store/panels.lock

if [ -n "$skipped" ]; then
  echo "skipped, no frame yet:$skipped"
  echo "The camera panel needs a device: ios/App/UITests, see docs/plan/app-store-release-ios.md §2.3"
fi
echo "OK — $OUT"
