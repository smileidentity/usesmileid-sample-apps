#!/usr/bin/env bash
# The definition of done for the Android app: tokens, lint, unit tests, release assemble.
#
# Device flows need a device and are not run here:
#   maestro --device <serial> test -e APP_ID=com.usesmileid.sampleapps.android.debug android/maestro
#   maestro --device <serial> test -e APP_ID=com.usesmileid.sampleapps.android       android/maestro
set -euo pipefail

cd "$(dirname "$0")"
REPO_ROOT="$(cd .. && pwd)"

# AGP 9 lint calls JDK 21 APIs; everything else builds on 17.
if [ -z "${JAVA_HOME:-}" ] || ! "${JAVA_HOME}/bin/java" -version 2>&1 | grep -qE '"(2[1-9]|[3-9][0-9])'; then
  echo "verify.sh needs JAVA_HOME pointing at a JDK 21 or newer (AGP 9 lint requires it)." >&2
  echo "Current JAVA_HOME: ${JAVA_HOME:-<unset>}" >&2
  exit 1
fi

echo "==> design tokens are current"
# --check needs the design system checked out. SMILE_DESIGN_SYSTEM points at it when it is not in one
# of the default skill paths, which is how CI supplies its own checkout.
#
# SMILE_TOKENS_OPTIONAL downgrades a missing design system from an error to a loud skip. It exists
# for one case: a fork PR, which gets no secret and so cannot check out a private repo. Never set it
# locally — a silent pass here is how vendored tokens drift from their source.
if [ -n "${SMILE_TOKENS_OPTIONAL:-}" ] && [ -z "${SMILE_DESIGN_SYSTEM:-}" ]; then
  echo "    SKIPPED — no design system available, so the vendored token output is unverified."
else
  TOKEN_ARGS=(--all --check)
  if [ -n "${SMILE_DESIGN_SYSTEM:-}" ]; then
    TOKEN_ARGS+=(--design-system "$SMILE_DESIGN_SYSTEM")
  fi
  python3 "$REPO_ROOT/scripts/sync_design_tokens.py" "${TOKEN_ARGS[@]}"
fi

echo "==> lint"
./gradlew lint

echo "==> unit tests (includes the spec validation and the font-scale predicates)"
./gradlew test

echo "==> goldens, light and dark"
./gradlew verifyRoborazziDebug

echo "==> release assemble (minified, resource-shrunk, no app-side keep rules)"
./gradlew assembleRelease

echo "OK"
