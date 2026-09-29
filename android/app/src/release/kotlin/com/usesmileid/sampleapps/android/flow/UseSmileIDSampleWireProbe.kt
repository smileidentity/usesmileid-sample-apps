package com.usesmileid.sampleapps.android.flow

import okhttp3.Interceptor

/** Release logs no traffic, so the probe is compiled out and the builder adds nothing. */
internal fun wireProbe(): Interceptor? = null
