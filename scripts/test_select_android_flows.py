#!/usr/bin/env python3
"""Tests for the Android flow selector. Run: python3 scripts/test_select_android_flows.py"""
from __future__ import annotations

import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import select_android_flows as sel  # noqa: E402

UI = "android/sample-ui/src/main/kotlin/com/usesmileid/sampleapps/ui"


class TestSelection(unittest.TestCase):
    def test_a_screen_runs_only_the_flow_that_drives_it(self):
        result = sel.select([f"{UI}/screens/VerificationsScreen.kt"])
        self.assertEqual((["verifications"], "debug"), (result["flows"], result["variant"]))

    def test_a_changed_flow_runs_itself(self):
        self.assertEqual(["settings"], sel.select(["android/maestro/settings.yaml"])["flows"])

    def test_a_shared_component_runs_the_full_suite(self):
        result = sel.select([f"{UI}/components/UseSmileIDSampleButton.kt"])
        self.assertEqual(sel.all_flows(), result["flows"])
        self.assertIn("maps to no flow", result["reason"])

    def test_a_subflow_or_a_spec_change_runs_the_full_suite(self):
        for path in ("android/maestro/subflows/warm-start.yaml", "spec/test-ids.json"):
            self.assertEqual(sel.all_flows(), sel.select([path])["flows"], path)

    def test_packaging_runs_the_full_suite_in_release(self):
        result = sel.select(["android/app/build.gradle.kts"])
        self.assertEqual((sel.all_flows(), "release"), (result["flows"], result["variant"]))

    def test_tests_goldens_and_prose_run_nothing(self):
        paths = [
            "android/sample-ui/src/test/kotlin/Foo.kt",
            "android/sample-ui/src/test/screenshots/a.png",
            "android/maestro/README.md",
            "ios/App/Foo.swift",
        ]
        self.assertEqual([], sel.select(paths)["flows"])

    def test_every_flow_the_rules_name_exists(self):
        named = {flow for _, flows in sel.RULES for flow in flows}
        self.assertEqual(set(), named - set(sel.all_flows()))


if __name__ == "__main__":
    unittest.main()
