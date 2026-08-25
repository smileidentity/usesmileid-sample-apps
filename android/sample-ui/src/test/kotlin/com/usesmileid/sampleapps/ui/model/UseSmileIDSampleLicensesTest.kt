package com.usesmileid.sampleapps.ui.model

import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class UseSmileIDSampleLicensesTest {

    private val notices by lazy { parseUseSmileIDSampleLicenses(asset()) }

    @Test
    fun the_shipped_notices_parse() {
        assertFalse("the generated asset produced nothing", notices.isEmpty)
        assertTrue("expected the SDK's whole transitive set", notices.openSource.size > 50)
    }

    @Test
    fun every_component_carries_a_version_and_a_licence() {
        val incomplete = (notices.openSource + notices.googleServices)
            .filter { it.version.isBlank() || it.licenses.isEmpty() }
            .map { it.artifact }
        assertEquals(emptyList<String>(), incomplete)
    }

    @Test
    fun nothing_is_listed_as_unknown() {
        val named = (notices.openSource + notices.googleServices)
            .flatMap { it.licenses }
            .map { it.name.lowercase() }
        assertFalse("unknown", named.any { it.contains("unknown") || it.isBlank() })
    }

    @Test
    fun the_apache_text_ships_with_the_app() {
        val apache = requireNotNull(notices.texts["Apache-2.0"]) { "no Apache-2.0 text bundled" }
        assertTrue(apache.contains("TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION"))
        assertTrue(apache.contains("Version 2.0, January 2004"))
    }

    @Test
    fun every_open_source_component_resolves_to_a_text_or_to_a_link() {
        val stranded = notices.openSource.filter { notice ->
            notice.licenses.none { it.id != null && notice.textOrNull() != null || it.url.isNotBlank() }
        }
        assertEquals(emptyList<String>(), stranded.map { it.artifact })
    }

    @Test
    fun the_google_artifacts_are_listed_separately_and_carry_no_text() {
        assertTrue("expected the ML Kit and Play artifacts", notices.googleServices.isNotEmpty())
        notices.googleServices.forEach { notice ->
            notice.licenses.forEach { assertNull("${notice.artifact} claims a bundled text", it.id) }
        }
        val open = notices.openSource.map { it.artifact }
        assertFalse(open.any { it.startsWith("com.google.mlkit") })
    }

    @Test
    fun the_sdk_itself_is_absent() {
        val all = (notices.openSource + notices.googleServices).map { it.artifact }
        assertEquals(emptyList<String>(), all.filter { it.startsWith("com.usesmileid") })
    }

    @Test
    fun a_malformed_asset_reads_as_no_notices_rather_than_crashing() {
        assertTrue(parseUseSmileIDSampleLicenses("{ not json").isEmpty)
        assertTrue(parseUseSmileIDSampleLicenses("").isEmpty)
    }

    private fun UseSmileIDSampleNotice.textOrNull(): String? =
        licenses.firstNotNullOfOrNull { notices.texts[it.id] }

    private fun asset(): String {
        // Read from the module rather than through AssetManager, which would need Robolectric.
        val file = File("src/main/assets/licenses.json")
        assertTrue("generated notices missing at ${file.absolutePath}", file.isFile)
        return file.readText()
    }
}
