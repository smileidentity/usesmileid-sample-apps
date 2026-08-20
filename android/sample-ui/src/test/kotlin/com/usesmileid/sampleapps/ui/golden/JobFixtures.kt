package com.usesmileid.sampleapps.ui.golden

import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct

/**
 * The eleven rows the design's counts describe. Test-only on purpose: the app itself seeds nothing,
 * because a persisted row is a claim that a verification was submitted, and eleven that never were
 * would sit among a partner's real ones for good.
 */
object JobFixtures {

    /** Offset from a caller-supplied now, so a golden groups the same way tomorrow. */
    fun jobs(nowMillis: Long): List<UseSmileIDSampleJob> {
        val statuses = listOf(
            UseSmileIDSampleStatus.Clear,
            UseSmileIDSampleStatus.Processing,
            UseSmileIDSampleStatus.Clear,
            UseSmileIDSampleStatus.Attention,
            UseSmileIDSampleStatus.Blocked,
            UseSmileIDSampleStatus.Clear,
            UseSmileIDSampleStatus.Clear,
            UseSmileIDSampleStatus.Attention,
            UseSmileIDSampleStatus.Blocked,
            UseSmileIDSampleStatus.Clear,
            UseSmileIDSampleStatus.Clear,
        )
        val products = UseSmileIDSampleProduct.entries
        return statuses.mapIndexed { index, status ->
            UseSmileIDSampleJob(
                id = "job_%02dky31za%02d".format(index, index * 7 % 100),
                userId = "user_%02dky31za%02d".format(index, index * 3 % 100),
                product = products[index % products.size],
                status = status,
                createdAtMillis = nowMillis - index * HOURS_APART * MILLIS_PER_HOUR,
                message = status.message(),
                httpStatus = if (status == UseSmileIDSampleStatus.Processing) "202 Accepted" else "200 OK",
            )
        }
    }

    private fun UseSmileIDSampleStatus.message() = when (this) {
        UseSmileIDSampleStatus.Clear -> "Approved"
        UseSmileIDSampleStatus.Attention -> "Provisional — needs review"
        UseSmileIDSampleStatus.Blocked -> "Rejected"
        UseSmileIDSampleStatus.Processing -> "Submitted, awaiting result"
    }

    private const val HOURS_APART = 5L
    private const val MILLIS_PER_HOUR = 60L * 60L * 1000L
}
