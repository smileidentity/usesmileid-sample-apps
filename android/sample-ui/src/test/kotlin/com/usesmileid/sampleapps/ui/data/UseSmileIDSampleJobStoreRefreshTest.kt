package com.usesmileid.sampleapps.ui.data

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenBindings
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import kotlinx.coroutines.async
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.IOException
import kotlin.coroutines.cancellation.CancellationException

/** The refresh sequence the store owns: what it reads off the row, and what it never asks the caller for. */
class UseSmileIDSampleJobStoreRefreshTest {

    @Test
    fun `refresh with no live session reports NoSession`() = runTest {
        val source = FakeStatusSource { _, _, _ -> updated() }
        val store = store(source)
        store.add(job("job-1", sessionId = "s-1"))

        assertEquals(UseSmileIDSampleStatusRefresh.NoSession, store.refresh("job-1", live = null, nowMillis = NOW))
        assertTrue(source.calls.isEmpty())
    }

    @Test
    fun `refresh with an expired session reports NoSession`() = runTest {
        val source = FakeStatusSource { _, _, _ -> updated() }
        val store = store(source)
        store.add(job("job-1", sessionId = "s-1"))

        val expired = session(id = "s-1", expiresAtMillis = NOW - 1)
        assertEquals(UseSmileIDSampleStatusRefresh.NoSession, store.refresh("job-1", expired, NOW))
        assertTrue(source.calls.isEmpty())
    }

    /** The row records the environment it was submitted under, and a refresh must ask that one. */
    @Test
    fun `refresh asks the environment recorded on the row`() = runTest {
        val source = FakeStatusSource { _, _, _ -> updated() }
        val store = store(source)
        store.add(job("job-production", sessionId = "s-1", sandbox = false))
        store.add(job("job-sandbox", sessionId = "s-1", sandbox = true))

        store.refresh("job-production", session(id = "s-1"), NOW)
        assertEquals(false, source.calls.single().third)

        store.refresh("job-sandbox", session(id = "s-1"), NOW)
        assertEquals(true, source.calls.last().third)
    }

    @Test
    fun `refresh under a different partner reports PartnerMismatch without calling the server`() = runTest {
        val source = FakeStatusSource { _, _, _ -> updated() }
        val store = store(source)
        store.add(job("job-1", sessionId = "old", partnerId = "partner-a"))

        val outcome = store.refresh("job-1", session(id = "new", partnerId = "partner-b"), NOW)
        assertEquals(UseSmileIDSampleStatusRefresh.PartnerMismatch, outcome)
        assertTrue(source.calls.isEmpty())
    }

    @Test
    fun `a new session for the same partner refreshes a row the expired one created`() = runTest {
        val source = FakeStatusSource { _, _, _ -> updated() }
        val store = store(source)
        store.add(job("job-1", sessionId = "expired", partnerId = "partner-a"))

        assertEquals(updated(), store.refresh("job-1", session(id = "fresh", partnerId = "partner-a"), NOW))
        assertEquals("token-fresh", source.calls.single().second)
    }

    @Test
    fun `refresh of a row without a session reports NoServerJob`() = runTest {
        val source = FakeStatusSource { _, _, _ -> updated() }
        val store = store(source)
        store.add(job("job-1", sessionId = null))

        assertEquals(UseSmileIDSampleStatusRefresh.NoServerJob, store.refresh("job-1", session(), NOW))
        assertTrue(source.calls.isEmpty())
    }

    @Test
    fun `an IOException maps to the could-not-reach failure`() = runTest {
        val store = store(FakeStatusSource { _, _, _ -> throw IOException() })
        store.add(job("job-1", sessionId = "s-1"))

        assertEquals(
            UseSmileIDSampleStatusRefresh.Failed(UseSmileIDSampleStatusRefresh.Reason.Unreachable),
            store.refresh("job-1", session(id = "s-1"), NOW),
        )
    }

    @Test
    fun `a cancellation rethrows instead of reporting failure`() = runTest {
        val store = store(FakeStatusSource { _, _, _ -> throw CancellationException() })
        store.add(job("job-1", sessionId = "s-1"))

        var thrown = false
        try {
            store.refresh("job-1", session(id = "s-1"), NOW)
        } catch (e: CancellationException) {
            thrown = true
        }
        assertTrue(thrown)
    }

    /** The row the write would land on can go away mid-request, and the list must not be contradicted. */
    @Test
    fun `a row deleted mid-request reports the stored failure`() = runTest {
        val dao = FakeJobDao()
        val store = UseSmileIDSampleJobStore(
            dao,
            FakeStatusSource { _, _, _ ->
                dao.delete(setOf("job-1"))
                updated()
            },
        )
        store.add(job("job-1", sessionId = "s-1"))

        assertEquals(
            UseSmileIDSampleStatusRefresh.Failed(UseSmileIDSampleStatusRefresh.Reason.NotStored),
            store.refresh("job-1", session(id = "s-1"), NOW),
        )
        assertNull(store.find("job-1"))
    }

    @Test
    fun `a second refresh while one is in flight is skipped`() = runTest {
        val entered = Channel<Unit>(Channel.RENDEZVOUS)
        val gate = Channel<Unit>(Channel.RENDEZVOUS)
        val source = FakeStatusSource { _, _, _ ->
            entered.send(Unit)
            gate.receive()
            updated()
        }
        val store = store(source)
        store.add(job("job-1", sessionId = "s-1"))

        val first = async { store.refresh("job-1", session(id = "s-1"), NOW) }
        entered.receive()
        assertNull(store.refresh("job-1", session(id = "s-1"), NOW))
        gate.send(Unit)
        assertEquals(updated(), first.await())
        assertEquals(1, source.calls.size)
    }

    /** Leaving mid-refresh must not make the row unrefreshable for the rest of the process. */
    @Test
    fun `a cancelled refresh releases the in-flight guard`() = runTest {
        val entered = Channel<Unit>(Channel.RENDEZVOUS)
        val gate = Channel<Unit>(Channel.RENDEZVOUS)
        val source = FakeStatusSource { _, _, _ ->
            entered.send(Unit)
            gate.receive()
            updated()
        }
        val store = store(source)
        store.add(job("job-1", sessionId = "s-1"))

        val leaving = launch { store.refresh("job-1", session(id = "s-1"), NOW) }
        entered.receive()
        leaving.cancelAndJoin()

        // Ungated, so a still-held guard shows up as a null return rather than as a hang.
        source.answer = { _, _, _ -> updated() }
        assertEquals(updated(), store.refresh("job-1", session(id = "s-1"), NOW))
    }

    @Test
    fun `a successful update writes the row back`() = runTest {
        val store = store(FakeStatusSource { _, _, _ -> updated() })
        store.add(job("job-1", sessionId = "s-1"))

        assertEquals(updated(), store.refresh("job-1", session(id = "s-1"), NOW))
        val stored = store.find("job-1")
        assertEquals(UseSmileIDSampleStatus.Clear, stored?.status)
        assertEquals("Approved", stored?.message)
        assertEquals(200, stored?.httpStatus)
    }

    @Test
    fun `a 404 reads as processing while the job is new, and as a failure after the window`() = runTest {
        val store = store(FakeStatusSource { _, _, _ -> UseSmileIDSampleStatusRefresh.NotRecorded })
        store.add(job("job-new", sessionId = "s-1").copy(createdAtMillis = NOW - 60_000L))
        store.add(job("job-old", sessionId = "s-1").copy(createdAtMillis = NOW - UseSmileIDSampleJobStore.NOT_RECORDED_WINDOW_MILLIS))

        assertEquals(UseSmileIDSampleStatusRefresh.StillProcessing, store.refresh("job-new", session(id = "s-1"), NOW))
        assertEquals(UseSmileIDSampleStatusRefresh.Failed("HTTP 404"), store.refresh("job-old", session(id = "s-1"), NOW))
    }

    @Test
    fun `the list backs off from 5 seconds to a minute and stops after twelve checks`() {
        assertEquals(
            listOf(5_000L, 10_000L, 20_000L, 40_000L, 60_000L, 60_000L, 60_000L, 60_000L, 60_000L, 60_000L, 60_000L, 60_000L, null),
            (0..12).map { UseSmileIDSampleJobStore.processingPollDelayMillis(it) },
        )
    }

    @Test
    fun `the list's check asks about every processing row and counts those still processing`() = runTest {
        val source = FakeStatusSource { jobId, _, _ ->
            if (jobId == "job-done") updated() else UseSmileIDSampleStatusRefresh.StillProcessing
        }
        val store = store(source)
        store.add(job("job-done", sessionId = "s-1"))
        store.add(job("job-waiting", sessionId = "s-1"))
        store.add(job("job-cleared", sessionId = "s-1").copy(status = UseSmileIDSampleStatus.Clear))

        assertEquals(1, store.refreshProcessing(session(id = "s-1"), NOW))
        assertEquals(setOf("job-done", "job-waiting"), source.calls.map { it.first }.toSet())
        assertEquals(UseSmileIDSampleStatus.Clear, store.find("job-done")?.status)
    }

    @Test
    fun `rows the session cannot ask about are not counted, so the list stops checking`() = runTest {
        val source = FakeStatusSource { _, _, _ -> UseSmileIDSampleStatusRefresh.StillProcessing }
        val store = store(source)
        store.add(job("job-fixture", sessionId = null))
        store.add(job("job-other", sessionId = "s-1", partnerId = "partner-b"))

        assertEquals(0, store.refreshProcessing(session(id = "s-1"), NOW))
        assertEquals(0, store.refreshProcessing(live = null, nowMillis = NOW))
        assertTrue(source.calls.isEmpty())
    }

    private fun store(source: UseSmileIDSampleJobStatusSource) = UseSmileIDSampleJobStore(FakeJobDao(), source)

    private fun updated() = UseSmileIDSampleStatusRefresh.Updated(UseSmileIDSampleStatus.Clear, "Approved", 200)

    private fun session(
        id: String = "s-1",
        expiresAtMillis: Long = NOW + 60_000L,
        partnerId: String? = PARTNER,
    ) = UseSmileIDSampleTokenSession(
        id = id,
        token = "token-$id",
        issuedAtMillis = NOW - 60_000L,
        expiresAtMillis = expiresAtMillis,
        bindings = UseSmileIDSampleTokenBindings(),
        partnerId = partnerId,
        environment = UseSmileIDSampleEnvironment.Sandbox,
    )

    private fun job(
        id: String,
        sessionId: String?,
        sandbox: Boolean = true,
        partnerId: String? = PARTNER,
    ) = UseSmileIDSampleJob(
        id = id,
        userId = "user-$id",
        product = UseSmileIDSampleProduct.SmartSelfieEnrollment,
        status = UseSmileIDSampleStatus.Processing,
        createdAtMillis = 0L,
        message = "Submitted",
        httpStatus = 202,
        sandbox = sandbox,
        sessionId = sessionId,
        partnerId = partnerId,
    )

    private companion object {
        const val NOW = 1_784_202_612_000L

        const val PARTNER = "partner-a"
    }
}

/** Records what the store asked for, which is the point of most of the table above. */
private class FakeStatusSource(
    var answer: suspend (jobId: String, token: String, sandbox: Boolean) -> UseSmileIDSampleStatusRefresh,
) : UseSmileIDSampleJobStatusSource {

    val calls = mutableListOf<Triple<String, String, Boolean>>()

    override suspend fun check(jobId: String, token: String, sandbox: Boolean): UseSmileIDSampleStatusRefresh {
        calls += Triple(jobId, token, sandbox)
        return answer(jobId, token, sandbox)
    }
}
