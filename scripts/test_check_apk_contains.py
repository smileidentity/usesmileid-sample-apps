#!/usr/bin/env python3
"""Tests for the release-APK presence check. Run: python3 scripts/test_check_apk_contains.py"""
from __future__ import annotations

import io
import os
import sys
import tempfile
import unittest
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import check_apk_contains as check  # noqa: E402


class TestApkContains(unittest.TestCase):
    def setUp(self):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        self.folder = folder.name

    def apk(self, **dex: bytes) -> str:
        """A throwaway APK holding the given dex files, by name."""
        path = os.path.join(self.folder, f"app{len(os.listdir(self.folder))}.apk")
        with zipfile.ZipFile(path, "w") as archive:
            archive.writestr("AndroidManifest.xml", b"manifest")
            for name, body in dex.items():
                archive.writestr(f"{name}.dex", body)
        return path

    def test_a_name_in_any_dex_file_is_found(self):
        path = self.apk(classes=b"\x00other", classes2=b"\x00UseSmileIDSampleCutout\x00")
        self.assertEqual([], check.missing(path, ["UseSmileIDSampleCutout"]))

    def test_a_name_r8_dropped_is_reported(self):
        path = self.apk(classes=b"\x00other\x00")
        self.assertEqual(["UseSmileIDSampleCutout"], check.missing(path, ["UseSmileIDSampleCutout"]))

    def test_a_name_outside_the_dex_files_does_not_count(self):
        path = self.apk(classes=b"\x00other\x00")
        with zipfile.ZipFile(path, "a") as archive:
            archive.writestr("assets/notes.txt", b"UseSmileIDSampleCutout")
        self.assertEqual(["UseSmileIDSampleCutout"], check.missing(path, ["UseSmileIDSampleCutout"]))

    def test_an_apk_with_no_dex_is_refused(self):
        with self.assertRaises(SystemExit):
            check.missing(self.apk(), ["UseSmileIDSampleCutout"])

    def test_the_command_fails_when_a_name_is_missing(self):
        path = self.apk(classes=b"\x00other\x00")
        stderr = io.StringIO()
        sys.stderr, saved = stderr, sys.stderr
        try:
            self.assertEqual(1, check.main([path, "UseSmileIDSampleCutout"]))
        finally:
            sys.stderr = saved
        self.assertIn("UseSmileIDSampleCutout", stderr.getvalue())

    def test_a_call_with_no_names_is_refused(self):
        with self.assertRaises(SystemExit):
            check.main([self.apk(classes=b"\x00other\x00")])

    def test_a_call_with_nothing_is_refused(self):
        with self.assertRaises(SystemExit):
            check.main([])


if __name__ == "__main__":
    unittest.main()
