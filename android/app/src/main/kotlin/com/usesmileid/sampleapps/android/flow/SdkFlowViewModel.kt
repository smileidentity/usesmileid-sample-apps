package com.usesmileid.sampleapps.android.flow

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel

/** Scoped to the run's njia entry, so a buffered SDK result is never orphaned on recreation (R6). */
class SdkFlowViewModel(private val savedStateHandle: SavedStateHandle) : ViewModel() {

    /** Read once at entry and never while the flow runs (§8.1). */
    var snapshot: FlowLaunchSnapshot? = null

    /** Set as soon as the SDK delivers, so a pending entry reset cannot erase a result that beat it. */
    var resultDelivered: Boolean = false
        private set

    /** True exactly once per run, so a recreation cannot wipe the counters. */
    fun markRunStarted(): Boolean {
        if (savedStateHandle.get<Boolean>(KEY_RUN_STARTED) == true) return false
        savedStateHandle[KEY_RUN_STARTED] = true
        return true
    }

    fun markResultDelivered() {
        resultDelivered = true
    }

    private companion object {
        const val KEY_RUN_STARTED = "sampleRunStarted"
    }
}
