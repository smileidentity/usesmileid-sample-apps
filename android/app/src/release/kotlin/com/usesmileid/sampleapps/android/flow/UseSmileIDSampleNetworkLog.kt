package com.usesmileid.sampleapps.android.flow

import android.content.Context
import android.content.Intent
import okhttp3.Interceptor

/** Release records no traffic, so there is nothing to install, add or open. */
internal object UseSmileIDSampleNetworkLog {
    fun install(context: Context) {}

    fun interceptor(): Interceptor? = null

    fun intent(context: Context): Intent? = null
}
