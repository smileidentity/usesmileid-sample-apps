package com.usesmileid.sampleapps.android.status

import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleJobStore
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import java.io.IOException
import kotlin.coroutines.cancellation.CancellationException

/** What a refresh did, so the screen can say so rather than silently re-render the same row. */
sealed interface UseSmileIDSampleStatusRefresh {
    data class Updated(val status: UseSmileIDSampleStatus, val message: String) : UseSmileIDSampleStatusRefresh

    /** 202: the verification is real and still running. The row already says Processing. */
    data object StillProcessing : UseSmileIDSampleStatusRefresh

    /** No live scanned session, so there is no credential to ask with. Not an error — a precondition. */
    data object NoSession : UseSmileIDSampleStatusRefresh

    /** The row was never submitted under a scanned session, so no server-side job exists to ask about. */
    data object NoServerJob : UseSmileIDSampleStatusRefresh

    data class Failed(val reason: String) : UseSmileIDSampleStatusRefresh
}

/**
 * Asks the server what became of one job and writes the answer to its row.
 *
 * Gated on the **currently scanned session**: the call needs a real `SmileID-Token`, and the only one
 * the sample holds is the token a scan linked. The caller also checks the row's own `sessionId` — a
 * job that was never submitted under a real session has nothing server-side to ask about, and asking
 * anyway spends a request to be told 404.
 */
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
        // The offline case is the one a partner will actually hit, and it is a state, not a no-op.
        return UseSmileIDSampleStatusRefresh.Failed(e.message ?: "Network unavailable")
    } catch (e: CancellationException) {
        // Leaving the screen mid-refresh must stay a cancellation, not become a reported failure.
        throw e
    } catch (e: Exception) {
        // A body the decoder cannot read throws SerializationException, not IOException, and this runs
        // in the screen's own scope — uncaught, it took the app down rather than reporting anything.
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

/**
 * The API's five terminal states onto the four the design draws. `error` has no badge of its own, so
 * it lands on Blocked and relies on the server's own message to say why — a fifth badge is a design
 * question, not something to invent here.
 */
private fun String.toSampleStatus(): UseSmileIDSampleStatus? = when (this) {
    "clear" -> UseSmileIDSampleStatus.Clear
    "attention" -> UseSmileIDSampleStatus.Attention
    "block", "error" -> UseSmileIDSampleStatus.Blocked
    else -> null
}

private fun UseSmileIDSampleStatus.httpReason() = if (this == UseSmileIDSampleStatus.Processing) "Accepted" else "OK"

private const val PROCESSING = "processing"
