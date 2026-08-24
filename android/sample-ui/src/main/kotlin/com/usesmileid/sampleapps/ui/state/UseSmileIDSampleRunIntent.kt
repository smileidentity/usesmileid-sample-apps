package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute

/** A run the expiry gate sent away, carrying the presentation it was launched in (R3). */
@Immutable
data class UseSmileIDSampleRunIntent(
    val productId: String,
    val route: UseSmileIDSampleFlowRoute,
) {
    /** Two plain strings rather than a `Saver`, so the scanner holds it in ordinary saveable state. */
    fun saved(): List<String> = listOf(productId, route.id)

    companion object {
        fun of(saved: List<String>): UseSmileIDSampleRunIntent? {
            val productId = saved.getOrNull(0)?.takeIf { it.isNotBlank() } ?: return null
            val route = UseSmileIDSampleFlowRoute.entries.firstOrNull { it.id == saved.getOrNull(1) } ?: return null
            return UseSmileIDSampleRunIntent(productId = productId, route = route)
        }
    }
}

/**
 * The hand-off from the expiry gate to the scanner, so relinking re-enters the run instead of
 * stranding the partner on the product list. Held here rather than in a route argument: the
 * wizard's linear Continue chain is what keeps continuation state out of the four-platform route
 * table, and the scanner sits outside that chain.
 */
@Stable
class UseSmileIDSampleInterruptedRun {
    var pending: UseSmileIDSampleRunIntent? by mutableStateOf(null)
        private set

    fun send(intent: UseSmileIDSampleRunIntent) {
        pending = intent
    }

    /** Reads and clears, so the visit that claims it owns it and backing out cannot leave it for a later scan. */
    fun claim(): UseSmileIDSampleRunIntent? = pending.also { pending = null }
}
