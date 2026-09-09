package com.usesmileid.sampleapps.ui.components

import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.runtime.staticCompositionLocalOf
import kotlinx.coroutines.delay

/** One transient confirmation: what it says and the single action it may offer. */
@Immutable
data class UseSmileIDSampleTransientNotice(
    val message: String,
    val actionLabel: String? = null,
    val onAction: (() -> Unit)? = null,
)

/** The bottom-center auto-dismissing notice, one state shape for every screen that confirms something. */
@Stable
class UseSmileIDSampleTransientNoticeState {
    var current: UseSmileIDSampleTransientNotice? by mutableStateOf(null)
        private set

    /** Restarts the window: a token, not a boolean, so showing the same message twice still resets it. */
    var showToken: Int by mutableIntStateOf(0)
        private set

    fun show(message: String, actionLabel: String? = null, onAction: (() -> Unit)? = null) {
        current = UseSmileIDSampleTransientNotice(message, actionLabel, onAction)
        showToken++
    }

    fun dismiss() {
        current = null
    }
}

/** Not saveable, deliberately: a confirmation must not survive recreation. */
@Composable
fun rememberTransientNotice(): UseSmileIDSampleTransientNoticeState =
    remember { UseSmileIDSampleTransientNoticeState() }

/** Renders [state] and owns its auto-dismiss window. Padding stays caller-supplied: every screen clears different chrome. */
@Composable
fun UseSmileIDSampleTransientNoticeHost(
    state: UseSmileIDSampleTransientNoticeState,
    modifier: Modifier = Modifier,
) {
    val windowMillis = LocalUseSmileIDSampleNoticeWindow.current
    LaunchedEffect(state.showToken) {
        if (state.current == null) return@LaunchedEffect
        delay(windowMillis)
        state.dismiss()
    }
    UseSmileIDSampleOverlay(visible = state.current != null, modifier = modifier) {
        // Keyed on the token rather than read live, so the bar still reads correctly while it slides away.
        val notice = remember(state.showToken) { state.current } ?: return@UseSmileIDSampleOverlay
        UseSmileIDSampleToast(
            message = notice.message,
            actionLabel = notice.actionLabel,
            onAction = notice.onAction?.let { action -> { action(); state.dismiss() } },
        )
    }
}

/** Long enough to undo, short enough not to outlive its cause. */
/**
 * How long a transient notice stays. The shell overrides it from `noticeWindow`; the default is the
 * product's, so a library consumer that provides nothing gets the real behaviour.
 */
val LocalUseSmileIDSampleNoticeWindow = staticCompositionLocalOf { NOTICE_WINDOW_MILLIS }

private const val NOTICE_WINDOW_MILLIS = 5_000L
