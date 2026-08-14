package com.usesmileid.sampleapps.ui.model

import androidx.compose.runtime.Immutable

/** Which container hosts the SDK flow. One route, two presentations. */
enum class UseSmileIDSampleFlowRoute(val id: String) {
    Fullscreen("fullscreen"),
    Shell("shell"),
}

/**
 * How far a flow got.
 *
 * [Cancelled] and [Failed] stay separate because that is the distinction the schema asks for: a user
 * backing out and a submission failing are indistinguishable in a screenshot, and conflating them
 * lets a flow that never ran pass as one that ran and failed.
 */
enum class UseSmileIDSampleFlowStatus(val id: String) {
    Idle("idle"),
    Running("running"),
    Succeeded("succeeded"),
    Cancelled("cancelled"),
    Failed("failed"),
}

/** A snapshot of what the SDK did, mirroring `spec/result-card.schema.json` field for field. */
@Immutable
data class UseSmileIDSampleResult(
    val activeScenario: UseSmileIDSampleScenario,
    val activeTheme: UseSmileIDSampleThemeScenario,
    val route: UseSmileIDSampleFlowRoute,
    val jobStatus: UseSmileIDSampleFlowStatus,
    val resultCallbackCount: Int,
    val refreshCallbackCount: Int,
    val jobId: String? = null,
    val userId: String? = null,
    val lastError: String? = null,
    /**
     * Always null on Android. The published artifact exposes no runtime accessor for its own version,
     * and the schema is explicit that the compiled-against BOM version must not be substituted —
     * reporting the wrong version is worse than reporting none. See `sdkVersion.blocked` in the schema.
     */
    val sdkVersion: String? = null,
) {
    val inFlight: Boolean get() = jobStatus == UseSmileIDSampleFlowStatus.Running
}
