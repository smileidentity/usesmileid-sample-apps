package com.usesmileid.sampleapps.ui

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class UseSmileIDSampleTestIdsSpecTest {

    private val specIds: Set<String> by lazy {
        ID_PATTERN.findAll(spec("test-ids.json")).map { it.groupValues[1] }.toSet()
    }

    @Test
    fun spec_file_is_readable() {
        assertTrue("extracted only ${specIds.size} ids from the spec", specIds.size > 40)
    }

    @Test
    fun every_declared_id_exists_in_the_spec() {
        val unknown = UseSmileIDSampleTestIds.all.filterNot { it in specIds }
        assertEquals("ids not present in spec/test-ids.json", emptyList<String>(), unknown)
    }

    // The direction an omission fails: every spec id is declared here, or excused with its reason.
    @Test
    fun every_spec_id_is_declared_or_excused() {
        val excused = mapOf(
            "sample_home_start_fullscreen" to "no app implements the shell start ids yet",
            "sample_home_start_shell" to "no app implements the shell start ids yet",
        )
        val declared = UseSmileIDSampleTestIds.all.toSet() + with(UseSmileIDSampleTestIds) {
            listOf(
                productCard("x"), tokenEnvironment("x"), settingNav("x"), licenseRow("x"), licenseText("x"),
                licenseLink("x"), scenarioItem("x"), themeItem("x"), filterChip("x"), filterCount("x"),
                jobRow(0).replace("_0", "_x"), selectionCheckbox(0).replace("_0", "_x"), detailField("x"),
                detailCopy("x"), userDetailsField("x"), countryOption("x"), idTypeOption("x"), profileRow("x"),
                profileConfigField("x"),
            ).map { it.removeSuffix("_x") }
        }
        assertEquals("spec ids nothing declares", emptyList<String>(), specIds.filterNot { it in declared || it in excused })
        // An excuse that stops being true has to go, or it hides the next omission.
        assertEquals("excused ids now declared", emptyList<String>(), excused.keys.filter { it in declared })
    }

    @Test
    fun every_declared_id_carries_the_sample_prefix() {
        assertEquals(UseSmileIDSampleTestIds.all, UseSmileIDSampleTestIds.all.filter { it.startsWith("sample_") })
    }

    @Test
    fun the_declared_set_has_no_duplicates() {
        assertEquals(UseSmileIDSampleTestIds.all.size, UseSmileIDSampleTestIds.all.toSet().size)
    }

    private companion object {
        val ID_PATTERN = Regex("\"id\"\\s*:\\s*\"(sample_[A-Za-z0-9_]+)\"")
    }
}
