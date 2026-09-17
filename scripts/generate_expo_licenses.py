#!/usr/bin/env python3
"""Generates the third-party notices the Expo sample app ships in its bundle.

npm is the easiest of the three registries to walk and the hardest to trust. A package declares a
`license` field AND usually ships a LICENSE file, so unlike SwiftPM there is metadata — but the
field is self-reported and the file is the only thing with a copyright holder in it. So this emits
the TEXT per component, the way the iOS generator does and unlike the Android one: two MIT packages
carry two different holders, and sharing one copy would attribute the wrong one.

The shipping set is what actually reaches the app, from two artefacts rather than from the package
graph: the JavaScript in the release bundle, read from its source maps, and the native modules Expo
autolinks. Both name the exact directory the shipped copy came from, so the version recorded is the
one that shipped.

Metro writes `sources` relative to its server root, so a map entry reads `/node_modules/x/y.js` and
identifies a package without locating it. Packages are therefore resolved by name in one fixed order
and the maps are read sorted, because `os.walk` returns filesystem order and two platforms disagree
on it. A package in the bundle that cannot be found on disk stops the run rather than being skipped.

Walking `dependencies` instead was wrong twice over. `expo` and `expo-constants` declare the Expo
CLI, Jest's formatter and a terminal spinner among their own dependencies, so the set reached 542
components a partner receives almost none of. And because those packages exist at several versions,
which copy the hoisted installer leaves at the top of node_modules depends on the whole graph —
including packages Linux installs and macOS does not — so 48 versions differed between a developer
machine and CI and the asset could not be current on both.

A package with neither a declared licence nor a licence file FAILS the run. "Unknown" in a notice
file is worse than a build that stops, because nobody audits what they cannot see.

    scripts/generate_expo_licenses.py --out <asset> --bundle <dir>           # rewrite the asset
    scripts/generate_expo_licenses.py --out <asset> --bundle <dir> --check   # fail if it is stale

<dir> is an `expo export --source-maps` output directory. There is no fallback without one: a
notice file guessed from the dependency graph is what this replaced.
"""

from __future__ import annotations

import argparse
import io
import json
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXPO = os.path.join(REPO, "expo")
APP_MANIFEST = os.path.join(EXPO, "app", "package.json")
HOISTED = os.path.join(EXPO, "node_modules")
APP_MODULES = os.path.join(EXPO, "app", "node_modules")

NODE_MODULES = "node_modules/"

# Licensed from Smile ID, not a third-party notice; sample-ui's own identity is the same case.
FIRST_PARTY_PREFIX = "@smileid/"

LICENCE_FILES = (
    "LICENSE",
    "LICENSE.md",
    "LICENSE.txt",
    "LICENCE",
    "LICENCE.md",
    "LICENSE-MIT",
    "COPYING",
)

# A component that vendors third-party code carries its own notices file, and npm metadata says
# nothing about it, so this file is the only signal that the notice has to travel.
NESTED_NOTICES = ("THIRD_PARTY_NOTICES.md", "THIRD-PARTY-NOTICES.md", "NOTICE", "NOTICE.md")


class LicenceError(Exception):
    pass


def resolve(name: str, parent: str | None) -> str | None:
    """Node resolution, near enough: a package's own node_modules first, then the hoisted root."""
    if parent is not None:
        nested = os.path.join(parent, "node_modules", name)
        if os.path.isfile(os.path.join(nested, "package.json")):
            return nested
    hoisted = os.path.join(HOISTED, name)
    return hoisted if os.path.isfile(os.path.join(hoisted, "package.json")) else None


def manifest(directory: str) -> dict:
    with io.open(os.path.join(directory, "package.json"), encoding="utf-8") as handle:
        return json.load(handle)


def declared(package: dict) -> str | None:
    licence = package.get("license") or package.get("licenses")
    if isinstance(licence, str):
        return licence
    if isinstance(licence, dict):
        return licence.get("type")
    if isinstance(licence, list):
        kinds = [entry.get("type") for entry in licence if isinstance(entry, dict)]
        kept = [kind for kind in kinds if kind]
        # More than one is kept rather than collapsed: a dual licence is the holder's choice to state.
        return " OR ".join(kept) if kept else None
    return None


def read_first(directory: str, candidates: tuple[str, ...]) -> str | None:
    """The first candidate present, matched without regard to case and in the order given.

    npm packages spell the file both ways and macOS cannot tell them apart, so a lookup by exact
    name reads `license` here and finds nothing on a Linux runner. That silently emitted six
    components with no licence text at all, which is the shape a licence file must never have.
    """
    try:
        actual = {name.lower(): name for name in os.listdir(directory)}
    except OSError:
        return None
    for candidate in candidates:
        name = actual.get(candidate.lower())
        if name is None:
            continue
        path = os.path.join(directory, name)
        if os.path.isfile(path):
            with io.open(path, encoding="utf-8", errors="replace") as handle:
                return handle.read().strip()
    return None


def licence_text(directory: str) -> str | None:
    return read_first(directory, LICENCE_FILES)


def nested_notice(directory: str) -> str | None:
    return read_first(directory, NESTED_NOTICES)


def package_name(source: str) -> str | None:
    """The package a source path belongs to, or None when the path names none."""
    marker = source.rfind(NODE_MODULES)
    if marker < 0:
        return None
    parts = source[marker + len(NODE_MODULES):].split("/")
    if not parts or not parts[0]:
        return None
    depth = 2 if parts[0].startswith("@") and len(parts) > 1 else 1
    return "/".join(parts[:depth])


def installed(name: str) -> str | None:
    """Where a package is installed, in one fixed order so two machines resolve it the same way."""
    for base in (APP_MODULES, HOISTED):
        directory = os.path.join(base, *name.split("/"))
        if os.path.isfile(os.path.join(directory, "package.json")):
            return directory
    return None


def bundled_packages(bundle: str) -> dict[str, str]:
    """Every package with JavaScript in the release bundle, resolved to where it is installed.

    Metro writes `sources` relative to its server root, so every entry reads `/node_modules/x/y.js`
    and names no location — the map identifies packages, never directories. Resolving by name in a
    fixed order is therefore the honest reading, and the alternative was a silent fallback that
    supplied the same answer while appearing to use the path.
    """
    maps: list[str] = []
    for root, _, files in os.walk(bundle):
        maps += [os.path.join(root, name) for name in files if name.endswith(".map")]
    if not maps:
        raise LicenceError(
            f"no source maps under {bundle}; export with --source-maps so the notices can be "
            "derived from what ships rather than from the dependency graph"
        )

    names: set[str] = set()
    # Sorted, because os.walk returns filesystem order and two platforms do not agree on it.
    for path in sorted(maps):
        with io.open(path, encoding="utf-8") as handle:
            sources = json.load(handle).get("sources", [])
        for source in sources:
            name = package_name(source)
            if name is not None and not name.startswith(FIRST_PARTY_PREFIX):
                names.add(name)

    found: dict[str, str] = {}
    unresolved: list[str] = []
    for name in sorted(names):
        directory = installed(name)
        if directory is None:
            unresolved.append(name)
            continue
        found[name] = directory
    if unresolved:
        # Loud rather than skipped: a package in the bundle that cannot be located on disk means the
        # notice is short, and a short licence file is the failure nobody notices.
        raise LicenceError(
            "these packages are in the bundle and cannot be found on disk, so no notice can be "
            f"emitted for them: {unresolved}"
        )
    return found


def autolinked_packages() -> dict[str, str]:
    """Every native module Expo links into the app, which ships code the bundle never mentions."""
    try:
        raw = subprocess.run(
            ["npx", "--no-install", "expo-modules-autolinking", "search", "--json"],
            cwd=os.path.join(EXPO, "app"),
            capture_output=True,
            text=True,
            check=True,
        ).stdout
    except (OSError, subprocess.CalledProcessError) as error:
        raise LicenceError(f"could not list the autolinked native modules: {error}") from error
    found: dict[str, str] = {}
    for name, entry in json.loads(raw).items():
        if name.startswith(FIRST_PARTY_PREFIX):
            continue
        directory = entry.get("path")
        if directory and os.path.isfile(os.path.join(directory, "package.json")):
            found[name] = directory
    return found


def shipping_set(bundle: str) -> dict[str, str]:
    """The union of both: a module with no JavaScript still ships its native half."""
    found = bundled_packages(bundle)
    for name, directory in autolinked_packages().items():
        found.setdefault(name, directory)
    return found


def generate(bundle: str) -> str:
    packages = shipping_set(bundle)
    if not packages:
        raise LicenceError("nothing shipped: the bundle named no packages and nothing autolinked")

    components = []
    missing = []
    for name in sorted(packages):
        directory = packages[name]
        package = manifest(directory)
        text = licence_text(directory)
        kind = declared(package)
        if text is None and kind is None:
            missing.append(name)
            continue
        entry = {
            "component": name,
            "version": package.get("version", ""),
            "declared": kind or "see the text below",
            "text": text or f"{name} declares {kind} and ships no licence file.",
        }
        notice = nested_notice(directory)
        if notice is not None:
            entry["notice"] = notice
        components.append(entry)

    if missing:
        raise LicenceError(
            "these packages declare no licence and ship no licence file, so no honest notice can be "
            f"emitted for them: {missing}"
        )

    return json.dumps({"components": components}, indent=2, ensure_ascii=False) + "\n"


def report_delta(existing: str | None, generated: str) -> None:
    """Print which components differ, so a stale asset says why rather than only that it is stale."""
    if existing is None:
        print("      the asset does not exist yet")
        return
    try:
        was = {c["component"]: c for c in json.loads(existing)["components"]}
        now = {c["component"]: c for c in json.loads(generated)["components"]}
    except (ValueError, KeyError) as error:
        print(f"      cannot compare: {error}")
        return
    added = sorted(set(now) - set(was))
    removed = sorted(set(was) - set(now))
    changed = sorted(name for name in set(was) & set(now) if was[name] != now[name])
    print(f"      committed {len(was)} components, generated {len(now)}")
    for label, names in (("only generated", added), ("only committed", removed), ("changed", changed)):
        if names:
            shown = ", ".join(names[:12])
            more = f" (+{len(names) - 12} more)" if len(names) > 12 else ""
            print(f"      {label}: {shown}{more}")
    # What changed, not only which: a version says the wrong copy was resolved, a text says the same
    # copy carries different bytes, and the two have different causes. Naming the field is what a
    # runner can report back that a local run cannot reproduce.
    for name in changed[:12]:
        before, after = was[name], now[name]
        fields = sorted(key for key in set(before) | set(after) if before.get(key) != after.get(key))
        detail = ", ".join(
            f"{key} {before.get(key)!r} -> {after.get(key)!r}" if key == "version" else key
            for key in fields
        )
        print(f"        {name}: {detail}   at {installed(name) or 'not installed'}")
    if not (added or removed or changed):
        print("      same components: the difference is formatting or order")


def write(path: str, content: str, check: bool) -> bool:
    existing = None
    if os.path.isfile(path):
        with io.open(path, encoding="utf-8") as handle:
            existing = handle.read()
    if existing == content:
        print(f"  unchanged  {os.path.relpath(path, REPO)}")
        return True
    if check:
        print(f"  STALE      {os.path.relpath(path, REPO)}")
        # Name what moved. "STALE" alone sent two people guessing at a platform difference that
        # was not one; the set this walks depends on what is installed, so print the delta.
        report_delta(existing, content)
        return False
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with io.open(path, "w", encoding="utf-8") as handle:
        handle.write(content)
    print(f"  {'updated' if existing else 'created'}    {os.path.relpath(path, REPO)}")
    return True


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, help="the committed asset to write")
    parser.add_argument("--check", action="store_true", help="fail if the asset is stale")
    parser.add_argument(
        "--bundle",
        required=True,
        help="an `expo export --source-maps` directory, which is what names the shipped packages",
    )
    args = parser.parse_args(argv)

    if not os.path.isdir(HOISTED):
        print(f"  skipped    {args.out} (expo/node_modules is absent; run pnpm install)")
        return 0

    bundle = args.bundle if os.path.isabs(args.bundle) else os.path.join(REPO, args.bundle)
    if not os.path.isdir(bundle):
        print(f"\n{bundle} does not exist; run the bundle phase first", file=sys.stderr)
        return 1

    try:
        content = generate(bundle)
    except LicenceError as error:
        print(f"\n{error}", file=sys.stderr)
        return 1

    target = args.out if os.path.isabs(args.out) else os.path.join(REPO, args.out)
    if not write(target, content, args.check):
        print("\nNotices are stale. Run scripts/generate_expo_licenses.py --out <asset>", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
