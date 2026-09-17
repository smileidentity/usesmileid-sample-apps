#!/usr/bin/env python3
"""Tests for the design-token generator.

Run: python3 scripts/test_sync_design_tokens.py

Every case here corresponds to a bug the generator actually had, or to a value format the
token source could plausibly switch to. The generator emits code that nothing else
type-checks until a Flutter app exists, so these are the only guard against a silent
change in its output.
"""

from __future__ import annotations

import io
import json
import os
import re
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import sync_design_tokens as gen  # noqa: E402


def design_system_or_skip(case: unittest.TestCase) -> str:
    """The design system, or a stated skip: it is a private repo, so CI and fork PRs have no copy."""
    try:
        return gen.find_design_system(None)
    except SystemExit:
        case.skipTest(
            "no design system on this machine, so this assertion cannot run. It compares the emitters "
            "against the real token set; run it with SMILE_DESIGN_SYSTEM pointed at a checkout, or set "
            "the DESIGN_SYSTEM_TOKEN secret so CI checks one out."
        )
        raise  # unreachable: skipTest raises. Present so the return type stays honest.


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
    HUE = {
        "from": "#05723A", "to": "#0A9B4C", "cardIcon": "#05723A", "icon": "#05723A", "tile": "#E4F2EA",
        "stopStart": 0.13, "stopEnd": 0.87, "fromAlpha": 1.0, "toAlpha": 1.0,
    }

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
        for role in ("from", "to", "cardIcon", "icon", "tile"):
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

    def test_border_strong_emits_an_opaque_colour(self):
        self.assertIn("val smileBorderStrong: Color = Color(0xFF", gen.emit_kotlin_border_strong(gen.read_border_strong()))

    def test_border_strong_without_a_value_fails_loudly(self):
        with self.assertRaises(gen.TokenError):
            gen.emit_kotlin_border_strong("")

    def test_surface2_emits_an_opaque_colour(self):
        self.assertIn("val smileSurface2: Color = Color(0xFF", gen.emit_kotlin_surface2(gen.read_surface2()))

    def test_profile_hues_emit_every_fill_the_design_supplies(self):
        hues = gen.read_profile_hues()
        out = gen.emit_kotlin_profile_hues(hues)
        self.assertIn("val smileProfileHues: List<Color> = listOf(", out)
        self.assertEqual(out.count("Color(0xFF"), len(hues))

    def test_profile_hues_keep_the_designs_order(self):
        # Position is the index, so reordering these recolours every profile in every app.
        self.assertEqual(
            [hue.upper() for hue in gen.read_profile_hues()],
            ["#151F72", "#05723A", "#B36500", "#2D2B2A"],
        )

    def test_token_session_emits_a_gradient_a_ring_and_a_track_opacity(self):
        out = gen.emit_kotlin_token_session(gen.read_token_session())
        self.assertIn("val smileTokenSessionGradient: List<Color> = listOf(", out)
        self.assertIn("val smileTokenRing: Color = Color(0xFF", out)
        self.assertIn("SMILE_TOKEN_RING_TRACK_OPACITY", out)

    def test_token_session_ring_is_not_the_feedback_success_fill(self):
        self.assertNotEqual(gen.read_token_session()["ring"].upper(), "#00C853")

    def test_a_one_stop_gradient_fails_loudly(self):
        with self.assertRaises(gen.TokenError):
            gen.emit_kotlin_token_session({"cardGradient": ["#1A7840"], "ring": "#06A850", "ringTrackOpacity": 0.18})

    def test_label_type_style_emits_a_size_and_a_tracking(self):
        out = gen.emit_kotlin_label_type_style(gen.read_label_type_style())
        self.assertIn("val smileLabelSize = 11.sp", out)
        self.assertIn("val smileLabelTracking = 0.88.sp", out)

    def test_label_type_style_is_bigger_than_the_overline_it_replaces(self):
        # The whole point of the delta: text-style.overline is 10 and set solid.
        delta = gen.read_label_type_style()
        self.assertGreater(delta["size"], 10)
        self.assertGreater(delta["tracking"], 0)

    def test_a_label_style_without_tracking_fails_loudly(self):
        with self.assertRaises(gen.TokenError):
            gen.emit_kotlin_label_type_style({"size": 11})

    def test_no_profile_hue_fails_loudly(self):
        with self.assertRaises(gen.TokenError):
            gen.emit_kotlin_profile_hues([])

    def test_surface2_is_not_the_warm_surface_alt(self):
        self.assertNotEqual(gen.read_surface2().upper(), "#F9F0E7")

    def test_border_strong_is_not_the_pale_semantic_border(self):
        self.assertNotEqual(gen.read_border_strong().upper(), "#EAECF0")

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


class TestSwiftTypography(unittest.TestCase):
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
        # As Compose keeps it; `lineSpacing` subtracts the size at the use site, not here.
        out = gen.emit_swift_type(self.style())
        self.assertIn("size: 16,", out)
        self.assertIn("lineHeight: 24,", out)
        self.assertIn("weight: 700,", out)

    def test_unitless_line_height_is_multiplied_out(self):
        self.assertIn("lineHeight: 22.4,", gen.emit_swift_type(self.style(lineHeight=1.4)))

    def test_negative_tracking_needs_no_parentheses(self):
        # Unlike the Compose emitter, where `-0.4.sp` does not parse.
        self.assertIn("tracking: -0.4", gen.emit_swift_type(self.style(letterSpacing="-0.4px")))

    def test_family_is_chosen_per_token_not_hardcoded(self):
        self.assertIn("family: body,", gen.emit_swift_type(self.style()))
        self.assertIn("family: display,", gen.emit_swift_type(self.style(fontFamily=["Epilogue", "DM Sans"])))

    def test_names_match_the_other_emitters(self):
        tokens = {"text-style": {"display-lg": self.style()["text-style"]["title"]}}
        self.assertIn("public var textStyleDisplayLg: SmileTextStyle {", gen.emit_swift_type(tokens))
        self.assertIn("val textStyleDisplayLg = TextStyle(", gen.emit_kotlin_type(tokens))

    def test_the_ramp_has_the_same_membership_as_the_compose_one(self):
        # The two files are the same stopgap; a style in one and not the other is the bug to catch.
        ds = design_system_or_skip(self)
        with io.open(os.path.join(ds, "dist", "json", "tokens.flat.json"), encoding="utf-8") as handle:
            light = json.load(handle)["light"]
        names = {gen.camel(path) for path, value in gen.walk(light) if gen.is_type_leaf(value)}
        swift = set(re.findall(r"public var ([A-Za-z0-9]+): SmileTextStyle", gen.emit_swift_type(light)))
        kotlin = set(re.findall(r"val ([A-Za-z0-9]+) = TextStyle\(", gen.emit_kotlin_type(light)))
        self.assertEqual(swift, names)
        self.assertEqual(swift, kotlin)


class TestSwiftStopgaps(unittest.TestCase):
    HUE = {
        "from": "#05723A", "to": "#0A9B4C", "cardIcon": "#05723A", "icon": "#05723A", "tile": "#E4F2EA",
        "stopStart": 0.13, "stopEnd": 0.87, "fromAlpha": 1.0, "toAlpha": 1.0,
    }

    def test_hex_becomes_the_vendored_color_initialiser(self):
        # `Color(hex:)` is declared in the vendored SmileTokens.swift, so nothing else has to exist.
        self.assertEqual(gen.swift_color("#e08600"), "Color(hex: 0xE08600)")

    def test_a_non_hex_value_is_rejected_rather_than_emitted(self):
        with self.assertRaises(gen.TokenError):
            gen.swift_color("rgba(5, 114, 58, 0.24)")

    def test_every_product_emits_all_five_roles(self):
        out = gen.emit_swift_product_hues({"smartSelfieEnrollment": self.HUE})
        self.assertIn('"smartSelfieEnrollment": SmileProductHue(', out)
        for role in ("from", "to", "cardIcon", "icon", "tile"):
            self.assertIn(f"{role}: Color(hex: 0x", out)

    def test_a_hue_missing_a_role_fails_loudly(self):
        with self.assertRaises(gen.TokenError):
            gen.emit_swift_product_hues({"biometricKyc": {"from": "#151F72", "to": "#2B3A9E"}})

    def test_soft_badge_fills_emit_every_feedback_role(self):
        out = gen.emit_swift_soft_badge_fills(gen.read_soft_badge_fills())
        for role in ("success", "info", "warning", "error"):
            self.assertIn(f'"{role}": SmileSoftBadgeFill(', out)

    def test_the_pairs_are_emitted_for_both_schemes(self):
        # Each of these shipped light-only once and produced a dark-mode defect.
        self.assertIn("smileOffBlackDark", gen.emit_swift_off_black(gen.read_off_black()))
        self.assertIn("smileNavBarDark", gen.emit_swift_nav_bar_fill(gen.read_nav_bar_fill()))
        self.assertIn("smileCardStrokeDark", gen.emit_swift_card_stroke(gen.read_card_stroke()))

    def test_a_pair_missing_its_dark_half_fails_loudly(self):
        with self.assertRaises(gen.TokenError):
            gen.emit_swift_off_black({"light": "#2D2B2A"})

    def test_profile_hues_keep_the_designs_order(self):
        out = gen.emit_swift_profile_hues(gen.read_profile_hues())
        self.assertIn("public let smileProfileHues: [Color] = [", out)
        self.assertEqual(out.count("Color(hex: 0x"), len(gen.read_profile_hues()))

    def test_both_platforms_generate_from_one_spec_entry(self):
        # The values, not the syntax: a divergence here means two apps disagree about a colour.
        # Compose bakes an opaque alpha into the literal, SwiftUI applies it at the use site.
        def swift(text):
            return set(re.findall(r"Color\(hex: 0x([0-9A-F]{6})\)", text))

        def kotlin(text):
            return set(re.findall(r"Color\(0xFF([0-9A-F]{6})\)", text))

        self.assertEqual(
            swift(gen.emit_swift_product_hues(gen.read_product_hues())),
            kotlin(gen.emit_kotlin_product_hues(gen.read_product_hues())),
        )
        self.assertEqual(
            swift(gen.emit_swift_soft_badge_fills(gen.read_soft_badge_fills())),
            kotlin(gen.emit_kotlin_soft_badge_fills(gen.read_soft_badge_fills())),
        )


class TestDartStopgaps(unittest.TestCase):
    HUE = {
        "from": "#05723A", "to": "#0A9B4C", "cardIcon": "#05723A", "icon": "#05723A", "tile": "#E4F2EA",
        "stopStart": 0.13, "stopEnd": 0.87, "fromAlpha": 1.0, "toAlpha": 1.0,
    }

    def test_hex_becomes_an_opaque_flutter_colour(self):
        self.assertEqual(gen.dart_hue_color("#e08600"), "Color(0xFFE08600)")

    def test_a_non_hex_value_is_rejected_rather_than_emitted(self):
        with self.assertRaises(gen.TokenError):
            gen.dart_hue_color("rgba(5, 114, 58, 0.24)")

    def test_a_metric_always_carries_a_decimal_point(self):
        # `const double x = 11;` is legal Dart but reads as an int; the emitter never leaves it ambiguous.
        self.assertEqual(gen.dart_double(11), "11.0")
        self.assertEqual(gen.dart_double(0.88), "0.88")
        self.assertEqual(gen.dart_double("-0.4"), "-0.4")

    def test_every_product_emits_all_five_roles(self):
        out = gen.emit_dart_product_hues({"smartSelfieEnrollment": self.HUE})
        self.assertIn("'smartSelfieEnrollment': SmileProductHue(", out)
        for role in ("from", "to", "cardIcon", "icon", "tile"):
            self.assertIn(f"{role}: Color(0xFF", out)

    def test_a_hue_missing_a_role_fails_loudly(self):
        with self.assertRaises(gen.TokenError):
            gen.emit_dart_product_hues({"biometricKyc": {"from": "#151F72", "to": "#2B3A9E"}})

    def test_soft_badge_fills_emit_every_feedback_role(self):
        out = gen.emit_dart_soft_badge_fills(gen.read_soft_badge_fills())
        for role in ("success", "info", "warning", "error"):
            self.assertIn(f"'{role}': SmileSoftBadgeFill(", out)

    def test_the_pairs_are_emitted_for_both_schemes(self):
        self.assertIn("smileOffBlackDark", gen.emit_dart_off_black(gen.read_off_black()))
        self.assertIn("smileNavBarDark", gen.emit_dart_nav_bar_fill(gen.read_nav_bar_fill()))
        self.assertIn("smileCardStrokeDark", gen.emit_dart_card_stroke(gen.read_card_stroke()))

    def test_a_pair_missing_its_dark_half_fails_loudly(self):
        with self.assertRaises(gen.TokenError):
            gen.emit_dart_off_black({"light": "#2D2B2A"})

    def test_profile_hues_keep_the_designs_order(self):
        out = gen.emit_dart_profile_hues(gen.read_profile_hues())
        self.assertIn("const List<Color> smileProfileHues = <Color>[", out)
        self.assertEqual(out.count("Color(0xFF"), len(gen.read_profile_hues()))

    def test_all_three_platforms_generate_the_same_hexes_from_one_spec_entry(self):
        # The values, not the syntax: a divergence here means the four apps disagree about a colour.
        def swift(text):
            return set(re.findall(r"Color\(hex: 0x([0-9A-F]{6})\)", text))

        def compose(text):
            return set(re.findall(r"Color\(0xFF([0-9A-F]{6})\)", text))

        for reader, emitters in (
            (gen.read_product_hues, (gen.emit_dart_product_hues, gen.emit_kotlin_product_hues, gen.emit_swift_product_hues)),
            (gen.read_soft_badge_fills, (gen.emit_dart_soft_badge_fills, gen.emit_kotlin_soft_badge_fills, gen.emit_swift_soft_badge_fills)),
        ):
            dart_emit, kotlin_emit, swift_emit = emitters
            ours = compose(dart_emit(reader()))
            self.assertTrue(ours, "parsed no colours out of the Dart emitter")
            self.assertEqual(ours, compose(kotlin_emit(reader())))
            self.assertEqual(ours, swift(swift_emit(reader())))

    def test_the_generated_file_declares_every_value_a_theme_needs(self):
        # Every name the hand-written Compose theme imports from the stopgap file must exist in Dart,
        # or the port silently falls back to a semantic token and the colour is quietly wrong.
        out = gen.generate_dart_product_hues()
        for name in (
            "smileProductHues", "smileSoftBadgeFills", "smileBorderStrong", "smileSurface2",
            "smileOffBlackLight", "smileOffBlackDark", "smileNavBarLight", "smileNavBarDark",
            "smileProfileHues", "smileTokenSessionGradient", "smileTokenRing",
            "smileLabelSize", "smileLabelTracking", "smileCardStrokeLight", "smileCardStrokeDark",
            "smileHeadingPageSize", "smileSectionHeaderSize",
        ):
            self.assertIn(name, out, f"{name} is missing from the generated Dart stopgaps")


class TestThemeParity(unittest.TestCase):
    """The two theme layers are hand-written, not generated, so nothing else holds them together.

    `docs/plan/port-patterns.md` treats a field resolving to a different token on one platform as a
    defect, and the failure is invisible: both apps compile and only the colour is wrong.
    """

    KOTLIN = "android/sample-ui/src/main/kotlin/com/usesmileid/sampleapps/ui/theme/UseSmileIDSampleColors.kt"
    SWIFT = "ios/SampleUI/Sources/SampleUI/Theme/UseSmileIDSampleColors.swift"

    MODES = (
        ("light", "internal val lightColors", "static let light = UseSmileIDSampleColors("),
        ("dark", "internal val darkColors", "static let dark = UseSmileIDSampleColors("),
    )

    def read(self, rel_path):
        with io.open(os.path.join(gen.REPO, rel_path), encoding="utf-8") as handle:
            return handle.read()

    def body(self, text, start, end):
        if start not in text:
            self.fail(f"{start!r} is gone; this test is comparing nothing")
        index = text.index(start)
        return text[index : text.index(end, index)]

    def scalars(self, body, sep):
        """The flat `field = SmileColorX.token` lines, keyed by field, valued by the token's leaf."""
        return {
            field: token.split(".")[-1]
            for field, token in re.findall(r"^[ ]{4}(\w+)%s ([\w.]+),?$" % sep, body, re.M)
        }

    def groups(self, body, sep):
        """The nested `field = XTokens( ... )` blocks, one dict of leaves per component group."""
        return {
            match.group(1): {
                field: token.split(".")[-1]
                for field, token in re.findall(r"^[ ]+(\w+)%s ([\w.]+),?$" % sep, match.group(2), re.M)
            }
            for match in re.finditer(
                r"^[ ]+(\w+)%s ?\w*Tokens\(\n(.*?)^[ ]+\),?$" % sep, body, re.M | re.S
            )
        }

    def test_every_field_resolves_to_the_same_token_on_both_platforms(self):
        kotlin, swift = self.read(self.KOTLIN), self.read(self.SWIFT)
        for mode, kotlin_start, swift_start in self.MODES:
            kotlin_body = self.body(kotlin, kotlin_start, "\n)")
            swift_body = self.body(swift, swift_start, "\n  )")

            ours = self.scalars(kotlin_body, " =")
            theirs = self.scalars(swift_body, ":")
            self.assertTrue(ours, f"parsed no {mode} fields from the Compose theme")
            self.assertEqual(ours, theirs, f"{mode} scalar colours differ between the two themes")

            ours = self.groups(kotlin_body, " =")
            theirs = self.groups(swift_body, ":")
            self.assertTrue(ours, f"parsed no {mode} component groups from the Compose theme")
            self.assertEqual(ours, theirs, f"{mode} component tokens differ between the two themes")

    def test_the_badge_group_is_generated_on_both_platforms(self):
        # Absent from both literals on purpose: the soft fills come from one spec entry, so the
        # comparison above would report the group missing rather than agreeing.
        self.assertIn("badge = softBadgeTokens()", self.read(self.KOTLIN))
        self.assertIn("badge: softBadgeTokens()", self.read(self.SWIFT))


if __name__ == "__main__":
    unittest.main(verbosity=2)
