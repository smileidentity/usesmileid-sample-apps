package com.usesmileid.sampleapps.android.status

import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleJobStatusSource
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleJobStore
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleStatusRefresh
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import java.io.IOException
import kotlin.coroutines.cancellation.CancellationException

/** Retrofit stays in the shell: the library defines the seam, this adapter fills it. */
class RetrofitJobStatusSource : UseSmileIDSampleJobStatusSource {

    override suspend fun check(jobId: String, token: String, sandbox: Boolean): UseSmileIDSampleStatusRefresh {
        val response = UseSmileIDSampleStatusApi.of(sandbox).status(jobId, token)
        return statusOutcome(response.code(), response.body())
    }
}

/** Asks the server what became of one job and writes the answer to its row. Needs a live scanned session. */
suspend fun refreshStatus(
    jobId: String,
    /** The session the row itself was submitted under; null means there is nothing server-side. */
    rowSessionId: String?,
    session: UseSmileIDSampleTokenSession?,
    sandbox: Boolean,
    jobStore: UseSmileIDSampleJobStore,
    nowMillis: Long,
): UseSmileIDSampleStatusRefresh {
    if (rowSessionId == null) return UseSmileIDSampleStatusRefresh.NoServerJob
    val live = session?.takeUnless { it.hasExpired(nowMillis) } ?: return UseSmileIDSampleStatusRefresh.NoSession
    val outcome = try {
        RetrofitJobStatusSource().check(jobId, live.token, sandbox)
    } catch (e: IOException) {
        return UseSmileIDSampleStatusRefresh.Failed("Could not reach the server")
    } catch (e: CancellationException) {
        // Leaving mid-refresh stays a cancellation, not a reported failure.
        throw e
    } catch (e: Exception) {
        // The type, never the message: this text goes on screen and a client exception carries the request URL.
        return UseSmileIDSampleStatusRefresh.Failed("Unexpected error: ${e::class.simpleName}")
    }
    if (outcome !is UseSmileIDSampleStatusRefresh.Updated) return outcome
    // A row deleted mid-request has nothing to write to, and the list would contradict the claim.
    val written = jobStore.applyStatus(
        jobId = jobId,
        status = outcome.status,
        message = outcome.message,
        httpStatus = "${outcome.httpCode} ${outcome.status.httpReason()}",
    )
    return if (written) outcome else UseSmileIDSampleStatusRefresh.Failed("The verification is no longer stored")
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

private fun UseSmileIDSampleStatus.httpReason() = if (this == UseSmileIDSampleStatus.Processing) "Accepted" else "OK"

private const val PROCESSING = "processing"
private val HTTP_SUCCESS = 200..299
