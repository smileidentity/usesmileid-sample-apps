package com.usesmileid.sampleapps.ui.data

import android.content.Context
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenBindings
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import com.usesmileid.sampleapps.ui.state.bindsIdDetails
import com.usesmileid.sampleapps.ui.state.bindsRequiredUserDetails
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.io.IOException
import kotlin.coroutines.cancellation.CancellationException

/** The submitted verifications, on disk: the SDK delivers a result once, and there is nowhere else to get it from. */
class UseSmileIDSampleJobStore(
    private val dao: UseSmileIDSampleJobDao,
    private val source: UseSmileIDSampleJobStatusSource,
) {

    /** What the last [remove] took, so undo re-inserts rather than clearing a soft-delete column. */
    private var lastRemoved: List<UseSmileIDSampleJobEntity> = emptyList()

    /** In flight per job id, so the entry refresh and a pull cannot double-request the same row. */
    private val inFlight = mutableSetOf<String>()
    private val inFlightLock = Mutex()

    /** Buffered until the list screen collects: the details screen navigates away before it could draw a confirmation. */
    private val removalNotices = Channel<Int>(Channel.BUFFERED)

    /** Batch sizes of removals, consumed exactly once by whoever renders the confirmation. */
    val removals: Flow<Int> = removalNotices.receiveAsFlow()

    val jobs: Flow<List<UseSmileIDSampleJob>> = dao.all().map { rows -> rows.map { it.toJob() } }

    /** A no-op on an id already stored, which is what makes a repeated result delivery harmless. */
    suspend fun add(job: UseSmileIDSampleJob, bindings: UseSmileIDSampleTokenBindings? = null) {
        dao.insert(
            listOf(
                job.toEntity(
                    boundUserDetails = bindings?.bindsRequiredUserDetails == true,
                    boundIdDetails = bindings?.bindsIdDetails(job.product) == true,
                    boundConsent = bindings?.consent != null,
                ),
            ),
        )
    }

    /** Retains the deleted rows for [undoRemove]; only the most recent batch stays undoable. */
    suspend fun remove(ids: Set<String>) {
        // A no-op removal must not discard an earlier batch that is still undoable.
        if (ids.isEmpty()) return
        lastRemoved = dao.findAll(ids)
        dao.delete(ids)
        lastRemoved.size.takeIf { it > 0 }?.let { removalNotices.trySend(it) }
    }

    /**
     * Re-inserts the batch the last [remove] took, and is a no-op with nothing pending.
     * Order restores itself: the list is ordered by the rows' own timestamps, not by insertion.
     */
    suspend fun undoRemove() {
        if (lastRemoved.isEmpty()) return
        dao.insert(lastRemoved)
        lastRemoved = emptyList()
    }

    /** The one write that overwrites: a status refresh rewrites its row in one atomic update. */
    suspend fun applyStatus(
        jobId: String,
        status: UseSmileIDSampleStatus,
        message: String,
        httpStatus: Int,
    ): Boolean = dao.updateStatus(jobId, status.name, message, httpStatus) > 0

    /**
     * The whole refresh sequence, owned by what owns the rows: read the row, take the environment
     * and partner FROM THE ROW, ask the source, write back atomically. Returns null when a refresh
     * for this job is already in flight — the second request is skipped, mirroring the screen
     * affordance it replaces.
     */
    suspend fun refresh(
        jobId: String,
        live: UseSmileIDSampleTokenSession?,
        nowMillis: Long,
    ): UseSmileIDSampleStatusRefresh? {
        inFlightLock.withLock { if (!inFlight.add(jobId)) return null }
        try {
            val row = dao.find(jobId)
                ?: return UseSmileIDSampleStatusRefresh.Failed("The verification is no longer stored")
            if (row.sessionId == null) return UseSmileIDSampleStatusRefresh.NoServerJob
            val session = live?.takeUnless { it.hasExpired(nowMillis) }
                ?: return UseSmileIDSampleStatusRefresh.NoSession
            // The partner, not the session: tokens expire and the same partner holds a newer one.
            if (session.partnerId != row.partnerId) return UseSmileIDSampleStatusRefresh.PartnerMismatch
            val outcome = try {
                // The row's environment, never the toggle: a row outlives the toggle that produced it.
                source.check(jobId, session.token, sandbox = row.sandbox)
            } catch (e: IOException) {
                return UseSmileIDSampleStatusRefresh.Failed("Could not reach the server")
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                // The type, never the message: this text goes on screen and a client exception carries the request URL.
                return UseSmileIDSampleStatusRefresh.Failed("Unexpected error: ${e::class.simpleName}")
            }
            if (outcome !is UseSmileIDSampleStatusRefresh.Updated) return outcome
            val written = applyStatus(
                jobId = jobId,
                status = outcome.status,
                message = outcome.message,
                httpStatus = outcome.httpCode,
            )
            return if (written) outcome else UseSmileIDSampleStatusRefresh.Failed("The verification is no longer stored")
        } finally {
            // The guard must release even on a cancelled caller, or the row is silently unrefreshable for the rest of the process.
            withContext(NonCancellable) { inFlightLock.withLock { inFlight.remove(jobId) } }
        }
    }

    suspend fun find(jobId: String): UseSmileIDSampleJob? = dao.find(jobId)?.toJob()

    /** Reached only by the `seedJobs` launch argument — see `spec/launch-args.json`. Idempotent. */
    suspend fun seedFixtures(nowMillis: Long) = dao.insert(fixtures(nowMillis).map { it.toEntity() })

    companion object {
        @Volatile
        private var instance: UseSmileIDSampleJobStore? = null

        /** One per process: a remembered store would open a second Room pool on every recreation and leak the first. */
        fun of(context: Context, source: UseSmileIDSampleJobStatusSource): UseSmileIDSampleJobStore =
            instance ?: synchronized(this) {
                instance ?: UseSmileIDSampleJobStore(UseSmileIDSampleJobDatabase.open(context).jobs(), source)
                    .also { instance = it }
            }

        /** One per process, like the store: a write must outlive whatever screen or recreation launched it. */
        val writeScope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

        /** The eleven the design's counts describe, offset from a caller-supplied now. */
        fun fixtures(nowMillis: Long): List<UseSmileIDSampleJob> {
            val statuses = listOf(
                UseSmileIDSampleStatus.Clear,
                UseSmileIDSampleStatus.Processing,
                UseSmileIDSampleStatus.Clear,
                UseSmileIDSampleStatus.Attention,
                UseSmileIDSampleStatus.Blocked,
                UseSmileIDSampleStatus.Clear,
                UseSmileIDSampleStatus.Clear,
                UseSmileIDSampleStatus.Attention,
                UseSmileIDSampleStatus.Blocked,
                UseSmileIDSampleStatus.Clear,
                UseSmileIDSampleStatus.Clear,
            )
            val products = UseSmileIDSampleProduct.entries
            return statuses.mapIndexed { index, status ->
                UseSmileIDSampleJob(
                    id = "job_%02dky31za%02d".format(index, index * 7 % 100),
                    userId = "user_%02dky31za%02d".format(index, index * 3 % 100),
                    product = products[index % products.size],
                    status = status,
                    createdAtMillis = nowMillis - index * HOURS_APART * MILLIS_PER_HOUR,
                    message = status.message(),
                    httpStatus = if (status == UseSmileIDSampleStatus.Processing) HTTP_ACCEPTED else HTTP_OK,
                )
            }
        }

        private fun UseSmileIDSampleStatus.message() = when (this) {
            UseSmileIDSampleStatus.Clear -> "Approved"
            UseSmileIDSampleStatus.Attention -> "Provisional — needs review"
            UseSmileIDSampleStatus.Blocked -> "Rejected"
            UseSmileIDSampleStatus.Processing -> "Submitted, awaiting result"
        }

        private const val HOURS_APART = 5L
        private const val MILLIS_PER_HOUR = 60L * 60L * 1000L
        private const val HTTP_OK = 200
        private const val HTTP_ACCEPTED = 202
    }
}
