package com.usesmileid.sampleapps.ui

import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** The other direction of the id contract: a declared id has to reach a view, not only the spec. */
class UseSmileIDSampleTestIdUsageTest {

    @Test
    fun every_declared_id_is_attached_somewhere() {
        val android = File(requireNotNull(System.getProperty("sampleapps.spec.dir"))).resolveSibling("android")
        val declarations = android.resolve("sample-ui/src/main/kotlin/com/usesmileid/sampleapps/ui/UseSmileIDSampleTestIds.kt")
        val declared = DECLARATION.findAll(declarations.readText()).map { it.groupValues[1].ifEmpty { it.groupValues[2] } }.toSet()
        assertTrue("parsed only ${declared.size} declarations", declared.size > 40)

        // Both modules: a sheet's id is supplied by the shell destination that presents it.
        val callers = listOf("sample-ui/src/main", "app/src/main")
            .flatMap { android.resolve(it).walk().filter { file -> file.extension == "kt" && file != declarations } }
            .joinToString("\n") { it.readText() }

        val unattached = declared.filterNot { Regex("""\bUseSmileIDSampleTestIds\.$it\b""").containsMatchIn(callers) }.sorted()
        assertEquals("declared, specified and attached to nothing", emptyList<String>(), unattached)
    }

    private companion object {
        val DECLARATION = Regex("""const val (\w+)|\bfun (\w+)\(""")
    }
}
