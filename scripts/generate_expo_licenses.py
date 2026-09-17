#!/usr/bin/env python3
"""Generates the third-party notices the Expo sample app ships in its bundle.

npm is the easiest of the three registries to walk and the hardest to trust. A package declares a
`license` field AND usually ships a LICENSE file, so unlike SwiftPM there is metadata — but the
field is self-reported and the file is the only thing with a copyright holder in it. So this emits
the TEXT per component, the way the iOS generator does and unlike the Android one: two MIT packages
carry two different holders, and sharing one copy would attribute the wrong one.

The shipping set is the PRODUCTION closure of the app's own package.json, walked through each
package's own `dependencies`. Not the lockfile, which pins dev and optional trees a partner ships
none of, and not `pnpm list`, which exhausts a 4 GB heap on this graph because it expands every
peer-suffixed key.

A package with neither a declared licence nor a licence file FAILS the run. "Unknown" in a notice
file is worse than a build that stops, because nobody audits what they cannot see.

    scripts/generate_expo_licenses.py --out <asset>           # rewrite the committed asset
    scripts/generate_expo_licenses.py --out <asset> --check    # fail if it is stale
"""

from __future__ import annotations

import argparse
import io
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXPO = os.path.join(REPO, "expo")
APP_MANIFEST = os.path.join(EXPO, "app", "package.json")
HOISTED = os.path.join(EXPO, "node_modules")

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


def licence_text(directory: str) -> str | None:
    for name in LICENCE_FILES:
        path = os.path.join(directory, name)
        if os.path.isfile(path):
            with io.open(path, encoding="utf-8", errors="replace") as handle:
                return handle.read().strip()
    return None


def nested_notice(directory: str) -> str | None:
    for name in NESTED_NOTICES:
        path = os.path.join(directory, name)
        if os.path.isfile(path):
            with io.open(path, encoding="utf-8", errors="replace") as handle:
                return handle.read().strip()
    return None


def closure() -> dict[str, str]:
    """The production graph, breadth-first from the app's own dependencies."""
    with io.open(APP_MANIFEST, encoding="utf-8") as handle:
        app = json.load(handle)

    found: dict[str, str] = {}
    unresolved: list[str] = []
    queue: list[tuple[str, str | None]] = [(name, None) for name in app.get("dependencies", {})]
    seen: set[str] = set()

    while queue:
        name, parent = queue.pop()
        if name in seen:
            continue
        seen.add(name)
        if name.startswith(FIRST_PARTY_PREFIX):
            continue
        directory = resolve(name, parent)
        if directory is None:
            unresolved.append(name)
            continue
        found[name] = directory
        package = manifest(directory)
        queue += [(child, directory) for child in package.get("dependencies", {})]

    if unresolved:
        # Reported rather than fatal: a package that is not installed ships no code and so owes no
        # notice. It is still named on every run, because an absent REQUIRED dependency is a defect
        # in somebody's graph and `strict-peer-dependencies` does not cover a plain dependency.
        optional = set(app.get("optionalDependencies", {}))
        for directory in found.values():
            optional |= set(manifest(directory).get("optionalDependencies", {}))
        for name in sorted(set(unresolved) - optional):
            dependents = sorted(
                package
                for package, directory in found.items()
                if name in manifest(directory).get("dependencies", {})
            )
            print(
                f"  UNMET      {name} is declared by {dependents} and is not installed, so it ships "
                "nothing and no notice is emitted for it",
                file=sys.stderr,
            )
    return found


def generate() -> str:
    packages = closure()
    if not packages:
        raise LicenceError("the production closure is empty; nothing would ship")

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
    args = parser.parse_args(argv)

    if not os.path.isdir(HOISTED):
        print(f"  skipped    {args.out} (expo/node_modules is absent; run pnpm install)")
        return 0

    try:
        content = generate()
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
