package com.usesmileid.sampleapps.android.navigation

import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.AnimatedContentTransitionScope.SlideDirection
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.ui.unit.IntOffset
import androidx.navigation.NavBackStackEntry
import com.ramcosta.composedestinations.animations.NavHostAnimatedDestinationStyle
import com.ramcosta.composedestinations.generated.navgraphs.ProductsNavGraph
import com.ramcosta.composedestinations.generated.navgraphs.SettingsNavGraph
import com.ramcosta.composedestinations.generated.navgraphs.VerificationsNavGraph
import com.ramcosta.composedestinations.spec.DestinationStyle
import com.ramcosta.composedestinations.utils.startDestination

/**
 * How every route enters and leaves. Two motions, because the route table has two relationships:
 * a push moves sideways to say "deeper", and a tab switch fades through because tabs are siblings.
 *
 * The library's default is no animation at all, which reads as a series of cuts.
 */
object UseSmileIDSampleNavTransitions : NavHostAnimatedDestinationStyle() {

    override val enterTransition: AnimatedContentTransitionScope<NavBackStackEntry>.() -> EnterTransition = {
        if (switchesTab()) fadeThroughIn() else slideIntoContainer(SlideDirection.Start, SLIDE) + fadeIn(FADE)
    }

    override val exitTransition: AnimatedContentTransitionScope<NavBackStackEntry>.() -> ExitTransition = {
        if (switchesTab()) fadeOut(FADE_OUT) else slideOutOfContainer(SlideDirection.Start, SLIDE) + fadeOut(FADE)
    }

    override val popEnterTransition: AnimatedContentTransitionScope<NavBackStackEntry>.() -> EnterTransition = {
        if (switchesTab()) fadeThroughIn() else slideIntoContainer(SlideDirection.End, SLIDE) + fadeIn(FADE)
    }

    override val popExitTransition: AnimatedContentTransitionScope<NavBackStackEntry>.() -> ExitTransition = {
        if (switchesTab()) fadeOut(FADE_OUT) else slideOutOfContainer(SlideDirection.End, SLIDE) + fadeOut(FADE)
    }
}

/**
 * For a route that draws its own presentation: a sheet animates itself, and animating the
 * destination as well slides the scrim in from the side before the sheet has appeared.
 */
object UseSmileIDSampleSheetTransitions : DestinationStyle.Animated() {
    override val enterTransition: AnimatedContentTransitionScope<NavBackStackEntry>.() -> EnterTransition? = { EnterTransition.None }
    override val exitTransition: AnimatedContentTransitionScope<NavBackStackEntry>.() -> ExitTransition? = { ExitTransition.None }
}

/** The SDK flow owns its own navigation, so the host only fades it in rather than sliding it. */
object UseSmileIDSampleFlowTransitions : DestinationStyle.Animated() {
    override val enterTransition: AnimatedContentTransitionScope<NavBackStackEntry>.() -> EnterTransition? = { fadeThroughIn() }
    override val exitTransition: AnimatedContentTransitionScope<NavBackStackEntry>.() -> ExitTransition? = { fadeOut(FADE_OUT) }
}

/**
 * The outgoing screen clears before the incoming one arrives. Overlapping the two instead leaves
 * both legible at once, and two dense screens on top of each other read as a rendering fault.
 */
private fun fadeThroughIn(): EnterTransition =
    fadeIn(FADE_IN_DELAYED) + scaleIn(FADE_IN_DELAYED, initialScale = FADE_THROUGH_SCALE)

/**
 * Only between the three tab roots. Comparing parent graphs instead calls Settings → Profiles a tab
 * switch, because a pushed route lives in the root graph, and the push then loses its direction.
 */
private fun AnimatedContentTransitionScope<NavBackStackEntry>.switchesTab(): Boolean =
    initialState.destination.route in TAB_ROOTS && targetState.destination.route in TAB_ROOTS

private val TAB_ROOTS: Set<String> = setOf(
    ProductsNavGraph.startDestination.route,
    VerificationsNavGraph.startDestination.route,
    SettingsNavGraph.startDestination.route,
)

private const val FADE_OUT_MILLIS = 90
private val SLIDE = tween<IntOffset>(durationMillis = 280, easing = FastOutSlowInEasing)
private val FADE = tween<Float>(durationMillis = 180, easing = FastOutSlowInEasing)
private val FADE_OUT = tween<Float>(durationMillis = FADE_OUT_MILLIS, easing = FastOutSlowInEasing)
private val FADE_IN_DELAYED = tween<Float>(durationMillis = 210, delayMillis = FADE_OUT_MILLIS, easing = FastOutSlowInEasing)
private const val FADE_THROUGH_SCALE = 0.94f
