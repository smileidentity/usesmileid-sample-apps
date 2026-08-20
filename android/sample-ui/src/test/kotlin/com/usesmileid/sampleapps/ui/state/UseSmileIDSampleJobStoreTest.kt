package com.usesmileid.sampleapps.ui.state

import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The store's own semantics, over a fake DAO. Room's SQL — the ordering, the conflict strategies —
 * needs the real database and belongs with the rest of the parked test batch.
 */
class UseSmileIDSampleJobStoreTest {

    @Test
    fun `adding the same job twice keeps one row`() = runTest {
        val store = UseSmileIDSampleJobStore(FakeJobDao())
        store.add(job("job-1"))
        store.add(job("job-1"))
        assertEquals(listOf("job-1"), store.jobs.first().map { it.id })
    }

    @Test
    fun `a new job lands first`() = runTest {
        val store = UseSmileIDSampleJobStore(FakeJobDao())
        store.add(job("job-1", createdAtMillis = 1L))
        store.add(job("job-2", createdAtMillis = 2L))
        assertEquals(listOf("job-2", "job-1"), store.jobs.first().map { it.id })
    }

    @Test
    fun `undo re-inserts what the last removal took`() = runTest {
        val store = UseSmileIDSampleJobStore(FakeJobDao())
        store.add(job("job-1", createdAtMillis = 1L))
        store.add(job("job-2", createdAtMillis = 2L))
        store.remove(setOf("job-1"))
        assertEquals(listOf("job-2"), store.jobs.first().map { it.id })
        store.undoRemove()
        assertEquals(listOf("job-2", "job-1"), store.jobs.first().map { it.id })
    }

    /** The reason [UseSmileIDSampleJobStore.remove] returns early: an empty set must not clear the batch. */
    @Test
    fun `an empty removal keeps the previous batch undoable`() = runTest {
        val store = UseSmileIDSampleJobStore(FakeJobDao())
        store.add(job("job-1"))
        store.remove(setOf("job-1"))
        store.remove(emptySet())
        store.undoRemove()
        assertEquals(listOf("job-1"), store.jobs.first().map { it.id })
    }

    @Test
    fun `a status refresh rewrites the row it read`() = runTest {
        val store = UseSmileIDSampleJobStore(FakeJobDao())
        store.add(job("job-1"))
        assertTrue(store.applyStatus("job-1", UseSmileIDSampleStatus.Clear, "Approved", "200 OK"))
        val stored = store.find("job-1")
        assertEquals(UseSmileIDSampleStatus.Clear, stored?.status)
        assertEquals("Approved", stored?.message)
        assertEquals("200 OK", stored?.httpStatus)
    }

    @Test
    fun `a status refresh for an unknown job changes nothing`() = runTest {
        val store = UseSmileIDSampleJobStore(FakeJobDao())
        assertEquals(false, store.applyStatus("job-absent", UseSmileIDSampleStatus.Clear, "Approved", "200 OK"))
        assertNull(store.find("job-absent"))
    }

    /** The session the run submitted under is what decides whether a status refresh has anything to ask. */
    @Test
    fun `the environment and session survive a round trip`() = runTest {
        val store = UseSmileIDSampleJobStore(FakeJobDao())
        store.add(job("job-1").copy(sandbox = false, sessionId = "4d33b7ba"))
        val stored = store.find("job-1")
        assertEquals(false, stored?.sandbox)
        assertEquals("4d33b7ba", stored?.sessionId)
    }

    /** The app seeds nothing, so an untouched install has an empty list rather than eleven claims. */
    @Test
    fun `a fresh store is empty`() = runTest {
        assertEquals(emptyList<UseSmileIDSampleJob>(), UseSmileIDSampleJobStore(FakeJobDao()).jobs.first())
    }

    private fun job(id: String, createdAtMillis: Long = 0L) = UseSmileIDSampleJob(
        id = id,
        userId = "user-$id",
        product = UseSmileIDSampleProduct.SmartSelfieEnrollment,
        status = UseSmileIDSampleStatus.Processing,
        createdAtMillis = createdAtMillis,
        message = "Submitted",
        httpStatus = "202 Accepted",
    )
}

/** Ordering and the two conflict strategies mirrored in Kotlin, which is all the store's logic reads. */
private class FakeJobDao : UseSmileIDSampleJobDao {

    private val rows = MutableStateFlow<Map<String, UseSmileIDSampleJobEntity>>(emptyMap())

    override fun all(): Flow<List<UseSmileIDSampleJobEntity>> =
        rows.map { it.values.sortedByDescending { row -> row.createdAtMillis } }

    override suspend fun find(id: String) = rows.value[id]

    override suspend fun insert(jobs: List<UseSmileIDSampleJobEntity>) {
        rows.value = rows.value + jobs.filterNot { it.id in rows.value }.associateBy { it.id }
    }

    override suspend fun upsert(job: UseSmileIDSampleJobEntity) {
        rows.value = rows.value + (job.id to job)
    }

    override suspend fun delete(ids: Set<String>) {
        rows.value = rows.value - ids
    }

    override suspend fun count() = rows.value.size
}
