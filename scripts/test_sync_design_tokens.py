#!/usr/bin/env python3
"""Tests for the design-token generator.

Run: python3 scripts/test_sync_design_tokens.py

Every case here corresponds to a bug the generator actually had, or to a value format the
token source could plausibly switch to. The generator emits code that nothing else
type-checks until a Flutter app exists, so these are the only guard against a silent
change in its output.
"""

from __future__ import annotations

import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import sync_design_tokens as gen  # noqa: E402


class TestColours(unittest.TestCase):
    def test_six_digit_hex_gets_opaque_alpha(self):
        self.assertEqual(gen.dart_color("#151f72"), "Color(0xFF151F72)")

    def test_eight_digit_hex_moves_alpha_to_the_front(self):
        # CSS orders it rrggbbaa; Flutter wants aarrggbb.
        self.assertEqual(gen.dart_color("#0000001a"), "Color(0x1A000000)")

    def test_rgba_converts_fractional_alpha(self):
        # Regression: rgba() values were silently dropped, losing eight colours.
        self.assertEqual(gen.dart_color("rgba(0, 0, 0, 0.102)"), "Color(0x1A000000)")
        self.assertEqual(gen.dart_color("rgba(255, 255, 255, 0.902)"), "Color(0xE6FFFFFF)")

    def test_rgb_without_alpha_is_opaque(self):
        self.assertEqual(gen.dart_color("rgb(6, 168, 80)"), "Color(0xFF06A850)")

    def test_rgba_is_recognised_as_a_colour(self):
        self.assertTrue(gen.is_color("rgba(0, 0, 0, 0.5)"))
        self.assertTrue(gen.is_color("#ff9b00"))
        self.assertFalse(gen.is_color("16px"))


class TestNumbers(unittest.TestCase):
    def test_strips_units_and_keeps_integers_clean(self):
        self.assertEqual(gen.number("16px"), "16")
        self.assertEqual(gen.number("300ms"), "300")

    def test_keeps_decimals_and_negatives(self):
        self.assertEqual(gen.number("-0.4px"), "-0.4")
        self.assertEqual(gen.number("1.5"), "1.5")

    def test_handles_zero_and_bare_numbers(self):
        self.assertEqual(gen.number("0px"), "0")
        self.assertEqual(gen.number(24), "24")


class TestDurations(unittest.TestCase):
    def test_milliseconds_pass_through_as_int(self):
        self.assertEqual(gen.dart_duration("300ms"), "Duration(milliseconds: 300)")

    def test_seconds_are_converted_not_just_stripped(self):
        # Regression: '0.3s' stripped to 0.3 and emitted Duration(milliseconds: 0.3),
        # which does not compile and would have meant 0.3 ms rather than 300 ms.
        self.assertEqual(gen.dart_duration("0.3s"), "Duration(milliseconds: 300)")
        self.assertEqual(gen.dart_duration("1s"), "Duration(milliseconds: 1000)")

    def test_sub_millisecond_values_use_microseconds(self):
        self.assertEqual(gen.dart_duration("0.5ms"), "Duration(microseconds: 500)")

    def test_bare_numbers_are_milliseconds(self):
        self.assertEqual(gen.dart_duration(250), "Duration(milliseconds: 250)")

    def test_every_argument_is_an_integer(self):
        for value in ("200ms", "0.3s", "1.25s", "0.5ms", 350):
            emitted = gen.dart_duration(value)
            argument = emitted.split(": ")[1].rstrip(")")
            self.assertTrue(argument.isdigit(), f"{emitted} has a non-integer argument")


class TestClassification(unittest.TestCase):
    def test_recognises_every_kind_in_the_current_source(self):
        cases = [
            ("#151f72", "color"),
            ("rgba(0, 0, 0, 0.1)", "color"),
            ("16px", "dimension"),
            ("300ms", "duration"),
            ("700", "number"),
            (700, "number"),
            ("DM Sans", "text"),
            (["DM Sans", "sans-serif"], "font-stack"),
        ]
        for value, expected in cases:
            self.assertEqual(gen.classify(value), expected, f"for {value!r}")

    def test_unrecognised_values_return_none(self):
        # These must fail the run rather than be skipped — see test_audit_raises.
        self.assertIsNone(gen.classify("hsl(210, 50%, 40%)"))
        self.assertIsNone(gen.classify("#fff"))  # shorthand is not currently emitted
        self.assertIsNone(gen.classify(True))

    def test_audit_raises_on_an_unknown_format(self):
        with self.assertRaises(gen.TokenError) as caught:
            gen.audit({"color": {"weird": "hsl(1, 2%, 3%)"}}, "light")
        self.assertIn("color.weird", str(caught.exception))

    def test_audit_counts_kinds(self):
        counts = gen.audit({"color": {"a": "#ffffff"}, "space": {"4": "4px"}}, "light")
        self.assertEqual(counts["color"], 1)
        self.assertEqual(counts["dimension"], 1)


class TestShadowDetection(unittest.TestCase):
    SHADOW = {"color": "#0000001a", "offsetX": "0px", "offsetY": "1px", "blur": "2px", "spread": "0px"}

    def test_detects_a_shadow_by_shape(self):
        self.assertTrue(gen.is_shadow_leaf(self.SHADOW))

    def test_component_nested_shadow_does_not_leak_into_colours(self):
        # Regression: card.shadow and filter.popover-shadow live inside COMPONENT groups,
        # so a group-name check missed them and their nested colour became a colour token.
        tokens = {"card": {"shadow": self.SHADOW, "background": "#ffffff"}}
        colours = gen.emit_colors("SmileColorLight", tokens)
        self.assertIn("cardBackground", colours)
        self.assertNotIn("cardShadowColor", colours)
        self.assertIn("cardShadow", gen.emit_shadows(tokens))

    def test_walk_treats_a_shadow_as_one_leaf(self):
        leaves = list(gen.walk({"elevation": {"card": self.SHADOW}}))
        self.assertEqual(len(leaves), 1)
        self.assertEqual(leaves[0][0], ["elevation", "card"])


class TestTypography(unittest.TestCase):
    def style(self, **overrides):
        base = {
            "fontFamily": ["DM Sans", "sans-serif"],
            "fontWeight": 700,
            "fontSize": "16px",
            "lineHeight": "24px",
            "letterSpacing": "0px",
        }
        base.update(overrides)
        return {"text-style": {"title": base}}

    def test_pixel_line_height_becomes_a_ratio(self):
        out = gen.emit_type(self.style())
        self.assertIn("height: 1.5,", out)  # 24 / 16
        self.assertIn("fontFamily: 'DM Sans',", out)
        self.assertIn("FontWeight.w700", out)

    def test_unitless_line_height_is_used_directly(self):
        # A DTCG source may express line height as a ratio. Dividing it by the font size
        # would silently yield a height near 0.09.
        out = gen.emit_type(self.style(lineHeight=1.4))
        self.assertIn("height: 1.4,", out)

    def test_negative_tracking_survives(self):
        self.assertIn("letterSpacing: -1,", gen.emit_type(self.style(letterSpacing="-1px")))


class TestComposeTypography(unittest.TestCase):
    def style(self, **overrides):
        base = {
            "fontFamily": ["DM Sans", "sans-serif"],
            "fontWeight": 700,
            "fontSize": "16px",
            "lineHeight": "24px",
            "letterSpacing": "0px",
        }
        base.update(overrides)
        return {"text-style": {"title": base}}

    def test_line_height_stays_absolute(self):
        # The inverse of the Dart emitter, which divides it into a ratio for `height:`.
        out = gen.emit_kotlin_type(self.style())
        self.assertIn("lineHeight = 24.sp,", out)
        self.assertIn("fontSize = 16.sp,", out)
        self.assertIn("FontWeight(700)", out)

    def test_unitless_line_height_is_multiplied_out(self):
        self.assertIn("lineHeight = 22.4.sp,", gen.emit_kotlin_type(self.style(lineHeight=1.4)))

    def test_negative_tracking_is_parenthesised(self):
        # `letterSpacing = -0.4.sp` does not parse.
        out = gen.emit_kotlin_type(self.style(letterSpacing="-0.4px"))
        self.assertIn("letterSpacing = (-0.4).sp,", out)

    def test_family_is_chosen_per_token_not_hardcoded(self):
        body = gen.emit_kotlin_type(self.style())
        display = gen.emit_kotlin_type(self.style(fontFamily=["Epilogue", "DM Sans"]))
        self.assertIn("fontFamily = body,", body)
        self.assertIn("fontFamily = display,", display)

    def test_names_match_the_dart_emitter(self):
        tokens = {"text-style": {"display-lg": self.style()["text-style"]["title"]}}
        self.assertIn("val textStyleDisplayLg = TextStyle(", gen.emit_kotlin_type(tokens))
        self.assertIn("TextStyle textStyleDisplayLg = TextStyle(", gen.emit_type(tokens))


class TestNaming(unittest.TestCase):
    def test_camel_matches_the_compose_emitter(self):
        self.assertEqual(gen.camel(["color", "text", "title"]), "colorTextTitle")
        self.assertEqual(gen.camel(["color", "surface-alt"]), "colorSurfaceAlt")
        self.assertEqual(gen.camel(["border-width", "hairline"]), "borderWidthHairline")
        self.assertEqual(gen.camel(["space", "16"]), "space16")


class TestDimens(unittest.TestCase):
    def test_only_the_dimension_groups_are_emitted(self):
        tokens = {
            "space": {"16": "16px"},
            "font-size": {"16": "16px"},  # a typography input, not a spacing token
        }
        out = gen.emit_dimens(tokens)
        self.assertIn("space16", out)
        self.assertNotIn("fontSize16", out)


class TestProductHues(unittest.TestCase):
    HUE = {"from": "#05723A", "to": "#0A9B4C", "icon": "#05723A", "scrim": "#FFFFFF", "tile": "#E4F2EA"}

    def test_hex_becomes_an_opaque_compose_colour(self):
        self.assertEqual(gen.kotlin_color("#e08600"), "Color(0xFFE08600)")

    def test_alpha_is_never_baked_in(self):
        self.assertEqual(gen.kotlin_color("#2D2B2A"), "Color(0xFF2D2B2A)")

    def test_a_non_hex_value_is_rejected_rather_than_emitted(self):
        with self.assertRaises(gen.TokenError):
            gen.kotlin_color("rgba(5, 114, 58, 0.24)")

    def test_a_short_hex_is_rejected(self):
        with self.assertRaises(gen.TokenError):
            gen.kotlin_color("#fff")

    def test_every_product_emits_all_five_roles(self):
        out = gen.emit_kotlin_product_hues({"smartSelfieEnrollment": self.HUE})
        self.assertIn('"smartSelfieEnrollment" to SmileProductHue(', out)
        for role in ("from", "to", "icon", "scrim", "tile"):
            self.assertIn(f"{role} = Color(0xFF", out)

    def test_a_hue_missing_a_role_fails_loudly(self):
        with self.assertRaises(gen.TokenError):
            gen.emit_kotlin_product_hues({"biometricKyc": {"from": "#151F72", "to": "#2B3A9E"}})

    def test_soft_badge_fills_emit_every_feedback_role(self):
        out = gen.emit_kotlin_soft_badge_fills(gen.read_soft_badge_fills())
        for role in ("success", "info", "warning", "error"):
            self.assertIn(f'"{role}" to SmileSoftBadgeFill(', out)

    def test_a_soft_badge_role_missing_from_the_spec_fails_loudly(self):
        with self.assertRaises(gen.TokenError):
            gen.emit_kotlin_soft_badge_fills({"success": {"background": "#DBF5E4", "text": "#04713A"}})

    def test_a_soft_badge_fill_missing_its_text_colour_fails_loudly(self):
        fills = {role: {"background": "#DBF5E4", "text": "#04713A"} for role in ("success", "info", "warning", "error")}
        del fills["error"]["text"]
        with self.assertRaises(gen.TokenError):
            gen.emit_kotlin_soft_badge_fills(fills)

    def test_the_soft_fills_are_not_the_saturated_design_system_pairs(self):
        fills = gen.read_soft_badge_fills()
        self.assertNotEqual(fills["warning"]["background"].upper(), "#FF9B00")

    def test_an_empty_spec_entry_fails_rather_than_emitting_an_empty_map(self):
        with self.assertRaises(gen.TokenError):
            gen.emit_kotlin_product_hues({})

    def test_the_spec_entry_covers_every_product_in_the_grid(self):
        self.assertEqual(
            [
                "smartSelfieEnrollment",
                "smartSelfieAuth",
                "documentVerification",
                "enhancedDocumentVerification",
                "biometricKyc",
                "enhancedKyc",
            ],
            list(gen.read_product_hues()),
        )

    def test_a_derived_hue_says_so(self):
        self.assertIn("DERIVED HERE", gen.read_product_hues()["enhancedKyc"]["origin"])

    def test_annotations_are_not_emitted_as_colours(self):
        out = gen.emit_kotlin_product_hues({"enhancedKyc": gen.read_product_hues()["enhancedKyc"]})
        self.assertNotIn("origin", out)


if __name__ == "__main__":
    unittest.main(verbosity=2)
