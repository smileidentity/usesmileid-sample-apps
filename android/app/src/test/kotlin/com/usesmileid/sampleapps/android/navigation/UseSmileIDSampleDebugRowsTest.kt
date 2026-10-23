package com.usesmileid.sampleapps.android.navigation

import org.junit.Assert.assertEquals
import org.junit.Test

class UseSmileIDSampleDebugRowsTest {
    @Test
    fun the_extensions_leading_rows_come_before_network_logs_and_its_others_after() {
        assertEquals(
            listOf(
                UseSmileIDSampleDebugRowGroup.ExtensionLeading,
                UseSmileIDSampleDebugRowGroup.Shell,
                UseSmileIDSampleDebugRowGroup.Extension,
            ),
            useSmileIDSampleDebugRowOrder,
        )
    }
}
