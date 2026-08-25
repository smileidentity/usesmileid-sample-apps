package com.usesmileid.sampleapps.ui

import com.usesmileid.sampleapps.ui.screens.useSmileIDSampleNavRows
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** A wrong URL is invisible until a partner taps it, so the rows are asserted against the spec. */
class UseSmileIDSampleSettingsLinksSpecTest {

    private val specLinks: Map<String, String> by lazy {
        val block = requireNotNull(LINKS_BLOCK.find(spec("screens.json"))) { "no links block in screens.json" }
        LINK.findAll(block.groupValues[1]).associate { it.groupValues[1] to it.groupValues[2] }
    }

    @Test
    fun spec_file_is_readable() {
        assertEquals(setOf("documentation", "support", "terms", "privacy", "licenses"), specLinks.keys)
    }

    @Test
    fun every_row_opens_the_url_the_spec_records() {
        val external = specLinks.filterValues { it.startsWith("https://") }
        assertEquals(external, useSmileIDSampleNavRows.mapNotNull { row -> row.url?.let { row.id to it } }.toMap())
    }

    @Test
    fun the_rows_are_the_five_the_spec_names() {
        assertEquals(specLinks.keys, useSmileIDSampleNavRows.map { it.id }.toSet())
    }

    /** Its notice ships in the binary, so it is the one row with nowhere external to go. */
    @Test
    fun the_licences_row_is_not_a_link() {
        assertNull(useSmileIDSampleNavRows.first { it.id == "licenses" }.url)
    }

    @Test
    fun the_documentation_row_says_the_host_it_opens() {
        val row = useSmileIDSampleNavRows.first { it.id == "documentation" }
        val host = requireNotNull(row.supportingText)
        assertTrue("'$host' is not the host of ${row.url}", row.url.orEmpty().contains(host))
    }

    private companion object {
        val LINKS_BLOCK = Regex("\"links\"\\s*:\\s*\\{([^}]*)\\}")
        val LINK = Regex("\"([a-z]+)\"\\s*:\\s*\"([^\"]+)\"")
    }
}
