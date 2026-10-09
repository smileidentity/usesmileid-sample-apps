package com.usesmileid.sampleapps.ui.model

import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleJobStore
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Each chip lists its own status and no other; Processing has no chip, so only All lists it. */
class UseSmileIDSampleJobFilterTest {

    private val job = UseSmileIDSampleJobStore.fixtures(0L).first()

    @Test
    fun `each status is listed by its own chip and by All, and by no other chip`() {
        val chipsListing = UseSmileIDSampleStatus.entries.associateWith { status ->
            UseSmileIDSampleJobFilter.entries.filter { it.matches(job.copy(status = status)) }
        }
        assertEquals(
            mapOf(
                UseSmileIDSampleStatus.Clear to listOf(UseSmileIDSampleJobFilter.All, UseSmileIDSampleJobFilter.Clear),
                UseSmileIDSampleStatus.Attention to listOf(UseSmileIDSampleJobFilter.All, UseSmileIDSampleJobFilter.Attention),
                UseSmileIDSampleStatus.Blocked to listOf(UseSmileIDSampleJobFilter.All, UseSmileIDSampleJobFilter.Blocked),
                UseSmileIDSampleStatus.Error to listOf(UseSmileIDSampleJobFilter.All, UseSmileIDSampleJobFilter.Error),
                UseSmileIDSampleStatus.Processing to listOf(UseSmileIDSampleJobFilter.All),
            ),
            chipsListing,
        )
    }

    @Test
    fun `the chips are All then one per final status, in the order drawn`() {
        assertEquals(listOf("all", "clear", "attention", "blocked", "error"), UseSmileIDSampleJobFilter.entries.map { it.id })
        assertTrue(UseSmileIDSampleJobFilter.entries.none { it.status == UseSmileIDSampleStatus.Processing })
    }
}
