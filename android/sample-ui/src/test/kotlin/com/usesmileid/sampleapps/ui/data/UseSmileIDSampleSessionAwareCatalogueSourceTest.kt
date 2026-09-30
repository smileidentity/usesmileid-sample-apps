package com.usesmileid.sampleapps.ui.data

import com.usesmileid.sampleapps.ui.CatalogueFixtures
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Test
import java.io.IOException

class UseSmileIDSampleSessionAwareCatalogueSourceTest {

    private val fixture = UseSmileIDSampleFixtureCatalogueSource(CatalogueFixtures.json)
    private val source = UseSmileIDSampleSessionAwareCatalogueSource(UseSmileIDSampleUnreachableCatalogueSource, fixture)

    @Test
    fun a_simulated_sessions_unsigned_token_reads_the_fixture() = runTest {
        val unsigned = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.e30.c2lnbmF0dXJl"
        assertEquals(
            fixture.servicesConfig(UseSmileIDSampleEnvironment.Sandbox, unsigned, "en-GB"),
            source.servicesConfig(UseSmileIDSampleEnvironment.Sandbox, unsigned, "en-GB"),
        )
    }

    @Test(expected = IOException::class)
    fun a_signed_token_asks_the_server() = runTest {
        source.servicesConfig(UseSmileIDSampleEnvironment.Sandbox, "eyJhbGciOiJIUzI1NiJ9.e30.c2lnbmF0dXJl", "en-GB")
    }
}
