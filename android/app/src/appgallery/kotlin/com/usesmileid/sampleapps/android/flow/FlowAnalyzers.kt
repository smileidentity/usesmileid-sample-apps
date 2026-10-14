package com.usesmileid.sampleapps.android.flow

import android.content.Context
import com.usesmileid.bridge.dsl.builder.CaptureTypeAnalyzerBuilder
import com.usesmileid.bridge.huawei.document.HuaweiDocumentDetectorAnalyzer
import com.usesmileid.bridge.huawei.face.HuaweiFaceDetectorAnalyzer
import com.usesmileid.bridge.mlkit.document.DocumentDetectorAnalyzer
import com.usesmileid.bridge.mlkit.face.FaceDetectorAnalyzer
import com.usesmileid.bridge.services.UseSmileIDMobileServices
import com.usesmileid.bridge.services.UseSmileIDMobileServicesProvider

/** AppGallery's own backend, for a device that reports neither vendor's services. */
internal val STORE_ML_BACKEND = UseSmileIDMobileServicesProvider.HUAWEI

/** Google's backend wherever Play services run, which includes most Huawei phones sold before 2020. */
internal fun mlBackendFor(context: Context): UseSmileIDMobileServicesProvider =
    UseSmileIDMobileServices.preferred(context).orStoreBackend()

/** A device with neither vendor's services still gets this store's backend rather than none. */
internal fun UseSmileIDMobileServicesProvider.orStoreBackend(): UseSmileIDMobileServicesProvider =
    if (this == UseSmileIDMobileServicesProvider.NONE) STORE_ML_BACKEND else this

internal fun CaptureTypeAnalyzerBuilder.addFaceAnalyzer(backend: UseSmileIDMobileServicesProvider) = addAnalyzer(
    factory = if (backend == UseSmileIDMobileServicesProvider.GOOGLE) {
        FaceDetectorAnalyzer.Factory()
    } else {
        HuaweiFaceDetectorAnalyzer.Factory()
    },
)

internal fun CaptureTypeAnalyzerBuilder.addDocumentAnalyzer(backend: UseSmileIDMobileServicesProvider) = addAnalyzer(
    factory = if (backend == UseSmileIDMobileServicesProvider.GOOGLE) {
        DocumentDetectorAnalyzer.Factory()
    } else {
        HuaweiDocumentDetectorAnalyzer.Factory()
    },
)
