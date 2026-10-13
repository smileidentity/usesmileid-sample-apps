package com.usesmileid.sampleapps.android.flow

import android.content.Context
import com.usesmileid.bridge.dsl.builder.CaptureTypeAnalyzerBuilder
import com.usesmileid.bridge.mlkit.document.DocumentDetectorAnalyzer
import com.usesmileid.bridge.mlkit.face.FaceDetectorAnalyzer
import com.usesmileid.bridge.services.UseSmileIDMobileServicesProvider

/** The only backend the Play build links. */
internal val STORE_ML_BACKEND = UseSmileIDMobileServicesProvider.GOOGLE

/** Play devices run Google's backend, so there is nothing to probe. */
@Suppress("UNUSED_PARAMETER")
internal fun mlBackendFor(context: Context): UseSmileIDMobileServicesProvider = STORE_ML_BACKEND

/** ML Kit face detection, the one face backend this build links. */
@Suppress("UNUSED_PARAMETER")
internal fun CaptureTypeAnalyzerBuilder.addFaceAnalyzer(backend: UseSmileIDMobileServicesProvider) =
    addAnalyzer(factory = FaceDetectorAnalyzer.Factory())

/** ML Kit document detection, the one document backend this build links. */
@Suppress("UNUSED_PARAMETER")
internal fun CaptureTypeAnalyzerBuilder.addDocumentAnalyzer(backend: UseSmileIDMobileServicesProvider) =
    addAnalyzer(factory = DocumentDetectorAnalyzer.Factory())
