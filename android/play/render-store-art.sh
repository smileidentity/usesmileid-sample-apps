#!/usr/bin/env bash
# Renders the Play screenshots from the committed frames. --frames re-renders the five off-device
# panels first; the camera panel comes from android/maestro/store/store-shots.yaml.
set -euo pipefail

cd "$(dirname "$0")/.."
REPO_ROOT="$(cd .. && pwd)"
FRAMES="sample-ui/src/test/store-art"
OUT="play/screenshots"   # exactly the panels Play receives
PRESET="android-phone"
BG="#151F72"

STORESHOTS=(npx --yes -p storeshots-mcp storeshots)

if [ "${1:-}" = "--frames" ]; then
  echo "==> rendering the five off-device panels"
  ./gradlew :sample-ui:recordRoborazziDebug --tests "*StoreArtTest*"
fi

mkdir -p "$OUT"
skipped=""

compose() {
  local name="$1" verb="$2" desc="$3" variant="$4"
  if [ ! -f "$FRAMES/$name.png" ]; then
    skipped="$skipped $name"
    return 0
  fi
  echo "==> $name"
  "${STORESHOTS[@]}" compose \
    --preset "$PRESET" \
    --bg "$BG" \
    --verb "$verb" \
    --desc "$desc" \
    --variant "$variant" \
    --screenshot "$FRAMES/$name.png" \
    --output "$OUT/$name.png"
  "${STORESHOTS[@]}" validate --preset "$PRESET" "$OUT/$name.png"
}

compose products             "Try"       "every Smile ID product"      text-top
compose token_session        "Scan"      "a token to start a session"  text-top
compose capture              "Capture"   "a selfie or a document"      text-top
compose verifications        "Review"    "every verification result"    text-top
compose verification_details "See"       "the details of a verification" text-top
compose settings             "Configure" "the steps in the flow"       text-top

if [ -z "$(ls -A "$OUT"/*.png 2>/dev/null)" ]; then
  echo "no frames to render; run with --frames" >&2
  exit 1
fi

echo "==> showcase strip, for review in a PR"
"${STORESHOTS[@]}" showcase --output "$(dirname "$OUT")/showcase.png" \
  $(for n in products token_session capture verifications verification_details settings; do
      [ -f "$OUT/$n.png" ] && printf '%s ' "$OUT/$n.png"
    done)

if [ -n "$skipped" ]; then
  echo "skipped, no frame yet:$skipped"
  echo "The camera panel needs a device: android/maestro/store/store-shots.yaml"
fi
echo "OK — $OUT"
