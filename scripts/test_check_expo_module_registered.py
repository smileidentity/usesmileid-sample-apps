#!/usr/bin/env python3
"""Tests for the Expo module registration check. Run: python3 scripts/test_check_expo_module_registered.py"""
from __future__ import annotations

import io
import os
import sys
import tempfile
import unittest
from contextlib import redirect_stderr

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import check_expo_module_registered as check  # noqa: E402

MODULE = "com.example.cutout.CutoutModule"


class TestExpoModuleRegistered(unittest.TestCase):
    def setUp(self):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        self.root = folder.name
        self.app = os.path.join(self.root, "workspace", "app")
        os.makedirs(self.app)

    def package_list(self, body: str, under: str = "workspace") -> None:
        """Writes the list Expo's autolinking generates, in an `expo` package under [under]."""
        folder = os.path.join(self.root, under, "node_modules", "expo", *check.PACKAGE_LIST.split("/")[:-1])
        os.makedirs(folder)
        with open(os.path.join(self.root, under, "node_modules", "expo", check.PACKAGE_LIST), "w") as out:
            out.write(body)

    def run_check(self, *names: str) -> tuple[int, str]:
        err = io.StringIO()
        with redirect_stderr(err):
            code = check.main([self.app, *names])
        return code, err.getvalue()

    def test_a_registered_module_passes(self):
        self.package_list(f"mapOf(\n      {MODULE}::class.java to null,\n)")
        self.assertEqual(self.run_check(MODULE), (0, ""))

    def test_a_module_missing_from_the_list_fails_and_names_it(self):
        self.package_list("mapOf(\n      com.example.other.OtherModule::class.java to null,\n)")
        code, err = self.run_check(MODULE)
        self.assertEqual(code, 1)
        self.assertIn(MODULE, err)

    def test_a_longer_class_name_does_not_count(self):
        self.package_list(f"mapOf(\n      {MODULE}Impl::class.java to null,\n)")
        self.assertEqual(self.run_check(MODULE)[0], 1)

    def test_the_expo_package_is_found_in_the_app_itself(self):
        self.package_list(f"{MODULE}::class.java", under="workspace/app")
        self.assertEqual(self.run_check(MODULE), (0, ""))

    def test_no_generated_list_stops_with_a_reason(self):
        os.makedirs(os.path.join(self.root, "workspace", "node_modules", "expo"))
        with self.assertRaises(SystemExit) as stopped:
            check.main([self.app, MODULE])
        self.assertIn("build the app first", str(stopped.exception))

    def test_no_expo_package_stops_with_a_reason(self):
        with self.assertRaises(SystemExit) as stopped:
            check.main([self.app, MODULE])
        self.assertIn("no expo package", str(stopped.exception))


if __name__ == "__main__":
    unittest.main()
