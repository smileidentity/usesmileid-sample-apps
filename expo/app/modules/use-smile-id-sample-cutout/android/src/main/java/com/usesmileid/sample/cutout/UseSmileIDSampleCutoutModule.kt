package com.usesmileid.sample.cutout

import android.os.Build
import android.view.View
import android.view.ViewTreeObserver
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

/** Keeps whether the screen has a camera cutout along its top edge, which React Native's insets fold into the status bar, read on the UI thread after each layout. */
class UseSmileIDSampleCutoutModule : Module() {
    @Volatile private var topCutout = false
    private var watched: View? = null
    private val onLayout = ViewTreeObserver.OnGlobalLayoutListener { read() }

    override fun definition() = ModuleDefinition {
        Name("UseSmileIDSampleCutout")

        Events("onTopCutoutChange")

        Function("hasTopCutout") { topCutout }

        // React Native runs the host lifecycle on the UI thread, which owns the view tree.
        OnActivityEntersForeground {
            appContext.currentActivity?.window?.decorView?.let(::watch)
        }

        OnActivityDestroys { unwatch() }
    }

    private fun watch(decor: View) {
        if (watched === decor) return
        unwatch()
        watched = decor
        decor.viewTreeObserver.addOnGlobalLayoutListener(onLayout)
        read()
    }

    private fun unwatch() {
        watched?.viewTreeObserver?.removeOnGlobalLayoutListener(onLayout)
        watched = null
    }

    private fun read() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return
        val present = (watched?.rootWindowInsets?.displayCutout?.safeInsetTop ?: 0) > 0
        if (present == topCutout) return
        topCutout = present
        sendEvent("onTopCutoutChange", mapOf("present" to present))
    }
}
