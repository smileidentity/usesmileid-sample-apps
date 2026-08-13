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
# --check needs the design system checked out locally.
python3 "$REPO_ROOT/scripts/sync_design_tokens.py" --all --check

echo "==> lint"
./gradlew lint

echo "==> unit tests (includes the spec validation)"
./gradlew test

echo "==> release assemble (minified, resource-shrunk, no app-side keep rules)"
./gradlew assembleRelease

echo "OK"
