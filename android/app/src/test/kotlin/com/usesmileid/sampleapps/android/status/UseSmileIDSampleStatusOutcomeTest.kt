package com.usesmileid.sampleapps.android.status

import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleStatusRefresh
import org.junit.Assert.assertEquals
import org.junit.Test

/** The branch table `GET /v3/status/{jobId}` is read through, with no I/O in the way. */
class UseSmileIDSampleStatusOutcomeTest {

    @Test
    fun `a terminal state is reported with the server's own message`() {
        listOf(
            "clear" to UseSmileIDSampleStatus.Clear,
            "attention" to UseSmileIDSampleStatus.Attention,
            "block" to UseSmileIDSampleStatus.Blocked,
        ).forEach { (apiStatus, expected) ->
            assertEquals(
                UseSmileIDSampleStatusRefresh.Updated(expected, "Decided", 200),
                statusOutcome(200, response(apiStatus, "Decided")),
            )
        }
    }

    /** The design draws four badges and the API has five states, so `error` shares Blocked deliberately. */
    @Test
    fun `error lands on blocked rather than inventing a badge`() {
        assertEquals(
            UseSmileIDSampleStatusRefresh.Updated(UseSmileIDSampleStatus.Blocked, "Upstream failed", 200),
            statusOutcome(200, response("error", "Upstream failed")),
        )
    }

    @Test
    fun `202 is still processing, not a change`() {
        assertEquals(
            UseSmileIDSampleStatusRefresh.StillProcessing,
            statusOutcome(202, response("processing", "Awaiting result")),
        )
    }

    /** A processing body is still processing whatever code carried it, so the body decides, not the code. */
    @Test
    fun `a processing body on a 200 is still processing`() {
        assertEquals(
            UseSmileIDSampleStatusRefresh.StillProcessing,
            statusOutcome(200, response("processing", "Awaiting result")),
        )
    }

    @Test
    fun `an error response has no body, and reports its code`() {
        assertEquals(UseSmileIDSampleStatusRefresh.Failed("HTTP 404"), statusOutcome(404, null))
        assertEquals(UseSmileIDSampleStatusRefresh.Failed("HTTP 401"), statusOutcome(401, null))
        assertEquals(UseSmileIDSampleStatusRefresh.Failed("HTTP 500"), statusOutcome(500, null))
    }

    /** A body on a non-2xx is still a failure: the code decides success, the body only decides which. */
    @Test
    fun `a body on a non-success code does not become an update`() {
        assertEquals(UseSmileIDSampleStatusRefresh.Failed("HTTP 400"), statusOutcome(400, response("clear", "no")))
    }

    /** A state added server-side must be named, not silently mapped onto a badge it does not mean. */
    @Test
    fun `an unrecognised status names itself`() {
        assertEquals(
            UseSmileIDSampleStatusRefresh.Failed("Unrecognised status 'quarantined'"),
            statusOutcome(200, response("quarantined", "New state")),
        )
    }

    @Test
    fun `a success code with no body is a failure, not an update`() {
        assertEquals(UseSmileIDSampleStatusRefresh.Failed("HTTP 200"), statusOutcome(200, null))
    }

    private fun response(status: String, message: String) = UseSmileIDSampleStatusResponse(
        status = status,
        jobId = "job_01m0fk6w3jep8bwkt8tazqz338",
        userId = "user_01m0fk6w3jep8bwkt8tazqz338",
        message = message,
        createdAt = "2026-08-21T09:00:00Z",
    )
}
