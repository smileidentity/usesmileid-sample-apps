package com.usesmileid.sampleapps.ui.state

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleErrorAction
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleErrorMessage
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleErrorResolution
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleTransportFailure

/** The table in `spec/error-handling.json`: rows are tried in order and the first match wins. */
object UseSmileIDSampleErrorHandling {
    /** What a status or transport failure the table does not name resolves as. */
    private val requestInvalid = Resolution("requestInvalid", Message.CouldNotStart, Action.Exit)

    /** What a reason the table does not name resolves as. */
    private val notVerified = Resolution("notVerified", Message.NotVerified, Action.Exit)

    private val submissionRows = listOf(
        Row(
            Resolution("idNumberInvalid", Message.IdNumberInvalid, Action.FixInput),
            statuses = listOf(400),
            serverMessageContains = listOf("id number format", "id_number", "id_type"),
        ),
        Row(
            Resolution("callbackUrlMissing", Message.ServiceNotSetUp, Action.Exit),
            statuses = listOf(400),
            serverMessageContains = listOf("callback"),
        ),
        Row(requestInvalid, statuses = listOf(400)),
        Row(Resolution("sessionExpired", Message.SessionExpired, Action.NewSession), statuses = listOf(401)),
        Row(Resolution("insufficientBalance", Message.ServiceUnavailable, Action.Exit), statuses = listOf(402)),
        Row(
            Resolution("sdkVersionNotAllowed", Message.UpdateApp, Action.Exit),
            statuses = listOf(403),
            serverMessageContains = listOf("sdk version"),
        ),
        Row(Resolution("notEnabled", Message.NotAvailable, Action.Exit), statuses = listOf(403)),
        Row(Resolution("notFound", Message.NotFound, Action.Exit), statuses = listOf(404)),
        Row(Resolution("alreadyStarted", Message.AlreadyStarted, Action.NewSession), statuses = listOf(409)),
        Row(Resolution("linkExpired", Message.LinkExpired, Action.Exit), statuses = listOf(410)),
        Row(Resolution("payloadTooLarge", Message.PhotosTooLarge, Action.Recapture), statuses = listOf(413)),
        Row(Resolution("wrongContentType", Message.CouldNotStart, Action.Exit), statuses = listOf(415)),
        Row(Resolution("tokenPayloadInvalid", Message.SessionExpired, Action.NewSession), statuses = listOf(422)),
        Row(Resolution("rateLimited", Message.TooManyAttempts, Action.Retry, backoffSeconds = listOf(30), maxUses = 1), statuses = listOf(429)),
        Row(
            Resolution("serverError", Message.Server, Action.Retry, backoffSeconds = listOf(5, 15, 30), maxUses = 3),
            statuses = listOf(500, 502, 503, 504),
        ),
        Row(
            Resolution("noConnection", Message.NoConnection, Action.Retry, waitsForConnection = true),
            transport = UseSmileIDSampleTransportFailure.NoConnection,
        ),
        Row(Resolution("timeout", Message.Timeout, Action.Retry, backoffSeconds = listOf(5)), transport = UseSmileIDSampleTransportFailure.Timeout),
    )

    private val resultRows = listOf(
        Row(
            Resolution("idAuthorityPhotoUnavailable", Message.FaceCheckUnavailable, Action.Exit),
            reasons = listOf("image_unavailable_or_invalid"),
            serverMessageContains = listOf("id authority photo not available"),
        ),
        Row(
            Resolution("noEnrolledSelfie", Message.NoSavedSelfie, Action.Exit),
            reasons = listOf("image_unavailable_or_invalid"),
            serverMessageContains = listOf("no enrolled selfie found"),
        ),
        Row(Resolution("photoUnusable", Message.PhotoUnusable, Action.Recapture), reasons = listOf("image_unavailable_or_invalid")),
        Row(Resolution("contentPolicyViolated", Message.PhotoRejected, Action.Recapture), reasons = listOf("content_policy_violated")),
        Row(Resolution("documentUnclassifiable", Message.DocumentNotRecognised, Action.Recapture), reasons = listOf("document_unclassifiable")),
        Row(Resolution("invalidIdNumber", Message.IdNumberNotAccepted, Action.FixInput), reasons = listOf("invalid_id_number")),
        Row(
            Resolution("serviceUnavailable", Message.IdServiceDown, Action.RetryLater, backoffSeconds = listOf(30), maxUses = 1),
            reasons = listOf("service_unavailable"),
        ),
        Row(
            Resolution("internalError", Message.CouldNotFinish, Action.Retry, backoffSeconds = listOf(5), maxUses = 1),
            reasons = listOf("internal_error"),
        ),
        Row(
            notVerified,
            reasons = listOf(
                "spoof_detected", "face_verification_failed", "document_check_failed", "age_requirement_not_met", "account_locked",
                "account_locked_fraud", "high_risk", "medium_risk", "identifier_not_found",
            ),
        ),
    )

    /** Every submission row's resolution, in the table's order. */
    val submission: List<UseSmileIDSampleErrorResolution> = submissionRows.map { it.resolution }

    /** Every result row's resolution, in the table's order. */
    val result: List<UseSmileIDSampleErrorResolution> = resultRows.map { it.resolution }

    /** The row a submission the table does not name resolves as. */
    val submissionFallback: UseSmileIDSampleErrorResolution get() = requestInvalid

    /** The row a saved [id] names; null for none, or for one this build no longer has. */
    fun resolution(id: String?): UseSmileIDSampleErrorResolution? = (submission + result).firstOrNull { it.id == id }

    /** A submission the server refused with [status]; [serverMessage] only tells rows apart and is never shown. */
    fun forStatus(status: Int, serverMessage: String? = null): UseSmileIDSampleErrorResolution =
        submissionRows.firstOrNull { status in it.statuses && it.accepts(serverMessage) }?.resolution ?: requestInvalid

    /** A submission the server never answered. */
    fun forTransport(failure: UseSmileIDSampleTransportFailure): UseSmileIDSampleErrorResolution =
        submissionRows.firstOrNull { it.transport == failure }?.resolution ?: requestInvalid

    /** An accepted job that ended in `error` or `block` with [reason]; none, or one the table does not name, is never explained. */
    fun forReason(reason: String?, serverMessage: String? = null): UseSmileIDSampleErrorResolution =
        resultRows.firstOrNull { reason in it.reasons && it.accepts(serverMessage) }?.resolution ?: notVerified
}

private typealias Resolution = UseSmileIDSampleErrorResolution

private typealias Message = UseSmileIDSampleErrorMessage

private typealias Action = UseSmileIDSampleErrorAction

/** One row: a resolution and what a failure must carry to match it. */
private class Row(
    val resolution: UseSmileIDSampleErrorResolution,
    val statuses: List<Int> = emptyList(),
    val transport: UseSmileIDSampleTransportFailure? = null,
    val reasons: List<String> = emptyList(),
    val serverMessageContains: List<String> = emptyList(),
) {
    fun accepts(serverMessage: String?): Boolean =
        serverMessageContains.isEmpty() || serverMessageContains.any { serverMessage.orEmpty().contains(it, ignoreCase = true) }
}
