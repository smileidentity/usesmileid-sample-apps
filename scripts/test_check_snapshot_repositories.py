#!/usr/bin/env python3
"""Tests for the snapshots repository filter. Run: python3 scripts/test_check_snapshot_repositories.py"""
from __future__ import annotations

import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import check_snapshot_repositories as check  # noqa: E402

URL = 'maven("https://central.sonatype.com/repository/maven-snapshots/")'


class TestSnapshotRepositories(unittest.TestCase):
    def test_a_repository_filtered_to_smile_id_passes(self):
        text = f'mavenCentral()\n{URL} {{\n    content {{ includeGroup("com.usesmileid") }}\n}}\n'
        self.assertEqual([], check.problems(text))

    def test_a_repository_without_a_filter_fails(self):
        self.assertEqual(1, len(check.problems(f"{URL}\nmaven(\"https://developer.huawei.com/repo/\") {{ }}\n")))

    def test_a_filter_on_the_next_repository_does_not_count(self):
        text = f'{URL}\nmaven("https://example.com/") {{\n    content {{ includeGroup("com.usesmileid") }}\n}}\n'
        self.assertEqual(1, len(check.problems(text)))

    def test_a_repository_with_a_wider_filter_fails(self):
        text = f'{URL} {{\n    content {{ includeGroupAndSubgroups("com") }}\n}}\n'
        self.assertEqual(1, len(check.problems(text)))

    def test_a_second_filter_next_to_smile_id_fails(self):
        text = f'{URL} {{\n    content {{ includeGroup("com.usesmileid") }}\n    content {{ includeGroup("org") }}\n}}\n'
        self.assertEqual(1, len(check.problems(text)))

    def test_a_build_without_the_repository_fails(self):
        self.assertEqual(1, len(check.problems("mavenCentral()\n")))

    def test_the_committed_builds_pass(self):
        self.assertEqual(0, check.main())


if __name__ == "__main__":
    unittest.main()
