#!/usr/bin/env python3
"""Tests for the AppGallery publish script. Run: python3 scripts/test_appgallery_publish.py"""
from __future__ import annotations

import io
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


class TestPublish(unittest.TestCase):
    def setUp(self):
        self.calls = []
        self.submit_failures = 0
        self.patch(agc, "call", self.fake_call)
        self.patch(agc, "upload", lambda headers, app, path: "https://obs/app.aab")
        self.patch(agc.time, "sleep", lambda seconds: None)

    def patch(self, owner, name, value):
        original = getattr(owner, name)
        setattr(owner, name, value)
        self.addCleanup(setattr, owner, name, original)

    def fake_call(self, method, url, headers, body=None):
        path = url.split("/api/", 1)[1].split("?", 1)[0]
        self.calls.append((method, path, body))
        if path == "publish/v2/appid-list":
            return {"appids": [{"key": "Smile ID", "value": "1234"}]}
        if path == "publish/v2/app-submit" and self.submit_failures:
            self.submit_failures -= 1
            raise agc.AgcError("the package is being parsed")
        return {}

    def test_notes_then_file_then_submit(self):
        agc.publish({}, "app-appgallery-release.aab", "Faster capture.")
        self.assertEqual(
            ["publish/v2/appid-list", "publish/v2/app-language-info", "publish/v2/app-file-info", "publish/v2/app-submit"],
            [path for _, path, _ in self.calls],
        )
        self.assertEqual({"lang": "en-US", "newFeatures": "Faster capture."}, self.calls[1][2])
        self.assertEqual(agc.SOFTWARE_PACKAGE, self.calls[2][2]["fileType"])
        self.assertEqual("https://obs/app.aab", self.calls[2][2]["files"][0]["fileDestUrl"])

    def test_a_submit_refused_while_parsing_is_retried(self):
        self.submit_failures = 2
        agc.publish({}, "app.aab", "Notes.")
        self.assertEqual(3, sum(1 for _, path, _ in self.calls if path == "publish/v2/app-submit"))

    def test_a_submit_still_refused_after_every_attempt_fails(self):
        self.submit_failures = agc.SUBMIT_ATTEMPTS
        with self.assertRaises(agc.AgcError):
            agc.publish({}, "app.aab", "Notes.")


class TestPackageSuffix(unittest.TestCase):
    def test_a_bundle_uploads_as_aab(self):
        self.assertEqual("aab", agc.package_suffix("out/app-appgallery-release.aab"))

    def test_an_apk_still_uploads_as_apk(self):
        self.assertEqual("apk", agc.package_suffix("app.APK"))

    def test_any_other_file_fails_before_upload(self):
        with self.assertRaises(agc.AgcError):
            agc.package_suffix("mapping.txt")


class TestUpload(unittest.TestCase):
    def setUp(self):
        package = tempfile.NamedTemporaryFile(suffix=".aab", delete=False)
        package.write(b"PK")
        package.close()
        self.addCleanup(os.unlink, package.name)
        self.package = package.name
        self.patch(agc, "call", lambda method, url, headers, body=None: {"authCode": "a", "uploadUrl": "https://obs/up"})

    def patch(self, owner, name, value):
        original = getattr(owner, name)
        setattr(owner, name, value)
        self.addCleanup(setattr, owner, name, original)

    def respond(self, body: bytes):
        class Response(io.BytesIO):
            def __enter__(self):
                return self

            def __exit__(self, *exc):
                return False

        self.patch(agc.urllib.request, "urlopen", lambda req, timeout: Response(body))

    def test_a_refused_upload_reports_the_store_s_error(self):
        def refuse(req, timeout):
            raise agc.urllib.error.HTTPError(req.full_url, 413, "too large", {}, io.BytesIO(b"package too large"))

        self.patch(agc.urllib.request, "urlopen", refuse)
        with self.assertRaisesRegex(agc.AgcError, "HTTP 413: package too large"):
            agc.upload({}, "1234", self.package)

    def test_a_non_json_reply_fails_with_its_body(self):
        self.respond(b"<html>gateway timeout</html>")
        with self.assertRaisesRegex(agc.AgcError, "gateway timeout"):
            agc.upload({}, "1234", self.package)

    def test_a_good_reply_returns_the_destination(self):
        self.respond(b'{"result": {"resultCode": "0", "UploadFileRsp": {"fileDestUrl": "https://obs/app.aab"}}}')
        self.assertEqual("https://obs/app.aab", agc.upload({}, "1234", self.package))


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
