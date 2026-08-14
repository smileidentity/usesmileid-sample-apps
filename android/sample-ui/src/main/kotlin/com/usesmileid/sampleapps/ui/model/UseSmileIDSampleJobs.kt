package com.usesmileid.sampleapps.ui.model

import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.toMutableStateList
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus

/** The submitted verifications, in memory until they arrive from the SDK. Removal keeps what it removed, so undo restores the rows in place. */
class UseSmileIDSampleJobs(seed: List<UseSmileIDSampleJob> = emptyList()) {

    private val items = seed.toMutableStateList()
    private val lastRemoved = mutableStateListOf<IndexedValue<UseSmileIDSampleJob>>()

    val all: List<UseSmileIDSampleJob> get() = items

    fun count(filter: UseSmileIDSampleJobFilter) = items.count(filter::matches)

    fun remove(ids: Set<String>) {
        // A no-op removal must not discard an earlier batch that is still undoable.
        if (ids.isEmpty()) return
        lastRemoved.clear()
        items.withIndex().filter { it.value.id in ids }.forEach(lastRemoved::add)
        items.removeAll { it.id in ids }
    }

    /** Reinserts by ascending index, so the rows land back where they were rather than at the end. */
    fun undoRemove() {
        lastRemoved.sortedBy { it.index }.forEach { (index, job) ->
            items.add(index.coerceAtMost(items.size), job)
        }
        lastRemoved.clear()
    }

    companion object {
        /** The eleven the design's counts describe, offset from a caller-supplied now so a golden groups the same way tomorrow. */
        fun seeded(nowMillis: Long): UseSmileIDSampleJobs {
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
            return UseSmileIDSampleJobs(
                statuses.mapIndexed { index, status ->
                    val product = products[index % products.size]
                    UseSmileIDSampleJob(
                        id = "job_%02dky31za%02d".format(index, index * 7 % 100),
                        userId = "user_%02dky31za%02d".format(index, index * 3 % 100),
                        product = product,
                        status = status,
                        createdAtMillis = nowMillis - index * HOURS_APART * MILLIS_PER_HOUR,
                        message = status.message(),
                        httpStatus = if (status == UseSmileIDSampleStatus.Processing) "202 Accepted" else "200 OK",
                    )
                },
            )
        }

        private fun UseSmileIDSampleStatus.message() = when (this) {
            UseSmileIDSampleStatus.Clear -> "Approved"
            UseSmileIDSampleStatus.Attention -> "Provisional — needs review"
            UseSmileIDSampleStatus.Blocked -> "Rejected"
            UseSmileIDSampleStatus.Processing -> "Submitted, awaiting result"
        }

        private const val HOURS_APART = 5L
        private const val MILLIS_PER_HOUR = 60L * 60L * 1000L
    }
}
