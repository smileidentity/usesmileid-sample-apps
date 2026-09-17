#!/usr/bin/env bash
# The definition of done for the Expo app: tokens, lint, types, unit tests, goldens, release bundle.
#
#   expo/verify.sh              everything, which is what a developer runs and what "green" means
#   expo/verify.sh checks       everything except the release bundle
#   expo/verify.sh bundle       only the production bundle both platforms ship
#   expo/verify.sh native       the minified release APK — not part of `all`
#
# `native` is out of `all` for the same reason iOS keeps `archive` out of its own: it needs a
# platform SDK a fresh clone does not have (the Android SDK, and a JDK the AARs were built against)
# and it is the only phase that leaves an installable artefact. `bundle` IS in `all`, because the
# Metro graph is where a missing file in a published package shows up, and it needs no native
# toolchain at all.
set -euo pipefail

cd "$(dirname "$0")"
REPO_ROOT="$(cd .. && pwd)"

PHASE="${1:-all}"
case "$PHASE" in
  all | checks | bundle | native) ;;
  *)
    echo "verify.sh: unknown phase '$PHASE' — expected all, checks, bundle or native" >&2
    exit 2
    ;;
esac

# `all` covers checks and bundle. `native` is only ever run by naming it, per the header.
runs() {
  if [ "$1" = native ]; then
    [ "$PHASE" = native ]
  else
    [ "$PHASE" = all ] || [ "$PHASE" = "$1" ]
  fi
}

# pnpm 9 by decision, not by accident: the sibling SDK repo needs 10.x and is run with npx, so a
# shared pin would drag one of the two onto a version it is not tested against.
PNPM="${PNPM:-pnpm}"
if ! "$PNPM" --version | grep -qE '^9\.'; then
  echo "verify.sh needs pnpm 9 (this workspace pins 9.15.9); found $("$PNPM" --version)." >&2
  exit 1
fi

if runs checks; then
  echo "==> dependencies resolve with every SDK peer satisfied"
  # --frozen-lockfile so a lockfile nobody regenerated fails here rather than on a runner, and the
  # strict peer setting in .npmrc is what makes a dropped SDK peer an error instead of a warning.
  "$PNPM" install --frozen-lockfile
fi

if runs checks; then
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
  python3 "$REPO_ROOT/scripts/test_sync_design_tokens.py" >/dev/null
fi

if runs checks; then
  echo "==> lint"
  "$PNPM" exec eslint .
fi

if runs checks; then
  echo "==> types"
  "$PNPM" --filter @smileid/sample-ui exec tsc --noEmit
  "$PNPM" --filter usesmileid-sample-expo exec tsc --noEmit
fi

if runs checks; then
  echo "==> unit tests (spec validation, fixture defaults, and the goldens in light and dark)"
  # --ci so an unrecorded golden fails instead of being written, which is how a missing state passes.
  "$PNPM" --filter @smileid/sample-ui exec jest --ci
fi

if runs bundle; then
  echo "==> release bundle for both platforms (minified, Hermes bytecode)"
  "$PNPM" --filter usesmileid-sample-expo exec expo export \
    --platform android --platform ios --output-dir dist
fi

if runs native; then
  echo "==> release APK (minified, resource-shrunk, no app-side keep rules)"
  if [ -z "${ANDROID_HOME:-}${ANDROID_SDK_ROOT:-}" ]; then
    echo "verify.sh native needs ANDROID_HOME or ANDROID_SDK_ROOT." >&2
    exit 1
  fi
  # Prebuild is regenerated rather than committed, so a hand-patched Podfile or Gradle file cannot
  # survive a run — which is the property this repository exists to keep.
  "$PNPM" --filter usesmileid-sample-expo exec expo prebuild --platform android --clean
  (cd app/android && ./gradlew assembleRelease)
fi

echo "OK"
