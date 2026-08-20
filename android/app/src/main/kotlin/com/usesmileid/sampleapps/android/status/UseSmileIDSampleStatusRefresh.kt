package com.usesmileid.sampleapps.android.status

import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleJobStore
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import java.io.IOException
import kotlin.coroutines.cancellation.CancellationException

/** What a refresh did, so the screen can say so. */
sealed interface UseSmileIDSampleStatusRefresh {
    data class Updated(val status: UseSmileIDSampleStatus, val message: String) : UseSmileIDSampleStatusRefresh

    /** 202 — still running; the row already says Processing. */
    data object StillProcessing : UseSmileIDSampleStatusRefresh

    /** No live session, so no credential to ask with. A precondition, not an error. */
    data object NoSession : UseSmileIDSampleStatusRefresh

    /** Never submitted under a scanned session, so there is no server-side job. */
    data object NoServerJob : UseSmileIDSampleStatusRefresh

    data class Failed(val reason: String) : UseSmileIDSampleStatusRefresh
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
    val response = try {
        UseSmileIDSampleStatusApi.of(sandbox).status(jobId, live.token)
    } catch (e: IOException) {
        return UseSmileIDSampleStatusRefresh.Failed(e.message ?: "Network unavailable")
    } catch (e: CancellationException) {
        // Leaving mid-refresh stays a cancellation, not a reported failure.
        throw e
    } catch (e: Exception) {
        // An undecodable body throws SerializationException, not IOException, and this runs in the screen's scope.
        return UseSmileIDSampleStatusRefresh.Failed(e.message ?: e::class.simpleName.orEmpty())
    }
    val body = response.body()
    if (!response.isSuccessful || body == null) {
        return UseSmileIDSampleStatusRefresh.Failed("HTTP ${response.code()}")
    }
    if (body.status == PROCESSING) return UseSmileIDSampleStatusRefresh.StillProcessing
    val status = body.status.toSampleStatus()
        ?: return UseSmileIDSampleStatusRefresh.Failed("Unrecognised status '${body.status}'")
    jobStore.applyStatus(
        jobId = jobId,
        status = status,
        message = body.message,
        httpStatus = "${response.code()} ${status.httpReason()}",
    )
    return UseSmileIDSampleStatusRefresh.Updated(status, body.message)
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
