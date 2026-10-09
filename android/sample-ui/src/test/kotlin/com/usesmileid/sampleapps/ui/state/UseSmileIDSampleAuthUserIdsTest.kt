package com.usesmileid.sampleapps.ui.state

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleStatus
import org.junit.Assert.assertEquals
import org.junit.Test

/** Which earlier runs offer a user ID to authenticate: those that enrolled one and were not refused or failed. */
class UseSmileIDSampleAuthUserIdsTest {

    private fun job(userId: String, product: UseSmileIDSampleProduct, status: UseSmileIDSampleStatus, at: Long) =
        UseSmileIDSampleJob(
            id = "job_$at",
            userId = userId,
            product = product,
            status = status,
            createdAtMillis = at,
            message = "",
            httpStatus = 200,
        )

    @Test
    fun `newest first and once each, from every product that enrols a user`() {
        val jobs = listOf(
            job("user_a", UseSmileIDSampleProduct.SmartSelfieEnrollment, UseSmileIDSampleStatus.Clear, 1),
            job("user_b", UseSmileIDSampleProduct.BiometricKyc, UseSmileIDSampleStatus.Attention, 3),
            job("user_c", UseSmileIDSampleProduct.DocumentVerification, UseSmileIDSampleStatus.Processing, 2),
            job("user_a", UseSmileIDSampleProduct.EnhancedDocumentVerification, UseSmileIDSampleStatus.Clear, 4),
        )
        assertEquals(listOf("user_a", "user_b", "user_c"), previousAuthUserIds(jobs))
    }

    @Test
    fun `refused, failed, authentication and Enhanced KYC runs offer none`() {
        val jobs = listOf(
            job("user_blocked", UseSmileIDSampleProduct.SmartSelfieEnrollment, UseSmileIDSampleStatus.Blocked, 1),
            job("user_error", UseSmileIDSampleProduct.BiometricKyc, UseSmileIDSampleStatus.Error, 2),
            job("user_auth", UseSmileIDSampleProduct.SmartSelfieAuth, UseSmileIDSampleStatus.Clear, 3),
            job("user_ekyc", UseSmileIDSampleProduct.EnhancedKyc, UseSmileIDSampleStatus.Clear, 4),
            job(" ", UseSmileIDSampleProduct.SmartSelfieEnrollment, UseSmileIDSampleStatus.Clear, 5),
        )
        assertEquals(emptyList<String>(), previousAuthUserIds(jobs))
    }
}
