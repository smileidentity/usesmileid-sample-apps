package com.usesmileid.sampleapps.android.navigation

import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.AnimatedContentTransitionScope.SlideDirection
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.ui.unit.IntOffset
import androidx.navigation.NavBackStackEntry
import com.ramcosta.composedestinations.animations.NavHostAnimatedDestinationStyle
import com.ramcosta.composedestinations.generated.navgraphs.ProductsNavGraph
import com.ramcosta.composedestinations.generated.navgraphs.SettingsNavGraph
import com.ramcosta.composedestinations.generated.navgraphs.VerificationsNavGraph
import com.ramcosta.composedestinations.spec.DestinationStyle
import com.ramcosta.composedestinations.utils.startDestination

/**
 * How every route enters and leaves: the outgoing screen has gone before the incoming one is legible,
 * and the travel is a fraction of the width. The library's default is no animation at all.
 */
object UseSmileIDSampleNavTransitions : NavHostAnimatedDestinationStyle() {

    override val enterTransition: AnimatedContentTransitionScope<NavBackStackEntry>.() -> EnterTransition = {
        if (switchesTab()) arrive() else arrive(SlideDirection.Start)
    }

    override val exitTransition: AnimatedContentTransitionScope<NavBackStackEntry>.() -> ExitTransition = {
        if (switchesTab()) leave() else leave(SlideDirection.Start)
    }

    override val popEnterTransition: AnimatedContentTransitionScope<NavBackStackEntry>.() -> EnterTransition = {
        if (switchesTab()) arrive() else arrive(SlideDirection.End)
    }

    override val popExitTransition: AnimatedContentTransitionScope<NavBackStackEntry>.() -> ExitTransition = {
        if (switchesTab()) leave() else leave(SlideDirection.End)
    }
}

/** A sheet animates itself; animating the destination too slides the scrim in before the sheet appears. */
object UseSmileIDSampleSheetTransitions : DestinationStyle.Animated() {
    override val enterTransition: AnimatedContentTransitionScope<NavBackStackEntry>.() -> EnterTransition? = { EnterTransition.None }
    override val exitTransition: AnimatedContentTransitionScope<NavBackStackEntry>.() -> ExitTransition? = { ExitTransition.None }
}

/** The SDK flow owns its own navigation, so the host only fades it in rather than implying a direction. */
object UseSmileIDSampleFlowTransitions : DestinationStyle.Animated() {
    override val enterTransition: AnimatedContentTransitionScope<NavBackStackEntry>.() -> EnterTransition? = { fadeIn(ARRIVE) }
    override val exitTransition: AnimatedContentTransitionScope<NavBackStackEntry>.() -> ExitTransition? = { fadeOut(LEAVE) }
}

/** Fade in once the outgoing screen has cleared: overlapping them shows its text through the new screen. */
private fun AnimatedContentTransitionScope<NavBackStackEntry>.arrive(
    towards: SlideDirection? = null,
): EnterTransition = fadeIn(ARRIVE).let { fade ->
    if (towards == null) fade else fade + slideIntoContainer(towards, TRAVEL) { full -> full / SLIDE_FRACTION }
}

/** Leaving: fade out quickly, travelling the same short distance so the motion is symmetrical. */
private fun AnimatedContentTransitionScope<NavBackStackEntry>.leave(
    towards: SlideDirection? = null,
): ExitTransition = fadeOut(LEAVE).let { fade ->
    if (towards == null) fade else fade + slideOutOfContainer(towards, TRAVEL) { full -> full / SLIDE_FRACTION }
}

/** Only between the tab roots: comparing parent graphs calls Settings → Profiles a tab switch. */
private fun AnimatedContentTransitionScope<NavBackStackEntry>.switchesTab(): Boolean =
    initialState.destination.route in TAB_ROOTS && targetState.destination.route in TAB_ROOTS

private val TAB_ROOTS: Set<String> = setOf(
    ProductsNavGraph.startDestination.route,
    VerificationsNavGraph.startDestination.route,
    SettingsNavGraph.startDestination.route,
)

/** An eighth of the width: enough to read as direction, not far enough to watch. */
private const val SLIDE_FRACTION = 8
private const val LEAVE_MILLIS = 100
private val LEAVE = tween<Float>(durationMillis = LEAVE_MILLIS, easing = FastOutSlowInEasing)
private val ARRIVE = tween<Float>(durationMillis = 160, delayMillis = LEAVE_MILLIS, easing = FastOutSlowInEasing)
private val TRAVEL = tween<IntOffset>(durationMillis = 200, easing = FastOutSlowInEasing)
