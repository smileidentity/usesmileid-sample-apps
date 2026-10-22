package com.usesmileid.sampleapps.android.flow

import android.content.Context
import android.content.Intent
import com.chuckerteam.chucker.api.Chucker
import com.chuckerteam.chucker.api.ChuckerCollector
import com.chuckerteam.chucker.api.ChuckerInterceptor
import com.chuckerteam.chucker.api.RetentionManager
import okhttp3.Interceptor
import okhttp3.OkHttpClient

/** Debug only: Chucker records the app's and the SDK's traffic for an hour, and Settings opens it. The release source set has neither. */
internal object UseSmileIDSampleNetworkLog {
    @Volatile private var interceptor: Interceptor? = null

    /** Starts recording; a second call keeps the first interceptor. */
    fun install(context: Context) {
        if (interceptor != null) return
        val app = context.applicationContext
        interceptor = ChuckerInterceptor.Builder(app)
            .collector(ChuckerCollector(app, showNotification = false, retentionPeriod = RetentionManager.Period.ONE_HOUR))
            .redactHeaders("Authorization", "SmileID-Token", "Cookie", "Set-Cookie")
            .build()
    }

    fun interceptor(): Interceptor? = interceptor

    /** The app's own client, recorded too. */
    fun client(): OkHttpClient = OkHttpClient.Builder().apply { interceptor?.let { addInterceptor(it) } }.build()

    fun intent(context: Context): Intent? = Chucker.getLaunchIntent(context)
}
