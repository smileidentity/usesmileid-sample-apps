package com.usesmileid.sampleapps.ui.model

import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleJobStore
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** A failed job is its own filter: the API's `error` is not a `block` verdict, so Blocked never lists it. */
class UseSmileIDSampleJobFilterTest {

    private val failed = UseSmileIDSampleJobStore.fixtures(0L).first().copy(status = UseSmileIDSampleStatus.Error)

    @Test
    fun `the error chip lists a failed job and the blocked chip does not`() {
        assertTrue(UseSmileIDSampleJobFilter.Error.matches(failed))
        assertFalse(UseSmileIDSampleJobFilter.Blocked.matches(failed))
        assertTrue(UseSmileIDSampleJobFilter.All.matches(failed))
    }

    @Test
    fun `every status has exactly one chip besides All`() {
        UseSmileIDSampleStatus.entries.filter { it != UseSmileIDSampleStatus.Processing }.forEach { status ->
            assertEquals(listOf(status), UseSmileIDSampleJobFilter.entries.mapNotNull { it.status }.filter { it == status })
        }
    }
}
