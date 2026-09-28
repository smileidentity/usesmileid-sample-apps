package com.usesmileid.sampleapps.android.flow

import android.util.Log
import okhttp3.Interceptor
import okhttp3.Response
import okio.Buffer

/** Debug only: the probe on the SDK's public interceptor hook. The release source set returns null. */
internal fun wireProbe(): Interceptor? = UseSmileIDSampleWireProbe

/** Logs the submission's `auto_capture_enabled`, `capture_both_sides` and `allow_gallery_upload`, and nothing else. */
private object UseSmileIDSampleWireProbe : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val body = request.body
        if (body != null && !body.isOneShot()) {
            val text = Buffer().also(body::writeTo).readUtf8()
            val found = KEYS.mapNotNull { key -> Regex("\"$key\"\\s*:\\s*(\"[^\"]*\"|true|false)").find(text)?.let { "$key=${it.groupValues[1]}" } }
            if (found.isNotEmpty()) Log.i(TAG, found.joinToString(" "))
        }
        return chain.proceed(request)
    }

    private val KEYS = listOf("auto_capture_enabled", "capture_both_sides", "allow_gallery_upload")
    private const val TAG = "UseSmileIDSampleWire"
}
