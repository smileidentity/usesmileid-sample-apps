package com.usesmileid.sampleapps.ui.model

import androidx.compose.runtime.Immutable

/** Which container hosts the SDK flow. One route, two presentations. */
enum class UseSmileIDSampleFlowRoute(val id: String) {
    Fullscreen("fullscreen"),
    Shell("shell"),
}

/** Cancelled and Failed stay separate: a screenshot cannot tell a user backing out from a failure. */
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
    /** Always null on Android: no runtime accessor exists, and the BOM version must not stand in. */
    val sdkVersion: String? = null,
) {
    val inFlight: Boolean get() = jobStatus == UseSmileIDSampleFlowStatus.Running
}
