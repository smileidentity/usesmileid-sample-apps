package com.usesmileid.sampleapps.android.flow

import android.content.Context
import android.content.Intent
import com.chuckerteam.chucker.api.Chucker
import com.chuckerteam.chucker.api.ChuckerCollector
import com.chuckerteam.chucker.api.ChuckerInterceptor
import com.chuckerteam.chucker.api.RetentionManager
import okhttp3.Interceptor

/** Debug only: Chucker records the SDK's traffic for an hour, and Settings opens it. The release source set has neither. */
internal object UseSmileIDSampleNetworkLog {
    private var interceptor: Interceptor? = null

    /** Starts recording; Chucker keeps one store per process, so a second call changes nothing. */
    fun install(context: Context) {
        if (interceptor != null) return
        val app = context.applicationContext
        interceptor = ChuckerInterceptor.Builder(app)
            .collector(ChuckerCollector(app, retentionPeriod = RetentionManager.Period.ONE_HOUR))
            .redactHeaders("Authorization", "Cookie", "Set-Cookie")
            .build()
    }

    fun interceptor(): Interceptor? = interceptor

    fun intent(context: Context): Intent? = Chucker.getLaunchIntent(context)
}
