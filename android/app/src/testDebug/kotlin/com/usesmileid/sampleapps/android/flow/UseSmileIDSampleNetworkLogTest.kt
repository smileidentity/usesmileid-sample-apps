package com.usesmileid.sampleapps.android.flow

import com.chuckerteam.chucker.api.ChuckerInterceptor
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment

/** A debug build records the SDK's traffic through one Chucker interceptor, and Settings can open it. */
@RunWith(RobolectricTestRunner::class)
class UseSmileIDSampleNetworkLogTest {

    @Test
    fun install_adds_one_chucker_interceptor_however_often_it_runs() {
        UseSmileIDSampleNetworkLog.install(RuntimeEnvironment.getApplication())
        val first = UseSmileIDSampleNetworkLog.interceptor()
        UseSmileIDSampleNetworkLog.install(RuntimeEnvironment.getApplication())

        assertTrue(first is ChuckerInterceptor)
        assertSame(first, UseSmileIDSampleNetworkLog.interceptor())
    }

    @Test
    fun settings_has_an_intent_to_open() {
        assertNotNull(UseSmileIDSampleNetworkLog.intent(RuntimeEnvironment.getApplication()))
    }
}
