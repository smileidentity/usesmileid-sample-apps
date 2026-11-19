package com.usesmileid.sampleapps.ui.model

import androidx.compose.runtime.Immutable

/** What a failed verification offers the user, with its button's key in `spec/l10n/app/`; a null [maxUses] is no limit. */
enum class UseSmileIDSampleErrorAction(val id: String, val buttonKey: String, val maxUses: Int? = null) {
    Retry("retry", "common_try_again"),
    RetryLater("retryLater", "common_try_again"),
    Recapture("recapture", "error_action_retake_photo", maxUses = 3),
    FixInput("fixInput", "error_action_edit_id_number"),
    NewSession("newSession", "error_action_start_again", maxUses = 1),
    Exit("exit", "error_action_close"),
}

/** The message a failure shows, by its key in `spec/l10n/app/`. */
enum class UseSmileIDSampleErrorMessage(val key: String) {
    CouldNotStart("error_could_not_start"),
    EndedEarly("error_ended_early"),
    IdNumberInvalid("error_id_number_invalid"),
    ServiceNotSetUp("error_service_not_set_up"),
    SessionExpired("error_session_expired"),
    ServiceUnavailable("error_service_unavailable"),
    NotAvailable("error_not_available"),
    UpdateApp("error_update_app"),
    NotFound("error_not_found"),
    AlreadyStarted("error_already_started"),
    LinkExpired("error_link_expired"),
    PhotosTooLarge("error_photos_too_large"),
    TooManyAttempts("error_too_many_attempts"),
    Server("error_server"),
    NoConnection("error_no_connection"),
    Timeout("error_timeout"),
    PhotoUnusable("error_photo_unusable"),
    PhotoRejected("error_photo_rejected"),
    DocumentNotRecognised("error_document_not_recognised"),
    FaceCheckUnavailable("error_face_check_unavailable"),
    NoSavedSelfie("error_no_saved_selfie"),
    IdNumberNotAccepted("error_id_number_not_accepted"),
    IdServiceDown("error_id_service_down"),
    CouldNotFinish("error_could_not_finish"),
    NotVerified("error_not_verified"),
}

/** A submission the server never answered. */
enum class UseSmileIDSampleTransportFailure(val id: String) {
    NoConnection("noConnection"),
    Timeout("timeout"),
}

/** What a failure resolves to: the message to show and the one action to offer. */
@Immutable
data class UseSmileIDSampleErrorResolution(
    val id: String,
    val message: UseSmileIDSampleErrorMessage,
    val action: UseSmileIDSampleErrorAction,
    /** How long the button stays dimmed before each use, in order. */
    val backoffSeconds: List<Int> = emptyList(),
    /** How many times the action is offered before Close replaces it; null is no limit. */
    val maxUses: Int? = action.maxUses,
    /** Whether the button also stays dimmed while the device is offline. */
    val waitsForConnection: Boolean = false,
)
