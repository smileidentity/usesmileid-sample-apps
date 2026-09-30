package com.usesmileid.sampleapps.ui.data

import com.usesmileid.sampleapps.ui.CatalogueFixtures
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSkeletonGate
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogue
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueFamily
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueRules
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenBindings
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.IOException

@OptIn(ExperimentalCoroutinesApi::class)
class UseSmileIDSampleCatalogueStoreTest {

    /** Answers from the fixture, counting calls and failing or hanging on request. */
    private class FakeSource : UseSmileIDSampleCatalogueSource {
        private val fixture = UseSmileIDSampleFixtureCatalogueSource(CatalogueFixtures.json)
        var calls = 0
        var failing = false
        var hang: CompletableDeferred<Unit>? = null
        var lastEnvironment: UseSmileIDSampleEnvironment? = null
        var configCalls = 0
        var lastToken: String? = null
        var refusing: Int? = null

        override suspend fun supportedIdTypes(environment: UseSmileIDSampleEnvironment): String = answer(environment) {
            fixture.supportedIdTypes(environment)
        }

        override suspend fun supportedDocuments(environment: UseSmileIDSampleEnvironment, locale: String): String =
            answer(environment) { fixture.supportedDocuments(environment, locale) }

        override suspend fun servicesConfig(environment: UseSmileIDSampleEnvironment, token: String, locale: String): String {
            configCalls++
            lastToken = token
            refusing?.let { throw UseSmileIDSampleCatalogueHttpException(it) }
            return answer(environment) { fixture.servicesConfig(environment, token, locale) }
        }

        private suspend fun answer(environment: UseSmileIDSampleEnvironment, body: suspend () -> String): String {
            calls++
            lastEnvironment = environment
            hang?.await()
            if (failing) throw IOException("offline")
            return body()
        }
    }

    /** On the test's own scope: advanceUntilIdle stops once only background work is left, which would skip every fetch. */
    private fun TestScope.store(source: UseSmileIDSampleCatalogueSource) =
        UseSmileIDSampleCatalogueStore(source, this, decoder = StandardTestDispatcher(testScheduler))

    private fun session(id: String) = UseSmileIDSampleTokenSession(
        id = id,
        token = "token-$id",
        issuedAtMillis = 0,
        expiresAtMillis = 1,
        bindings = UseSmileIDSampleTokenBindings(),
        environment = UseSmileIDSampleEnvironment.Sandbox,
    )

    private val edv = UseSmileIDSampleProduct.EnhancedDocumentVerification

    @Test
    fun enhanced_document_verification_offers_only_what_the_partner_enabled() = runTest {
        val source = FakeSource()
        val store = store(source)
        store.begin(UseSmileIDSampleEnvironment.Sandbox, "en-GB")
        store.ensureEnabled(UseSmileIDSampleEnvironment.Sandbox, "en-GB", session("a"))
        advanceUntilIdle()
        assertEquals("token-a", source.lastToken)
        val enabled = store.countries(UseSmileIDSampleCatalogueFamily.Document, edv) as UseSmileIDSampleCatalogue.Ready
        assertEquals(listOf("KE", "NG"), enabled.items.map { it.code })
        val all = store.countries(UseSmileIDSampleCatalogueFamily.Document) as UseSmileIDSampleCatalogue.Ready
        assertEquals(listOf("GH", "KE", "NG", "ZA"), all.items.map { it.code })
        val kenya = store.documents("KE", edv) as UseSmileIDSampleCatalogue.Ready
        assertEquals(listOf("IDENTITY_CARD", "PASSPORT"), kenya.items.map { it.id })
    }

    @Test
    fun no_session_asks_nothing_and_names_the_refusal() = runTest {
        val source = FakeSource()
        val store = store(source)
        store.ensureEnabled(UseSmileIDSampleEnvironment.Sandbox, "en-GB", null)
        advanceUntilIdle()
        assertEquals(0, source.configCalls)
        val failed = store.enabled as UseSmileIDSampleCatalogue.Failed
        assertEquals(UseSmileIDSampleCatalogueRules.advice(401), failed.advice)
    }

    @Test
    fun the_partners_list_is_kept_per_session_and_a_relink_asks_again() = runTest {
        val source = FakeSource()
        val store = store(source)
        store.ensureEnabled(UseSmileIDSampleEnvironment.Sandbox, "en-GB", session("a"))
        advanceUntilIdle()
        store.stop()
        store.begin(UseSmileIDSampleEnvironment.Sandbox, "en-GB")
        store.ensureEnabled(UseSmileIDSampleEnvironment.Sandbox, "en-GB", session("a"))
        advanceUntilIdle()
        assertEquals("a new run on the same session must not ask again", 1, source.configCalls)
        store.ensureEnabled(UseSmileIDSampleEnvironment.Sandbox, "en-GB", session("b"))
        advanceUntilIdle()
        assertEquals(2, source.configCalls)
        assertEquals("token-b", source.lastToken)
    }

    @Test
    fun a_refused_token_names_the_reason_and_retry_asks_again() = runTest {
        listOf(401, 403).forEach { status ->
            val source = FakeSource().apply { refusing = status }
            val store = store(source)
            store.begin(UseSmileIDSampleEnvironment.Production, "en-GB")
            store.ensureEnabled(UseSmileIDSampleEnvironment.Production, "en-GB", session("a"))
            advanceUntilIdle()
            val failed = store.countries(UseSmileIDSampleCatalogueFamily.Document, edv) as UseSmileIDSampleCatalogue.Failed
            assertEquals(UseSmileIDSampleCatalogueRules.advice(status), failed.advice)
            source.refusing = null
            store.retry()
            advanceUntilIdle()
            assertTrue(store.countries(UseSmileIDSampleCatalogueFamily.Document, edv) is UseSmileIDSampleCatalogue.Ready)
        }
    }

    @Test
    fun no_network_on_the_partners_list_is_the_default_error() = runTest {
        val source = FakeSource().apply { failing = true }
        val store = store(source)
        store.ensureEnabled(UseSmileIDSampleEnvironment.Sandbox, "en-GB", session("a"))
        advanceUntilIdle()
        val failed = store.documents("KE", edv) as UseSmileIDSampleCatalogue.Failed
        assertEquals(UseSmileIDSampleCatalogueRules.DEFAULT_ADVICE, failed.advice)
    }

    @Test
    fun a_product_tap_fetches_both_lists_ahead() = runTest {
        val source = FakeSource()
        val store = store(source)
        store.begin(UseSmileIDSampleEnvironment.Production, "en-GB")
        advanceUntilIdle()
        assertEquals(2, source.calls)
        assertEquals(UseSmileIDSampleEnvironment.Production, source.lastEnvironment)
        val countries = store.countries(UseSmileIDSampleCatalogueFamily.Kyc) as UseSmileIDSampleCatalogue.Ready
        assertEquals(listOf("GH", "KE", "NG"), countries.items.map { it.code })
        assertTrue(store.idTypes("KE") is UseSmileIDSampleCatalogue.Ready)
    }

    @Test
    fun the_form_reuses_the_runs_lists_and_a_new_run_asks_again() = runTest {
        val source = FakeSource()
        val store = store(source)
        store.begin(UseSmileIDSampleEnvironment.Sandbox, "en-GB")
        advanceUntilIdle()
        store.ensure(UseSmileIDSampleEnvironment.Sandbox, "en-GB")
        advanceUntilIdle()
        assertEquals("reopening the form must not fetch again", 2, source.calls)
        store.begin(UseSmileIDSampleEnvironment.Sandbox, "en-GB")
        advanceUntilIdle()
        assertEquals("the next run asks the server again", 4, source.calls)
    }

    @Test
    fun a_failure_is_a_state_and_retry_asks_again() = runTest {
        val source = FakeSource().apply { failing = true }
        val store = store(source)
        store.begin(UseSmileIDSampleEnvironment.Sandbox, "en-GB")
        advanceUntilIdle()
        assertTrue(store.countries(UseSmileIDSampleCatalogueFamily.Kyc) is UseSmileIDSampleCatalogue.Failed)
        source.failing = false
        store.retry()
        assertEquals(UseSmileIDSampleCatalogue.Loading, store.countries(UseSmileIDSampleCatalogueFamily.Kyc))
        advanceUntilIdle()
        assertTrue(store.countries(UseSmileIDSampleCatalogueFamily.Kyc) is UseSmileIDSampleCatalogue.Ready)
    }

    @Test
    fun ten_seconds_without_an_answer_is_a_failure_never_an_endless_skeleton() = runTest {
        val source = FakeSource().apply { hang = CompletableDeferred() }
        val store = store(source)
        store.begin(UseSmileIDSampleEnvironment.Sandbox, "en-GB")
        advanceTimeBy(9_999)
        runCurrent()
        assertEquals(UseSmileIDSampleCatalogue.Loading, store.countries(UseSmileIDSampleCatalogueFamily.Document))
        advanceTimeBy(2)
        runCurrent()
        assertTrue(store.countries(UseSmileIDSampleCatalogueFamily.Document) is UseSmileIDSampleCatalogue.Failed)
    }

    @Test
    fun leaving_cancels_what_is_in_flight() = runTest {
        val source = FakeSource().apply { hang = CompletableDeferred() }
        val store = store(source)
        store.begin(UseSmileIDSampleEnvironment.Sandbox, "en-GB")
        runCurrent()
        store.stop()
        source.hang?.complete(Unit)
        advanceUntilIdle()
        assertEquals("a cancelled fetch must not land after the form is gone", UseSmileIDSampleCatalogue.Loading, store.idTypes)
    }

    @Test
    fun a_country_with_nothing_the_form_can_use_is_empty() = runTest {
        val store = store(FakeSource())
        store.begin(UseSmileIDSampleEnvironment.Sandbox, "en-GB")
        advanceUntilIdle()
        assertEquals(UseSmileIDSampleCatalogue.Empty, store.idTypes("ET"))
        assertEquals(UseSmileIDSampleCatalogue.Empty, store.documents("RW"))
    }

    @Test
    fun the_skeleton_waits_300_ms_then_stays_at_least_400_ms() = runTest {
        val gate = UseSmileIDSampleSkeletonGate(backgroundScope) { testScheduler.currentTime }
        gate.loading(true)
        advanceTimeBy(299)
        runCurrent()
        assertFalse("a fast answer never flashes a skeleton", gate.visible)
        advanceTimeBy(2)
        runCurrent()
        assertTrue(gate.visible)
        gate.loading(false)
        advanceTimeBy(398)
        runCurrent()
        assertTrue("shown rows never flicker away early", gate.visible)
        advanceTimeBy(3)
        runCurrent()
        assertFalse(gate.visible)
    }

    @Test
    fun an_answer_inside_300_ms_shows_no_skeleton_at_all() = runTest {
        val gate = UseSmileIDSampleSkeletonGate(backgroundScope) { testScheduler.currentTime }
        gate.loading(true)
        advanceTimeBy(200)
        gate.loading(false)
        advanceUntilIdle()
        assertFalse(gate.visible)
    }
}
