package com.usesmileid.sample.flutter

import android.os.Build
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

    private fun hasTopCutout(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return false
        return (window.decorView.rootWindowInsets?.displayCutout?.safeInsetTop ?: 0) > 0
    }
}
