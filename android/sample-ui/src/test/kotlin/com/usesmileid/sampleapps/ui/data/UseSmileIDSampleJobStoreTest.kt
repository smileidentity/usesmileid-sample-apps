package com.usesmileid.sampleapps.ui.data

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.withTimeoutOrNull
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** The store's own semantics over a fake DAO; Room's own SQL needs the real database. */
class UseSmileIDSampleJobStoreTest {

    @Test
    fun `adding the same job twice keeps one row`() = runTest {
        val store = UseSmileIDSampleJobStore(FakeJobDao(), NoStatusSource)
        store.add(job("job-1"))
        store.add(job("job-1"))
        assertEquals(listOf("job-1"), store.jobs.first().map { it.id })
    }

    @Test
    fun `a new job lands first`() = runTest {
        val store = UseSmileIDSampleJobStore(FakeJobDao(), NoStatusSource)
        store.add(job("job-1", createdAtMillis = 1L))
        store.add(job("job-2", createdAtMillis = 2L))
        assertEquals(listOf("job-2", "job-1"), store.jobs.first().map { it.id })
    }

    @Test
    fun `undo re-inserts what the last removal took`() = runTest {
        val store = UseSmileIDSampleJobStore(FakeJobDao(), NoStatusSource)
        store.add(job("job-1", createdAtMillis = 1L))
        store.add(job("job-2", createdAtMillis = 2L))
        store.remove(setOf("job-1"))
        assertEquals(listOf("job-2"), store.jobs.first().map { it.id })
        store.undoRemove()
        assertEquals(listOf("job-2", "job-1"), store.jobs.first().map { it.id })
    }

    @Test
    fun `an empty removal keeps the previous batch undoable`() = runTest {
        val store = UseSmileIDSampleJobStore(FakeJobDao(), NoStatusSource)
        store.add(job("job-1"))
        store.remove(setOf("job-1"))
        store.remove(emptySet())
        store.undoRemove()
        assertEquals(listOf("job-1"), store.jobs.first().map { it.id })
    }


    /** The iOS store guarded this first; nothing reachable passes an unknown id, so it is hardening. */
    @Test
    fun `a removal that took no rows keeps the previous batch undoable`() = runTest {
        val store = UseSmileIDSampleJobStore(FakeJobDao(), NoStatusSource)
        store.add(job("job-1"))
        store.remove(setOf("job-1"))
        store.remove(setOf("job-never-stored"))
        store.undoRemove()
        assertEquals(listOf("job-1"), store.jobs.first().map { it.id })
    }
    @Test
    fun `a status refresh rewrites the row it read`() = runTest {
        val store = UseSmileIDSampleJobStore(FakeJobDao(), NoStatusSource)
        store.add(job("job-1"))
        assertTrue(store.applyStatus("job-1", UseSmileIDSampleStatus.Clear, "Approved", 200))
        val stored = store.find("job-1")
        assertEquals(UseSmileIDSampleStatus.Clear, stored?.status)
        assertEquals("Approved", stored?.message)
        assertEquals(200, stored?.httpStatus)
    }

    @Test
    fun `a status refresh for an unknown job changes nothing`() = runTest {
        val store = UseSmileIDSampleJobStore(FakeJobDao(), NoStatusSource)
        assertEquals(false, store.applyStatus("job-absent", UseSmileIDSampleStatus.Clear, "Approved", 200))
        assertNull(store.find("job-absent"))
    }

    @Test
    fun `the environment and session survive a round trip`() = runTest {
        val store = UseSmileIDSampleJobStore(FakeJobDao(), NoStatusSource)
        store.add(job("job-1").copy(sandbox = false, sessionId = "4d33b7ba"))
        val stored = store.find("job-1")
        assertEquals(false, stored?.sandbox)
        assertEquals("4d33b7ba", stored?.sessionId)
    }

    /** The confirmation is an event, so it fires once for the batch and an undo is not another one. */
    @Test
    fun `a removal emits its batch size once`() = runTest {
        val store = UseSmileIDSampleJobStore(FakeJobDao(), NoStatusSource)
        store.add(job("job-1"))
        store.add(job("job-2"))
        store.remove(setOf("job-1", "job-2"))
        assertEquals(2, withTimeout(5_000) { store.removals.first() })
        store.undoRemove()
        assertNull(withTimeoutOrNull(100) { store.removals.first() })
    }

    @Test
    fun `an empty removal emits nothing`() = runTest {
        val store = UseSmileIDSampleJobStore(FakeJobDao(), NoStatusSource)
        store.remove(emptySet())
        assertNull(withTimeoutOrNull(100) { store.removals.first() })
    }

    @Test
    fun `a fresh store is empty`() = runTest {
        assertEquals(emptyList<UseSmileIDSampleJob>(), UseSmileIDSampleJobStore(FakeJobDao(), NoStatusSource).jobs.first())
    }

    /** The write scope's whole contract: cancelling the screen that launched a write must not cancel the write. */
    @Test
    fun `a write on the process scope survives cancellation of the scope that launched it`() {
        runBlocking {
            val dao = GatedDao()
            val store = UseSmileIDSampleJobStore(dao, NoStatusSource)
            val screenScope = CoroutineScope(Job())
            screenScope.launch {
                UseSmileIDSampleJobStore.writeScope.launch { store.add(job("job-1")) }
            }
            dao.entered.receive() // the insert is in flight
            screenScope.cancel() // the "screen" goes away mid-write
            dao.gate.send(Unit) // let the insert finish
            withTimeout(5_000) {
                assertEquals(listOf("job-1"), store.jobs.first { it.isNotEmpty() }.map { it.id })
            }
        }
    }

    private fun job(id: String, createdAtMillis: Long = 0L) = UseSmileIDSampleJob(
        id = id,
        userId = "user-$id",
        product = UseSmileIDSampleProduct.SmartSelfieEnrollment,
        status = UseSmileIDSampleStatus.Processing,
        createdAtMillis = createdAtMillis,
        message = "Submitted",
        httpStatus = 202,
    )
}

/** Ordering and the two conflict strategies, which is all the store's logic reads. */
internal class FakeJobDao : UseSmileIDSampleJobDao {

    private val rows = MutableStateFlow<Map<String, UseSmileIDSampleJobEntity>>(emptyMap())

    override fun all(): Flow<List<UseSmileIDSampleJobEntity>> =
        rows.map { it.values.sortedByDescending { row -> row.createdAtMillis } }

    override suspend fun find(id: String) = rows.value[id]

    override suspend fun findAll(ids: Set<String>) = rows.value.filterKeys { it in ids }.values.toList()

    override suspend fun insert(jobs: List<UseSmileIDSampleJobEntity>) {
        rows.value = rows.value + jobs.filterNot { it.id in rows.value }.associateBy { it.id }
    }

    override suspend fun updateStatus(id: String, statusId: String, message: String, httpStatus: Int): Int {
        val row = rows.value[id] ?: return 0
        rows.value = rows.value + (id to row.copy(statusId = statusId, message = message, httpStatus = httpStatus))
        return 1
    }

    override suspend fun delete(ids: Set<String>) {
        rows.value = rows.value - ids
    }

    override suspend fun count() = rows.value.size
}

/** Suspends the first insert until released, so a cancellation can land mid-write. */
private class GatedDao : UseSmileIDSampleJobDao {
    private val delegate = FakeJobDao()
    val entered = Channel<Unit>(Channel.RENDEZVOUS)
    val gate = Channel<Unit>(Channel.RENDEZVOUS)
    override suspend fun insert(jobs: List<UseSmileIDSampleJobEntity>) {
        entered.send(Unit)
        gate.receive()
        delegate.insert(jobs)
    }
    override fun all() = delegate.all()
    override suspend fun find(id: String) = delegate.find(id)
    override suspend fun findAll(ids: Set<String>) = delegate.findAll(ids)
    override suspend fun updateStatus(id: String, statusId: String, message: String, httpStatus: Int) =
        delegate.updateStatus(id, statusId, message, httpStatus)
    override suspend fun delete(ids: Set<String>) = delegate.delete(ids)
    override suspend fun count() = delegate.count()
}

/** For the tests that never refresh: reaching the network from one of them is the failure, not a fixture. */
internal object NoStatusSource : UseSmileIDSampleJobStatusSource {
    override suspend fun check(jobId: String, token: String, sandbox: Boolean) = error("no network in this test")
}
