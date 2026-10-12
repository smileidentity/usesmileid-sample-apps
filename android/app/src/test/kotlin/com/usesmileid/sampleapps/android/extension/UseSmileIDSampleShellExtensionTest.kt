package com.usesmileid.sampleapps.android.extension

import com.usesmileid.sampleapps.android.BuildConfig
import org.junit.Assert.assertNull
import org.junit.Assume.assumeFalse
import org.junit.Test

class UseSmileIDSampleShellExtensionTest {
    @Test
    fun a_registry_build_has_no_extension() {
        assumeFalse("a source build carries its SDK repo's extension", BuildConfig.SOURCE_MODE)
        assertNull(useSmileIDSampleShellExtension)
    }
}
