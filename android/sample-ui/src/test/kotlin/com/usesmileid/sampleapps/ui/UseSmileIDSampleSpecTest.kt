package com.usesmileid.sampleapps.ui

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class UseSmileIDSampleSpecTest {

    private val scenarios: String by lazy { spec("scenarios.json") }

    @Test
    fun flow_scenarios_match_the_spec() {
        val expected = idsOf(scenarios, kind = "flow")
        assertTrue("extracted no flow scenarios", expected.isNotEmpty())
        assertEquals(expected, UseSmileIDSampleScenario.entries.map { it.id })
    }

    @Test
    fun theme_scenarios_match_the_spec() {
        val expected = idsOf(scenarios, kind = "theme")
        assertTrue("extracted no theme scenarios", expected.isNotEmpty())
        assertEquals(expected, UseSmileIDSampleThemeScenario.entries.map { it.id })
    }

    @Test
    fun products_match_the_spec_in_design_order() {
        val expected = PRODUCT_ID.findAll(scenarios).map { it.groupValues[1] }.toList()
        assertTrue("extracted no products", expected.isNotEmpty())
        assertEquals(expected, UseSmileIDSampleProduct.entries.map { it.id })
    }

    /** Four platforms must abbreviate identically: "Enhanced Doc." and "Enh. Doc" are both reasonable. */
    @Test
    fun card_titles_and_families_match_the_spec() {
        val expected = CARD_RUNS.findAll(scenarios).map { it.groupValues[1] to it.groupValues[2] }.toList()
        assertTrue("extracted no card runs", expected.isNotEmpty())
        assertEquals(expected, UseSmileIDSampleProduct.entries.map { it.cardTitle to it.cardFamily })
    }

    /** The mark is one constant, so a card that stops carrying it fails here rather than on a device. */
    @Test
    fun the_smart_selfie_products_carry_the_mark() {
        assertEquals(
            listOf("smartSelfieEnrollment", "smartSelfieAuth"),
            UseSmileIDSampleProduct.entries
                .filter { it.cardFamily == UseSmileIDSampleMarks.SMART_SELFIE }
                .map { it.id },
        )
    }

    @Test
    fun the_captureless_product_is_the_one_the_spec_names() {
        assertEquals(
            listOf("enhancedKyc"),
            UseSmileIDSampleProduct.entries.filterNot { it.capture }.map { it.id },
        )
    }

    /** Scenario entries carry `"id"` then `"kind"`, so the pair is matched together rather than counted. */
    private fun idsOf(json: String, kind: String): List<String> =
        SCENARIO_ID_AND_KIND.findAll(json)
            .filter { it.groupValues[2] == kind }
            .map { it.groupValues[1] }
            .toList()

    private companion object {
        val SCENARIO_ID_AND_KIND =
            Regex("\"id\"\\s*:\\s*\"([A-Za-z]+)\"\\s*,\\s*\"kind\"\\s*:\\s*\"(flow|theme)\"")
        val PRODUCT_ID = Regex("\"id\"\\s*:\\s*\"([A-Za-z]+)\"\\s*,\\s*\"label\"\\s*:")
        val CARD_RUNS =
            Regex("\"cardTitle\"\\s*:\\s*\"([^\"]+)\"\\s*,\\s*\"cardFamily\"\\s*:\\s*\"([^\"]+)\"")
    }
}
