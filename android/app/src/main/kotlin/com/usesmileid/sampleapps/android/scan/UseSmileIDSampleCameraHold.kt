package com.usesmileid.sampleapps.android.scan

import android.Manifest
import android.content.pm.PackageManager
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleHoldCamera
import com.usesmileid.sampleapps.ui.state.describe
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.delay
import kotlinx.coroutines.suspendCancellableCoroutine

/**
 * Honours `holdCamera`: the host keeps [product]'s own lens while the SDK starts, so a run can be
 * observed on a contended device. Frames are counted because `spec/launch-args.json` warns that a
 * probe which never acquired the camera passes vacuously.
 */
@Composable
fun UseSmileIDSampleCameraHold(hold: UseSmileIDSampleHoldCamera?, product: UseSmileIDSampleProduct) {
    if (hold == null) return
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current

    LaunchedEffect(hold, product) {
        // Checked, never requested: a dialog over a starting flow would change the hand-off measured.
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            Log.w(TAG, "${hold.describe()} did nothing: no camera permission, so the hand-off was uncontended")
            return@LaunchedEffect
        }
        val provider = runCatching {
            suspendCancellableCoroutine { continuation ->
                val pending = ProcessCameraProvider.getInstance(context)
                // runCatching so a failed future resumes the coroutine instead of throwing on the executor.
                pending.addListener(
                    { continuation.resumeWith(runCatching { pending.get() }) },
                    ContextCompat.getMainExecutor(context),
                )
            }
        }.getOrElse { failure ->
            Log.w(TAG, "${hold.describe()} could not reach the camera provider: ${failure.javaClass.simpleName}")
            return@LaunchedEffect
        }

        val frames = AtomicInteger(0)
        val lastFrameAt = AtomicLong(0L)
        val executor = Executors.newSingleThreadExecutor()
        val analysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()
        val lens = product.holdLens()
        // Read in `finally`, so a hold that never bound is not also reported as one that released.
        var bound = false
        try {
            analysis.setAnalyzer(executor) { proxy ->
                if (frames.getAndIncrement() == 0) Log.i(TAG, "${hold.describe()} acquired the ${lens.label} camera")
                lastFrameAt.set(System.currentTimeMillis())
                proxy.close()
            }
            // Only this use case is unbound again: `unbindAll` would take the camera off the SDK.
            runCatching { provider.bindToLifecycle(lifecycleOwner, lens.selector, analysis) }
                .onFailure { failure ->
                    Log.w(TAG, "${hold.describe()} could not bind the ${lens.label} camera (${failure.javaClass.simpleName}), so the hand-off was uncontended")
                    return@LaunchedEffect
                }
            bound = true
            when (hold) {
                UseSmileIDSampleHoldCamera.Keep -> awaitCancellation()
                is UseSmileIDSampleHoldCamera.Millis -> delay(hold.value)
            }
        } finally {
            runCatching { provider.unbind(analysis) }
            executor.shutdown()
            if (bound) report(hold, lens, frames.get(), lastFrameAt.get())
        }
    }
}

private fun report(hold: UseSmileIDSampleHoldCamera, lens: HoldLens, frames: Int, lastFrameAt: Long) {
    if (frames == 0) {
        Log.w(TAG, "${hold.describe()} released the ${lens.label} camera without a single frame — treat the run as uncontended")
        return
    }
    // Frames stopping early means something else took the camera; without the gap it reads as a hold that lasted.
    val quietFor = System.currentTimeMillis() - lastFrameAt
    Log.i(TAG, "${hold.describe()} released the ${lens.label} camera after $frames frames, last one ${quietFor}ms before release")
}

/** The lens the product captures with, so the hold contends with the run rather than beside it. */
private fun UseSmileIDSampleProduct.holdLens(): HoldLens = when (this) {
    UseSmileIDSampleProduct.SmartSelfieEnrollment,
    UseSmileIDSampleProduct.SmartSelfieAuth,
    UseSmileIDSampleProduct.BiometricKyc,
    -> HoldLens.Front
    else -> HoldLens.Back
}

private enum class HoldLens(val label: String, val selector: CameraSelector) {
    Front("front", CameraSelector.DEFAULT_FRONT_CAMERA),
    Back("back", CameraSelector.DEFAULT_BACK_CAMERA),
}

/** Matches the file, and stays inside the 23-character tag limit that API 24-25 still enforces. */
private const val TAG = "UseSmileIDCameraHold"
