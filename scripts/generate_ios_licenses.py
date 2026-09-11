#!/usr/bin/env python3
"""Generates the third-party notices the iOS sample app ships in its binary.

SwiftPM has no POM: a package declares no licence metadata at all, so the notice is the LICENSE
file in the resolved checkout. That is the component's verbatim text, holder line included, which
is why this emits the text per component rather than per licence the way the Android generator
does — two MIT components carry two different copyright holders, and sharing one copy would
attribute the wrong one.

The shipping set is walked from the products the app links, not from Package.resolved: that file
lists test-only pins too, and a partner ships none of them.

    scripts/generate_ios_licenses.py --out <asset>            # rewrite the committed asset
    scripts/generate_ios_licenses.py --out <asset> --check     # fail if it is stale
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROOT_PACKAGE = os.path.join(REPO, "ios", "SampleUI")
SHELL_PROJECT = os.path.join(REPO, "ios", "App", "project.yml")

# Licensed from Smile ID, not a third-party notice; `sample-ui`'s own identity is the same case.
FIRST_PARTY = {"ios-spm", "sampleui"}

LICENCE_FILES = ("LICENSE", "LICENSE.md", "LICENSE.txt", "LICENCE", "LICENCE.md", "COPYING")

# Source copied into the app rather than resolved by SwiftPM, so no checkout carries its licence and
# the walk below cannot see it. The text lives in scripts/license-texts because nothing else in the
# tree holds a copy; `version` is the upstream release the port was taken from.
VENDORED = (
    {
        "component": "netfox",
        "version": "1.21.0",
        "text_file": "netfox.txt",
        "declared": "MIT",
    },
)

# A component that vendors third-party code carries its own notices file. SwiftPM gives no
# transitive licence metadata, so this file is the only signal that the notice has to travel.
NESTED_NOTICES = ("THIRD_PARTY_NOTICES.md", "THIRD-PARTY-NOTICES.md", "NOTICE", "NOTICE.md")

# Ordered: the first signature found in the text wins, so the Apache header beats a bare "MIT"
# appearing inside a longer notice.
SIGNATURES = (
    ("Apache-2.0", "Apache License, Version 2.0", ("apache license", "version 2.0")),
    ("APSL-2.0", "Apple Public Source License, Version 2.0", ("apple public source license",)),
    # The third clause is the only thing separating these two, so it is what the match keys on.
    ("BSD-3-Clause", "BSD 3-Clause License", ("redistributions in binary form", "endorse or promote products derived")),
    ("BSD-2-Clause", "BSD 2-Clause License", ("redistributions in binary form",)),
    ("MIT", "MIT License", ("permission is hereby granted, free of charge",)),
)


# Components that ship no licence file of their own. Each entry is a reviewed fact, and a null text
# means the licence travels inside the component rather than with us, so the notice links it instead.
# Empty today: every package the app ships carries its own text.
OVERRIDES: dict[str, dict] = {}

# What the app needs to render an override. A missing key would emit a component the screen cannot
# decode, and a failed decode is the whole list gone rather than one row wrong.
OVERRIDE_KEYS = ("licenseId", "licenseName", "text")


class Unidentified(Exception):
    """A component whose licence could not be established. Never emitted as data."""


def identify(text: str) -> tuple[str, str]:
    lowered = " ".join(text.lower().split())
    for spdx, name, needles in SIGNATURES:
        if all(needle in lowered for needle in needles):
            return spdx, name
    raise Unidentified("no known licence signature matched")


def override_problem(identity: str, override: dict) -> str | None:
    """Why a reviewed override could not be emitted, or None if it is renderable."""
    missing = [key for key in OVERRIDE_KEYS if key not in override]
    if missing:
        return f"{identity}: its OVERRIDES entry is missing {', '.join(missing)}"
    if override["text"] is None and not override.get("url"):
        return f"{identity}: its OVERRIDES entry ships no text, so it needs the url that carries one"
    return None


def dump_package(path: str, scratch: str) -> dict:
    result = subprocess.run(
        ["swift", "package", "dump-package", "--package-path", path, "--scratch-path", scratch],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise Unidentified(f"{path} has an unreadable manifest: {result.stderr.strip()}")
    return json.loads(result.stdout)


def shell_products() -> set[tuple[str, str]]:
    """The (identity, product) pairs the app target links, read from the generated project's source.

    Hand-scanned rather than parsed as YAML so this needs no dependency CI would have to install.
    The shell names a package by its YAML key, so the key's `url` is what maps it onto an identity.
    """
    with open(SHELL_PROJECT, encoding="utf-8") as handle:
        body = handle.read()
    # Any field may precede `url:`, and a sibling key at two spaces must not be crossed into, so the
    # block is walked by indent: one regex spanning it either misses a reordered field or reads the
    # next package's url as this one's.
    identities: dict[str, str] = {}
    key: str | None = None
    for line in body.splitlines():
        heading = re.match(r"^  (\w+):\s*$", line)
        if heading:
            key = heading.group(1)
            continue
        if line.strip() and not line.startswith("    "):
            key = None
            continue
        found = re.match(r"^\s+url:\s*(\S+)", line) if key else None
        if found:
            identities[key.lower()] = os.path.basename(found.group(1)).removesuffix(".git").lower()
            key = None
    pairs = {
        (identities.get(package.lower(), package.lower()), product)
        for package, product in re.findall(r"-\s*package:\s*(\S+)\s*\n\s*product:\s*(\S+)", body)
    }
    if not pairs:
        raise Unidentified(f"{SHELL_PROJECT} declares no package products; the walk would start nowhere")
    return pairs


def checkout_dir(scratch: str, identity: str) -> str | None:
    path = os.path.join(scratch, "checkouts", identity)
    return path if os.path.isdir(path) else None


def read_first(directory: str, names: tuple[str, ...]) -> tuple[str, str] | None:
    for name in names:
        path = os.path.join(directory, name)
        if os.path.isfile(path):
            with open(path, encoding="utf-8") as handle:
                return name, handle.read()
    return None


def parse_nested(markdown: str) -> list[dict]:
    """Reads a component's own notices file: one `## Name (Licence)` heading per vendored notice,
    the text in the first fenced block under it."""
    notices = []
    sections = re.split(r"^## ", markdown, flags=re.MULTILINE)[1:]
    for section in sections:
        heading = section.splitlines()[0].strip()
        declared = re.search(r"\(([^)]*)\)\s*$", heading)
        name = re.sub(r"\s*\(.*\)\s*$", "", heading).strip()
        fenced = re.search(r"```[a-z]*\n(.*?)```", section, flags=re.DOTALL)
        if not name or not fenced:
            continue
        notices.append(
            {"name": name, "text": fenced.group(1).strip(), "declared": declared.group(1) if declared else None}
        )
    return notices


def declared_identities(manifest: dict) -> list[str]:
    """The identities of the packages a manifest depends on, however each dependency is written."""
    identities = []
    for dependency in manifest.get("dependencies", []):
        for entries in dependency.values():
            for entry in entries:
                if entry.get("identity"):
                    identities.append(entry["identity"].lower())
    return identities


def walk(scratch: str) -> list[str]:
    """The package identities the app actually ships, from the products it links outward.

    Test-only packages need no exclusion list: a test target is never a root, so nothing reaches them.
    """
    root = dump_package(ROOT_PACKAGE, scratch)
    manifests = {"sampleui": root}

    def manifest_for(identity: str) -> dict | None:
        if identity not in manifests:
            directory = checkout_dir(scratch, identity)
            manifests[identity] = dump_package(directory, scratch) if directory else None
        return manifests[identity]

    def declares(identity: str, name: str) -> bool:
        manifest = manifest_for(identity)
        return manifest is not None and any(name == product["name"] for product in manifest["products"])

    def by_name(name: str, package: str, manifest: dict) -> list[tuple[str, str]]:
        """Where a bare dependency name points: this package's own, or a dependency's product."""
        if any(name == entry["name"] for entry in manifest["targets"] + manifest["products"]):
            return [(package, name)]
        # SwiftPM reads a name the package does not declare as another package's product, and the
        # owner is whichever dependency declares it — resolved rather than guessed, so a manifest
        # written this way cannot drop a notice.
        return [(identity, name) for identity in declared_identities(manifest) if declares(identity, name)]

    pending = [("sampleui", target["name"]) for target in root["targets"] if target["type"] == "regular"]
    pending += [pair for pair in shell_products() if pair[0] != "sampleui"]

    seen: set[tuple[str, str]] = set()
    shipped: set[str] = set()
    while pending:
        package, name = pending.pop()
        if (package, name) in seen:
            continue
        seen.add((package, name))
        shipped.add(package)
        manifest = manifest_for(package)
        if manifest is None:
            continue
        targets = {target["name"]: target for target in manifest["targets"]}
        products = {product["name"]: product for product in manifest["products"]}
        # A name is either one of the package's products or one of its targets.
        if name in products:
            pending += [(package, member) for member in products[name]["targets"]]
        target = targets.get(name)
        if target is None:
            continue
        for dependency in target.get("dependencies", []):
            if "byName" in dependency:
                pending += by_name(dependency["byName"][0], package, manifest)
            elif "target" in dependency:
                pending.append((package, dependency["target"][0]))
            elif "product" in dependency:
                product_name, owner = dependency["product"][0], dependency["product"][1]
                if owner:
                    pending.append((owner.lower(), product_name))
    return sorted(shipped - FIRST_PARTY)


def build(scratch: str, vendored: tuple[dict, ...] = VENDORED) -> dict:
    components = []
    problems = []
    versions = resolved_versions()
    for identity in walk(scratch):
        directory = checkout_dir(scratch, identity)
        if directory is None:
            problems.append(f"{identity}: no checkout resolved")
            continue
        version = versions.get(identity, "")
        found = read_first(directory, LICENCE_FILES)
        override = OVERRIDES.get(identity)
        if found is None and override is None:
            problems.append(
                f"{identity}: ships no licence file. Establish its licence and add a reviewed OVERRIDES entry"
            )
            continue
        if found is None:
            problem = override_problem(identity, override)
            if problem:
                problems.append(problem)
                continue
            components.append({"component": identity, "version": version, **override})
        else:
            filename, text = found
            try:
                spdx, name = identify(text)
            except Unidentified as error:
                problems.append(f"{identity} ({filename}): {error}")
                continue
            components.append(
                {
                    "component": identity,
                    "version": version,
                    "licenseId": spdx,
                    "licenseName": name,
                    "text": text.strip(),
                }
            )

        nested = read_first(directory, NESTED_NOTICES)
        if nested is None:
            continue
        entries = parse_nested(nested[1])
        if not entries:
            problems.append(f"{identity} carries {nested[0]} but none of it parsed; the notices would silently shrink")
            continue
        for entry in entries:
            try:
                nested_spdx, nested_name = identify(entry["text"])
            except Unidentified as error:
                problems.append(f"{identity}/{entry['name']}: {error}")
                continue
            # The heading states the licence, so it is a free second opinion on the text match.
            declared = (entry["declared"] or "").lower().replace(" ", "-")
            if declared and declared not in {nested_spdx.lower(), nested_name.lower().replace(" ", "-")}:
                problems.append(
                    f"{identity}/{entry['name']}: the notice says {entry['declared']}, the text reads as {nested_spdx}"
                )
                continue
            components.append(
                {
                    "component": f"{identity}/{entry['name']}",
                    "version": "",
                    "licenseId": nested_spdx,
                    "licenseName": nested_name,
                    "text": entry["text"],
                }
            )

    for entry in vendored:
        path = os.path.join(REPO, "scripts", "license-texts", entry["text_file"])
        if not os.path.exists(path):
            problems.append(f"{entry['component']}: {entry['text_file']} is missing, so its notice would not ship")
            continue
        with open(path, encoding="utf-8") as handle:
            text = handle.read().strip()
        try:
            spdx, name = identify(text)
        except Unidentified as error:
            problems.append(f"{entry['component']}: {error}")
            continue
        # The declaration is a free second opinion on the text match, as it is for nested notices.
        if entry["declared"].lower() != spdx.lower():
            problems.append(f"{entry['component']}: declared {entry['declared']}, the text reads as {spdx}")
            continue
        components.append(
            {
                "component": entry["component"],
                "version": entry["version"],
                "licenseId": spdx,
                "licenseName": name,
                "text": text,
            }
        )

    if problems:
        raise Unidentified("\n".join(problems))
    if not components:
        raise Unidentified("the shipping graph resolved no third-party component, which cannot be right")
    return {
        "generatedBy": "scripts/generate_ios_licenses.py from the products the iOS app links, plus its vendored source",
        "components": sorted(components, key=lambda entry: entry["component"].lower()),
    }


def resolved_versions() -> dict[str, str]:
    """The pinned version per identity; wrong about what ships, right about the version of what does."""
    path = os.path.join(ROOT_PACKAGE, "Package.resolved")
    with open(path, encoding="utf-8") as handle:
        return {
            pin["identity"]: pin["state"].get("version", pin["state"].get("revision", "")[:7])
            for pin in json.load(handle)["pins"]
        }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, help="the generated notices asset")
    parser.add_argument("--scratch", default=os.path.join(ROOT_PACKAGE, ".build"), help="SwiftPM scratch path")
    parser.add_argument("--check", action="store_true", help="compare instead of writing")
    args = parser.parse_args()

    resolve = subprocess.run(
        ["swift", "package", "resolve", "--package-path", ROOT_PACKAGE, "--scratch-path", args.scratch],
        capture_output=True,
        text=True,
    )
    if resolve.returncode != 0:
        print(f"third-party notices: could not resolve the package graph: {resolve.stderr.strip()}", file=sys.stderr)
        return 1

    try:
        notices = build(args.scratch)
    except (Unidentified, OSError, KeyError) as error:
        print(f"third-party notices: {error}", file=sys.stderr)
        return 1

    rendered = json.dumps(notices, indent=2, ensure_ascii=False) + "\n"
    if args.check:
        if not os.path.isfile(args.out):
            print(f"third-party notices: {args.out} is missing; run scripts/generate_ios_licenses.py", file=sys.stderr)
            return 1
        with open(args.out, encoding="utf-8") as handle:
            if handle.read() != rendered:
                print(
                    "third-party notices are stale: the shipping graph no longer matches "
                    f"{args.out}. Regenerate it and commit the result.",
                    file=sys.stderr,
                )
                return 1
        print(f"    {len(notices['components'])} components")
        return 0

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as handle:
        handle.write(rendered)
    print(f"wrote {args.out}: {len(notices['components'])} components")
    return 0


if __name__ == "__main__":
    sys.exit(main())
