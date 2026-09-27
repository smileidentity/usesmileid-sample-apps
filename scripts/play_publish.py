#!/usr/bin/env python3
"""Reads what Google Play already holds for the Android sample, so an upload never reuses a versionCode.

The service-account token is signed with the openssl every runner already has, so nothing is installed.

    PLAY_STORE_SERVICE_ACCOUNT_JSON='<json>' scripts/play_publish.py next-version-code
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.parse
import urllib.request

PACKAGE = "com.usesmileid.sample.android"
API = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications"
SCOPE = "https://www.googleapis.com/auth/androidpublisher"


def b64url(raw: bytes) -> str:
    """Base64url without padding, as a JWT segment is written."""
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()


def assertion(account: dict, now: int) -> str:
    """An RS256 JWT the token endpoint exchanges for an access token."""
    header = b64url(json.dumps({"alg": "RS256", "typ": "JWT"}).encode())
    claims = b64url(json.dumps({
        "iss": account["client_email"],
        "scope": SCOPE,
        "aud": account["token_uri"],
        "iat": now,
        "exp": now + 600,
    }).encode())
    signing_input = f"{header}.{claims}".encode()
    with tempfile.NamedTemporaryFile("w", suffix=".pem") as key:
        key.write(account["private_key"])
        key.flush()
        signature = subprocess.run(
            ["openssl", "dgst", "-sha256", "-sign", key.name],
            input=signing_input, check=True, capture_output=True,
        ).stdout
    return f"{header}.{claims}.{b64url(signature)}"


def request(method: str, url: str, token: str | None = None, form: dict | None = None) -> dict:
    """One JSON call; an HTTP error propagates, because a guessed versionCode is worse than a failed run."""
    data = urllib.parse.urlencode(form).encode() if form else (b"" if method == "POST" else None)
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    req = urllib.request.Request(url, data=data, method=method, headers=headers)
    with urllib.request.urlopen(req, timeout=60) as response:
        body = response.read()
    return json.loads(body) if body else {}


def highest_version_code(bundles: dict, tracks: dict) -> int:
    """The highest code Play knows, from uploaded bundles and from every track's releases."""
    codes = [int(b["versionCode"]) for b in bundles.get("bundles", [])]
    for track in tracks.get("tracks", []):
        for release in track.get("releases", []):
            codes.extend(int(code) for code in release.get("versionCodes", []))
    return max(codes, default=0)


def next_version_code(account: dict) -> int:
    """Opens an edit only to read it, and deletes it so it never blocks a real publish."""
    token = request("POST", account["token_uri"], form={
        "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion": assertion(account, int(time.time())),
    })["access_token"]
    edit = request("POST", f"{API}/{PACKAGE}/edits", token)["id"]
    try:
        bundles = request("GET", f"{API}/{PACKAGE}/edits/{edit}/bundles", token)
        tracks = request("GET", f"{API}/{PACKAGE}/edits/{edit}/tracks", token)
    finally:
        request("DELETE", f"{API}/{PACKAGE}/edits/{edit}", token)
    return highest_version_code(bundles, tracks) + 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("command", choices=["next-version-code"])
    parser.parse_args()
    account = json.loads(os.environ["PLAY_STORE_SERVICE_ACCOUNT_JSON"])
    print(next_version_code(account))
    return 0


if __name__ == "__main__":
    sys.exit(main())
