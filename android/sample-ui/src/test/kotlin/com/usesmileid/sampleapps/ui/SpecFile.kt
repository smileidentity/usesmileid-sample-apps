package com.usesmileid.sampleapps.ui

import java.io.File
import org.junit.Assert.assertTrue

/**
 * Reads a file from `spec/`, the contract these tests validate the app against.
 *
 * Callers match with patterns rather than parsing, because `org.json` is only a stub on the unit
 * test classpath. Each caller therefore also asserts it extracted something, so a change to a
 * spec file's shape fails loudly instead of passing an empty comparison.
 */
internal fun spec(name: String): String {
    val dir = requireNotNull(System.getProperty("sampleapps.spec.dir")) {
        "sampleapps.spec.dir is not set; see sample-ui/build.gradle.kts"
    }
    val file = File(dir, name)
    assertTrue("spec/$name not found at ${file.absolutePath}", file.isFile)
    return file.readText()
}
