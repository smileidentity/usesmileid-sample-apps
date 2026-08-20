package com.usesmileid.sampleapps.ui.state

import android.content.Context
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
    }

    /** Order restores itself: the list is ordered by the rows' own timestamps, not by insertion. */
    suspend fun undoRemove() {
        if (lastRemoved.isEmpty()) return
        dao.insert(lastRemoved)
        lastRemoved = emptyList()
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
     * Seeds the design's eleven fixtures once, on the flag rather than on an empty table: a partner
     * who removes every row must not have them handed back on the next launch.
     */
    suspend fun seedOnce(alreadySeeded: Boolean, nowMillis: Long, profile: UseSmileIDSampleProfile) {
        if (alreadySeeded) return
        dao.insert(fixtures(nowMillis, profile).map { it.toEntity() })
    }

    companion object {
        /** The eleven the design's counts describe, offset from a caller-supplied now so a golden groups the same way tomorrow. */
        fun fixtures(nowMillis: Long, profile: UseSmileIDSampleProfile): List<UseSmileIDSampleJob> {
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
                    profileId = profile.id,
                    profileOrganisation = profile.organisation,
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
