package com.usesmileid.sampleapps.android.flow

import android.content.Context
import android.content.Intent
import okhttp3.Interceptor
import okhttp3.OkHttpClient

/** Release records no traffic, so there is nothing to install, add or open. */
internal object UseSmileIDSampleNetworkLog {
    fun install(context: Context) {}

    fun interceptor(): Interceptor? = null

    fun client(): OkHttpClient = OkHttpClient()

    fun intent(context: Context): Intent? = null
}
