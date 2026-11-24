package com.usesmileid.sample.cutout

import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewTreeObserver
import android.view.WindowInsets
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

/** Keeps whether the screen shows its status bar over a camera cutout along its top edge, which React Native's insets fold together, read on the UI thread after each layout. */
class UseSmileIDSampleCutoutModule : Module() {
    @Volatile private var topCutout = false
    private val main = Handler(Looper.getMainLooper())

    // Touched on the main thread only.
    private var watched: View? = null
    private var destroyed = false
    private val onLayout = ViewTreeObserver.OnGlobalLayoutListener { read() }

    override fun definition() = ModuleDefinition {
        Name("UseSmileIDSampleCutout")

        Events("onTopCutoutChange")

        Function("hasTopCutout") { topCutout }

        // An activity already resumed when the module is created sends no foreground event.
        OnCreate { main.post { decorView()?.let(::watch) } }

        // React Native runs the host lifecycle on the UI thread, which owns the view tree.
        OnActivityEntersForeground { decorView()?.let(::watch) }

        OnActivityDestroys { unwatch() }

        OnDestroy {
            main.post {
                destroyed = true
                unwatch()
            }
        }
    }

    private fun decorView(): View? = appContext.currentActivity?.window?.decorView

    private fun watch(decor: View) {
        if (destroyed || watched === decor) return
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
        val insets = watched?.rootWindowInsets ?: return
        val present = (insets.displayCutout?.safeInsetTop ?: 0) > 0 && statusBarShown(insets)
        if (present == topCutout) return
        topCutout = present
        sendEvent("onTopCutoutChange", mapOf("present" to present))
    }

    private fun statusBarShown(insets: WindowInsets): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            insets.isVisible(WindowInsets.Type.statusBars())
        } else {
            @Suppress("DEPRECATION")
            insets.systemWindowInsetTop > 0
        }
}
