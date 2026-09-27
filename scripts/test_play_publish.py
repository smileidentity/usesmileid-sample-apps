#!/usr/bin/env python3
"""Tests for the Play version-code lookup. Run: python3 scripts/test_play_publish.py"""
from __future__ import annotations

import base64
import json
import os
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import play_publish as play  # noqa: E402


class TestHighestVersionCode(unittest.TestCase):
    def test_the_highest_code_wins_across_bundles_and_every_track(self):
        bundles = {"bundles": [{"versionCode": 110}, {"versionCode": 108}]}
        tracks = {"tracks": [
            {"track": "internal", "releases": [{"versionCodes": ["112"]}]},
            {"track": "production", "releases": [{"versionCodes": ["109"]}, {}]},
        ]}
        self.assertEqual(112, play.highest_version_code(bundles, tracks))

    def test_an_app_with_nothing_uploaded_starts_from_zero(self):
        self.assertEqual(0, play.highest_version_code({}, {}))


class TestAssertion(unittest.TestCase):
    def test_the_token_is_an_rs256_jwt_the_key_verifies(self):
        with tempfile.TemporaryDirectory() as scratch:
            key = os.path.join(scratch, "key.pem")
            subprocess.run(["openssl", "genrsa", "-out", key, "2048"], check=True, capture_output=True)
            account = {"client_email": "ci@example.iam.gserviceaccount.com", "token_uri": "https://oauth2.googleapis.com/token",
                       "private_key": open(key).read()}
            token = play.assertion(account, 1_700_000_000)
            header, claims, signature = token.split(".")
            pad = lambda part: base64.urlsafe_b64decode(part + "=" * (-len(part) % 4))
            self.assertEqual("RS256", json.loads(pad(header))["alg"])
            self.assertEqual(1_700_000_600, json.loads(pad(claims))["exp"])
            public = os.path.join(scratch, "pub.pem")
            subprocess.run(["openssl", "rsa", "-in", key, "-pubout", "-out", public], check=True, capture_output=True)
            with open(os.path.join(scratch, "sig"), "wb") as handle:
                handle.write(pad(signature))
            verified = subprocess.run(
                ["openssl", "dgst", "-sha256", "-verify", public, "-signature", os.path.join(scratch, "sig")],
                input=f"{header}.{claims}".encode(), capture_output=True,
            )
            self.assertEqual(0, verified.returncode, verified.stdout + verified.stderr)


if __name__ == "__main__":
    unittest.main()
