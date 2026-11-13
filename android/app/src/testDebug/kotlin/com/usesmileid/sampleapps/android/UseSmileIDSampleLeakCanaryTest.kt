package com.usesmileid.sampleapps.android

import android.content.pm.PackageManager
import com.usesmileid.sampleapps.android.flow.UseSmileIDSampleLeakWatch
import leakcanary.LeakCanary
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment

/** A debug build watches the app for leaks from launch, and never writes the heap to a file. */
@RunWith(RobolectricTestRunner::class)
class UseSmileIDSampleLeakCanaryTest {

    @Test
    fun the_debug_manifest_starts_leakcanary_at_launch() {
        val app = RuntimeEnvironment.getApplication()
        val providers = app.packageManager.getPackageInfo(app.packageName, PackageManager.GET_PROVIDERS).providers.orEmpty()

        assertTrue(providers.any { it.name == "leakcanary.internal.MainProcessAppWatcherInstaller" && it.enabled })
    }

    @Test
    fun install_turns_heap_dumps_off() {
        UseSmileIDSampleLeakWatch.install()

        assertFalse(LeakCanary.config.dumpHeap)
    }
}
