package com.usesmileid.sampleapps.ui

import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Validates [SampleTestIds] against `spec/test-ids.json`, which owns the ids.
 *
 * This is the cheapest test in the repo and the one that keeps four apps aligned: ids are a
 * contract device flows and golden tests key off, so a typo here breaks flows rather than this
 * build. Reading the spec at test time — rather than trusting the transcription — is what makes
 * the constants verifiable.
 *
 * The ids are extracted with a pattern rather than parsed: `org.json` is only a stub on the unit
 * test classpath, and pulling in a JSON library is a dependency that needs an explicit ask
 * (AGENTS.md → Definition of Done). The failure mode is safe — if the spec's shape ever changes
 * so the pattern stops matching, [spec_file_is_readable] fails outright instead of the
 * assertions passing vacuously.
 */
class SampleTestIdsSpecTest {

    private val specIds: Set<String> by lazy {
        val specDir = requireNotNull(System.getProperty("sampleapps.spec.dir")) {
            "sampleapps.spec.dir is not set; see sample-ui/build.gradle.kts"
        }
        val spec = File(specDir, "test-ids.json")
        assertTrue("spec/test-ids.json not found at ${spec.absolutePath}", spec.isFile)
        ID_PATTERN.findAll(spec.readText()).map { it.groupValues[1] }.toSet()
    }

    @Test
    fun spec_file_is_readable() {
        // test-ids.json declared 80+ ids when this was written; a shape change that broke the
        // extraction would show up here rather than as silently-empty assertions below.
        assertTrue("extracted only ${specIds.size} ids from the spec", specIds.size > 40)
    }

    @Test
    fun every_declared_id_exists_in_the_spec() {
        val unknown = SampleTestIds.all.filterNot { it in specIds }
        assertEquals("ids not present in spec/test-ids.json", emptyList<String>(), unknown)
    }

    @Test
    fun every_declared_id_carries_the_sample_prefix() {
        assertEquals(SampleTestIds.all, SampleTestIds.all.filter { it.startsWith("sample_") })
    }

    @Test
    fun the_declared_set_has_no_duplicates() {
        assertEquals(SampleTestIds.all.size, SampleTestIds.all.toSet().size)
    }

    private companion object {
        val ID_PATTERN = Regex("\"id\"\\s*:\\s*\"(sample_[A-Za-z0-9_]+)\"")
    }
}
