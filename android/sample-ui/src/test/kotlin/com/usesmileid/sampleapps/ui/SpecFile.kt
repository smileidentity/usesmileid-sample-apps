package com.usesmileid.sampleapps.ui

import java.io.File
import org.junit.Assert.assertTrue

/** Callers match with patterns rather than parsing: `org.json` is only a stub on the test classpath. */
internal fun spec(name: String): String {
    val dir = requireNotNull(System.getProperty("sampleapps.spec.dir")) {
        "sampleapps.spec.dir is not set; see sample-ui/build.gradle.kts"
    }
    val file = File(dir, name)
    assertTrue("spec/$name not found at ${file.absolutePath}", file.isFile)
    return file.readText()
}
