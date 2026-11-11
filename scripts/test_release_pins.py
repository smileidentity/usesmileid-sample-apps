#!/usr/bin/env python3
"""Tests for the production release check. Run: python3 scripts/test_release_pins.py"""
from __future__ import annotations

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import release_pins  # noqa: E402

RESOLVED = json.dumps({"pins": [
    {"identity": "ios-spm", "location": "https://github.com/smileidentity/ios-spm.git", "state": {"version": "12.4.0"}},
    {"identity": "njia-spm", "location": "https://github.com/smileidentity/njia-spm", "state": {"version": "1.0.0"}},
    {"identity": "kamera-spm", "location": "https://github.com/smileidentity/kamera-spm", "state": {"version": "1.3.0"}},
    {"identity": "sentry-cocoa", "location": "https://github.com/getsentry/sentry-cocoa", "state": {"version": "8.58.4"}},
]})

RELEASED = {
    "android/gradle/libs.versions.toml": (
        '[versions]\nusesmileid = "12.4.0"\nusesmileid-bom = "12.4.0"\nnjia = "1.0.0"\nkotlin = "2.4.21"\n\n'
        '[libraries]\nusesmileid = { module = "com.usesmileid:usesmileid", version.ref = "usesmileid" }\n'
        'njia = { module = "com.usesmileid:njia", version.ref = "njia" }\n'
    ),
    "ios/App/project.yml": (
        "packages:\n  UseSmileID:\n    url: https://github.com/smileidentity/ios-spm.git\n    exactVersion: 12.4.0\n"
        "  Njia:\n    url: https://github.com/smileidentity/njia-spm\n    exactVersion: 1.0.0\n"
    ),
    "ios/SampleUI/Package.swift": (
        '.package(url: "https://github.com/smileidentity/ios-spm.git", exact: "12.4.0"),\n'
        '.package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.19.7")\n'
    ),
    "ios/SampleUI/Package.resolved": RESOLVED,
    "flutter/app/ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved": RESOLVED,
    "flutter/app/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved": RESOLVED,
    "flutter/app/pubspec.yaml": "dependencies:\n  usesmileid: 12.4.0\n  usesmileid_njia: 1.0.0\n  usesmileid_sample_ui:\n    path: ../sample_ui\n",
    "flutter/sample_ui/pubspec.yaml": "dependencies:\n  usesmileid: 12.4.0\n",
    "flutter/app/pubspec.lock": (
        'packages:\n  usesmileid:\n    dependency: "direct main"\n    source: hosted\n    version: "12.4.0"\n'
        '  usesmileid_kamera:\n    dependency: transitive\n    source: hosted\n    version: "1.3.0"\n'
    ),
    "expo/app/package.json": json.dumps({"dependencies": {
        "@smileid/usesmileid": "12.4.0", "@smileid/njia": "1.0.0", "@smileid/sample-ui": "workspace:*"}}),
    "expo/sample-ui/package.json": json.dumps({"peerDependencies": {"@smileid/usesmileid": "12.4.0"}}),
    "expo/pnpm-lock.yaml": (
        "importers:\n  app:\n    dependencies:\n      '@smileid/sample-ui':\n        specifier: workspace:*\n"
        "        version: link:../sample-ui\n      '@smileid/usesmileid':\n        specifier: 12.4.0\n"
        "        version: 12.4.0(abc)\npackages:\n  '@smileid/usesmileid@12.4.0':\n    resolution: {}\n"
        "  '@smileid/kamera@1.3.0':\n    resolution: {}\nsnapshots:\n  '@smileid/usesmileid@12.4.0(abc)':\n"
        "    dependencies:\n      '@smileid/kamera': 1.3.0(react@19.2.3)\n"
    ),
}


class PinTest(unittest.TestCase):
    def problems(self, changes=None):
        """The pin problems of the released tree, each site in `changes` edited by its function or left out when None."""
        changes = changes or {}
        with tempfile.TemporaryDirectory() as root:
            for site, text in RELEASED.items():
                change = changes.get(site, lambda same: same)
                if change is None:
                    continue
                path = Path(root, site)
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(change(text))
            return release_pins.pin_problems(Path(root))

    def replaced(self, site, old, new):
        self.assertIn(old, RELEASED[site])
        return self.problems({site: lambda text: text.replace(old, new)})

    def test_a_tree_of_releases_passes(self):
        self.assertEqual([], self.problems())

    def test_a_snapshot_at_any_site_fails(self):
        cases = [
            ("android/gradle/libs.versions.toml", 'usesmileid = "12.4.0"', 'usesmileid = "12.4.1-SNAPSHOT"'),
            ("ios/App/project.yml", "exactVersion: 12.4.0", "exactVersion: 12.4.0-SNAPSHOT.20261111125905.43023329917"),
            ("ios/SampleUI/Package.swift", 'exact: "12.4.0"', 'exact: "12.4.0-SNAPSHOT.20261111125905.43023329917"'),
            ("flutter/app/pubspec.yaml", "usesmileid: 12.4.0", "usesmileid: 12.4.1-SNAPSHOT.39"),
            ("flutter/sample_ui/pubspec.yaml", "usesmileid: 12.4.0", "usesmileid: 12.4.1-SNAPSHOT.39"),
            ("expo/app/package.json", '"@smileid/usesmileid": "12.4.0"', '"@smileid/usesmileid": "12.4.1-SNAPSHOT.86"'),
            ("expo/sample-ui/package.json", '"12.4.0"', '"12.4.1-SNAPSHOT.86"'),
        ]
        for site, old, new in cases:
            with self.subTest(site=site):
                self.assertTrue(any(p.startswith(site) for p in self.replaced(site, old, new)))

    def test_the_android_timestamped_build_is_not_a_release(self):
        problems = self.replaced("android/gradle/libs.versions.toml", 'usesmileid = "12.4.0"', 'usesmileid = "12.4.0-20261110.133529-83"')
        self.assertIn("android/gradle/libs.versions.toml: usesmileid is 12.4.0-20261110.133529-83, not a release", problems)

    def test_a_snapshot_in_a_lockfile_alone_fails(self):
        cases = [
            ("ios/SampleUI/Package.resolved", '"version": "1.3.0"', '"version": "1.3.1-SNAPSHOT.38"'),
            ("flutter/app/ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved", '"version": "12.4.0"', '"version": "12.4.0-SNAPSHOT.1.2"'),
            ("flutter/app/pubspec.lock", 'version: "1.3.0"', 'version: "1.3.1-SNAPSHOT.38"'),
            ("expo/pnpm-lock.yaml", "'@smileid/kamera': 1.3.0(react", "'@smileid/kamera': 1.3.1-SNAPSHOT.38(react"),
            ("expo/pnpm-lock.yaml", "specifier: 12.4.0\n        version: 12.4.0(abc)", "specifier: 12.4.0\n        version: 12.4.1-SNAPSHOT.86(abc)"),
        ]
        for site, old, new in cases:
            with self.subTest(site=site, new=new):
                self.assertTrue(any(p.startswith(site) for p in self.replaced(site, old, new)))

    def test_a_library_named_by_group_is_read(self):
        problems = self.replaced("android/gradle/libs.versions.toml", 'njia = { module = "com.usesmileid:njia", version.ref = "njia" }',
                                 'njia = { group = "com.usesmileid", name = "njia", version = "1.0.1-SNAPSHOT" }')
        self.assertIn("android/gradle/libs.versions.toml: com.usesmileid is 1.0.1-SNAPSHOT, not a release", problems)

    def test_a_snapshot_njia_fails(self):
        problems = self.replaced("android/gradle/libs.versions.toml", 'njia = "1.0.0"', 'njia = "0.0.1-20261030.012141-13"')
        self.assertTrue(any("njia" in p for p in problems))
        problems = self.replaced("ios/App/project.yml", "exactVersion: 1.0.0", "exactVersion: 0.0.1-SNAPSHOT.13")
        self.assertTrue(any("njia-spm" in p for p in problems))

    def test_an_sdk_from_the_workspace_or_a_path_fails(self):
        problems = self.replaced("expo/app/package.json", '"@smileid/usesmileid": "12.4.0"', '"@smileid/usesmileid": "workspace:*"')
        self.assertIn("expo/app/package.json: @smileid/usesmileid is workspace:*, not a release", problems)
        problems = self.replaced("expo/pnpm-lock.yaml", "        version: 12.4.0(abc)", "        version: link:../../usesmileid")
        self.assertIn("expo/pnpm-lock.yaml: @smileid/usesmileid is link:../../usesmileid, not a release", problems)
        problems = self.replaced("flutter/app/pubspec.lock", '    source: hosted\n    version: "12.4.0"', '    source: path\n    version: "12.4.0"')
        self.assertIn("flutter/app/pubspec.lock: usesmileid is from path, not a release", problems)

    def test_another_publisher_is_not_read(self):
        self.assertEqual([], self.replaced("ios/SampleUI/Package.resolved", '"8.58.4"', '"8.58.4-beta.1"'))

    def test_a_branch_or_range_requirement_is_not_a_release(self):
        problems = self.replaced("ios/SampleUI/Package.swift", 'exact: "12.4.0"', 'branch: "main"')
        self.assertTrue(any(p.startswith("ios/SampleUI/Package.swift") for p in problems))

    def test_a_missing_site_or_one_without_a_pin_fails(self):
        self.assertIn("expo/pnpm-lock.yaml is missing; update release_pins.py's pin sites",
                      self.problems({"expo/pnpm-lock.yaml": None}))
        self.assertIn("flutter/sample_ui/pubspec.yaml has no Smile ID pin; update release_pins.py's pin sites",
                      self.replaced("flutter/sample_ui/pubspec.yaml", "usesmileid: 12.4.0", "sdk: flutter"))


class RefTest(unittest.TestCase):
    def test_a_v_tag_on_main_passes(self):
        self.assertEqual([], release_pins.ref_problems("refs/tags/v12.4.0", True))

    def test_a_branch_fails(self):
        self.assertEqual(1, len(release_pins.ref_problems("refs/heads/main", True)))

    def test_another_tag_fails(self):
        for ref in ("refs/tags/sdk-pin/12.4.0", "refs/tags/vtest", "refs/tags/v12.4.0-rc1"):
            with self.subTest(ref=ref):
                self.assertEqual(1, len(release_pins.ref_problems(ref, True)))

    def test_a_tag_off_main_fails(self):
        self.assertEqual(["refs/tags/v12.4.0 is not on main"], release_pins.ref_problems("refs/tags/v12.4.0", False))


if __name__ == "__main__":
    unittest.main()
