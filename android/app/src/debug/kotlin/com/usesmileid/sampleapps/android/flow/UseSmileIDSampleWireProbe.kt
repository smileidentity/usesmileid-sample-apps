package com.usesmileid.sampleapps.android.flow

import android.util.Log
import okhttp3.Interceptor
import okhttp3.Response
import okio.Buffer

/** Debug only: the probe on the SDK's public interceptor hook. The release source set returns null. */
internal fun wireProbe(): Interceptor? = UseSmileIDSampleWireProbe

/** The three document-capture keys found in a request body, as `key=value`; the SDK nests them as an escaped JSON string. */
internal fun wireKeysIn(body: String): List<String> = WIRE_KEYS.mapNotNull { key ->
    Regex("""\\?"$key\\?"\s*:\s*(\\?"[^"\\]*\\?"|true|false)""").find(body)
        ?.let { "$key=${it.groupValues[1].replace("\\", "")}" }
}

private val WIRE_KEYS = listOf("auto_capture_enabled", "capture_both_sides", "allow_skip_back", "allow_gallery_upload")

/** Logs the submission's `auto_capture_enabled`, `capture_both_sides`, `allow_skip_back` and `allow_gallery_upload`, and nothing else. */
private object UseSmileIDSampleWireProbe : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val body = request.body
        if (body != null && !body.isOneShot()) {
            val found = wireKeysIn(Buffer().also(body::writeTo).readUtf8())
            if (found.isNotEmpty()) Log.i(TAG, found.joinToString(" "))
        }
        return chain.proceed(request)
    }

    private const val TAG = "UseSmileIDSampleWire"
}
