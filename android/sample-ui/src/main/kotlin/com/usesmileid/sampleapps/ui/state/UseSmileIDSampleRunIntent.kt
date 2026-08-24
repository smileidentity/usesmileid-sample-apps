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
 * The hand-off from the expiry gate to the scanner, so relinking re-enters the run instead of
 * stranding the partner on the product list. Held here rather than in a route argument: the
 * wizard's linear Continue chain is what keeps continuation state out of the four-platform route
 * table, and the scanner sits outside that chain.
 *
 * Deliberately not Compose state. It is written once and read once, imperatively, and nothing
 * renders it — holding it as state only subscribed the scanner to a value it never draws.
 */
class UseSmileIDSampleInterruptedRun {
    var pending: UseSmileIDSampleRunIntent? = null
        private set

    fun send(intent: UseSmileIDSampleRunIntent) {
        pending = intent
    }

    /**
     * Forgets the run. Called from an effect rather than from a `remember` calculation: a composition
     * that is abandoned mid-flight must not swallow the intent, so reading and clearing are separate.
     */
    fun clear() {
        pending = null
    }
}
