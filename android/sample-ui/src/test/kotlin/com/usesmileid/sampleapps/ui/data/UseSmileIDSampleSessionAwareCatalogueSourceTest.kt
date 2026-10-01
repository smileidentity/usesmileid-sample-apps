package com.usesmileid.sampleapps.ui.data

import com.usesmileid.sampleapps.ui.CatalogueFixtures
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Test
import java.io.IOException
import java.util.Base64

class UseSmileIDSampleSessionAwareCatalogueSourceTest {

    private val fixture = UseSmileIDSampleFixtureCatalogueSource(CatalogueFixtures.json)
    private val source = UseSmileIDSampleSessionAwareCatalogueSource(UseSmileIDSampleUnreachableCatalogueSource, fixture)

    private fun token(header: String) = listOf(header, "{}", "not-a-signature")
        .joinToString(".") { Base64.getUrlEncoder().withoutPadding().encodeToString(it.toByteArray()) }

    @Test
    fun a_simulated_sessions_unsigned_token_reads_the_fixture() = runTest {
        val unsigned = token("""{"alg":"none","typ":"JWT"}""")
        assertEquals(
            fixture.servicesConfig(UseSmileIDSampleEnvironment.Sandbox, unsigned, "en-GB"),
            source.servicesConfig(UseSmileIDSampleEnvironment.Sandbox, unsigned, "en-GB"),
        )
    }

    @Test
    fun an_empty_token_is_refused_without_asking_the_server() = runTest {
        val refused = runCatching { source.servicesConfig(UseSmileIDSampleEnvironment.Sandbox, "", "en-GB") }.exceptionOrNull()
        assertEquals(401, (refused as UseSmileIDSampleCatalogueHttpException).status)
    }

    @Test(expected = IOException::class)
    fun a_signed_token_asks_the_server() = runTest {
        source.servicesConfig(UseSmileIDSampleEnvironment.Sandbox, token("""{"alg":"HS256","typ":"JWT"}"""), "en-GB")
    }
}
