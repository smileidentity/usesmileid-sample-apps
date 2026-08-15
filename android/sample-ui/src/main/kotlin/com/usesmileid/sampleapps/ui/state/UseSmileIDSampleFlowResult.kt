package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.listSaver
import androidx.compose.runtime.setValue
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowStatus
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleResult
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario

/** Saveable, because a count that resets on recreation would swallow the second call it exists to catch. */
class UseSmileIDSampleFlowResult(
    scenario: UseSmileIDSampleScenario = UseSmileIDSampleScenario.Normal,
    theme: UseSmileIDSampleThemeScenario = UseSmileIDSampleThemeScenario.BrandDefault,
    route: UseSmileIDSampleFlowRoute = UseSmileIDSampleFlowRoute.Fullscreen,
    status: UseSmileIDSampleFlowStatus = UseSmileIDSampleFlowStatus.Idle,
    jobId: String? = null,
    userId: String? = null,
    lastError: String? = null,
    resultCallbackCount: Int = 0,
    refreshCallbackCount: Int = 0,
) {
    var scenario by mutableStateOf(scenario)
        private set

    var theme by mutableStateOf(theme)
        private set

    var route by mutableStateOf(route)
        private set

    var status by mutableStateOf(status)
        private set

    var jobId by mutableStateOf(jobId)
        private set

    var userId by mutableStateOf(userId)
        private set

    var lastError by mutableStateOf(lastError)
        private set

    var resultCallbackCount by mutableIntStateOf(resultCallbackCount)
        private set

    var refreshCallbackCount by mutableIntStateOf(refreshCallbackCount)
        private set

    val snapshot: UseSmileIDSampleResult
        get() = UseSmileIDSampleResult(
            activeScenario = scenario,
            activeTheme = theme,
            route = route,
            jobStatus = status,
            resultCallbackCount = resultCallbackCount,
            refreshCallbackCount = refreshCallbackCount,
            jobId = jobId,
            userId = userId,
            lastError = lastError,
        )

    fun selectScenario(value: UseSmileIDSampleScenario) {
        scenario = value
    }

    fun selectTheme(value: UseSmileIDSampleThemeScenario) {
        theme = value
    }

    /** Navigation decides this, so it is set on arrival rather than on handoff. */
    fun enterRoute(value: UseSmileIDSampleFlowRoute) {
        route = value
    }

    /** Both counts reset here, so "exactly once" is asserted per run rather than per app launch. */
    fun startFlow() {
        status = UseSmileIDSampleFlowStatus.Running
        jobId = null
        userId = null
        lastError = null
        resultCallbackCount = 0
        refreshCallbackCount = 0
    }

    /** [userId] must be what the server returned; a local placeholder invalidates every run after it. */
    fun recordResultCallback(
        status: UseSmileIDSampleFlowStatus,
        jobId: String? = null,
        userId: String? = null,
        error: String? = null,
    ) {
        resultCallbackCount++
        this.status = status
        this.jobId = jobId
        this.userId = userId
        lastError = error
    }

    fun recordRefreshCallback() {
        refreshCallbackCount++
    }

    companion object {
        val Saver: Saver<UseSmileIDSampleFlowResult, Any> = listSaver(
            save = {
                listOf(
                    it.scenario.id,
                    it.theme.id,
                    it.route.id,
                    it.status.id,
                    it.jobId.orEmpty(),
                    it.userId.orEmpty(),
                    it.lastError.orEmpty(),
                    it.resultCallbackCount.toString(),
                    it.refreshCallbackCount.toString(),
                )
            },
            restore = { saved ->
                UseSmileIDSampleFlowResult(
                    // Read defensively: this runs after process death, where a throw takes the app down.
                    scenario = UseSmileIDSampleScenario.entries.firstOrNull { it.id == saved[0] }
                        ?: UseSmileIDSampleScenario.Normal,
                    theme = UseSmileIDSampleThemeScenario.entries.firstOrNull { it.id == saved[1] }
                        ?: UseSmileIDSampleThemeScenario.BrandDefault,
                    route = UseSmileIDSampleFlowRoute.entries.firstOrNull { it.id == saved[2] }
                        ?: UseSmileIDSampleFlowRoute.Fullscreen,
                    status = UseSmileIDSampleFlowStatus.entries.firstOrNull { it.id == saved[3] }
                        ?: UseSmileIDSampleFlowStatus.Idle,
                    jobId = saved[4].ifEmpty { null },
                    userId = saved[5].ifEmpty { null },
                    lastError = saved[6].ifEmpty { null },
                    resultCallbackCount = saved[7].toIntOrNull() ?: 0,
                    refreshCallbackCount = saved[8].toIntOrNull() ?: 0,
                )
            },
        )
    }
}
