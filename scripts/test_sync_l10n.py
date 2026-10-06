#!/usr/bin/env python3
"""Tests for the localisation generator: run `python3 scripts/test_sync_l10n.py`."""

from __future__ import annotations

import io
import json
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import sync_l10n as gen  # noqa: E402


def write(path: str, value) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with io.open(path, "w", encoding="utf-8") as handle:
        json.dump(value, handle, ensure_ascii=False)


def make_spec(root: str, app: dict, sdk: dict | None = None, sdk_arguments: dict | None = None) -> str:
    """A minimal spec/l10n tree with English and French."""
    spec = os.path.join(root, "spec", "l10n")
    write(
        os.path.join(spec, "languages.json"),
        {
            "base": "en",
            "languages": [
                {"id": "en", "endonym": "English", "direction": "ltr", "androidFolder": "values"},
                {"id": "fr", "endonym": "Français", "direction": "ltr", "androidFolder": "values-fr"},
            ],
            "integerArguments": ["count"],
        },
    )
    for lang, values in app.items():
        write(os.path.join(spec, "app", f"{lang}.json"), values)
    write(os.path.join(spec, "sdk", "fr.json"), sdk or {"si_title": "Titre"})
    write(os.path.join(spec, "sdk-arguments.json"), sdk_arguments or {})
    return spec


class CommittedSourceTest(unittest.TestCase):
    def test_every_language_has_every_key_with_the_same_arguments(self):
        data = gen.load()
        self.assertEqual([language["id"] for language in data["languages"]], ["en", "fr", "ar", "he"])
        self.assertEqual(set(data["sdk"]), {"fr", "ar", "he"})

    def test_no_value_carries_androids_whitespace_quotes(self):
        data = gen.load()
        for language, strings in data["sdk"].items():
            for key, value in strings.items():
                self.assertFalse(value.startswith('"') and value.endswith('"'), f"{language} {key}")

    def test_a_trailing_space_survives_on_android_without_literal_quotes(self):
        self.assertEqual(gen.android_escape("Lire les ", formatted=False), '"Lire les "')

    def test_direction_marks_are_escaped_where_source_would_hide_them(self):
        self.assertEqual(gen.dart_string("\u2066x\u2069"), "'\\u2066x\\u2069'")
        self.assertEqual(gen.ts_string("\u2066x\u2069"), "'\\u2066x\\u2069'")

    def test_hebrew_is_iw_only_in_android_resource_folders(self):
        data = gen.load()
        android = gen.android_outputs(data)
        self.assertIn("android/app/src/main/res/values-iw/sdk_strings.xml", android)
        self.assertIn('android:name="he"', android["android/app/src/main/res/xml/locales_config.xml"])
        self.assertIn("ios/App/Sources/Localization/he.lproj/Localizable.strings", gen.ios_outputs(data))
        self.assertIn("flutter/app/lib/l10n/intl_he.arb", gen.flutter_outputs(data))

    def test_sdk_keys_keep_each_platforms_own_argument_form(self):
        data = gen.load()
        android = gen.android_outputs(data)["android/app/src/main/res/values-fr/sdk_strings.xml"]
        ios = gen.ios_outputs(data)["ios/App/Sources/Localization/fr.lproj/Localizable.strings"]
        flutter = json.loads(gen.flutter_outputs(data)["flutter/app/lib/l10n/intl_fr.arb"])
        expo = json.loads(gen.expo_outputs(data)["expo/app/src/l10n/fr.json"])
        self.assertIn('"si_consent_title">{partnerName} ', android)
        self.assertIn('"si_consent_learn_more_privacy_partner_link">%1$s<', android)
        self.assertIn('"si_consent_title" = "%@ ', ios)
        self.assertIn('"si_consent_learn_more_privacy_partner_link" = "%@";', ios)
        self.assertTrue(flutter["si_consent_title"].startswith("{partnerName} "))
        self.assertEqual(flutter["@@locale"], "fr")
        self.assertEqual(expo["si_consent_learn_more_privacy_partner_link"], "{partnerName}")


class ValidationTest(unittest.TestCase):
    def test_a_missing_translation_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            spec = make_spec(tmp, {"en": {"a": "A", "b": "B"}, "fr": {"a": "A"}})
            with self.assertRaisesRegex(gen.L10nError, "missing \\['b'\\]"):
                gen.load(spec)

    def test_an_unknown_translation_key_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            spec = make_spec(tmp, {"en": {"a": "A"}, "fr": {"a": "A", "z": "Z"}})
            with self.assertRaisesRegex(gen.L10nError, "unknown \\['z'\\]"):
                gen.load(spec)

    def test_a_renamed_argument_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            spec = make_spec(tmp, {"en": {"a": "Hi {name}"}, "fr": {"a": "Salut {nom}"}})
            with self.assertRaisesRegex(gen.L10nError, "arguments"):
                gen.load(spec)

    def test_sdk_languages_must_override_the_same_keys(self):
        with tempfile.TemporaryDirectory() as tmp:
            spec = make_spec(tmp, {"en": {"a": "A"}, "fr": {"a": "A"}})
            write(os.path.join(spec, "languages.json"), {
                "base": "en",
                "languages": [
                    {"id": "en", "androidFolder": "values"},
                    {"id": "fr", "androidFolder": "values-fr"},
                    {"id": "ar", "androidFolder": "values-ar"},
                ],
            })
            write(os.path.join(spec, "app", "ar.json"), {"a": "A"})
            write(os.path.join(spec, "sdk", "ar.json"), {"si_other": "X"})
            with self.assertRaisesRegex(gen.L10nError, "different keys"):
                gen.load(spec)


class EmitterTest(unittest.TestCase):
    def data(self, en: dict, fr: dict, **kwargs) -> dict:
        with tempfile.TemporaryDirectory() as tmp:
            return gen.load(make_spec(tmp, {"en": en, "fr": fr}, **kwargs))

    def test_a_reordered_translation_keeps_each_argument_on_its_english_index(self):
        data = self.data({"pair": "{first} then {second}"}, {"pair": "{second} avant {first}"})
        self.assertIn(">%2$s avant %1$s<", gen.android_app(data, "fr"))
        self.assertIn('"pair" = "%2$@ avant %1$@";', gen.ios_app(data, "fr"))

    def test_an_integer_argument_is_typed_on_every_platform(self):
        data = self.data({"n": "{count} left"}, {"n": "{count} restants"})
        self.assertIn(">%1$d left<", gen.android_app(data, "en"))
        self.assertIn('"n" = "%1$ld left";', gen.ios_app(data, "en"))
        self.assertIn("fun n(count: Int)", gen.kotlin_accessors(data))
        self.assertIn("func n(count: Int)", gen.swift_accessors(data))
        self.assertIn("required int count", gen.dart_strings(data))
        self.assertIn("n(args: { count: number })", gen.ts_strings(data))

    def test_android_escapes_what_aapt_would_otherwise_eat(self):
        self.assertEqual(gen.android_escape("l'image", formatted=False), "l\\'image")
        self.assertEqual(gen.android_escape('say "hi"', formatted=False), 'say \\"hi\\"')
        self.assertEqual(gen.android_escape("a & <b>", formatted=False), "a &amp; &lt;b>")
        self.assertEqual(gen.android_escape("@home", formatted=False), "\\@home")
        self.assertEqual(gen.android_escape(" · active", formatted=False), '" · active"')
        self.assertEqual(gen.android_escape("100%", formatted=True), "100%%")
        self.assertEqual(gen.android_escape("100%", formatted=False), "100%")

    def test_strings_files_escape_quotes_and_percent_only_when_formatted(self):
        self.assertEqual(gen.strings_escape('a "b" \\ c', formatted=False), 'a \\"b\\" \\\\ c')
        self.assertEqual(gen.strings_escape("100%", formatted=True), "100%%")
        self.assertEqual(gen.strings_escape("100%", formatted=False), "100%")

    def test_dart_and_typescript_literals_escape_quotes_and_interpolation(self):
        self.assertEqual(gen.dart_string("l'$x"), "'l\\'\\$x'")
        self.assertEqual(gen.ts_string("l'image\n"), "'l\\'image\\n'")

    def test_sdk_arguments_apply_only_to_the_listed_platform(self):
        data = self.data(
            {"a": "A"},
            {"a": "A"},
            sdk={"si_title": "{partnerName} veut"},
            sdk_arguments={"si_title": {"ios": {"partnerName": "%@"}}},
        )
        self.assertIn('"si_title" = "%@ veut";', gen.ios_sdk(data, "fr"))
        self.assertIn(">{partnerName} veut<", gen.android_sdk(data, "fr"))


class CheckTest(unittest.TestCase):
    def test_check_reports_a_stale_output_and_writing_clears_it(self):
        with tempfile.TemporaryDirectory() as tmp:
            spec = make_spec(tmp, {"en": {"a": "A"}, "fr": {"a": "Á"}})
            stale = gen.sync(["expo"], check=True, repo=tmp, spec=spec)
            self.assertIn("expo/sample-ui/src/use-smile-id-sample-strings.ts", stale)
            gen.sync(["expo"], check=False, repo=tmp, spec=spec)
            self.assertEqual(gen.sync(["expo"], check=True, repo=tmp, spec=spec), [])


if __name__ == "__main__":
    unittest.main()
