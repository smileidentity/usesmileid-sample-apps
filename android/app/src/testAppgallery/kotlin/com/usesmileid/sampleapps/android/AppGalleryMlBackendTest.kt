package com.usesmileid.sampleapps.android

import com.usesmileid.bridge.services.UseSmileIDMobileServicesProvider
import com.usesmileid.sampleapps.android.flow.orStoreBackend
import org.junit.Assert.assertEquals
import org.junit.Test

/** The AppGallery build's backend choice: the probe's answer, with HMS standing in for none. */
class AppGalleryMlBackendTest {

    @Test
    fun keepsGoogleWherePlayServicesRun() {
        assertEquals(UseSmileIDMobileServicesProvider.GOOGLE, UseSmileIDMobileServicesProvider.GOOGLE.orStoreBackend())
    }

    @Test
    fun keepsHuaweiWhereOnlyHmsRuns() {
        assertEquals(UseSmileIDMobileServicesProvider.HUAWEI, UseSmileIDMobileServicesProvider.HUAWEI.orStoreBackend())
    }

    @Test
    fun fallsBackToHuaweiWhenNeitherIsReported() {
        assertEquals(UseSmileIDMobileServicesProvider.HUAWEI, UseSmileIDMobileServicesProvider.NONE.orStoreBackend())
    }
}
