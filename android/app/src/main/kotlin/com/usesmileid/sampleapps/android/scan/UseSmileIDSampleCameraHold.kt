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
 * Honours the `holdCamera` launch argument: the host takes a camera and keeps it while the SDK
 * starts, so a run can be observed meeting a device that is already contended.
 *
 * The argument's note in `spec/launch-args.json` is the hard part — "a probe that never acquired the
 * camera passes vacuously" — so this counts delivered frames rather than trusting that the bind
 * returned, and reports both the count and how long ago the last frame arrived. A hold that was
 * evicted early otherwise reports identically to one that lasted, and eviction is real: the provider
 * is a process singleton and an `unbindAll` anywhere drops this use case.
 *
 * It holds the lens [product] will use, because holding the back camera against a selfie flow
 * contends with nothing while still logging a successful acquisition — the vacuous pass again, only
 * harder to spot. Nothing here may fail the run it observes, so every camera call is guarded: a
 * probe that crashed the flow would be reported as an SDK defect.
 *
 * The report goes to logcat, which is a deliberate and limited choice: a `sample_*` node would be
 * assertable, but adding one is a four-platform `spec/test-ids.json` change and this argument has no
 * other consumer to justify it yet. Nothing here touches the token, so nothing logged is a credential.
 */
@Composable
fun UseSmileIDSampleCameraHold(hold: UseSmileIDSampleHoldCamera?, product: UseSmileIDSampleProduct) {
    if (hold == null) return
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current

    LaunchedEffect(hold, product) {
        // Checked, never requested: a permission dialog over a starting flow would change the very
        // hand-off this argument exists to measure.
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            Log.w(TAG, "${hold.describe()} did nothing: no camera permission, so the hand-off was uncontended")
            return@LaunchedEffect
        }
        val provider = runCatching {
            suspendCancellableCoroutine { continuation ->
                val pending = ProcessCameraProvider.getInstance(context)
                // resumeWith(runCatching { … }) so a failed future becomes a coroutine result rather
                // than an uncaught throw on the main executor's thread.
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
        try {
            analysis.setAnalyzer(executor) { proxy ->
                if (frames.getAndIncrement() == 0) Log.i(TAG, "${hold.describe()} acquired the ${lens.label} camera")
                lastFrameAt.set(System.currentTimeMillis())
                proxy.close()
            }
            // Only this use case is ever unbound again: `unbindAll` here would take the camera off
            // the SDK, which is the opposite of holding it against them.
            runCatching { provider.bindToLifecycle(lifecycleOwner, lens.selector, analysis) }
                .onFailure { failure ->
                    Log.w(TAG, "${hold.describe()} could not bind the ${lens.label} camera (${failure.javaClass.simpleName}), so the hand-off was uncontended")
                    return@LaunchedEffect
                }
            when (hold) {
                UseSmileIDSampleHoldCamera.Keep -> awaitCancellation()
                is UseSmileIDSampleHoldCamera.Millis -> delay(hold.value)
            }
        } finally {
            runCatching { provider.unbind(analysis) }
            executor.shutdown()
            report(hold, lens, frames.get(), lastFrameAt.get())
        }
    }
}

private fun report(hold: UseSmileIDSampleHoldCamera, lens: HoldLens, frames: Int, lastFrameAt: Long) {
    if (frames == 0) {
        Log.w(TAG, "${hold.describe()} released the ${lens.label} camera without a single frame — treat the run as uncontended")
        return
    }
    // Frames stopping long before release means something else took the camera, which reads the same
    // as a hold that lasted unless the gap is reported.
    val quietFor = System.currentTimeMillis() - lastFrameAt
    Log.i(TAG, "${hold.describe()} released the ${lens.label} camera after $frames frames, last one ${quietFor}ms before release")
}

/** The lens a product's capture actually uses, so the hold contends with the run rather than beside it. */
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
