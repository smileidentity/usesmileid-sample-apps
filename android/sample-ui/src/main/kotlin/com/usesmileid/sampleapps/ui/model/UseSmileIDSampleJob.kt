package com.usesmileid.sampleapps.ui.model

import androidx.compose.runtime.Immutable
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus

/** One submitted verification. `createdAtMillis` is absolute, so grouping never depends on when it is read. */
@Immutable
data class UseSmileIDSampleJob(
    val id: String,
    val userId: String,
    val product: UseSmileIDSampleProduct,
    val status: UseSmileIDSampleStatus,
    val createdAtMillis: Long,
    val message: String,
    val httpStatus: String,
) {
    /** The design truncates the job id in the list and on the details row; the full one is still copyable. */
    val shortId: String get() = if (id.length <= SHORT_ID_LENGTH) id else id.take(SHORT_ID_LENGTH) + "…"

    val shortUserId: String get() = if (userId.length <= SHORT_ID_LENGTH) userId else userId.take(SHORT_ID_LENGTH) + "…"

    private companion object {
        const val SHORT_ID_LENGTH = 8
    }
}

/** The filters above the list. `All` is not a status, which is why this is not the status enum. */
enum class UseSmileIDSampleJobFilter(val id: String, val label: String, val status: UseSmileIDSampleStatus?) {
    All("all", "All", null),
    Clear("clear", "Clear", UseSmileIDSampleStatus.Clear),
    Attention("attention", "Attention", UseSmileIDSampleStatus.Attention),
    Blocked("blocked", "Blocked", UseSmileIDSampleStatus.Blocked),
    ;

    fun matches(job: UseSmileIDSampleJob) = status == null || job.status == status
}
