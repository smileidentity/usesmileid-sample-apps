package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.Immutable
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
 * The expiry gate's hand-off to the scanner, so relinking re-enters the run. Held here rather than in
 * a route argument, which is what keeps continuation state out of the four-platform route table.
 */
class UseSmileIDSampleInterruptedRun {
    var pending: UseSmileIDSampleRunIntent? = null
        private set

    fun send(intent: UseSmileIDSampleRunIntent) {
        pending = intent
    }

    /** Called from an effect, not a `remember`: an abandoned composition must not swallow the intent. */
    fun clear() {
        pending = null
    }
}
