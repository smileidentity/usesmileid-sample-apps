#!/usr/bin/env python3
"""Tests for the release-size report. Run: python3 scripts/test_app_size.py"""
from __future__ import annotations

import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import app_size  # noqa: E402


class TestAppSize(unittest.TestCase):
    def test_the_download_is_the_max_column_of_get_size(self):
        self.assertEqual(4200, app_size.download_bytes("MIN,MAX\n4100,4200\n"))

    def test_an_app_bundle_counts_its_files_and_skips_symlinks(self):
        with tempfile.TemporaryDirectory() as root:
            app = os.path.join(root, "Products", "Applications", "Sample.app")
            os.makedirs(os.path.join(app, "Frameworks"))
            with open(os.path.join(app, "Sample"), "wb") as out:
                out.write(b"\0" * 3000)
            with open(os.path.join(app, "Frameworks", "lib"), "wb") as out:
                out.write(b"\0" * 1000)
            os.symlink(os.path.join(app, "Sample"), os.path.join(app, "link"))
            download, on_device = app_size.ios(root)
            self.assertEqual(4000, on_device)
            self.assertLess(download, on_device)
            self.assertEqual(download, app_size.zipped_bytes(app))

    def test_the_zip_leaves_out_symlinks_as_the_on_device_count_does(self):
        with tempfile.TemporaryDirectory() as root:
            app = os.path.join(root, "Sample.app")
            os.makedirs(app)
            with open(os.path.join(app, "Sample"), "wb") as out:
                out.write(os.urandom(5000))
            without = app_size.zipped_bytes(app)
            os.symlink(os.path.join(app, "Sample"), os.path.join(app, "link"))
            self.assertEqual(without, app_size.zipped_bytes(app))

    def test_megabytes_are_decimal_with_two_places(self):
        self.assertEqual("14.14 MB", app_size.megabytes(14_140_000))


if __name__ == "__main__":
    unittest.main()
