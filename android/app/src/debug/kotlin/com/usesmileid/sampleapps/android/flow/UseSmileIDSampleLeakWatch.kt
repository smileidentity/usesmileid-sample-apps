package com.usesmileid.sampleapps.android.flow

import leakcanary.LeakCanary

/** Debug watches for leaks but never writes the heap to a file: a dump holds the token and captured images. */
internal object UseSmileIDSampleLeakWatch {
    fun install() {
        LeakCanary.config = LeakCanary.config.copy(dumpHeap = false)
    }
}
