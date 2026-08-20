package com.usesmileid.sampleapps.ui.state

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct

/**
 * One submitted verification on disk, keyed by the server's job id — which is what makes a repeated
 * result idempotent at the storage layer as well as in the list.
 *
 * Enums and the product are stored as their stable string ids rather than ordinals: an ordinal
 * silently re-points every stored row when someone reorders an enum.
 */
@Entity(tableName = "jobs")
data class UseSmileIDSampleJobEntity(
    @PrimaryKey val id: String,
    val userId: String,
    val productId: String,
    val statusId: String,
    val createdAtMillis: Long,
    val message: String,
    val httpStatus: String,
    /** Sandbox or production at submission time. A row outlives the toggle that produced it. */
    val sandbox: Boolean,
    /**
     * The session handle the run submitted under, null for a run on the local fixture token. Only a
     * real one can be asked for its status, and this is the row's own evidence of which it was.
     */
    val sessionId: String? = null,
    /**
     * Which fields the token supplied — the shape, never the values. The values include a vault
     * reference standing in for the ID number; persisting them would put a live credential-adjacent
     * identifier in an unencrypted database to answer a question the shape already answers.
     */
    @ColumnInfo(defaultValue = "0") val boundUserDetails: Boolean = false,
    @ColumnInfo(defaultValue = "0") val boundIdDetails: Boolean = false,
    @ColumnInfo(defaultValue = "0") val boundConsent: Boolean = false,
)

/** Unknown ids fall back rather than throwing: a destructive migration can leave a row from an older enum. */
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
