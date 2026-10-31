package com.usesmileid.sampleapps.ui.screens

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.Easing
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.util.lerp
import com.usesmileid.sampleapps.ui.UseSmileIDSampleStrings
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleLogo
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import kotlin.math.PI
import kotlin.math.sin

/** The cold-start intro: "SmileID" unrolls out of the logo's lock, which shuts and opens again on the way; a tap skips to [onFinished]. */
@Composable
fun LaunchIntroScreen(onFinished: () -> Unit, modifier: Modifier = Modifier) {
    val progress = remember { Animatable(0f) }
    val finish by rememberUpdatedState(onFinished)
    LaunchedEffect(progress) {
        progress.animateTo(1f, tween(LaunchIntroTimeline.DURATION_MILLIS, easing = LinearEasing))
        finish()
    }
    LaunchIntroFrame(
        progress = { progress.value },
        modifier = modifier.pointerInput(Unit) { detectTapGestures { finish() } },
    )
}

/** One frame of the intro, always on the dark scheme; [progress] is read at draw time so the animation never recomposes. */
@Composable
internal fun LaunchIntroFrame(progress: () -> Float, modifier: Modifier = Modifier) {
    val paths = remember { UseSmileIDSampleLogo.Paths() }
    val label = UseSmileIDSampleStrings.launchIntroLabel
    UseSmileIDSampleTheme(darkTheme = true) {
        val colors = UseSmileIDSampleTheme.colors
        val ink = colors.textTitle
        val accent = colors.decorative.orange
        Canvas(
            modifier
                .fillMaxSize()
                .background(colors.background)
                .semantics { contentDescription = label },
        ) {
            drawLaunchIntro(LaunchIntroTimeline.pose(progress()), paths, ink, accent)
        }
    }
}

/** Where every part of the logo is at one instant. [shackleLock] runs from 0, the logo's own open shackle, to 1, seated on the body. */
@Immutable
internal data class LaunchIntroPose(
    val markAlpha: Float,
    val markScale: Float,
    val shackleLock: Float,
    val shackleLift: Float,
    val clickSquash: Float,
    val ringProgress: Float,
    val wordmarkReveal: Float,
) {
    companion object {
        /** The logo as the brand draws it, which is where every intro ends. */
        val Rest = LaunchIntroPose(
            markAlpha = 1f,
            markScale = 1f,
            shackleLock = 0f,
            shackleLift = 0f,
            clickSquash = 0f,
            ringProgress = 1f,
            wordmarkReveal = 1f,
        )
    }
}

/** The intro's choreography in milliseconds, as a pure function of progress so goldens can stop it on any frame. */
internal object LaunchIntroTimeline {
    const val DURATION_MILLIS = 2800

    /** The logo drawn in full size, its shackle still in the brand's open position. */
    const val APPEARED = 500f / DURATION_MILLIS

    /** The shackle seated on the body, with the name part-way out. */
    const val LOCKED = 1150f / DURATION_MILLIS

    private const val MARK_START_SCALE = 0.85f
    private const val HOP_HEIGHT = 1.6f
    private const val UNLOCK_CLICK_STRENGTH = 0.6f

    fun pose(progress: Float): LaunchIntroPose {
        val ms = progress.coerceIn(0f, 1f) * DURATION_MILLIS
        val lock = phase(ms, 600f, 1000f, FastOutSlowInEasing)
        val unlock = phase(ms, 1300f, 1700f, FastOutSlowInEasing)
        return LaunchIntroPose(
            markAlpha = phase(ms, 0f, 350f, LinearOutSlowInEasing),
            markScale = lerp(MARK_START_SCALE, 1f, phase(ms, 0f, 450f, FastOutSlowInEasing)),
            shackleLock = lock * (1f - unlock),
            shackleLift = HOP_HEIGHT * (arc(lock) + arc(unlock)),
            clickSquash = bump(phase(ms, 1000f, 1250f, LinearEasing)) +
                UNLOCK_CLICK_STRENGTH * bump(phase(ms, 1700f, 1950f, LinearEasing)),
            ringProgress = phase(ms, 1000f, 1500f, LinearOutSlowInEasing),
            wordmarkReveal = phase(ms, 350f, 1600f, LinearOutSlowInEasing),
        )
    }

    private fun phase(ms: Float, start: Float, end: Float, easing: Easing): Float =
        easing.transform(((ms - start) / (end - start)).coerceIn(0f, 1f))

    /** A hop's height along its flight: zero on the ground at both ends, never below it. */
    private fun arc(flight: Float): Float = if (flight > 0f && flight < 1f) sin(flight * PI).toFloat() else 0f

    /** A landing's squash, decaying to nothing so the body settles back to its own shape. */
    private fun bump(time: Float): Float = (1f - time) * arc(time)
}

private const val LOGO_WIDTH_FRACTION = 0.62f
private const val SQUASH_Y = 0.14f
private const val SQUASH_X = 0.07f
private const val RING_START_RADIUS = 4f
private const val RING_END_RADIUS = 9f
private const val RING_STROKE = 0.16f
private const val RING_ALPHA = 0.45f
private const val WORDMARK_SLIDE = 2f
private const val CLIP_BLEED = 0.5f

private fun DrawScope.drawLaunchIntro(pose: LaunchIntroPose, paths: UseSmileIDSampleLogo.Paths, ink: Color, accent: Color) {
    val logo = UseSmileIDSampleLogo
    val logoScale = size.width * LOGO_WIDTH_FRACTION / logo.bounds.width
    // Centres what is visible so far, so the name pushes the lock aside as it unrolls.
    val visibleRight = lerp(logo.markBounds.right, logo.bounds.right, pose.wordmarkReveal)
    val focus = Offset((logo.markBounds.left + visibleRight) / 2f, logo.bounds.center.y)
    val logoOrigin = center - focus * logoScale

    withTransform({
        translate(logoOrigin.x, logoOrigin.y)
        scale(logoScale, logoScale, Offset.Zero)
    }) {
        withTransform({ scale(pose.markScale, pose.markScale, logo.markBounds.center) }) {
            drawLock(pose, paths, ink, accent)
        }
        if (pose.wordmarkReveal > 0f) {
            val words = logo.wordmarkBounds
            val start = words.left - CLIP_BLEED
            clipRect(
                left = start,
                top = logo.bounds.top - CLIP_BLEED,
                right = lerp(start, words.right + CLIP_BLEED, pose.wordmarkReveal),
                bottom = logo.bounds.bottom + CLIP_BLEED,
            ) {
                translate(left = -WORDMARK_SLIDE * (1f - pose.wordmarkReveal)) { drawPath(paths.wordmark, ink) }
            }
        }
    }
}

private fun DrawScope.drawLock(pose: LaunchIntroPose, paths: UseSmileIDSampleLogo.Paths, ink: Color, accent: Color) {
    val logo = UseSmileIDSampleLogo
    if (pose.ringProgress > 0f && pose.ringProgress < 1f) {
        drawCircle(
            color = accent,
            radius = lerp(RING_START_RADIUS, RING_END_RADIUS, pose.ringProgress),
            center = Offset(logo.bodyBase.x, logo.markBounds.center.y),
            alpha = (1f - pose.ringProgress) * RING_ALPHA,
            style = Stroke(width = RING_STROKE),
        )
    }
    val bodyScaleY = 1f - SQUASH_Y * pose.clickSquash
    val bodyScaleX = 1f + SQUASH_X * pose.clickSquash
    withTransform({ scale(bodyScaleX, bodyScaleY, logo.bodyBase) }) {
        drawPath(paths.body, ink, alpha = pose.markAlpha)
    }
    // The shackle rides the body's top edge, so it sinks with the squash instead of floating above it.
    val seatDrop = (logo.bodyBase.y - logo.BODY_TOP) * (1f - bodyScaleY)
    translate(left = logo.LOCKED_SHACKLE_SHIFT * pose.shackleLock, top = seatDrop - pose.shackleLift) {
        drawPath(paths.shackle, accent, alpha = pose.markAlpha)
    }
}
