package com.usesmileid.sampleapps.android.flow

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import java.util.UUID
import com.ramcosta.composedestinations.generated.destinations.SdkFlowScreenDestination
import com.ramcosta.composedestinations.generated.destinations.SdkFlowScreenDestinationNavArgs

/** Route-derived identity, so a buffered SDK result is never orphaned on recreation (R6). */
class SdkFlowViewModel(private val savedStateHandle: SavedStateHandle) : ViewModel() {

    val args: SdkFlowScreenDestinationNavArgs = SdkFlowScreenDestination.argsFrom(savedStateHandle)

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

    /**
     * The id this run submits under. Every other snapshot field is rebuilt from a saveable store, so
     * without this a run surviving process death would silently resume under a different id.
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
