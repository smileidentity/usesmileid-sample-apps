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

# Wordless since 2026-09-14, and storeshots cannot compose without a headline — hence the local composer.
compose() {
  local name="$1"
  if [ ! -f "$FRAMES/$name.png" ]; then
    skipped="$skipped $name"
    return 0
  fi
  echo "==> $name"
  node "$REPO_ROOT/scripts/compose-store-panel.mjs" \
    --preset "$PRESET" \
    --bg "$BG" \
    --screenshot "$FRAMES/$name.png" \
    --output "$OUT/$name.png"
  "${STORESHOTS[@]}" validate --preset "$PRESET" "$OUT/$name.png"
}

compose products
compose token_session
compose capture
compose verifications
compose verification_details
compose settings

FEATURE_GRAPHIC="$(dirname "$OUT")/feature-graphic.png"
if [ -f "$FRAMES/products.png" ]; then
  echo "==> feature graphic"
  "${STORESHOTS[@]}" compose \
    --preset play-feature-graphic \
    --bg "$BG" \
    --verb "Smile ID" \
    --desc "identity verification, end to end" \
    --variant text-top \
    --screenshot "$FRAMES/products.png" \
    --output "$FEATURE_GRAPHIC"
  "${STORESHOTS[@]}" validate --preset play-feature-graphic "$FEATURE_GRAPHIC"
else
  skipped="$skipped feature-graphic"
fi

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
  echo "The release lane requires every one of them, so it will fail until they exist."
fi
echo "OK — $OUT"
