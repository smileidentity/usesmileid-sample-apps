package com.usesmileid.sampleapps.ui.data

import com.usesmileid.sampleapps.ui.CatalogueFixtures
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSkeletonGate
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogue
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueFamily
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

        override suspend fun supportedIdTypes(environment: UseSmileIDSampleEnvironment): String = answer(environment) {
            fixture.supportedIdTypes(environment)
        }

        override suspend fun supportedDocuments(environment: UseSmileIDSampleEnvironment, locale: String): String =
            answer(environment) { fixture.supportedDocuments(environment, locale) }

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
