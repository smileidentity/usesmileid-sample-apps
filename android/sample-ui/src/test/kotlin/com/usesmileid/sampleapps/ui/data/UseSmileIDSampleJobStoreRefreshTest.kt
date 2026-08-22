package com.usesmileid.sampleapps.ui.data

import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus
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
    fun `refresh with a different live session reports SessionMismatch without calling the server`() = runTest {
        val source = FakeStatusSource { _, _, _ -> updated() }
        val store = store(source)
        store.add(job("job-1", sessionId = "old"))

        val outcome = store.refresh("job-1", session(id = "new"), NOW)
        assertEquals(UseSmileIDSampleStatusRefresh.SessionMismatch, outcome)
        assertTrue(source.calls.isEmpty())
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
            UseSmileIDSampleStatusRefresh.Failed("Could not reach the server"),
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
            UseSmileIDSampleStatusRefresh.Failed("The verification is no longer stored"),
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

    private fun store(source: UseSmileIDSampleJobStatusSource) = UseSmileIDSampleJobStore(FakeJobDao(), source)

    private fun updated() = UseSmileIDSampleStatusRefresh.Updated(UseSmileIDSampleStatus.Clear, "Approved", 200)

    private fun session(id: String = "s-1", expiresAtMillis: Long = NOW + 60_000L) = UseSmileIDSampleTokenSession(
        id = id,
        token = "token-$id",
        issuedAtMillis = NOW - 60_000L,
        expiresAtMillis = expiresAtMillis,
        bindings = UseSmileIDSampleTokenBindings(),
    )

    private fun job(id: String, sessionId: String?, sandbox: Boolean = true) = UseSmileIDSampleJob(
        id = id,
        userId = "user-$id",
        product = UseSmileIDSampleProduct.SmartSelfieEnrollment,
        status = UseSmileIDSampleStatus.Processing,
        createdAtMillis = 0L,
        message = "Submitted",
        httpStatus = 202,
        sandbox = sandbox,
        sessionId = sessionId,
    )

    private companion object {
        const val NOW = 1_784_202_612_000L
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
