#!/usr/bin/env python3
"""Tests for the Expo third-party notices generator.

Run: python3 scripts/test_generate_expo_licenses.py

The bundle is a synthetic source map over a synthetic node_modules, so the rules are tested without
running an export. Autolinking is stubbed, because it shells out to npx.
"""

from __future__ import annotations

import io
import json
import os
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import generate_expo_licenses as gen  # noqa: E402


class BundleCase(unittest.TestCase):
    def setUp(self) -> None:
        self.root = tempfile.mkdtemp(prefix="expo-notices-")
        self.modules = os.path.join(self.root, "node_modules")
        self.bundle = os.path.join(self.root, "dist")
        os.makedirs(self.bundle)
        self.autolinked: dict[str, str] = {}
        self._real_autolinked = gen.autolinked_packages
        self._real_hoisted = gen.HOISTED
        gen.autolinked_packages = lambda: dict(self.autolinked)
        gen.HOISTED = self.modules

    def tearDown(self) -> None:
        gen.autolinked_packages = self._real_autolinked
        gen.HOISTED = self._real_hoisted
        shutil.rmtree(self.root, ignore_errors=True)

    def package(self, name: str, version: str = "1.0.0", licence: str = "MIT", text: str = "MIT text") -> str:
        directory = os.path.join(self.modules, *name.split("/"))
        os.makedirs(directory, exist_ok=True)
        with io.open(os.path.join(directory, "package.json"), "w", encoding="utf-8") as handle:
            json.dump({"name": name, "version": version, "license": licence}, handle)
        if text:
            with io.open(os.path.join(directory, "LICENSE"), "w", encoding="utf-8") as handle:
                handle.write(text)
        return directory

    def emit_map(self, *sources: str, name: str = "entry.hbc.map") -> None:
        with io.open(os.path.join(self.bundle, name), "w", encoding="utf-8") as handle:
            json.dump({"version": 3, "sources": list(sources)}, handle)

    def module(self, name: str, file: str = "index.js") -> str:
        return os.path.join(self.modules, *name.split("/"), file)

    def names(self) -> list[str]:
        return sorted(gen.shipping_set(self.bundle))


class TestTheShippingSet(BundleCase):
    def test_a_bundled_package_is_named_by_its_directory_not_its_file(self):
        self.package("color-convert")
        self.emit_map(self.module("color-convert", "route.js"))
        self.assertEqual(self.names(), ["color-convert"])

    def test_a_scoped_package_keeps_both_segments(self):
        self.package("@expo/cli")
        self.emit_map(self.module("@expo/cli", "build/metro-require/require.js"))
        self.assertEqual(self.names(), ["@expo/cli"])

    def test_a_source_outside_node_modules_contributes_nothing(self):
        self.package("color")
        self.emit_map(os.path.join(self.root, "app", "index.tsx"), self.module("color"))
        self.assertEqual(self.names(), ["color"])

    def test_first_party_code_is_not_a_third_party_notice(self):
        self.package("@smileid/usesmileid")
        self.package("color")
        self.emit_map(self.module("@smileid/usesmileid"), self.module("color"))
        self.assertEqual(self.names(), ["color"])

    def test_every_map_in_the_export_is_read_not_only_the_first(self):
        self.package("ios-only")
        self.package("android-only")
        self.emit_map(self.module("ios-only"), name="ios.hbc.map")
        self.emit_map(self.module("android-only"), name="android.hbc.map")
        self.assertEqual(self.names(), ["android-only", "ios-only"])

    def test_a_native_module_with_no_javascript_still_owes_a_notice(self):
        # The defect this guards: expo-file-system ships native code and no bundled module, so a
        # set taken from the bundle alone would drop it and the notice would understate what ships.
        self.package("color")
        directory = self.package("expo-file-system")
        self.autolinked = {"expo-file-system": directory}
        self.emit_map(self.module("color"))
        self.assertEqual(self.names(), ["color", "expo-file-system"])

    def test_a_module_that_is_both_bundled_and_autolinked_is_listed_once(self):
        directory = self.package("expo-camera")
        self.autolinked = {"expo-camera": directory}
        self.emit_map(self.module("expo-camera"))
        self.assertEqual(self.names(), ["expo-camera"])

    def test_an_export_with_no_source_maps_fails_rather_than_emitting_a_short_file(self):
        self.package("color")
        with self.assertRaises(gen.LicenceError) as caught:
            gen.shipping_set(self.bundle)
        self.assertIn("--source-maps", str(caught.exception))

    def test_the_version_comes_from_the_copy_that_shipped_not_the_hoisted_one(self):
        # The drift this guards: the hoisted copy and the nested copy can differ, and only the one
        # the bundle actually pulled from is the one whose licence and version ship.
        self.package("chalk", version="5.3.0")
        nested = os.path.join(self.modules, "ora", "node_modules", "chalk")
        os.makedirs(nested)
        with io.open(os.path.join(nested, "package.json"), "w", encoding="utf-8") as handle:
            json.dump({"name": "chalk", "version": "4.1.2", "license": "MIT"}, handle)
        with io.open(os.path.join(nested, "LICENSE"), "w", encoding="utf-8") as handle:
            handle.write("MIT text")
        self.emit_map(os.path.join(nested, "source.js"))
        emitted = json.loads(gen.generate(self.bundle))["components"]
        self.assertEqual([(c["component"], c["version"]) for c in emitted], [("chalk", "4.1.2")])


class TestTheEmittedNotice(BundleCase):
    def test_a_package_with_no_licence_at_all_fails_the_run(self):
        self.package("mystery", licence="", text="")
        self.emit_map(self.module("mystery"))
        with self.assertRaises(gen.LicenceError) as caught:
            gen.generate(self.bundle)
        self.assertIn("mystery", str(caught.exception))

    def test_a_declared_licence_with_no_file_still_emits_a_notice_that_says_so(self):
        self.package("declared-only", licence="Apache-2.0", text="")
        self.emit_map(self.module("declared-only"))
        emitted = json.loads(gen.generate(self.bundle))["components"]
        self.assertEqual(emitted[0]["declared"], "Apache-2.0")
        self.assertIn("ships no licence file", emitted[0]["text"])

    def test_the_licence_text_is_carried_per_component_not_per_licence_kind(self):
        # Two MIT packages carry two different holders, so sharing one copy attributes the wrong one.
        self.package("first", text="MIT, Copyright Alice")
        self.package("second", text="MIT, Copyright Bob")
        self.emit_map(self.module("first"), self.module("second"))
        emitted = {c["component"]: c["text"] for c in json.loads(gen.generate(self.bundle))["components"]}
        self.assertEqual(emitted["first"], "MIT, Copyright Alice")
        self.assertEqual(emitted["second"], "MIT, Copyright Bob")

    def test_components_are_sorted_so_the_asset_does_not_churn_on_walk_order(self):
        for name in ("zebra", "alpha", "middle"):
            self.package(name)
        self.emit_map(*(self.module(name) for name in ("zebra", "alpha", "middle")))
        emitted = [c["component"] for c in json.loads(gen.generate(self.bundle))["components"]]
        self.assertEqual(emitted, ["alpha", "middle", "zebra"])

    def test_a_vendored_notice_travels_with_the_component_that_carries_it(self):
        directory = self.package("vendoring")
        with io.open(os.path.join(directory, "NOTICE"), "w", encoding="utf-8") as handle:
            handle.write("contains third-party code")
        self.emit_map(self.module("vendoring"))
        emitted = json.loads(gen.generate(self.bundle))["components"]
        self.assertEqual(emitted[0]["notice"], "contains third-party code")

    def test_nothing_shipping_fails_rather_than_writing_an_empty_notice_file(self):
        self.emit_map()
        with self.assertRaises(gen.LicenceError) as caught:
            gen.generate(self.bundle)
        self.assertIn("nothing shipped", str(caught.exception))


class TestTheDeltaReport(unittest.TestCase):
    @staticmethod
    def asset(*pairs: tuple[str, str]) -> str:
        return json.dumps(
            {"components": [{"component": n, "version": v, "declared": "MIT", "text": "t"} for n, v in pairs]}
        )

    def report(self, existing: str | None, generated: str) -> str:
        captured = io.StringIO()
        stdout, sys.stdout = sys.stdout, captured
        try:
            gen.report_delta(existing, generated)
        finally:
            sys.stdout = stdout
        return captured.getvalue()

    def test_a_changed_version_is_named_rather_than_only_counted(self):
        output = self.report(self.asset(("chalk", "4.1.2")), self.asset(("chalk", "5.3.0")))
        self.assertIn("changed: chalk", output)

    def test_a_dropped_component_is_named_as_committed_only(self):
        output = self.report(self.asset(("chalk", "1.0.0"), ("color", "1.0.0")), self.asset(("color", "1.0.0")))
        self.assertIn("only committed: chalk", output)

    def test_an_added_component_is_named_as_generated_only(self):
        output = self.report(self.asset(("color", "1.0.0")), self.asset(("color", "1.0.0"), ("tslib", "2.8.1")))
        self.assertIn("only generated: tslib", output)


if __name__ == "__main__":
    unittest.main(verbosity=2)
