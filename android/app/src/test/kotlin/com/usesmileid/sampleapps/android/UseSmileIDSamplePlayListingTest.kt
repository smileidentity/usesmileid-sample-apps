package com.usesmileid.sampleapps.android

import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** The Play listing copy: Play truncates silently rather than rejecting, so the limits are asserted. */
class UseSmileIDSamplePlayListingTest {

    @Test
    fun `every listing field is within the limit Play enforces`() {
        val limits = mapOf(
            "title.txt" to 30,
            "short-description.txt" to 80,
            "full-description.txt" to 4000,
            "whatsnew/whatsnew-en-US" to 500,
        )
        for ((name, limit) in limits) {
            val text = listing(name)
            assertTrue(
                "$name is ${text.length} characters, over Play's limit of $limit",
                text.length <= limit,
            )
        }
    }

    @Test
    fun `the store title is the identity the spec settled`() {
        assertEquals("UseSmileID Sample", listing("title.txt"))
    }

    @Test
    fun `release notes carry no pull request number or internal shorthand`() {
        val notes = listing("whatsnew/whatsnew-en-US")
        for (pattern in listOf(Regex("""\(#\d+\)"""), Regex("""#\d{2,}"""), Regex("""\[\d{4}-\d{2}-\d{2}]"""))) {
            assertTrue("release notes contain $pattern: $notes", pattern.find(notes) == null)
        }
    }

    /** The no-special-access declaration is false the moment Simulate is gated. */
    @Test
    fun `nothing gates the scan sheet's Simulate wiring behind debug or probes`() {
        val source = File(specDir(), "../android/app/src/main/kotlin/com/usesmileid/sampleapps/android/navigation/TokenDestinations.kt")
        assertTrue("TokenDestinations.kt not found at ${source.absolutePath}", source.isFile)
        val text = source.readText()
        assertTrue("onSimulate is no longer wired in TokenDestinations.kt", text.contains("onSimulate"))
        for (gate in listOf("BuildConfig.DEBUG", "showProbes", "launchArgs.probes")) {
            assertTrue("TokenDestinations.kt now gates on $gate", !text.contains(gate))
        }
    }

    private fun specDir(): File = File(
        requireNotNull(System.getProperty("sampleapps.spec.dir")) {
            "sampleapps.spec.dir is not set; see app/build.gradle.kts"
        },
    )

    private fun listing(name: String): String {
        val file = File(specDir(), "../android/play/$name")
        assertTrue("listing copy not found at ${file.absolutePath}", file.isFile)
        return file.readText().trim()
    }
}
