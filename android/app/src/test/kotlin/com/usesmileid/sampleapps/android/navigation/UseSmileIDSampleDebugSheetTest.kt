package com.usesmileid.sampleapps.android.navigation

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** A debug sheet opens only in a debug build that has an extension to draw it; a release build closes it at once. */
class UseSmileIDSampleDebugSheetTest {
    @Test
    fun a_debug_build_with_an_extension_opens_the_sheet() {
        assertTrue(debugSheetOpens(debugBuild = true, hasExtension = true))
    }

    @Test
    fun a_release_build_never_opens_it_even_with_an_extension() {
        assertFalse(debugSheetOpens(debugBuild = false, hasExtension = true))
    }

    @Test
    fun a_build_with_no_extension_has_nothing_to_draw() {
        assertFalse(debugSheetOpens(debugBuild = true, hasExtension = false))
        assertFalse(debugSheetOpens(debugBuild = false, hasExtension = false))
    }
}
