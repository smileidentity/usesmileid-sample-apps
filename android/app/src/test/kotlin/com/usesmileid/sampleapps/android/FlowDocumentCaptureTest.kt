package com.usesmileid.sampleapps.android

import com.usesmileid.sampleapps.android.flow.capturesBothSides
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdType
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class FlowDocumentCaptureTest {

    @Test
    fun `a passport is captured front only`() {
        assertFalse(UseSmileIDSampleIdType.Passport.capturesBothSides)
    }

    @Test
    fun `every other document, and none chosen, is captured on both sides`() {
        UseSmileIDSampleIdType.entries.filter { it != UseSmileIDSampleIdType.Passport }.forEach {
            assertTrue(it.name, it.capturesBothSides)
        }
        assertTrue((null as UseSmileIDSampleIdType?).capturesBothSides)
    }
}
