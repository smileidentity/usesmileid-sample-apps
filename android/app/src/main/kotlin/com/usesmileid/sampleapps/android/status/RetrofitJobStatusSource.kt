package com.usesmileid.sampleapps.android.status

import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleJobStatusSource
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleStatusRefresh

/** Retrofit stays in the shell: the library defines the seam, this adapter fills it. */
class RetrofitJobStatusSource : UseSmileIDSampleJobStatusSource {

    override suspend fun check(jobId: String, token: String, sandbox: Boolean): UseSmileIDSampleStatusRefresh {
        val response = UseSmileIDSampleStatusApi.of(sandbox).status(jobId, token)
        return statusOutcome(response.code(), response.body())
    }
}

/** The HTTP code and body onto an outcome. Pure, so the branch table is unit-testable. */
internal fun statusOutcome(code: Int, body: UseSmileIDSampleStatusResponse?): UseSmileIDSampleStatusRefresh = when {
    body == null || code !in HTTP_SUCCESS -> UseSmileIDSampleStatusRefresh.Failed("HTTP $code")
    body.status == PROCESSING -> UseSmileIDSampleStatusRefresh.StillProcessing
    else -> body.status.toSampleStatus()?.let { UseSmileIDSampleStatusRefresh.Updated(it, body.message, code) }
        ?: UseSmileIDSampleStatusRefresh.Failed("Unrecognised status '${body.status}'")
}

/** Five API states onto the four badges the design draws: `error` lands on Blocked and leans on the server's message. */
private fun String.toSampleStatus(): UseSmileIDSampleStatus? = when (this) {
    "clear" -> UseSmileIDSampleStatus.Clear
    "attention" -> UseSmileIDSampleStatus.Attention
    "block", "error" -> UseSmileIDSampleStatus.Blocked
    else -> null
}

private const val PROCESSING = "processing"
private val HTTP_SUCCESS = 200..299
