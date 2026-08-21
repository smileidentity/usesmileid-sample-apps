package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.saveable.SaverScope
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJobFilter
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** The holder's saveable policy: what survives recreation, and what a stale bundle restores to. */
class UseSmileIDSampleVerificationsScreenStateTest {

    @Test
    fun `a round trip through the saver keeps all three fields`() {
        val state = UseSmileIDSampleVerificationsScreenState(
            filter = UseSmileIDSampleJobFilter.Blocked,
            selectMode = true,
            selected = setOf("job-1", "job-2"),
        )
        val restored = requireNotNull(UseSmileIDSampleVerificationsScreenState.Saver.restore(savedFrom(state)))
        assertEquals(UseSmileIDSampleJobFilter.Blocked, restored.filter)
        assertTrue(restored.selectMode)
        assertEquals(setOf("job-1", "job-2"), restored.selected)
    }

    @Test
    fun `an unknown saved filter name restores as All`() {
        val saved = listOf("Gone", false, emptyList<String>())
        val restored = requireNotNull(UseSmileIDSampleVerificationsScreenState.Saver.restore(saved))
        assertEquals(UseSmileIDSampleJobFilter.All, restored.filter)
    }

    // Saving is a member extension on SaverScope, so both receivers have to be implicit. Every value
    // the holder writes is bundle-safe, so the scope allows all of them.
    private fun savedFrom(state: UseSmileIDSampleVerificationsScreenState): Any =
        with(UseSmileIDSampleVerificationsScreenState.Saver) {
            with(object : SaverScope { override fun canBeSaved(value: Any) = true }) {
                requireNotNull(save(state))
            }
        }
}
