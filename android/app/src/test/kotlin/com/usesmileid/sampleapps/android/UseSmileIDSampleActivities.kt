package com.usesmileid.sampleapps.android

import android.app.Activity
import android.content.Intent
import android.os.SystemClock
import android.view.Choreographer
import androidx.compose.ui.platform.AndroidUiDispatcher
import org.junit.rules.ExternalResource
import org.robolectric.Robolectric
import org.robolectric.android.controller.ActivityController
import org.robolectric.shadows.ShadowLooper
import java.util.concurrent.TimeUnit
import kotlin.coroutines.ContinuationInterceptor

/** Builds a test's activities, closes them when it ends, and unstalls Compose's main dispatcher before each one. */
class UseSmileIDSampleActivities : ExternalResource() {
    private val controllers = mutableListOf<ActivityController<out Activity>>()

    /** A controller for [type], launched with [intent] when given, that this rule closes when the test ends. */
    fun <T : Activity> build(type: Class<T>, intent: Intent? = null): ActivityController<T> {
        val controller = if (intent == null) Robolectric.buildActivity(type) else Robolectric.buildActivity(type, intent)
        controllers += controller
        return controller
    }

    override fun before() {
        val callback = pendingDispatch
        // Robolectric drops a dispatch that lands after the last test's drain, and the dispatcher then waits for it forever.
        runCatching { callback.doFrame(TimeUnit.MILLISECONDS.toNanos(SystemClock.uptimeMillis())) }
            .onFailure { throw AssertionError("Compose work left by an earlier test failed when this rule ran it", it) }
        ShadowLooper.idleMainLooper(DRAIN_MILLIS, TimeUnit.MILLISECONDS)
    }

    override fun after() {
        val failures = controllers.asReversed().mapNotNull { controller -> runCatching { controller.close() }.exceptionOrNull() }
        controllers.clear()
        ShadowLooper.idleMainLooper(DRAIN_MILLIS, TimeUnit.MILLISECONDS)
        failures.firstOrNull()?.let { first ->
            failures.drop(1).forEach(first::addSuppressed)
            throw first
        }
    }

    private companion object {
        /** Long enough for a frame a closing composition still has scheduled. */
        const val DRAIN_MILLIS = 100L

        /** Runs every dispatch and frame the main dispatcher has pending. */
        val pendingDispatch: Choreographer.FrameCallback by lazy {
            runCatching {
                val field = AndroidUiDispatcher::class.java.getDeclaredField("dispatchCallback").apply { isAccessible = true }
                field.get(AndroidUiDispatcher.Main[ContinuationInterceptor]) as Choreographer.FrameCallback
            }.getOrElse {
                throw IllegalStateException("AndroidUiDispatcher.dispatchCallback changed in this Compose version; revisit UseSmileIDSampleActivities.before()", it)
            }
        }
    }
}
