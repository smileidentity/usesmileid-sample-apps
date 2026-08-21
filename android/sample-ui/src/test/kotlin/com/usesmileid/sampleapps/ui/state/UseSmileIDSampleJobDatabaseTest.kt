package com.usesmileid.sampleapps.ui.state

import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.golden.ROBOLECTRIC_SDK
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** The SQL itself, against a real database: the store's own tests use a fake DAO and prove nothing about it. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [ROBOLECTRIC_SDK])
class UseSmileIDSampleJobDatabaseTest {

    private lateinit var database: UseSmileIDSampleJobDatabase
    private lateinit var dao: UseSmileIDSampleJobDao

    @Before
    fun open() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            UseSmileIDSampleJobDatabase::class.java,
        ).build()
        dao = database.jobs()
    }

    @After
    fun close() = database.close()

    @Test
    fun `rows come back newest first`() = runTest {
        dao.insert(listOf(entity("job-old", createdAtMillis = 1L), entity("job-new", createdAtMillis = 9L)))
        assertEquals(listOf("job-new", "job-old"), dao.all().first().map { it.id })
    }

    /** The conflict strategy the repeated-result guarantee rests on. */
    @Test
    fun `insert ignores a job id already stored`() = runTest {
        dao.insert(listOf(entity("job-1", message = "first")))
        dao.insert(listOf(entity("job-1", message = "second")))
        assertEquals(1, dao.count())
        assertEquals("first", dao.find("job-1")?.message)
    }

    /** The one write that must change a row, or a status refresh could never land. */
    @Test
    fun `updateStatus rewrites exactly the row it names`() = runTest {
        dao.insert(listOf(entity("job-1", message = "first"), entity("job-2", message = "other")))
        assertEquals(1, dao.updateStatus("job-1", UseSmileIDSampleStatus.Clear.name, "second", "200 OK"))
        assertEquals("second", dao.find("job-1")?.message)
        assertEquals("other", dao.find("job-2")?.message)
    }

    @Test
    fun `updateStatus on an absent id affects no rows`() = runTest {
        assertEquals(0, dao.updateStatus("job-absent", UseSmileIDSampleStatus.Clear.name, "x", "200 OK"))
    }

    @Test
    fun `delete removes only the ids it is given`() = runTest {
        dao.insert(listOf(entity("job-1"), entity("job-2"), entity("job-3")))
        dao.delete(setOf("job-1", "job-3"))
        assertEquals(listOf("job-2"), dao.all().first().map { it.id })
    }

    @Test
    fun `find returns null for a job that was never stored`() = runTest {
        assertNull(dao.find("job-absent"))
    }

    /** Enums are stored as string ids, so a round trip through SQLite must preserve them. */
    @Test
    fun `a row survives a round trip with its enums and flags intact`() = runTest {
        val job = UseSmileIDSampleJob(
            id = "job-1",
            userId = "user-1",
            product = UseSmileIDSampleProduct.EnhancedDocumentVerification,
            status = UseSmileIDSampleStatus.Attention,
            createdAtMillis = 42L,
            message = "Provisional",
            httpStatus = "200 OK",
            sandbox = false,
            sessionId = "4d33b7ba",
        )
        dao.insert(listOf(job.toEntity(boundUserDetails = true, boundConsent = true)))
        val stored = dao.find("job-1")

        assertEquals(job, stored?.toJob())
        assertEquals(true, stored?.boundUserDetails)
        assertEquals(false, stored?.boundIdDetails)
        assertEquals(true, stored?.boundConsent)
    }

    /** The store re-inserts what it removed, which only restores order because the query does the ordering. */
    @Test
    fun `re-inserting a removed row restores its place in the order`() = runTest {
        val store = UseSmileIDSampleJobStore(dao)
        store.add(job("job-1", createdAtMillis = 1L))
        store.add(job("job-2", createdAtMillis = 2L))
        store.add(job("job-3", createdAtMillis = 3L))
        store.remove(setOf("job-2"))
        store.undoRemove()
        assertEquals(listOf("job-3", "job-2", "job-1"), store.jobs.first().map { it.id })
    }

    /** A delete landing mid-refresh must win: the row stays deleted and the write reports failure. */
    @Test
    fun `a delete landing mid-refresh does not resurrect the row`() = runTest {
        dao.insert(listOf(entity("job-1")))
        val store = UseSmileIDSampleJobStore(DeleteBeforeWriteDao(dao))
        val written = store.applyStatus("job-1", UseSmileIDSampleStatus.Clear, "Approved", "200 OK")
        assertEquals(false, written)
        assertNull(dao.find("job-1"))
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

    private fun entity(id: String, createdAtMillis: Long = 0L, message: String = "Submitted") =
        job(id, createdAtMillis).copy(message = message).toEntity()

    /** Injects a delete immediately before the status write, the interleaving the details screen can produce. */
    private class DeleteBeforeWriteDao(private val delegate: UseSmileIDSampleJobDao) :
        UseSmileIDSampleJobDao by delegate {
        override suspend fun updateStatus(id: String, statusId: String, message: String, httpStatus: String): Int {
            delegate.delete(setOf(id))
            return delegate.updateStatus(id, statusId, message, httpStatus)
        }
    }
}
