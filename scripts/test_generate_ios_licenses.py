#!/usr/bin/env python3
"""Tests for the iOS third-party notices generator.

Run: python3 scripts/test_generate_ios_licenses.py

The checkouts are written into a fake SwiftPM scratch path and the manifest walk is fed synthetic
manifests, so the rules are tested without resolving a package graph or running swift.
"""

from __future__ import annotations

import os
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import generate_ios_licenses as gen  # noqa: E402

MIT = """MIT License

Copyright (c) 2015 Sentry

Permission is hereby granted, free of charge, to any person obtaining a copy of this software.
"""

APACHE = """                                 Apache License
                           Version 2.0, January 2004

   Licensed under the Apache License, Version 2.0 (the "License");
"""

# The clause that separates the two BSD variants, and the reason the 3-clause signature keys on it.
BSD_3 = """Copyright (c) 2013, Facebook, Inc. All rights reserved.

Redistributions in binary form must reproduce the above copyright notice.
Neither the name of Facebook nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written permission.
"""

BSD_2 = """Copyright (c) 2013, Someone.

Redistributions in binary form must reproduce the above copyright notice.
"""

APSL = """APPLE PUBLIC SOURCE LICENSE
Version 2.0 - August 6, 2003
"""


def notices(*sections: tuple[str, str]) -> str:
    body = "# Third-party notices\n"
    for heading, text in sections:
        body += f"\n## {heading}\n\n```\n{text}\n```\n"
    return body


class GeneratorCase(unittest.TestCase):
    def setUp(self) -> None:
        self.scratch = tempfile.mkdtemp()
        self.shipped: list[str] = []
        self.versions: dict[str, str] = {}
        self.real_walk, self.real_versions = gen.walk, gen.resolved_versions
        gen.walk = lambda _: list(self.shipped)
        gen.resolved_versions = lambda: dict(self.versions)

    def tearDown(self) -> None:
        gen.walk, gen.resolved_versions = self.real_walk, self.real_versions
        shutil.rmtree(self.scratch, ignore_errors=True)

    def checkout(self, identity: str, version: str = "1.0.0", **files: str) -> None:
        directory = os.path.join(self.scratch, "checkouts", identity)
        os.makedirs(directory, exist_ok=True)
        for name, body in files.items():
            with open(os.path.join(directory, name.replace("__", ".")), "w", encoding="utf-8") as handle:
                handle.write(body)
        self.shipped.append(identity)
        self.versions[identity] = version

    def build(self) -> list[dict]:
        return gen.build(self.scratch)["components"]

    def failure(self) -> str:
        with self.assertRaises(gen.Unidentified) as raised:
            gen.build(self.scratch)
        return str(raised.exception)


class TestIdentify(unittest.TestCase):
    def test_the_apache_header_beats_a_bare_mit_mention_further_down(self):
        self.assertEqual("Apache-2.0", gen.identify(APACHE + "\nsome MIT-licensed part")[0])

    def test_a_three_clause_bsd_is_not_read_as_two_clause(self):
        self.assertEqual("BSD-3-Clause", gen.identify(BSD_3)[0])

    def test_a_two_clause_bsd_is_read_as_two_clause(self):
        self.assertEqual("BSD-2-Clause", gen.identify(BSD_2)[0])

    def test_the_apple_licence_is_identified(self):
        self.assertEqual("APSL-2.0", gen.identify(APSL)[0])

    def test_a_signature_is_matched_whatever_its_line_breaks(self):
        self.assertEqual("MIT", gen.identify("Permission is hereby\n granted,   free of\tcharge,")[0])

    def test_a_text_nobody_recognises_fails_rather_than_being_guessed(self):
        with self.assertRaises(gen.Unidentified):
            gen.identify("All rights reserved. Ask us nicely.")


class TestParseNested(unittest.TestCase):
    def test_a_section_yields_its_name_text_and_declared_licence(self):
        parsed = gen.parse_nested(notices(("KSCrash (MIT)", MIT)))
        self.assertEqual([("KSCrash", "MIT")], [(it["name"], it["declared"]) for it in parsed])
        self.assertEqual(MIT.strip(), parsed[0]["text"])

    def test_a_heading_with_no_fenced_text_is_not_a_notice(self):
        self.assertEqual([], gen.parse_nested("# Notices\n\n## KSCrash (MIT)\n\nSee the component.\n"))

    def test_a_file_with_no_headings_parses_to_nothing(self):
        self.assertEqual([], gen.parse_nested("Third-party notices\n\nNothing to see.\n"))

    def test_a_heading_without_a_declared_licence_still_parses(self):
        parsed = gen.parse_nested(notices(("KSCrash", MIT)))
        self.assertEqual([("KSCrash", None)], [(it["name"], it["declared"]) for it in parsed])


class TestComponentText(GeneratorCase):
    def test_the_component_ships_its_own_verbatim_text(self):
        self.checkout("lottie-spm", version="4.6.1", LICENSE=APACHE)
        entry = self.build()[0]
        self.assertEqual("lottie-spm", entry["component"])
        self.assertEqual("4.6.1", entry["version"])
        self.assertEqual("Apache-2.0", entry["licenseId"])
        self.assertEqual(APACHE.strip(), entry["text"])

    def test_two_mit_components_keep_two_texts_so_neither_holder_is_reattributed(self):
        self.checkout("sentry-cocoa", LICENSE=MIT)
        self.checkout("other", LICENSE=MIT.replace("2015 Sentry", "2012 Karl Stenerud"))
        texts = [entry["text"] for entry in self.build()]
        self.assertEqual(2, len(set(texts)))
        self.assertIn("Karl Stenerud", "".join(texts))

    def test_any_of_the_licence_filenames_is_read(self):
        self.checkout("markdowned", LICENSE__md=MIT)
        self.assertEqual("MIT", self.build()[0]["licenseId"])

    def test_components_come_out_ordered_case_insensitively(self):
        self.checkout("Zebra", LICENSE=MIT)
        self.checkout("apple", LICENSE=MIT)
        self.assertEqual(["apple", "Zebra"], [entry["component"] for entry in self.build()])

    def test_a_text_nobody_recognises_fails_and_names_the_file(self):
        self.checkout("mystery", LICENSE="All rights reserved.")
        self.assertIn("mystery (LICENSE)", self.failure())

    def test_a_graph_that_resolves_nothing_cannot_be_right(self):
        self.assertIn("no third-party component", self.failure())

    def test_a_component_with_no_resolved_checkout_says_so(self):
        self.shipped.append("never-fetched")
        self.assertIn("no checkout resolved", self.failure())

    def test_every_problem_is_reported_at_once(self):
        self.checkout("one", LICENSE="All rights reserved.")
        self.checkout("two", LICENSE="Ask us nicely.")
        reported = self.failure()
        self.assertIn("one (LICENSE)", reported)
        self.assertIn("two (LICENSE)", reported)


class TestNestedNotices(GeneratorCase):
    def test_a_vendored_notice_is_listed_as_a_component_in_its_own_right(self):
        self.checkout(
            "sentry-cocoa",
            version="9.26.1",
            LICENSE=MIT,
            THIRD_PARTY_NOTICES__md=notices(("KSCrash (MIT)", MIT), ("facebook/fishhook (BSD 3-Clause)", BSD_3)),
        )
        built = {entry["component"]: entry for entry in self.build()}
        self.assertEqual(
            {"sentry-cocoa", "sentry-cocoa/KSCrash", "sentry-cocoa/facebook/fishhook"}, set(built)
        )
        # No version: a notice vendored inside another component is not separately pinned.
        self.assertEqual("", built["sentry-cocoa/KSCrash"]["version"])
        self.assertEqual("BSD-3-Clause", built["sentry-cocoa/facebook/fishhook"]["licenseId"])

    def test_a_notices_file_that_parses_to_nothing_is_a_red_build_not_a_shorter_list(self):
        self.checkout("sentry-cocoa", LICENSE=MIT, THIRD_PARTY_NOTICES__md="Notices, but not as sections.\n")
        self.assertIn("none of it parsed", self.failure())

    def test_a_heading_that_disagrees_with_its_text_fails(self):
        self.checkout(
            "sentry-cocoa", LICENSE=MIT, THIRD_PARTY_NOTICES__md=notices(("fishhook (BSD 2-Clause)", BSD_3))
        )
        reported = self.failure()
        self.assertIn("the notice says BSD 2-Clause", reported)
        self.assertIn("reads as BSD-3-Clause", reported)

    def test_a_heading_that_agrees_by_spdx_id_rather_than_by_name_is_accepted(self):
        self.checkout("sentry-cocoa", LICENSE=MIT, THIRD_PARTY_NOTICES__md=notices(("KSCrash (BSD-3-Clause)", BSD_3)))
        built = {entry["component"]: entry for entry in self.build()}
        self.assertEqual("BSD-3-Clause", built["sentry-cocoa/KSCrash"]["licenseId"])

    def test_a_component_with_no_notices_file_lists_only_itself(self):
        self.checkout("lottie-spm", LICENSE=APACHE)
        self.assertEqual(["lottie-spm"], [entry["component"] for entry in self.build()])


class TestOverrides(GeneratorCase):
    def setUp(self) -> None:
        super().setUp()
        self.real_overrides = gen.OVERRIDES
        gen.OVERRIDES = {}

    def tearDown(self) -> None:
        gen.OVERRIDES = self.real_overrides
        super().tearDown()

    def test_the_table_is_empty_because_every_shipped_package_carries_its_text(self):
        self.assertEqual({}, self.real_overrides)

    def test_a_package_shipping_no_licence_file_fails_towards_the_reviewed_table(self):
        self.checkout("licenceless")
        self.assertIn("reviewed OVERRIDES entry", self.failure())

    def test_a_reviewed_override_with_no_text_links_the_page_that_carries_one(self):
        self.checkout("licenceless")
        gen.OVERRIDES["licenceless"] = {
            "licenseId": "Vendor-1.0",
            "licenseName": "Vendor Licence",
            "text": None,
            "url": "https://example.com/licence",
        }
        entry = self.build()[0]
        self.assertIsNone(entry["text"])
        self.assertEqual("https://example.com/licence", entry["url"])

    def test_an_override_missing_a_key_the_app_renders_fails(self):
        self.checkout("licenceless")
        gen.OVERRIDES["licenceless"] = {"licenseName": "Vendor Licence", "text": "t"}
        self.assertIn("missing licenseId", self.failure())

    def test_an_override_with_no_text_and_no_url_offers_the_reader_nothing(self):
        self.checkout("licenceless")
        gen.OVERRIDES["licenceless"] = {"licenseId": "V", "licenseName": "V", "text": None}
        self.assertIn("needs the url", self.failure())


class TestWalk(unittest.TestCase):
    def setUp(self) -> None:
        self.scratch = tempfile.mkdtemp()
        self.manifests: dict[str, dict] = {}
        self.pairs: set[tuple[str, str]] = set()
        self.real_dump, self.real_shell = gen.dump_package, gen.shell_products
        gen.dump_package = lambda path, _: self.manifests[os.path.basename(path)]
        gen.shell_products = lambda: set(self.pairs)

    def tearDown(self) -> None:
        gen.dump_package, gen.shell_products = self.real_dump, self.real_shell
        shutil.rmtree(self.scratch, ignore_errors=True)

    def manifest(self, identity: str, products: list[dict], targets: list[dict], depends: tuple = ()) -> None:
        key = "SampleUI" if identity == "sampleui" else identity
        self.manifests[key] = {
            "products": products,
            "targets": targets,
            "dependencies": [{"sourceControl": [{"identity": it}]} for it in depends],
        }
        if identity != "sampleui":
            os.makedirs(os.path.join(self.scratch, "checkouts", identity), exist_ok=True)

    def test_a_package_only_a_test_target_depends_on_is_never_reached(self):
        self.manifest(
            "sampleui",
            products=[{"name": "SampleUI", "targets": ["SampleUI"]}],
            targets=[
                {"name": "SampleUI", "type": "regular", "dependencies": []},
                {
                    "name": "SampleUITests",
                    "type": "test",
                    "dependencies": [{"product": ["SnapshotTesting", "swift-snapshot-testing"]}],
                },
            ],
        )
        self.assertEqual([], gen.walk(self.scratch))

    def test_the_sdk_is_excluded_because_a_partner_licenses_it_from_us(self):
        self.manifest(
            "sampleui",
            products=[{"name": "SampleUI", "targets": ["SampleUI"]}],
            targets=[{"name": "SampleUI", "type": "regular", "dependencies": [{"product": ["UseSmileID", "ios-spm"]}]}],
        )
        self.manifest("ios-spm", products=[{"name": "UseSmileID", "targets": ["UseSmileID"]}], targets=[])
        self.assertEqual([], gen.walk(self.scratch))

    def test_a_dependency_of_a_dependency_still_ships(self):
        self.manifest(
            "sampleui",
            products=[{"name": "SampleUI", "targets": ["SampleUI"]}],
            targets=[{"name": "SampleUI", "type": "regular", "dependencies": [{"product": ["UseSmileID", "ios-spm"]}]}],
        )
        self.manifest(
            "ios-spm",
            products=[{"name": "UseSmileID", "targets": ["UseSmileID"]}],
            targets=[{"name": "UseSmileID", "type": "regular", "dependencies": [{"product": ["Lottie", "lottie-spm"]}]}],
        )
        self.manifest("lottie-spm", products=[{"name": "Lottie", "targets": ["Lottie"]}], targets=[])
        self.assertEqual(["lottie-spm"], gen.walk(self.scratch))

    def test_a_bare_name_the_package_declares_itself_stays_inside_it(self):
        self.manifest(
            "sampleui",
            products=[{"name": "SampleUI", "targets": ["SampleUI"]}],
            targets=[
                {"name": "SampleUI", "type": "regular", "dependencies": [{"byName": ["Helper", None]}]},
                {"name": "Helper", "type": "regular", "dependencies": [{"product": ["Lottie", "lottie-spm"]}]},
            ],
        )
        self.manifest("lottie-spm", products=[{"name": "Lottie", "targets": []}], targets=[])
        self.assertEqual(["lottie-spm"], gen.walk(self.scratch))

    def test_a_bare_name_the_package_does_not_declare_is_followed_to_the_package_that_does(self):
        self.manifest(
            "sampleui",
            products=[{"name": "SampleUI", "targets": ["SampleUI"]}],
            targets=[{"name": "SampleUI", "type": "regular", "dependencies": [{"byName": ["Lottie", None]}]}],
            depends=["lottie-spm", "swift-snapshot-testing"],
        )
        self.manifest("lottie-spm", products=[{"name": "Lottie", "targets": []}], targets=[])
        self.manifest("swift-snapshot-testing", products=[{"name": "SnapshotTesting", "targets": []}], targets=[])
        # Only the package that declares the product: the test-only sibling is not swept in with it.
        self.assertEqual(["lottie-spm"], gen.walk(self.scratch))

    def test_a_bare_name_nothing_declares_ships_nothing(self):
        self.manifest(
            "sampleui",
            products=[{"name": "SampleUI", "targets": ["SampleUI"]}],
            targets=[{"name": "SampleUI", "type": "regular", "dependencies": [{"byName": ["Absent", None]}]}],
            depends=["lottie-spm"],
        )
        self.manifest("lottie-spm", products=[{"name": "Lottie", "targets": []}], targets=[])
        self.assertEqual([], gen.walk(self.scratch))

    def test_a_product_the_shell_adds_is_walked_too(self):
        self.manifest("sampleui", products=[], targets=[])
        self.pairs = {("ios-spm", "UseSmileIDVisionFace")}
        self.manifest(
            "ios-spm",
            products=[{"name": "UseSmileIDVisionFace", "targets": ["VisionFace"]}],
            targets=[{"name": "VisionFace", "type": "regular", "dependencies": [{"product": ["Sentry", "sentry-cocoa"]}]}],
        )
        self.manifest("sentry-cocoa", products=[], targets=[])
        self.assertEqual(["sentry-cocoa"], gen.walk(self.scratch))


class TestShellProducts(unittest.TestCase):
    def setUp(self) -> None:
        self.home = tempfile.mkdtemp()
        self.real_project = gen.SHELL_PROJECT
        gen.SHELL_PROJECT = os.path.join(self.home, "project.yml")

    def tearDown(self) -> None:
        gen.SHELL_PROJECT = self.real_project
        shutil.rmtree(self.home, ignore_errors=True)

    def write(self, body: str) -> None:
        with open(gen.SHELL_PROJECT, "w", encoding="utf-8") as handle:
            handle.write(body)

    def test_a_package_named_by_its_yaml_key_maps_onto_its_urls_identity(self):
        self.write(
            "packages:\n"
            "  UseSmileID:\n"
            "    url: https://github.com/smileidentity/ios-spm.git\n"
            "targets:\n"
            "  App:\n"
            "    dependencies:\n"
            "      - package: UseSmileID\n"
            "        product: UseSmileIDVisionFace\n"
        )
        self.assertEqual({("ios-spm", "UseSmileIDVisionFace")}, gen.shell_products())

    def test_a_comment_between_the_key_and_its_url_does_not_hide_the_identity(self):
        self.write(
            "packages:\n"
            "  UseSmileID:\n"
            "    # The registry, never a path.\n"
            "    url: https://github.com/smileidentity/ios-spm.git\n"
            "targets:\n"
            "  App:\n"
            "    dependencies:\n"
            "      - package: UseSmileID\n"
            "        product: UseSmileID\n"
        )
        self.assertEqual({("ios-spm", "UseSmileID")}, gen.shell_products())

    def test_a_field_before_the_url_does_not_hide_it(self):
        self.write(
            "packages:\n"
            "  UseSmileID:\n"
            "    exactVersion: 12.0.2\n"
            "\n"
            "    url: https://github.com/smileidentity/ios-spm.git\n"
            "targets:\n"
            "  App:\n"
            "    dependencies:\n"
            "      - package: UseSmileID\n"
            "        product: UseSmileID\n"
        )
        self.assertEqual({("ios-spm", "UseSmileID")}, gen.shell_products())

    def test_a_package_with_no_url_does_not_borrow_the_next_ones(self):
        self.write(
            "packages:\n"
            "  SampleUI:\n"
            "    path: ../SampleUI\n"
            "  UseSmileID:\n"
            "    url: https://github.com/smileidentity/ios-spm.git\n"
            "targets:\n"
            "  App:\n"
            "    dependencies:\n"
            "      - package: SampleUI\n"
            "        product: SampleUI\n"
        )
        self.assertEqual({("sampleui", "SampleUI")}, gen.shell_products())

    def test_a_local_package_keeps_its_key_as_its_identity(self):
        self.write(
            "packages:\n"
            "  SampleUI:\n"
            "    path: ../SampleUI\n"
            "targets:\n"
            "  App:\n"
            "    dependencies:\n"
            "      - package: SampleUI\n"
            "        product: SampleUI\n"
        )
        self.assertEqual({("sampleui", "SampleUI")}, gen.shell_products())

    def test_a_shell_declaring_no_products_would_start_the_walk_nowhere(self):
        self.write("packages: {}\n")
        with self.assertRaises(gen.Unidentified) as raised:
            gen.shell_products()
        self.assertIn("declares no package products", str(raised.exception))


class TestResolvedVersions(unittest.TestCase):
    def test_a_pin_with_no_version_falls_back_to_a_short_revision(self):
        home = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, home, True)
        with open(os.path.join(home, "Package.resolved"), "w", encoding="utf-8") as handle:
            handle.write(
                '{"pins": ['
                '{"identity": "tagged", "state": {"version": "1.2.3"}},'
                '{"identity": "pinned", "state": {"revision": "0123456789abcdef"}}'
                "]}"
            )
        real, gen.ROOT_PACKAGE = gen.ROOT_PACKAGE, home
        try:
            self.assertEqual({"tagged": "1.2.3", "pinned": "0123456"}, gen.resolved_versions())
        finally:
            gen.ROOT_PACKAGE = real


if __name__ == "__main__":
    unittest.main(verbosity=2)
