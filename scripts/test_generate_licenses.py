#!/usr/bin/env python3
"""Tests for the third-party notices generator.

Run: python3 scripts/test_generate_licenses.py

Every case is an artifact this app resolves, and the failure path is the point. The POMs are written
into a fake Gradle cache, so the rules are tested without depending on what happens to be downloaded.
"""

from __future__ import annotations

import os
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import generate_licenses as gen  # noqa: E402

APACHE = """<name>The Apache Software License, Version 2.0</name>
      <url>https://www.apache.org/licenses/LICENSE-2.0.txt</url>"""


def pom(licenses: str = "", parent: str = "", packaging: str = "") -> str:
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  {parent}
  {packaging}
  {licenses}
</project>
"""


def licences(*blocks: str) -> str:
    entries = "".join(f"<license>{block}</license>" for block in blocks)
    return f"<licenses>{entries}</licenses>"


def parent_of(group: str, artifact: str, version: str) -> str:
    return (
        f"<parent><groupId>{group}</groupId><artifactId>{artifact}</artifactId>"
        f"<version>{version}</version></parent>"
    )


class GeneratorCase(unittest.TestCase):
    def setUp(self) -> None:
        self.home = tempfile.mkdtemp()
        self.texts = os.path.join(self.home, "texts")
        os.makedirs(self.texts)
        for name in ("apache-2.0.txt", "mit.txt", "bsd-3-clause.txt"):
            with open(os.path.join(self.texts, name), "w", encoding="utf-8") as handle:
                handle.write(f"text of {name}\n")
        # The index Gradle hands over, which is the generator's only route to a POM.
        gen.POM_INDEX = {}

    def tearDown(self) -> None:
        shutil.rmtree(self.home, ignore_errors=True)
        gen.POM_INDEX = {}

    def write_pom(self, coordinate: str, body: str) -> None:
        group, artifact, version = coordinate.split(":")
        path = os.path.join(self.home, f"{group}-{artifact}-{version}.pom")
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(body)
        gen.POM_INDEX[coordinate] = path


class TestParentWalk(GeneratorCase):
    def test_a_licence_only_in_the_parent_is_found(self):
        self.write_pom(
            "com.google.guava:guava:33.6.0-android",
            pom(parent=parent_of("com.google.guava", "guava-parent", "33.6.0-android")),
        )
        self.write_pom("com.google.guava:guava-parent:33.6.0-android", pom(licences(APACHE)))
        found = gen.licences_for("com.google.guava", "guava", "33.6.0-android")
        self.assertEqual(["The Apache Software License, Version 2.0"], [it["name"] for it in found])

    def test_the_walk_stops_rather_than_looping_forever(self):
        self.write_pom("a:b:1", pom(parent=parent_of("a", "b", "1")))
        with self.assertRaises(gen.Unidentified):
            gen.licences_for("a", "b", "1")


class TestOverrides(GeneratorCase):
    def test_the_override_answers_when_no_pom_does(self):
        self.write_pom("org.bouncycastle:bcprov-jdk18on:1.83", pom())
        found = gen.licences_for("org.bouncycastle", "bcprov-jdk18on", "1.83")
        self.assertEqual(["Bouncy Castle Licence"], [it["name"] for it in found])

    def test_an_artifact_with_no_pom_at_all_still_takes_its_override(self):
        found = gen.licences_for("javax.inject", "javax.inject", "1")
        self.assertEqual(["The Apache Software License, Version 2.0"], [it["name"] for it in found])


class TestMultipleLicences(GeneratorCase):
    def test_both_declared_licences_are_kept(self):
        bsd = "<name>BSD-3-Clause</name><url>https://opensource.org/license/bsd-3-clause</url>"
        self.write_pom("androidx.camera:camera-core:1.6.1", pom(licences(APACHE, bsd)))
        notices = gen.build(["androidx.camera:camera-core:1.6.1"], self.texts)
        entry = notices["openSource"][0]
        self.assertEqual(["Apache-2.0", "BSD-3-Clause"], [it["id"] for it in entry["licenses"]])
        self.assertEqual({"Apache-2.0", "BSD-3-Clause"}, set(notices["licenseTexts"]))


class TestFailurePath(GeneratorCase):
    def test_an_artifact_with_no_metadata_and_no_override_fails(self):
        self.write_pom("com.example:fabricated:1.0", pom())
        with self.assertRaises(gen.Unidentified) as raised:
            gen.build(["com.example:fabricated:1.0"], self.texts)
        self.assertIn("com.example:fabricated", str(raised.exception))

    def test_a_licence_nobody_reviewed_fails_rather_than_being_guessed(self):
        odd = "<name>Some Vendor Licence 3</name><url>https://example.com/licence</url>"
        self.write_pom("com.example:odd:1.0", pom(licences(odd)))
        with self.assertRaises(gen.Unidentified) as raised:
            gen.build(["com.example:odd:1.0"], self.texts)
        self.assertIn("Some Vendor Licence 3", str(raised.exception))

    def test_nothing_is_ever_emitted_as_unknown(self):
        self.write_pom("com.example:fabricated:1.0", pom())
        with self.assertRaises(gen.Unidentified):
            gen.build(["com.example:fabricated:1.0"], self.texts)

    def test_every_problem_is_reported_at_once(self):
        self.write_pom("com.example:one:1.0", pom())
        self.write_pom("com.example:two:1.0", pom())
        with self.assertRaises(gen.Unidentified) as raised:
            gen.build(["com.example:one:1.0", "com.example:two:1.0"], self.texts)
        self.assertIn("com.example:one", str(raised.exception))
        self.assertIn("com.example:two", str(raised.exception))


class TestPomIndex(GeneratorCase):
    def test_an_artifact_with_no_resolved_pom_says_so(self):
        gen.POM_INDEX["com.example:unresolved:1.0"] = ""
        with self.assertRaises(gen.Unidentified) as raised:
            gen.build(["com.example:unresolved:1.0"], self.texts)
        self.assertIn("no POM in the index", str(raised.exception))

    def test_the_index_is_read_as_gradle_writes_it(self):
        path = os.path.join(self.home, "poms.tsv")
        with open(path, "w", encoding="utf-8") as handle:
            handle.write("a:b:1\t/tmp/b.pom\nc:d:2\t\n\n")
        self.assertEqual({"a:b:1": "/tmp/b.pom", "c:d:2": ""}, gen.load_pom_index(path))


class TestSections(GeneratorCase):
    def test_googles_own_terms_are_not_listed_as_open_source(self):
        terms = "<name>ML Kit Terms of Service</name><url>https://developers.google.com/ml-kit/terms</url>"
        self.write_pom("com.google.mlkit:barcode-scanning:17.3.0", pom(licences(terms)))
        notices = gen.build(["com.google.mlkit:barcode-scanning:17.3.0"], self.texts)
        self.assertEqual([], notices["openSource"])
        self.assertEqual("com.google.mlkit:barcode-scanning", notices["googleServices"][0]["artifact"])

    def test_the_sdk_itself_is_not_a_third_party_notice(self):
        own = "<name>Smile ID Terms of Use</name><url>https://smile.id/terms-and-conditions</url>"
        self.write_pom("com.usesmileid:usesmileid:12.0.2", pom(licences(own)))
        notices = gen.build(["com.usesmileid:usesmileid:12.0.2"], self.texts)
        self.assertEqual([], notices["openSource"])
        self.assertEqual([], notices["googleServices"])

    def test_a_bom_carries_no_notice_because_it_ships_no_code(self):
        self.write_pom(
            "androidx.compose:compose-bom:2026.06.01",
            pom(licences(APACHE), packaging="<packaging>pom</packaging>"),
        )
        notices = gen.build(["androidx.compose:compose-bom:2026.06.01"], self.texts)
        self.assertEqual([], notices["openSource"])

    def test_a_licence_name_is_matched_whatever_its_spacing(self):
        spaced = "<name>The  Apache\n      Software License,  Version 2.0</name><url>u</url>"
        self.write_pom("com.example:spaced:1.0", pom(licences(spaced)))
        notices = gen.build(["com.example:spaced:1.0"], self.texts)
        self.assertEqual("Apache-2.0", notices["openSource"][0]["licenses"][0]["id"])

    def test_a_licence_with_no_vendored_text_still_lists_and_links(self):
        self.write_pom("org.bouncycastle:bcprov-jdk18on:1.83", pom())
        notices = gen.build(["org.bouncycastle:bcprov-jdk18on:1.83"], self.texts)
        entry = notices["openSource"][0]["licenses"][0]
        self.assertEqual("Bouncy Castle Licence", entry["id"])
        self.assertTrue(entry["url"])
        self.assertNotIn("Bouncy Castle Licence", notices["licenseTexts"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
