package com.usesmileid.sampleapps.android.extension

import org.junit.Assert.assertNull
import org.junit.Test

/** A registry build carries no extension, so the public app behaves exactly as it ships. */
class UseSmileIDSampleShellExtensionTest {
    @Test
    fun a_registry_build_has_no_extension() {
        assertNull(useSmileIDSampleShellExtension)
    }
}
