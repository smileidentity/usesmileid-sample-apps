package com.usesmileid.sampleapps.android.scan

import android.Manifest
import android.content.pm.PackageManager
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleHoldCamera
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.delay
import kotlinx.coroutines.suspendCancellableCoroutine

/**
 * Honours the `holdCamera` launch argument: the host takes the camera and keeps it while the SDK
 * starts, so a run can be observed meeting a device that is already contended.
 *
 * The argument's note in `spec/launch-args.json` is the hard part — "a probe that never acquired the
 * camera passes vacuously" — so this counts delivered frames rather than trusting that the bind
 * returned, and reports the count on release. Frames are the only proof the camera actually opened.
 *
 * That report goes to logcat, which is a deliberate and limited choice: a `sample_*` node would be
 * the assertable signal, but adding one is a four-platform `spec/test-ids.json` change and the
 * argument has no other consumer to justify it yet. Nothing here touches the token, so nothing that
 * reaches the log is a credential.
 */
@Composable
fun UseSmileIDSampleCameraHold(hold: UseSmileIDSampleHoldCamera?) {
    if (hold == null) return
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val frames = remember { AtomicInteger(0) }

    LaunchedEffect(hold) {
        // Checked, never requested: a permission dialog over a starting flow would change the very
        // hand-off this argument exists to measure.
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            Log.w(TAG, "holdCamera=${hold.describe()} did nothing: no camera permission, so the hand-off was uncontended")
            return@LaunchedEffect
        }
        val executor = Executors.newSingleThreadExecutor()
        val analysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()
        analysis.setAnalyzer(executor) { proxy ->
            if (frames.getAndIncrement() == 0) Log.i(TAG, "holdCamera acquired the camera")
            proxy.close()
        }
        val provider = suspendCancellableCoroutine { continuation ->
            val pending = ProcessCameraProvider.getInstance(context)
            pending.addListener(
                { continuation.resumeWith(Result.success(pending.get())) },
                ContextCompat.getMainExecutor(context),
            )
        }
        try {
            // Only this use case is ever unbound again: `unbindAll` here would take the camera off
            // the SDK, which is the opposite of holding it against them.
            provider.bindToLifecycle(lifecycleOwner, CameraSelector.DEFAULT_BACK_CAMERA, analysis)
            when (hold) {
                UseSmileIDSampleHoldCamera.Keep -> awaitCancellation()
                is UseSmileIDSampleHoldCamera.Millis -> delay(hold.value)
            }
        } finally {
            provider.unbind(analysis)
            executor.shutdown()
            val seen = frames.get()
            if (seen == 0) {
                Log.w(TAG, "holdCamera=${hold.describe()} released without a single frame — treat the run as uncontended")
            } else {
                Log.i(TAG, "holdCamera=${hold.describe()} released after $seen frames")
            }
        }
    }
}

private fun UseSmileIDSampleHoldCamera.describe(): String = when (this) {
    UseSmileIDSampleHoldCamera.Keep -> "keep"
    is UseSmileIDSampleHoldCamera.Millis -> "${value}ms"
}

/** One tag for the one thing this file reports, so a device run can filter for it. */
private const val TAG = "UseSmileIDSampleHoldCamera"
