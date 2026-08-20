package com.usesmileid.sampleapps.ui.state

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

/**
 * The submitted verifications, on disk. A job survives the process because the SDK's result arrives
 * once and there is nowhere else to get it from — a re-read of the server would need a status call
 * per row, and a cancelled run leaves nothing to re-read at all.
 */
class UseSmileIDSampleJobStore(private val dao: UseSmileIDSampleJobDao) {

    constructor(context: Context) : this(UseSmileIDSampleJobDatabase.open(context).jobs())

    /** What the last [remove] took, so undo re-inserts rather than clearing a soft-delete column. */
    private var lastRemoved: List<UseSmileIDSampleJobEntity> = emptyList()

    /**
     * How many rows the last removal took, for whoever shows the confirmation. Held here rather than
     * on the screen that removed them, because three paths remove — the swipe, the selection bar, and
     * the details screen's own delete — and the third navigates away before a confirmation could be
     * drawn. The list reads it on arrival instead.
     *
     * Consumed once by [takeRemovalNotice]: a value that merely persisted would replay the toast on
     * every later return to the list.
     */
    private var removalNotice: Int? by mutableStateOf(null)

    /**
     * Moves only when a removal happens, so a screen can key an effect on it. Keying on the job list
     * instead meant any unrelated write — a status refresh, say — restarted the effect mid-window,
     * found the notice already consumed, and left the confirmation on screen for good.
     */
    var removalToken: Int by mutableIntStateOf(0)
        private set

    fun takeRemovalNotice(): Int? = removalNotice?.also { removalNotice = null }

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

    suspend fun remove(ids: Set<String>) {
        // A no-op removal must not discard an earlier batch that is still undoable.
        if (ids.isEmpty()) return
        lastRemoved = ids.mapNotNull { dao.find(it) }
        dao.delete(ids)
        removalNotice = lastRemoved.size.takeIf { it > 0 }
        if (removalNotice != null) removalToken++
    }

    /** Order restores itself: the list is ordered by the rows' own timestamps, not by insertion. */
    suspend fun undoRemove() {
        if (lastRemoved.isEmpty()) return
        dao.insert(lastRemoved)
        lastRemoved = emptyList()
        removalNotice = null
    }

    /** The one write that overwrites: a status refresh rewrites the row it was read from. */
    suspend fun applyStatus(
        jobId: String,
        status: UseSmileIDSampleStatus,
        message: String,
        httpStatus: String,
    ): Boolean {
        val row = dao.find(jobId) ?: return false
        dao.upsert(row.copy(statusId = status.name, message = message, httpStatus = httpStatus))
        return true
    }

    suspend fun find(jobId: String): UseSmileIDSampleJob? = dao.find(jobId)?.toJob()

    /**
     * Inserts the fixture rows. Reached only by the `seedJobs` launch argument, never on an ordinary
     * launch: a stored row claims a verification was submitted, and these never were. It exists because
     * no UI path creates a row without a successful submission, so a device flow covering the list has
     * no other way to arrive at one. Idempotent — the rows are keyed by job id and insert ignores
     * conflicts, so a repeated seed changes nothing.
     */
    suspend fun seedFixtures(nowMillis: Long) = dao.insert(fixtures(nowMillis).map { it.toEntity() })

    companion object {
        /** The eleven the design's counts describe, offset from a caller-supplied now so a golden groups the same way tomorrow. */
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
        private const val HTTP_OK = "200 OK"
        private const val HTTP_ACCEPTED = "202 Accepted"
    }
}
