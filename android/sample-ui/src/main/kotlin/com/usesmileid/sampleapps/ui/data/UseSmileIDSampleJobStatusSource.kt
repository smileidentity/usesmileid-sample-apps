package com.usesmileid.sampleapps.ui.data

import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus

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

    /** No live session, so no credential to ask with. A precondition, not an error. */
    data object NoSession : UseSmileIDSampleStatusRefresh

    /** Never submitted under a scanned session, so there is no server-side job. */
    data object NoServerJob : UseSmileIDSampleStatusRefresh

    /** Submitted under a different token session, so this session's credential cannot ask about it. */
    data object SessionMismatch : UseSmileIDSampleStatusRefresh

    data class Failed(val reason: String) : UseSmileIDSampleStatusRefresh
}
