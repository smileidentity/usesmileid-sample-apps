#!/usr/bin/env bash
# The definition of done for the Flutter app: tokens, format, analyze, tests, goldens, release builds.
#
# Device flows need a device and are not run here. The app shares its application id with the
# Flutter SDK repo's development sample (spec/app-identity.json), so install one at a time.
# Phases: all (default) · checks (all but the release APKs) · android (only the release APKs).
set -euo pipefail

PHASE="${1:-all}"
case "$PHASE" in
  all | checks | android) ;;
  *) echo "usage: $0 [all|checks|android]" >&2; exit 2 ;;
esac

cd "$(dirname "$0")"
REPO_ROOT="$(cd .. && pwd)"

PACKAGES=(sample_ui app)

if [ "$PHASE" != android ]; then
  echo "==> design tokens are current"
  # SMILE_DESIGN_SYSTEM points --check at a checkout outside the default skill paths, which is how CI
  # supplies its own. SMILE_TOKENS_OPTIONAL downgrades a missing one to a loud skip, for fork PRs that
  # get no secret — never set it locally, or vendored tokens drift from their source unnoticed.
  if [ -n "${SMILE_TOKENS_OPTIONAL:-}" ] && [ -z "${SMILE_DESIGN_SYSTEM:-}" ]; then
    echo "    SKIPPED — no design system available, so the vendored token output is unverified."
  else
    TOKEN_ARGS=(--all --check)
    if [ -n "${SMILE_DESIGN_SYSTEM:-}" ]; then
      TOKEN_ARGS+=(--design-system "$SMILE_DESIGN_SYSTEM")
    fi
    python3 "$REPO_ROOT/scripts/sync_design_tokens.py" "${TOKEN_ARGS[@]}"
  fi

  echo "==> the token generator's own tests"
  python3 "$REPO_ROOT/scripts/test_sync_design_tokens.py" >/dev/null

  echo "==> icons are current"
  # Vendored byte for byte from design/icons/, like the Compose drawables and the SwiftUI shapes are
  # generated from it; a hand-edited asset or an unsourced one fails here.
  python3 "$REPO_ROOT/scripts/generate_flutter_icons.py" --check
fi

for package in "${PACKAGES[@]}"; do
  echo "==> $package: resolve"
  (cd "$package" && flutter pub get >/dev/null)
done

if [ "$PHASE" != android ]; then
  echo "==> format"
  # --set-exit-if-changed rather than a check flag: dart format has no read-only mode that fails.
  dart format --output=none --set-exit-if-changed "${PACKAGES[@]}"

  for package in "${PACKAGES[@]}"; do
    echo "==> $package: analyze"
    (cd "$package" && flutter analyze)

    echo "==> $package: tests (spec validation, goldens light and dark, text-scale predicates)"
    # A zone with a clock change, or the 23-hour-day test passes the bug it exists to catch.
    (cd "$package" && TZ=Europe/London flutter test)
  done
fi

if [ "$PHASE" != checks ]; then
  echo "==> release APKs, one per ABI (minified, resource-shrunk, no app-side keep rules)"
  # Bundled ML Kit ships a native library per ABI, so a single APK carries four and weighs ~117 MB.
  (cd app && flutter build apk --release --split-per-abi)
fi

if [ "$PHASE" != android ]; then
  # The one lane that needs a Mac. Skipped loudly rather than silently, so a Linux run cannot read as
  # having proved the iOS side.
  if [ "$(uname -s)" = "Darwin" ] && command -v xcodebuild >/dev/null 2>&1; then
    echo "==> release iOS build (unsigned)"
    (cd app && flutter build ios --release --no-codesign)
  else
    echo "==> release iOS build"
    echo "    SKIPPED — needs macOS with Xcode; the iOS side of this app is unverified by this run."
  fi
fi

echo "OK"
