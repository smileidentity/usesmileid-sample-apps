#!/usr/bin/env bash
# The definition of done for the Expo app: tokens, lint, types, unit tests, goldens, release bundle.
#
#   expo/verify.sh              everything, which is what a developer runs and what "green" means
#   expo/verify.sh checks       everything except the release bundle
#   expo/verify.sh bundle       the production bundle both platforms ship, and the notices from it
#   expo/verify.sh native       the minified release APK — not part of `all`
#
# `native` is out of `all` for the same reason iOS keeps `archive` out of its own: it needs a
# platform SDK a fresh clone does not have (the Android SDK, and a JDK the AARs were built against)
# and it is the only phase that leaves an installable artefact. `bundle` IS in `all`, because the
# Metro graph is where a missing file in a published package shows up, and it needs no native
# toolchain at all. The notices check lives in `bundle` because it reads that bundle's source maps.
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
  # The notices generator's own rules, which no export is needed to check and which a wrong shipping
  # set would pass silently: a graph-walked set shipped 542 components and drifted 48 of them.
  python3 "$REPO_ROOT/scripts/test_generate_expo_licenses.py" >/dev/null 2>&1
fi

if runs checks; then
  echo "==> icons are current"
  # Generated from design/icons/, which lives in this repo rather than the design system, so this
  # needs no secret and always runs. A hand-edited path fails here.
  python3 "$REPO_ROOT/scripts/generate_expo_icons.py" --check
fi

if runs checks; then
  echo "==> third-party notices are current"
  # Apache-2.0 §4 asks the notice to travel with the distribution, so the bundle ships the list
  # rather than linking it. Walked from the app's production closure, which is what a partner ships.
  python3 "$REPO_ROOT/scripts/generate_expo_licenses.py" \
    --out expo/sample-ui/src/assets/licenses.json --check
fi

if runs checks; then
  echo "==> the project is still a well-formed Expo app"
  # The cheapest check that continuous native generation still holds and that every dependency version
  # agrees with the installed SDK — otherwise only a human noticing catches either.
  "$PNPM" --filter usesmileid-sample-expo exec expo-doctor
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
  # Source maps are what the notices are derived from: they name every module that actually shipped,
  # so the licence set cannot drift with whatever the hoisted installer left at the top of the tree.
  "$PNPM" --filter usesmileid-sample-expo exec expo export \
    --platform android --platform ios --source-maps --output-dir dist
fi

if runs bundle; then
  echo "==> third-party notices are current"
  # Apache-2.0 §4 asks the notice to travel with the distribution, so the bundle ships the list
  # rather than linking it. Derived from the bundle above and from the autolinked native modules,
  # which is what the app actually contains — the dependency graph reached 542 components a partner
  # receives almost none of, and 48 of them differed between a developer machine and CI.
  python3 "$REPO_ROOT/scripts/generate_expo_licenses.py" \
    --out expo/sample-ui/src/assets/licenses.json --bundle expo/app/dist --check
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
  # Both default to false in Expo's template, so an unflagged release APK is neither minified nor
  # shrunk — 184 MB of it, measured — and proves none of what this lane exists to prove. Passed as
  # project properties rather than through a build-properties plugin, which would be a new dependency.
  (cd app/android && ./gradlew assembleRelease \
    -Pandroid.enableMinifyInReleaseBuilds=true \
    -Pandroid.enableShrinkResourcesInReleaseBuilds=true)
fi

echo "OK"
