#!/usr/bin/env bash
# Renders the Play screenshots from committed frames. No agent in the loop, so CI can run it.
#
# Two sources, because only one of them can be rendered off-device:
#   five panels  — Roborazzi, on the JVM at 1080x1920 (sample-ui/src/test/store-art)
#   one panel    — Maestro on a Gradle Managed Device (android/maestro/store-shots.yaml)
#
# The frames are an output artefact and never an oracle. Goldens live in a different directory and are
# untouched by this script.
set -euo pipefail

cd "$(dirname "$0")/.."
REPO_ROOT="$(cd .. && pwd)"
FRAMES="sample-ui/src/test/store-art"
OUT="play/screenshots"
PRESET="android-phone"
# The brand blue the mark uses, so the panels sit on Smile ID's own colour rather than a default.
BG="#151F72"

# The CLI ships inside storeshots-mcp as a second binary; there is no package called `storeshots`.
STORESHOTS=(npx --yes -p storeshots-mcp storeshots)

if [ "${1:-}" = "--frames" ]; then
  echo "==> rendering the five off-device panels"
  # Filtered to the store-art class: recording every Roborazzi test would also rewrite the goldens.
  ./gradlew :sample-ui:recordRoborazziDebug --tests "*StoreArtTest*"
fi

missing=0
for name in products token_session capture verifications verification_details settings; do
  [ -f "$FRAMES/$name.png" ] || { echo "missing frame: $FRAMES/$name.png" >&2; missing=$((missing + 1)); }
done
if [ "$missing" -gt 0 ]; then
  echo "" >&2
  echo "Run with --frames to render the five off-device panels." >&2
  echo "The camera panel needs a device: see android/maestro/store-shots.yaml." >&2
  exit 1
fi

mkdir -p "$OUT"

# verb | descriptor | layout — the layout varies so six panels do not read as one template repeated.
compose() {
  local name="$1" verb="$2" desc="$3" variant="$4"
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

compose products             "Six"     "products, one integration"      text-top
compose token_session        "Link"    "a session from a token"         text-bottom
compose capture              "Capture" "with the Smile ID SDK"          text-top
compose verifications        "Track"   "every verification run"         text-bottom
compose verification_details "See"     "what the SDK returned"          text-top
compose settings             "Compose" "the journey step by step"       tilted

echo "==> showcase strip, for review in a PR"
"${STORESHOTS[@]}" showcase --output "$OUT/showcase.png" \
  "$OUT/products.png" "$OUT/token_session.png" "$OUT/capture.png" \
  "$OUT/verifications.png" "$OUT/verification_details.png" "$OUT/settings.png"

echo "OK — $OUT"
