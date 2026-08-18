package com.usesmileid.sampleapps.ui.state

import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJobs
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import org.junit.Assert.assertEquals
import org.junit.Test

class UseSmileIDSampleJobsTest {

    /** The list keys rows by job id, so a repeated result must not be able to add a second one. */
    @Test
    fun `adding the same job twice keeps one row`() {
        val jobs = UseSmileIDSampleJobs()
        jobs.add(job("job-1"))
        jobs.add(job("job-1"))
        assertEquals(1, jobs.all.size)
        assertEquals(1, jobs.all.count { it.id == "job-1" })
    }

    @Test
    fun `a new job lands first`() {
        val jobs = UseSmileIDSampleJobs()
        jobs.add(job("job-1"))
        jobs.add(job("job-2"))
        assertEquals(listOf("job-2", "job-1"), jobs.all.map { it.id })
    }

    private fun job(id: String) = UseSmileIDSampleJob(
        id = id,
        userId = "user-$id",
        product = UseSmileIDSampleProduct.SmartSelfieEnrollment,
        status = UseSmileIDSampleStatus.Processing,
        createdAtMillis = 0L,
        message = "Submitted",
        httpStatus = "202 Accepted",
    )
}
