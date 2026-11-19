package com.usesmileid.sampleapps.android.navigation

import com.usesmileid.sampleapps.android.extension.UseSmileIDSampleShellExtension
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** A debug sheet opens only in a debug build whose extension draws it; a release build, no extension or an unknown id closes it at once. */
class UseSmileIDSampleDebugSheetTest {
    private val extension = object : UseSmileIDSampleShellExtension {
        override fun hasDebugSheet(sheetId: String) = sheetId == "captureTimings"
    }

    @Test
    fun a_debug_build_opens_a_sheet_its_extension_draws() {
        assertTrue(debugSheetOpens(debugBuild = true, extension, "captureTimings"))
    }

    @Test
    fun a_release_build_never_opens_it() {
        assertFalse(debugSheetOpens(debugBuild = false, extension, "captureTimings"))
    }

    @Test
    fun an_id_the_extension_does_not_draw_closes() {
        assertFalse(debugSheetOpens(debugBuild = true, extension, "unknown"))
    }

    @Test
    fun a_build_with_no_extension_has_nothing_to_draw() {
        assertFalse(debugSheetOpens(debugBuild = true, extension = null, sheetId = "captureTimings"))
    }
}
