package com.usesmileid.sampleapps.ui.state

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
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

}
