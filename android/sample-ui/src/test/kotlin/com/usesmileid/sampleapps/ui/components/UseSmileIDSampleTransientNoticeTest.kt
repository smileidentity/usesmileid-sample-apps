package com.usesmileid.sampleapps.ui.components

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** The one state shape behind every bottom-center confirmation. */
class UseSmileIDSampleTransientNoticeTest {

    @Test
    fun `showing carries the message and dismissing clears it`() {
        val state = UseSmileIDSampleTransientNoticeState()
        assertNull(state.current)

        state.show("Verification removed")

        assertEquals("Verification removed", state.current?.message)
        assertEquals(1, state.showToken)

        state.dismiss()

        assertNull(state.current)
    }

    @Test
    fun `the same message shown twice still restarts the window`() {
        val state = UseSmileIDSampleTransientNoticeState()

        state.show("Still processing")
        val first = state.showToken
        state.show("Still processing")

        assertEquals(first + 1, state.showToken)
    }

    @Test
    fun `the stored action is the caller's, and running it does not clear the notice itself`() {
        val state = UseSmileIDSampleTransientNoticeState()
        var undone = false

        state.show("Verification removed", actionLabel = "Undo", onAction = { undone = true })
        state.current?.onAction?.invoke()

        assertTrue(undone)
        assertEquals("Undo", state.current?.actionLabel)

        state.dismiss()

        assertNull(state.current)
    }
}
