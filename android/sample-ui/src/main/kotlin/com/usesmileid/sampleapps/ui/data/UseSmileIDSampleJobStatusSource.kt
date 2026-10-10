package com.usesmileid.sampleapps.ui.data

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleStatus

/** The one network call the app owns, behind a seam so the refresh orchestration tests off-device. */
interface UseSmileIDSampleJobStatusSource {

    /**
     * Asks the server what became of one job. Implementations map the HTTP exchange onto the
     * sealed outcome and let transport failures ([java.io.IOException]) propagate — the store
     * owns turning them into a reported outcome.
     */
    suspend fun check(jobId: String, token: String, sandbox: Boolean): UseSmileIDSampleStatusRefresh
}

/** What a refresh did, so the screen can say so. */
sealed interface UseSmileIDSampleStatusRefresh {
    data class Updated(
        val status: UseSmileIDSampleStatus,
        val message: String,
        val httpCode: Int,
    ) : UseSmileIDSampleStatusRefresh

    /** 202 — still running; the row already says Processing. */
    data object StillProcessing : UseSmileIDSampleStatusRefresh

    /** 404 — the server has no state for the job yet. The store reads it as still processing while the job is new, and as a failure after that. */
    data object NotRecorded : UseSmileIDSampleStatusRefresh

    /** No live session, so no credential to ask with. A precondition, not an error. */
    data object NoSession : UseSmileIDSampleStatusRefresh

    /** Never submitted under a scanned session, so there is no server-side job. */
    data object NoServerJob : UseSmileIDSampleStatusRefresh

    /** Submitted by a different partner, so this session's credential is for another account. */
    data object PartnerMismatch : UseSmileIDSampleStatusRefresh

    data class Failed(val reason: Reason) : UseSmileIDSampleStatusRefresh {
        /** A server's own wording, such as an HTTP code, which is shown as it came. */
        constructor(detail: String) : this(Reason.Detail(detail))
    }

    /** Why a refresh failed, worded where it is shown so it follows the app's language. */
    sealed interface Reason {
        data object NotStored : Reason
        data object Unreachable : Reason

        /** The exception's type, never its message: a client exception carries the request URL. */
        data class Unexpected(val type: String) : Reason
        data class Detail(val text: String) : Reason
    }
}
