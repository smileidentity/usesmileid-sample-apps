package com.usesmileid.sampleapps.android.flow

import com.usesmileid.core.exception.UseSmileIDValidationException
import com.usesmileid.presentation.flow.dsl.UseSmileIDFlowBuilder
import com.usesmileid.presentation.flow.validation.ValidationState
import com.usesmileid.sampleapps.ui.state.userDetailsRequirement

/** §7.3's entry gate: the SDK's non-throwing pre-flight plus its per-payload validators. */
fun preflight(snapshot: FlowLaunchSnapshot): FlowPreflight {
    // Ahead of the payloads, because no form fixes a session that has run out (TOK-A5).
    if (snapshot.sessionExpired) return FlowPreflight.NeedsSession
    val builder = UseSmileIDFlowBuilder().apply { applying(snapshot) }
    // A form can fix what the user typed but not how the host built the flow, and §7.3 redirects only the first.
    val requirement = snapshot.liveSession?.bindings.userDetailsRequirement()
    val payloadChecks = buildList {
        // The SDK still does the validating — its overload that takes a token payload is not public API
        // at 12.0.2, so the bindings are subtracted from what it reports instead.
        builder.userDetails?.let { add(builder.validateUserDetails(it).minus(requirement)) }
        builder.biometricKYCParams?.let { add(builder.validateBiometricKYCParams(it)) }
        builder.enhancedKYCParams?.let { add(builder.validateEnhancedKYCParams(it)) }
        builder.documentVerificationParams?.let { add(builder.validateDocumentVerificationParams(it)) }
        builder.enhancedDocumentVerificationParams?.let { add(builder.validateEnhancedDocumentVerificationParams(it)) }
    }
    val payloadIssues = payloadChecks.filterIsInstance<ValidationState.Invalid>().flatMap { it.issues }
    if (payloadIssues.isNotEmpty()) return FlowPreflight.NeedsDetails(payloadIssues)
    return when (val builderState = builder.validate()) {
        is ValidationState.Valid -> FlowPreflight.Ready
        is ValidationState.Invalid -> FlowPreflight.Misconfigured(builderState.issues)
    }
}

/** What the gate decided, and so where the journey goes instead of the SDK. */
sealed interface FlowPreflight {
    data object Ready : FlowPreflight

    /** The forms can resolve it. */
    data class NeedsDetails(val issues: List<UseSmileIDValidationException>) : FlowPreflight

    /** Only a new token resolves it, so the journey goes back to the scanner rather than to a form. */
    data object NeedsSession : FlowPreflight

    /** No form can resolve it, and it must still never reach the SDK. */
    data class Misconfigured(val issues: List<UseSmileIDValidationException>) : FlowPreflight
}
