package com.usesmileid.sample.flutter

import android.os.Build
import android.view.WindowInsets
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** The single host activity; the journey draws Dart-side, and only the top cutout is read here. */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "usesmileid_sample/cutout").setMethodCallHandler { call, result ->
            if (call.method == "hasTopCutout") result.success(hasTopCutout()) else result.notImplemented()
        }
    }

    // Null before the first layout gives the window its insets, which is not the same as no cutout.
    private fun hasTopCutout(): Boolean? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return false
        val insets = window.decorView.rootWindowInsets ?: return null
        return (insets.displayCutout?.safeInsetTop ?: 0) > 0 && statusBarShown(insets)
    }

    private fun statusBarShown(insets: WindowInsets): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            insets.isVisible(WindowInsets.Type.statusBars())
        } else {
            @Suppress("DEPRECATION")
            insets.systemWindowInsetTop > 0
        }
}
