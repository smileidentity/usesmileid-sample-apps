package com.usesmileid.sampleapps.android.flow

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import java.util.UUID
import com.ramcosta.composedestinations.generated.destinations.SdkFlowScreenDestination
import com.ramcosta.composedestinations.generated.destinations.SdkFlowScreenDestinationNavArgs

/**
 * Identity comes from the route via the SavedStateHandle, so every arrival path — tap, cold deep
 * link, recreation — resolves to the same host and the SDK's buffered result is never orphaned (R6).
 */
class SdkFlowViewModel(private val savedStateHandle: SavedStateHandle) : ViewModel() {

    val args: SdkFlowScreenDestinationNavArgs = SdkFlowScreenDestination.argsFrom(savedStateHandle)

    /** Read once at entry and never while the flow runs (§8.1); surviving recreation is what makes that true. */
    var snapshot: FlowLaunchSnapshot? = null

    /** Set as soon as the SDK delivers, so a pending entry reset cannot erase a result that beat it. */
    var resultDelivered: Boolean = false
        private set

    /** True exactly once per run: a recreation must not re-run `startFlow()` and wipe the run's counters. */
    fun markRunStarted(): Boolean {
        if (savedStateHandle.get<Boolean>(KEY_RUN_STARTED) == true) return false
        savedStateHandle[KEY_RUN_STARTED] = true
        return true
    }

    fun markResultDelivered() {
        resultDelivered = true
    }

    /**
     * The user id this run submits under, stable for the run's whole life. Every other snapshot
     * field is rebuilt from a saveable store, so without this a run that survives process death
     * would resume under a different id than it started with — silently, and only Smart Selfie
     * Authentication would show it, as an auth against an id that was never enrolled.
     */
    fun runUserId(enrolled: String?): String {
        savedStateHandle.get<String>(KEY_RUN_USER_ID)?.let { return it }
        val id = enrolled ?: UUID.randomUUID().toString()
        savedStateHandle[KEY_RUN_USER_ID] = id
        return id
    }

    private companion object {
        const val KEY_RUN_STARTED = "sampleRunStarted"
        const val KEY_RUN_USER_ID = "sampleRunUserId"
    }
}
