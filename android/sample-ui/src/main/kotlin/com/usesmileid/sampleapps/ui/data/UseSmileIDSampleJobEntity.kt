package com.usesmileid.sampleapps.ui.data

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct

/** One submitted verification on disk, keyed by job id. Enums stored as string ids, never ordinals. */
@Entity(tableName = "jobs")
data class UseSmileIDSampleJobEntity(
    @PrimaryKey val id: String,
    val userId: String,
    val productId: String,
    val statusId: String,
    val createdAtMillis: Long,
    val message: String,
    /** The response code the row was last written from; null when nothing has answered for it yet. */
    val httpStatus: Int?,
    /** Sandbox or production at submission time. A row outlives the toggle that produced it. */
    val sandbox: Boolean,
    /** The session the run submitted under; null on a fixture token, which has no status to ask for. */
    val sessionId: String? = null,
    /** Which fields the token supplied — the shape, never the values: one of them is a vault reference. */
    @ColumnInfo(defaultValue = "0") val boundUserDetails: Boolean = false,
    @ColumnInfo(defaultValue = "0") val boundIdDetails: Boolean = false,
    @ColumnInfo(defaultValue = "0") val boundConsent: Boolean = false,
)

/** Unknown ids fall back rather than throwing. */
fun UseSmileIDSampleJobEntity.toJob() = UseSmileIDSampleJob(
    id = id,
    userId = userId,
    product = UseSmileIDSampleProduct.entries.firstOrNull { it.id == productId }
        ?: UseSmileIDSampleProduct.entries.first(),
    status = UseSmileIDSampleStatus.entries.firstOrNull { it.name == statusId }
        ?: UseSmileIDSampleStatus.Processing,
    createdAtMillis = createdAtMillis,
    message = message,
    httpStatus = httpStatus,
    sandbox = sandbox,
    sessionId = sessionId,
)

fun UseSmileIDSampleJob.toEntity(
    boundUserDetails: Boolean = false,
    boundIdDetails: Boolean = false,
    boundConsent: Boolean = false,
) = UseSmileIDSampleJobEntity(
    id = id,
    userId = userId,
    productId = product.id,
    statusId = status.name,
    createdAtMillis = createdAtMillis,
    message = message,
    httpStatus = httpStatus,
    sandbox = sandbox,
    sessionId = sessionId,
    boundUserDetails = boundUserDetails,
    boundIdDetails = boundIdDetails,
    boundConsent = boundConsent,
)
