#!/usr/bin/env python3
"""Generates the third-party notices the Android sample app ships in its binary.

Gradle hands over the release runtime classpath; the rules here are: walk parent POMs, consult a
reviewed override table, keep every licence an artifact declares, and fail rather than emit
"Unknown" — one that reaches a partner is worse than a red build.

    ./gradlew :app:generateLicenses      # rewrite the committed asset
    ./gradlew :app:checkLicenses         # fail if the committed asset is stale
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import re
import sys
import xml.etree.ElementTree as ET

MAVEN = "{http://maven.apache.org/POM/4.0.0}"
PARENT_LIMIT = 8

# Licences whose text ships with the app, keyed by the file in --texts holding it.
KNOWN_LICENCES = {
    "Apache-2.0": {
        "text": "apache-2.0.txt",
        "names": {
            "the apache software license, version 2.0",
            "the apache license, version 2.0",
            "apache license, version 2.0",
            "apache license 2.0",
            "apache 2.0",
            "apache-2.0",
            "apache license version 2.0",
        },
    },
    "MIT": {
        "text": "mit.txt",
        "names": {"mit", "mit license", "the mit license", "mit licence"},
    },
    "BSD-3-Clause": {
        "text": "bsd-3-clause.txt",
        "names": {
            "bsd-3-clause",
            "bsd 3-clause",
            "the 3-clause bsd license",
            "bsd license",
            "bsd",
        },
    },
    # No text vendored: it ships inside the jar as org/bouncycastle/LICENSE.class, so the notice links it.
    "Bouncy Castle Licence": {
        "text": None,
        "names": {"bouncy castle licence", "bouncy castle license"},
    },
}

# Not open source: these declare Google's own terms, and the page they point at IS the licence.
GOOGLE_TERMS = {
    "play integrity api terms of service",
    "ml kit terms of service",
    "android software development kit license",
    "google apis terms of service",
    "google play core software development kit terms of service",
    "play core software development kit terms of service",
}

# The SDK itself, which a partner licenses from us rather than being told about. Its own terms are
# not a third-party notice, and listing them under an open-source heading would be wrong.
FIRST_PARTY_GROUPS = ("com.usesmileid",)

# Artifacts that declare a licence in no POM in their chain. Each entry is a reviewed fact.
OVERRIDES = {
    # JSR-330's reference implementation: no <licenses> block in its POM; published Apache-2.0.
    "javax.inject:javax.inject": [
        {
            "id": "Apache-2.0",
            "name": "The Apache Software License, Version 2.0",
            "url": "https://www.apache.org/licenses/LICENSE-2.0.txt",
        },
    ],
    # Ships its licence inside the jar, at org/bouncycastle/LICENSE.class.
    "org.bouncycastle:bcprov-jdk18on": [
        {"id": "Bouncy Castle Licence", "name": "Bouncy Castle Licence", "url": "https://www.bouncycastle.org/licence.html"},
    ],
    "org.bouncycastle:bcprov-jdk15on": [
        {"id": "Bouncy Castle Licence", "name": "Bouncy Castle Licence", "url": "https://www.bouncycastle.org/licence.html"},
    ],
    "org.bouncycastle:bcutil-jdk18on": [
        {"id": "Bouncy Castle Licence", "name": "Bouncy Castle Licence", "url": "https://www.bouncycastle.org/licence.html"},
    ],
}


class Unidentified(Exception):
    """An artifact whose licence could not be established. Never emitted as data."""


def gradle_cache() -> str:
    home = os.environ.get("GRADLE_USER_HOME") or os.path.join(os.path.expanduser("~"), ".gradle")
    return os.path.join(home, "caches", "modules-2", "files-2.1")


def pom_path(group: str, artifact: str, version: str) -> str | None:
    """The POM Gradle already downloaded. Its own resolution is what puts it here."""
    pattern = os.path.join(gradle_cache(), group, artifact, version, "*", f"{artifact}-{version}.pom")
    found = sorted(glob.glob(pattern))
    return found[0] if found else None


def read_pom(group: str, artifact: str, version: str) -> ET.Element | None:
    path = pom_path(group, artifact, version)
    if path is None:
        return None
    try:
        return ET.parse(path).getroot()
    except ET.ParseError as error:
        raise Unidentified(f"{group}:{artifact}:{version} has an unreadable POM: {error}") from error


def is_platform(root: ET.Element) -> bool:
    """A BOM ships no code, so it carries no notice — it only constrains versions."""
    return (root.findtext(f"{MAVEN}packaging") or "jar").strip() == "pom"


def declared_licences(root: ET.Element) -> list[dict[str, str]]:
    out = []
    for licence in root.findall(f"{MAVEN}licenses/{MAVEN}license"):
        name = (licence.findtext(f"{MAVEN}name") or "").strip()
        url = (licence.findtext(f"{MAVEN}url") or "").strip()
        if name or url:
            out.append({"name": name, "url": url})
    return out


def parent_of(root: ET.Element) -> tuple[str, str, str] | None:
    parent = root.find(f"{MAVEN}parent")
    if parent is None:
        return None
    group = (parent.findtext(f"{MAVEN}groupId") or "").strip()
    artifact = (parent.findtext(f"{MAVEN}artifactId") or "").strip()
    version = (parent.findtext(f"{MAVEN}version") or "").strip()
    if not (group and artifact and version):
        return None
    return group, artifact, version


def licences_for(group: str, artifact: str, version: str) -> list[dict[str, str]]:
    """The artifact's own declaration, else its nearest ancestor's, else the override table."""
    module = f"{group}:{artifact}"
    coordinates: tuple[str, str, str] | None = (group, artifact, version)
    for _ in range(PARENT_LIMIT):
        if coordinates is None:
            break
        root = read_pom(*coordinates)
        if root is None:
            break
        found = declared_licences(root)
        if found:
            return found
        coordinates = parent_of(root)
    override = OVERRIDES.get(module)
    if override:
        return [dict(entry) for entry in override]
    raise Unidentified(
        f"{module}:{version} declares no licence in its POM or any parent, and has no override. "
        "Read the artifact, then add a reviewed entry to OVERRIDES — never emit an unknown licence.",
    )


def identify(licence: dict[str, str]) -> tuple[str, bool]:
    """Returns the licence id and whether it is open source. Raises when it is neither."""
    name = licence["name"].strip().lower()
    normalised = re.sub(r"\s+", " ", name)
    for licence_id, known in KNOWN_LICENCES.items():
        if normalised in known["names"]:
            return licence_id, True
    if normalised in GOOGLE_TERMS:
        return licence["name"].strip(), False
    raise Unidentified(
        f"unrecognised licence '{licence['name']}' ({licence['url'] or 'no url'}). "
        "Add it to KNOWN_LICENCES with its text, or to GOOGLE_TERMS if it is a terms-of-service page.",
    )


def build(coordinates: list[str], texts_dir: str) -> dict:
    open_source: list[dict] = []
    google: list[dict] = []
    used_texts: set[str] = set()
    problems: list[str] = []

    for coordinate in coordinates:
        group, artifact, version = coordinate.split(":")
        if group.startswith(FIRST_PARTY_GROUPS):
            continue
        own_pom = read_pom(group, artifact, version)
        if own_pom is not None and is_platform(own_pom):
            continue
        try:
            entries = []
            proprietary = []
            for licence in licences_for(group, artifact, version):
                licence_id, is_open = identify(licence)
                if is_open:
                    entries.append({"id": licence_id, "name": licence["name"], "url": licence["url"]})
                    used_texts.add(licence_id)
                else:
                    proprietary.append({"name": licence_id, "url": licence["url"]})
        except Unidentified as error:
            problems.append(str(error))
            continue
        record = {"artifact": f"{group}:{artifact}", "version": version}
        # An artifact declaring both kinds is listed under the terms that restrict it.
        if proprietary:
            google.append({**record, "terms": proprietary})
        else:
            open_source.append({**record, "licenses": entries})

    if problems:
        raise Unidentified("\n".join(problems))

    licence_texts = {}
    for licence_id in sorted(used_texts):
        name = KNOWN_LICENCES[licence_id]["text"]
        if name is None:
            continue
        path = os.path.join(texts_dir, name)
        if not os.path.isfile(path):
            raise Unidentified(f"no text vendored for {licence_id} (expected {path})")
        with open(path, encoding="utf-8") as handle:
            licence_texts[licence_id] = handle.read()

    return {
        "generatedBy": "scripts/generate_licenses.py from the Android app's release runtime classpath",
        "openSource": open_source,
        "googleServices": google,
        "licenseTexts": licence_texts,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--coordinates", required=True, help="file of group:artifact:version lines")
    parser.add_argument("--texts", required=True, help="directory holding the vendored licence texts")
    parser.add_argument("--out", required=True, help="the generated notices asset")
    parser.add_argument("--check", action="store_true", help="compare instead of writing")
    args = parser.parse_args()

    with open(args.coordinates, encoding="utf-8") as handle:
        coordinates = [line.strip() for line in handle if line.strip()]
    if not coordinates:
        print("no coordinates resolved, so the notices would be empty", file=sys.stderr)
        return 1

    try:
        notices = build(coordinates, args.texts)
    except Unidentified as error:
        print(f"third-party notices: {error}", file=sys.stderr)
        return 1

    rendered = json.dumps(notices, indent=2, ensure_ascii=False) + "\n"
    if args.check:
        if not os.path.isfile(args.out):
            print(f"third-party notices: {args.out} is missing; run :app:generateLicenses", file=sys.stderr)
            return 1
        with open(args.out, encoding="utf-8") as handle:
            written = handle.read()
        if written != rendered:
            print(
                "third-party notices are stale: the release classpath no longer matches "
                f"{args.out}. Run ./gradlew :app:generateLicenses and commit the result.",
                file=sys.stderr,
            )
            return 1
        print(f"    {len(notices['openSource'])} open-source components, {len(notices['googleServices'])} under Google's terms")
        return 0

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as handle:
        handle.write(rendered)
    print(f"wrote {args.out}: {len(notices['openSource'])} open-source, {len(notices['googleServices'])} Google terms")
    return 0


if __name__ == "__main__":
    sys.exit(main())
