package com.usesmileid.sampleapps.android.scan

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.compose.CameraXViewfinder
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.ExperimentalGetImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.core.SurfaceRequest
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicReference

/**
 * The token QR reader: CameraX preview plus the bundled ML Kit barcode model, in the app's own scan
 * screen rather than behind a Google-provided sheet, so camera contention with the SDK is something
 * this sample can actually demonstrate.
 *
 * Two invariants this screen owns:
 *
 * - **The camera is released when the screen leaves composition.** Navigating scan → flow otherwise
 *   hands the SDK a camera the host still holds, which is one of the host-interaction defects this
 *   repo exists to catch.
 * - **A given code is reported once, but a different one still gets through.** The analyser sees the
 *   same QR in many consecutive frames, so reporting every frame would link a session repeatedly. A
 *   one-shot latch would be worse: point the camera at a QR that is not a token and the rejection is
 *   shown, but the scanner would then be dead for the rest of the visit. Keying on the last value
 *   reported gives both.
 *
 * A denied camera permission is not a dead end — the sheet's manual entry still links a token — so
 * this reports the denial and gets out of the way.
 */
@Composable
fun UseSmileIDSampleQrScanner(
    onCode: (String) -> Unit,
    torchOn: Boolean,
    modifier: Modifier = Modifier,
    onPermissionDenied: () -> Unit = {},
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    var granted by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) ==
                PackageManager.PERMISSION_GRANTED,
        )
    }
    val request = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { allowed ->
        granted = allowed
        if (!allowed) onPermissionDenied()
    }
    LaunchedEffect(granted) { if (!granted) request.launch(Manifest.permission.CAMERA) }
    if (!granted) return

    var surfaceRequest by remember { mutableStateOf<SurfaceRequest?>(null) }
    // Written from the analyser thread, so atomic rather than a plain var.
    val lastReported = remember { AtomicReference<String?>(null) }
    val analysisExecutor = remember { Executors.newSingleThreadExecutor() }
    val scanner = remember {
        BarcodeScanning.getClient(
            BarcodeScannerOptions.Builder().setBarcodeFormats(Barcode.FORMAT_QR_CODE).build(),
        )
    }
    var camera by remember { mutableStateOf<Camera?>(null) }
    // Held so release does not have to block the main thread re-fetching the provider.
    var provider by remember { mutableStateOf<ProcessCameraProvider?>(null) }

    LaunchedEffect(lifecycleOwner) {
        val preview = Preview.Builder().build().apply {
            setSurfaceProvider { request -> surfaceRequest = request }
        }
        val analysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()
        analysis.setAnalyzer(analysisExecutor) { proxy ->
            scanner.readQrCode(proxy) { value ->
                if (lastReported.getAndSet(value) != value) onCode(value)
            }
        }
        // The provider arrives as a ListenableFuture, and binding must happen on the main thread, so
        // the main executor is the callback's home rather than a blocking `get()`.
        val pending = ProcessCameraProvider.getInstance(context)
        pending.addListener(
            {
                val cameraProvider = pending.get()
                cameraProvider.unbindAll()
                provider = cameraProvider
                camera = cameraProvider.bindToLifecycle(
                    lifecycleOwner,
                    CameraSelector.DEFAULT_BACK_CAMERA,
                    preview,
                    analysis,
                )
            },
            ContextCompat.getMainExecutor(context),
        )
    }

    LaunchedEffect(camera, torchOn) { camera?.cameraControl?.enableTorch(torchOn) }

    DisposableEffect(provider) {
        onDispose {
            // Order matters: stop the frames, then hand the camera back, then close the detector.
            analysisExecutor.shutdown()
            provider?.unbindAll()
            scanner.close()
        }
    }

    surfaceRequest?.let { pending -> CameraXViewfinder(surfaceRequest = pending, modifier = modifier) }
}

/**
 * Reads a QR code out of one frame, always closing the proxy. The opt-in is scoped to this function
 * rather than the file: `ImageProxy.image` is the only experimental API in play, and it is what ML
 * Kit's CameraX integration is built on.
 *
 * The value is a bearer credential, so it goes straight to [onValue] — never to a log, a metric or a
 * `testTag`ged node.
 */
@androidx.annotation.OptIn(ExperimentalGetImage::class)
private fun BarcodeScanner.readQrCode(proxy: ImageProxy, onValue: (String) -> Unit) {
    val frame = proxy.image
    if (frame == null) {
        proxy.close()
        return
    }
    process(InputImage.fromMediaImage(frame, proxy.imageInfo.rotationDegrees))
        .addOnSuccessListener { codes ->
            codes.firstNotNullOfOrNull { code -> code.rawValue?.takeIf { it.isNotBlank() } }?.let(onValue)
        }
        .addOnCompleteListener { proxy.close() }
}
