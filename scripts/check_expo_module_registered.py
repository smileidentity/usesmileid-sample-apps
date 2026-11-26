#!/usr/bin/env python3
"""Fails unless Expo's generated module list registers each given class, so a module that builds but never loads cannot pass."""
from __future__ import annotations

import os
import re
import sys

PACKAGE_LIST = "android/build/generated/expo/src/main/java/expo/modules/ExpoModulesPackageList.kt"


def package_list(app: str) -> str:
    """The module list autolinking wrote into the `expo` package that [app] resolves."""
    folder = os.path.abspath(app)
    while True:
        expo = os.path.join(folder, "node_modules", "expo")
        if os.path.isdir(expo):
            path = os.path.join(os.path.realpath(expo), PACKAGE_LIST)
            if not os.path.isfile(path):
                sys.exit(f"check_expo_module_registered: {path} is missing; build the app first.")
            return path
        parent = os.path.dirname(folder)
        if parent == folder:
            sys.exit(f"check_expo_module_registered: no expo package resolves from {app}.")
        folder = parent


def unregistered(path: str, classes: list[str]) -> list[str]:
    """The classes the list at [path] does not register."""
    with open(path, encoding="utf-8") as source:
        body = source.read()
    return [name for name in classes if not re.search(rf"(?<![\w.]){re.escape(name)}::class\.java", body)]


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        sys.exit("usage: check_expo_module_registered.py <app-dir> <module-class>...")
    path = package_list(argv[0])
    absent = unregistered(path, argv[1:])
    for name in absent:
        print(f"check_expo_module_registered: {path} does not register {name}; check expo-module.config.json.", file=sys.stderr)
    return 1 if absent else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
