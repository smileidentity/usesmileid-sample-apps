package com.usesmileid.sampleapps.ui

import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Asserts the ids this module attaches are exactly the ones `spec/test-ids.json` declares.
 *
 * The ids are extracted with a pattern rather than parsed, because `org.json` is only a stub on the
 * unit test classpath. A change to the file's shape therefore fails [spec_file_is_readable] rather
 * than passing the rest of this class vacuously.
 */
class UseSmileIDSampleTestIdsSpecTest {

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
        assertTrue("extracted only ${specIds.size} ids from the spec", specIds.size > 40)
    }

    @Test
    fun every_declared_id_exists_in_the_spec() {
        val unknown = UseSmileIDSampleTestIds.all.filterNot { it in specIds }
        assertEquals("ids not present in spec/test-ids.json", emptyList<String>(), unknown)
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
