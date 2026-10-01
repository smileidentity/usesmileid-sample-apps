#!/usr/bin/env python3
"""Sizes a release build the way the SDK repos size theirs, so the README's two ends compare.

Android: bundletool sizes the bundle for one arm64 phone (Android 14, 480 dpi), the download Google
Play would transfer and the APKs it would install. iOS: the archive's `.app` on disk, and a zip of it
as an approximation of the App Store's compressed transfer.

    scripts/app_size.py android android/app/build/outputs/bundle/release/app-release.aab
    scripts/app_size.py ios path/to/UseSmileIDSample.xcarchive
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import os
import subprocess
import sys
import tempfile
import urllib.request
import zipfile

BUNDLETOOL_VERSION = "1.18.3"
BUNDLETOOL_SHA256 = "a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29"
BUNDLETOOL_URL = (
    f"https://github.com/google/bundletool/releases/download/{BUNDLETOOL_VERSION}/"
    f"bundletool-all-{BUNDLETOOL_VERSION}.jar"
)
DEVICE_SPEC = {
    "supportedAbis": ["arm64-v8a"],
    "supportedLocales": ["en-US"],
    "screenDensity": 480,
    "sdkVersion": 34,
}


def die(message: str) -> None:
    """Stops with `message` on stderr."""
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def ensure_bundletool(path: str) -> str:
    """Returns a verified bundletool jar, downloading the pinned release when absent."""
    if not os.path.exists(path):
        if os.path.dirname(path):
            os.makedirs(os.path.dirname(path), exist_ok=True)
        with urllib.request.urlopen(BUNDLETOOL_URL, timeout=120) as response, open(path, "wb") as out:
            out.write(response.read())
    with open(path, "rb") as jar:
        digest = hashlib.sha256(jar.read()).hexdigest()
    if digest != BUNDLETOOL_SHA256:
        os.remove(path)
        die(f"bundletool checksum mismatch: {digest}")
    return path


def bundletool(jar: str, *args: str) -> str:
    """Runs one bundletool command and returns its stdout, stopping on failure."""
    result = subprocess.run(["java", "-jar", jar, *args], capture_output=True, text=True)
    if result.returncode != 0:
        die(f"bundletool {args[0]} failed:\n{result.stderr or result.stdout}")
    return result.stdout


def download_bytes(get_size_csv: str) -> int:
    """The MAX column of `get-size total`, which is one value for a single device spec."""
    rows = list(csv.reader(io.StringIO(get_size_csv)))
    return int(rows[1][rows[0].index("MAX")])


def android(bundle: str, jar: str) -> tuple[int, int]:
    """Download and on-device bytes of `bundle` for the device spec."""
    with tempfile.TemporaryDirectory() as work:
        spec = os.path.join(work, "device-spec.json")
        with open(spec, "w") as out:
            json.dump(DEVICE_SPEC, out)
        apks = os.path.join(work, "app.apks")
        bundletool(jar, "build-apks", f"--bundle={bundle}", f"--output={apks}", f"--device-spec={spec}", "--overwrite")
        download = download_bytes(bundletool(jar, "get-size", "total", f"--apks={apks}", f"--device-spec={spec}"))
        with zipfile.ZipFile(apks) as archive:
            on_device = sum(info.file_size for info in archive.infolist() if info.filename.endswith(".apk"))
    return download, on_device


def tree_bytes(root: str) -> int:
    """Bytes of every regular file under `root`, symlinks not followed."""
    total = 0
    for directory, _, files in os.walk(root):
        for name in files:
            path = os.path.join(directory, name)
            if not os.path.islink(path):
                total += os.path.getsize(path)
    return total


def zipped_bytes(root: str) -> int:
    """A deflated zip of `root`, as an approximation of the App Store's compressed transfer."""
    with tempfile.TemporaryDirectory() as work:
        target = os.path.join(work, "app.zip")
        with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as archive:
            for directory, _, files in os.walk(root):
                for name in files:
                    path = os.path.join(directory, name)
                    if not os.path.islink(path):
                        archive.write(path, os.path.relpath(path, os.path.dirname(root)))
        return os.path.getsize(target)


def ios(archive: str) -> tuple[int, int]:
    """Download and on-device bytes of the one `.app` inside `archive`."""
    applications = os.path.join(archive, "Products", "Applications")
    apps = [name for name in os.listdir(applications) if name.endswith(".app")] if os.path.isdir(applications) else []
    if len(apps) != 1:
        die(f"expected one .app in {applications}, found {apps}")
    app = os.path.join(applications, apps[0])
    return zipped_bytes(app), tree_bytes(app)


def megabytes(size: int) -> str:
    """Decimal megabytes to two places, as the SDK tables print them."""
    return f"{size / 1_000_000:.2f} MB"


def main(argv: list[str] | None = None) -> int:
    """Prints the download and on-device size of one release build."""
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("platform", choices=("android", "ios"))
    parser.add_argument("build", help="the release .aab, or the .xcarchive")
    parser.add_argument("--bundletool", default=os.path.join(tempfile.gettempdir(), "bundletool", f"bundletool-{BUNDLETOOL_VERSION}.jar"))
    args = parser.parse_args(argv)
    if not os.path.exists(args.build):
        die(f"{args.build} does not exist")
    if args.platform == "android":
        download, on_device = android(args.build, ensure_bundletool(args.bundletool))
    else:
        download, on_device = ios(args.build)
    print(f"download: {megabytes(download)}")
    print(f"on device: {megabytes(on_device)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
