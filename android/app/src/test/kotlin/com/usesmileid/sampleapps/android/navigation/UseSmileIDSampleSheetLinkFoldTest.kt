package com.usesmileid.sampleapps.android.navigation

import android.content.Intent
import androidx.core.net.toUri
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class UseSmileIDSampleSheetLinkFoldTest {

    @Test
    fun `a cold sheet link reaches the graph as its owner, with its query and the sheet kept`() {
        val intent = Intent(Intent.ACTION_VIEW, "${UseSmileIDSampleDeepLinks.NEW_PROFILE}?probes=true".toUri())

        intent.foldUseSmileIDSampleSheetLink()

        assertEquals("${UseSmileIDSampleDeepLinks.PROFILES}?probes=true", intent.data.toString())
        assertEquals(UseSmileIDSampleSheet.NewProfile, intent.pendingUseSmileIDSampleSheet())
    }

    @Test
    fun `any other link is left for the graph`() {
        val intent = Intent(Intent.ACTION_VIEW, UseSmileIDSampleDeepLinks.PROFILES.toUri())

        intent.foldUseSmileIDSampleSheetLink()

        assertEquals(UseSmileIDSampleDeepLinks.PROFILES, intent.data.toString())
        assertNull(intent.pendingUseSmileIDSampleSheet())
    }
}
