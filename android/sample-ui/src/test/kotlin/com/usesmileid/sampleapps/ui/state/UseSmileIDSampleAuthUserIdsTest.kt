package com.usesmileid.sampleapps.ui.state

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleStatus
import org.junit.Assert.assertEquals
import org.junit.Test

/** Which earlier runs offer a user ID to authenticate: those that enrolled one and were not refused or failed. */
class UseSmileIDSampleAuthUserIdsTest {

    private fun job(
        userId: String,
        product: UseSmileIDSampleProduct,
        status: UseSmileIDSampleStatus,
        at: Long,
        partnerId: String? = PARTNER,
        sandbox: Boolean = true,
    ) =
        UseSmileIDSampleJob(
            id = "job_$at",
            userId = userId,
            product = product,
            status = status,
            createdAtMillis = at,
            message = "",
            httpStatus = 200,
            sandbox = sandbox,
            partnerId = partnerId,
        )

    @Test
    fun `newest first and once each, from every product that enrols a user`() {
        val jobs = listOf(
            job("user_a", UseSmileIDSampleProduct.SmartSelfieEnrollment, UseSmileIDSampleStatus.Clear, 1),
            job("user_b", UseSmileIDSampleProduct.BiometricKyc, UseSmileIDSampleStatus.Attention, 3),
            job("user_c", UseSmileIDSampleProduct.DocumentVerification, UseSmileIDSampleStatus.Processing, 2),
            job("user_a", UseSmileIDSampleProduct.EnhancedDocumentVerification, UseSmileIDSampleStatus.Clear, 4),
        )
        assertEquals(listOf("user_a", "user_b", "user_c"), previousAuthUsers(jobs, PARTNER, sandbox = true).map { it.userId })
    }

    @Test
    fun `each user is offered with the newest run that enrolled it, so its row names that product and time`() {
        val jobs = listOf(
            job("user_a", UseSmileIDSampleProduct.SmartSelfieEnrollment, UseSmileIDSampleStatus.Clear, 1),
            job("user_b", UseSmileIDSampleProduct.BiometricKyc, UseSmileIDSampleStatus.Clear, 2),
            job("user_a", UseSmileIDSampleProduct.DocumentVerification, UseSmileIDSampleStatus.Clear, 3),
        )
        assertEquals(listOf("job_3", "job_2"), previousAuthUsers(jobs, PARTNER, sandbox = true).map { it.id })
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
        assertEquals(emptyList<String>(), previousAuthUsers(jobs, PARTNER, sandbox = true).map { it.userId })
    }

    @Test
    fun `another partner's users, or this partner's in the other environment, are not offered`() {
        val jobs = listOf(
            job("user_mine", UseSmileIDSampleProduct.SmartSelfieEnrollment, UseSmileIDSampleStatus.Clear, 1),
            job("user_theirs", UseSmileIDSampleProduct.SmartSelfieEnrollment, UseSmileIDSampleStatus.Clear, 2, partnerId = "partner-b"),
            job("user_production", UseSmileIDSampleProduct.SmartSelfieEnrollment, UseSmileIDSampleStatus.Clear, 3, sandbox = false),
            job("user_fixture", UseSmileIDSampleProduct.SmartSelfieEnrollment, UseSmileIDSampleStatus.Clear, 4, partnerId = null),
        )
        assertEquals(listOf("user_mine"), previousAuthUsers(jobs, PARTNER, sandbox = true).map { it.userId })
        assertEquals(emptyList<String>(), previousAuthUsers(jobs, partnerId = null, sandbox = true).map { it.userId })
    }

    private companion object {
        const val PARTNER = "partner-a"
    }
}
