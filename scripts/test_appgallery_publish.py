#!/usr/bin/env python3
"""Tests for the AppGallery publish script. Run: python3 scripts/test_appgallery_publish.py"""
from __future__ import annotations

import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import appgallery_publish as agc  # noqa: E402


class TestChecked(unittest.TestCase):
    def test_a_zero_code_passes_the_body_through(self):
        self.assertEqual({"ret": {"code": 0}, "x": 1}, agc.checked({"ret": {"code": 0}, "x": 1}))

    def test_a_non_zero_code_fails_although_http_said_200(self):
        with self.assertRaisesRegex(agc.AgcError, "204144647"):
            agc.checked({"ret": {"code": 204144647, "msg": "app not found"}})


class TestHighestVersionCode(unittest.TestCase):
    def test_a_draft_above_the_live_version_wins(self):
        self.assertEqual(118, agc.highest_version_code({"appInfo": {"versionCode": 118, "onShelfVersionCode": 115}}))

    def test_the_live_version_wins_when_no_draft_is_higher(self):
        self.assertEqual(115, agc.highest_version_code({"appInfo": {"versionCode": 0, "onShelfVersionCode": 115}}))

    def test_an_app_with_nothing_uploaded_starts_from_zero(self):
        self.assertEqual(0, agc.highest_version_code({"appInfo": {}}))


class TestReleaseNotes(unittest.TestCase):
    def notes(self, text: str) -> str:
        handle = tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False)
        handle.write(text)
        handle.close()
        self.addCleanup(os.unlink, handle.name)
        return handle.name

    def test_notes_are_trimmed(self):
        self.assertEqual("Faster capture.", agc.release_notes(self.notes("  Faster capture.\n")))

    def test_empty_notes_fail(self):
        with self.assertRaises(agc.AgcError):
            agc.release_notes(self.notes("\n"))

    def test_notes_over_the_store_limit_fail(self):
        with self.assertRaisesRegex(agc.AgcError, "at most 500"):
            agc.release_notes(self.notes("x" * 501))


class TestDestination(unittest.TestCase):
    def test_agc_s_own_spelling_is_read(self):
        response = {"result": {"resultCode": "0", "UploadFileRsp": {"fileInfoList": [{"fileDestUlr": "https://obs/a.apk"}]}}}
        self.assertEqual("https://obs/a.apk", agc.destination(response))

    def test_the_corrected_spelling_is_read_too(self):
        response = {"result": {"UploadFileRsp": {"fileDestUrl": "https://obs/b.apk"}}}
        self.assertEqual("https://obs/b.apk", agc.destination(response))

    def test_a_refused_upload_fails(self):
        with self.assertRaises(agc.AgcError):
            agc.destination({"result": {"resultCode": "1"}})

    def test_an_upload_with_no_destination_fails(self):
        with self.assertRaises(agc.AgcError):
            agc.destination({"result": {"resultCode": "0", "UploadFileRsp": {"fileInfoList": [{}]}}})


class TestMultipart(unittest.TestCase):
    def test_the_fields_and_the_file_are_framed_by_one_boundary(self):
        body, content_type = agc.multipart({"authCode": "abc", "fileCount": "1"}, "app.apk", b"PK\x03\x04")
        boundary = content_type.split("boundary=")[1]
        self.assertTrue(body.endswith(f"--{boundary}--\r\n".encode()))
        self.assertIn(b'name="authCode"\r\n\r\nabc\r\n', body)
        self.assertIn(b'filename="app.apk"', body)
        self.assertIn(b"PK\x03\x04", body)


if __name__ == "__main__":
    unittest.main()
