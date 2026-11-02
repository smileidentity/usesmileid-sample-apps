package com.usesmileid.sampleapps.android

import android.app.Activity
import android.content.Intent
import org.junit.rules.ExternalResource
import org.robolectric.Robolectric
import org.robolectric.android.controller.ActivityController
import org.robolectric.shadows.ShadowLooper
import java.util.concurrent.TimeUnit

/** Builds a test's activities and closes them when it ends, so no Compose dispatch outlives the test to stall the next one. */
class UseSmileIDSampleActivities : ExternalResource() {
    private val controllers = mutableListOf<ActivityController<out Activity>>()

    /** A controller for [type], launched with [intent] when given, that this rule closes when the test ends. */
    fun <T : Activity> build(type: Class<T>, intent: Intent? = null): ActivityController<T> {
        val controller = if (intent == null) Robolectric.buildActivity(type) else Robolectric.buildActivity(type, intent)
        controllers += controller
        return controller
    }

    override fun after() {
        controllers.forEach { it.close() }
        controllers.clear()
        // Robolectric drops the main looper's queue between tests, and a Compose dispatch dropped there stalls every later first frame in this JVM.
        ShadowLooper.idleMainLooper(DRAIN_MILLIS, TimeUnit.MILLISECONDS)
    }

    private companion object {
        /** Long enough for a frame a closing composition still has scheduled. */
        const val DRAIN_MILLIS = 100L
    }
}
