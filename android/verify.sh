#!/usr/bin/env bash
# The definition of done for the Android app: run this before opening a PR.
#
#   token check -> lint -> unit tests (incl. spec validation) -> release assemble
#
# The release lane is not optional. Minification and resource shrinking with no app-side keep
# rules is the configuration where a defect in the *published* SDK actually surfaces, and it is
# the reason this repository consumes the SDK from Maven Central rather than by path.
#
# Device flows live in android/maestro and are not run here: they need a device. Run them with
#   maestro --device <serial> test -e APP_ID=com.usesmileid.sampleapps.android.debug android/maestro
# and against the minified build with
#   maestro --device <serial> test -e APP_ID=com.usesmileid.sampleapps.android       android/maestro
set -euo pipefail

cd "$(dirname "$0")"
REPO_ROOT="$(cd .. && pwd)"

# AGP 9 lint calls JDK 21 APIs, so 17 is not enough even though everything else builds on it.
if [ -z "${JAVA_HOME:-}" ] || ! "${JAVA_HOME}/bin/java" -version 2>&1 | grep -qE '"(2[1-9]|[3-9][0-9])'; then
  echo "verify.sh needs JAVA_HOME pointing at a JDK 21 or newer (AGP 9 lint requires it)." >&2
  echo "Current JAVA_HOME: ${JAVA_HOME:-<unset>}" >&2
  exit 1
fi

echo "==> design tokens are current"
# --check needs the design system checked out locally; it is generated output, never hand-edited.
python3 "$REPO_ROOT/scripts/sync_design_tokens.py" --all --check

echo "==> lint"
./gradlew lint

echo "==> unit tests (includes the spec validation)"
./gradlew test

echo "==> release assemble (minified, resource-shrunk, no app-side keep rules)"
./gradlew assembleRelease

echo "OK"
