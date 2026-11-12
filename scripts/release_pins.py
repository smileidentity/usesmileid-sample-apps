#!/usr/bin/env python3
"""Fails a production store build unless it runs from a v* tag on main whose Smile ID pins are all releases.

Every SDK, njia and kamera version at every pin site, lockfiles included, must be a plain x.y.z.
A missing pin site, or one with no pin, fails too, so a moved file can't pass by being skipped.
Run from the repository root: python3 scripts/release_pins.py (GITHUB_REF names the ref).
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path

RELEASE = re.compile(r"\d+\.\d+\.\d+")
SMILE_ID_URL = re.compile(r"github\.com/smileidentity/[\w.-]+")
# The Expo apps' own shared UI, which the workspace links; every other @smileid package comes from npm.
WORKSPACE = "@smileid/sample-ui"


def catalog(text: str) -> list[tuple[str, str]]:
    """Each com.usesmileid library's version, and each usesmileid, njia or kamera version entry."""
    section = ""
    versions: dict[str, str] = {}
    pins = []
    for line in text.splitlines():
        header = re.match(r"\s*\[(\w+)\]", line)
        if header:
            section = header.group(1)
            continue
        entry = re.match(r'\s*([\w-]+)\s*=\s*"([^"]*)"', line)
        if section == "versions" and entry:
            versions[entry.group(1)] = entry.group(2)
            if re.match(r"(usesmileid|njia|kamera)", entry.group(1)):
                pins.append((entry.group(1), entry.group(2)))
        module = re.search(r'module\s*=\s*"(com\.usesmileid:[^"]+)"|group\s*=\s*"(com\.usesmileid)"', line)
        if section == "libraries" and module:
            ref = re.search(r'version\.ref\s*=\s*"([^"]+)"', line)
            inline = re.search(r'version\s*=\s*"([^"]+)"', line)
            pins.append((module.group(1) or module.group(2), versions.get(ref.group(1), "<missing>") if ref else inline.group(1) if inline else "<none>"))
    return pins


def project_yml(text: str) -> list[tuple[str, str]]:
    """Each package from a smileidentity URL and its pinned version, read from that package's own keys."""
    lines = text.splitlines()
    pins = []
    for index, line in enumerate(lines):
        url = re.match(r"(\s*)url:\s*(\S+)", line)
        if not url or not SMILE_ID_URL.search(url.group(2)):
            continue
        version = "<none>"
        for sibling in lines[index + 1:]:
            if len(sibling) - len(sibling.lstrip()) != len(url.group(1)):
                break
            requirement = re.match(r"\s*(exactVersion|version|from|branch|revision|minorVersion|majorVersion):\s*(\S+)", sibling)
            if requirement:
                # Only an exact requirement pins one build; any other kind is reported with its kind.
                version = requirement.group(2) if requirement.group(1) == "exactVersion" else f"{requirement.group(1)} {requirement.group(2)}"
        pins.append((url.group(2), version))
    return pins


def package_swift(text: str) -> list[tuple[str, str]]:
    """Each .package from a smileidentity URL and its requirement."""
    pins = []
    for match in re.finditer(r'\.package\(\s*url:\s*"([^"]+)"\s*,\s*([^)]*)\)', text):
        if SMILE_ID_URL.search(match.group(1)):
            exact = re.fullmatch(r'exact:\s*"([^"]+)"', match.group(2).strip())
            pins.append((match.group(1), exact.group(1) if exact else match.group(2).strip()))
    return pins


def package_resolved(text: str) -> list[tuple[str, str]]:
    """Each resolved package from a smileidentity URL and the version SwiftPM took."""
    return [
        (pin["location"], pin.get("state", {}).get("version") or "<no version>")
        for pin in json.loads(text).get("pins", [])
        if SMILE_ID_URL.search(pin.get("location", ""))
    ]


def pubspec(text: str) -> list[tuple[str, str]]:
    """Each Smile ID package a pubspec names with a version."""
    return [(m.group(1), m.group(2)) for m in re.finditer(r"^\s+(usesmileid\w*):[ \t]*(\S+)", text, re.M)]


def pubspec_lock(text: str) -> list[tuple[str, str]]:
    """Each Smile ID package in a pubspec.lock and the version pub resolved; one not from pub.dev isn't a release."""
    pins = []
    for match in re.finditer(r"^  (usesmileid\w*):\n((?:    .*\n?)*)", text, re.M):
        source = re.search(r"^    source: (\S+)", match.group(2), re.M)
        version = re.search(r'^    version: "([^"]+)"', match.group(2), re.M)
        hosted = source and source.group(1) == "hosted"
        pins.append((match.group(1), version.group(1) if version and hosted else f"from {source.group(1) if source else 'nowhere'}"))
    return pins


def package_json(text: str) -> list[tuple[str, str]]:
    """Each @smileid package a package.json names, apart from the workspace's shared UI."""
    manifest = json.loads(text)
    return [
        (name, version)
        for field in ("dependencies", "devDependencies", "peerDependencies")
        for name, version in manifest.get(field, {}).items()
        if name.startswith("@smileid/") and name != WORKSPACE
    ]


def pnpm_lock(text: str) -> list[tuple[str, str]]:
    """Each @smileid package version a pnpm lockfile resolves, apart from the workspace's shared UI."""
    # A package's peerDependencies are ranges it declares, not versions pnpm resolved.
    text = re.sub(r"^( +)peerDependencies:\n(?:\1 +.*\n)*", "", text, flags=re.M)
    keys = re.findall(r"@smileid/([\w-]+)@([^:(\s'\"]+)", text)
    deps = re.findall(r"'@smileid/([\w-]+)':[ \t]+([^\s(]+)", text)
    versions = re.findall(r"'@smileid/([\w-]+)':\n\s+specifier:[^\n]*\n\s+version:\s*([^\s(]+)", text)
    return [(f"@smileid/{n}", v) for n, v in keys + deps + versions if f"@smileid/{n}" != WORKSPACE]


SITES = {
    "android/gradle/libs.versions.toml": catalog,
    "ios/App/project.yml": project_yml,
    "ios/SampleUI/Package.swift": package_swift,
    "ios/SampleUI/Package.resolved": package_resolved,
    "flutter/app/ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved": package_resolved,
    "flutter/app/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved": package_resolved,
    "flutter/app/pubspec.yaml": pubspec,
    "flutter/sample_ui/pubspec.yaml": pubspec,
    "flutter/app/pubspec.lock": pubspec_lock,
    "expo/app/package.json": package_json,
    "expo/sample-ui/package.json": package_json,
    "expo/pnpm-lock.yaml": pnpm_lock,
}


def pin_problems(root: Path) -> list[str]:
    """Every pin site that is missing, has no pin, or pins something other than a release."""
    problems = []
    for site, read in SITES.items():
        path = root / site
        if not path.is_file():
            problems.append(f"{site} is missing; update release_pins.py's pin sites")
            continue
        pins = read(path.read_text())
        if not pins:
            problems.append(f"{site} has no Smile ID pin; update release_pins.py's pin sites")
        problems += [f"{site}: {name} is {version}, not a release" for name, version in pins if not RELEASE.fullmatch(version)]
    return problems


def ref_problems(ref: str, on_main: bool) -> list[str]:
    """Why the ref isn't a v* tag on main, or nothing."""
    if not re.fullmatch(r"refs/tags/v\d+\.\d+\.\d+", ref):
        return [f"{ref or 'the ref'} is not a v* tag; production store builds run only from one"]
    return [] if on_main else [f"{ref} is not on main"]


def on_main() -> bool:
    """Whether the checked-out commit is on origin/main."""
    return subprocess.run(["git", "merge-base", "--is-ancestor", "HEAD", "origin/main"]).returncode == 0


def main() -> int:
    ref = os.environ.get("GITHUB_REF", "")
    problems = ref_problems(ref, on_main()) + pin_problems(Path.cwd())
    for problem in problems:
        print(f"::error::{problem}", file=sys.stderr)
    if problems:
        return 1
    print(f"{ref}: on main, and every Smile ID pin is a release")
    return 0


if __name__ == "__main__":
    sys.exit(main())
