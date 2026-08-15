package com.usesmileid.sampleapps.ui.golden

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowStatus
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleResult
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario

/** Every state the card has to render: nothing run yet, a run in flight, and all three terminal outcomes. */
internal object ResultFixtures {

    val Idle = UseSmileIDSampleResult(
        activeScenario = UseSmileIDSampleScenario.Normal,
        activeTheme = UseSmileIDSampleThemeScenario.BrandDefault,
        route = UseSmileIDSampleFlowRoute.Fullscreen,
        jobStatus = UseSmileIDSampleFlowStatus.Idle,
        resultCallbackCount = 0,
        refreshCallbackCount = 0,
    )

    val Running = Idle.copy(
        route = UseSmileIDSampleFlowRoute.Shell,
        jobStatus = UseSmileIDSampleFlowStatus.Running,
    )

    val Succeeded = Idle.copy(
        jobStatus = UseSmileIDSampleFlowStatus.Succeeded,
        jobId = "job_9f3a2c7104e8",
        userId = "user_5b1ec4d2",
        resultCallbackCount = 1,
    )

    val Cancelled = Idle.copy(
        jobStatus = UseSmileIDSampleFlowStatus.Cancelled,
        resultCallbackCount = 1,
    )

    val Failed = Idle.copy(
        activeScenario = UseSmileIDSampleScenario.BadRefresh,
        jobStatus = UseSmileIDSampleFlowStatus.Failed,
        resultCallbackCount = 1,
        refreshCallbackCount = 2,
        lastError = "2213: authentication failed — refresh returned an expired token",
    )
}
