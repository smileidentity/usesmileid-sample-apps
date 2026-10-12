package com.usesmileid.sampleapps.ui.golden

import androidx.compose.runtime.Composable
import com.usesmileid.sampleapps.ui.screens.AuthUserIdScreen
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleStatus
import java.util.Calendar
import org.junit.Test

/** The authentication user ID screen in each state `spec/screens.json` names. */
class AuthUserIdGoldenTest : GoldenTest() {

    @Test
    fun no_jobs() = goldens("screen_auth_user_id_no_jobs") { AuthUserId(userId = "", previous = emptyList()) }

    @Test
    fun previous_ids() = goldens("screen_auth_user_id_previous") { AuthUserId(userId = "", previous = PREVIOUS) }

    @Test
    fun selected() = goldens("screen_auth_user_id_selected") { AuthUserId(userId = PREVIOUS[0].userId, previous = PREVIOUS) }

    @Test
    fun typed() = goldens("screen_auth_user_id_typed") { AuthUserId(userId = "user_01typedbyhand0000000000", previous = PREVIOUS) }

    @Test
    fun no_jobs_max_font_scale() = assertSurvivesMaxFontScale { AuthUserId(userId = "", previous = emptyList()) }

    @Test
    fun previous_ids_max_font_scale() = assertSurvivesMaxFontScale { AuthUserId(userId = PREVIOUS[0].userId, previous = PREVIOUS) }

    @Composable
    private fun AuthUserId(userId: String, previous: List<UseSmileIDSampleJob>) = AuthUserIdScreen(
        userId = userId,
        previousUsers = previous,
        onUserIdChange = {},
        onRegister = {},
        onBack = {},
        onContinue = {},
    )

    private companion object {
        val PREVIOUS = listOf(
            job("user_01m4gahg4ceceatsw25mc5dd1h", UseSmileIDSampleProduct.SmartSelfieEnrollment, hour = 23, minute = 10),
            job("user_01r4l94gahg4ceceatsw25mc5d", UseSmileIDSampleProduct.BiometricKyc, hour = 18, minute = 42),
            job("user_01r4l94gahg4ceceatsw25mc51", UseSmileIDSampleProduct.DocumentVerification, hour = 9, minute = 5),
        )

        fun job(userId: String, product: UseSmileIDSampleProduct, hour: Int, minute: Int) = UseSmileIDSampleJob(
            id = "job_$userId",
            userId = userId,
            product = product,
            status = UseSmileIDSampleStatus.Clear,
            createdAtMillis = todayAt(hour, minute),
            message = "",
            httpStatus = 200,
        )

        // Set from the local wall clock, not added to midnight, so a clock-change day reads the same.
        fun todayAt(hour: Int, minute: Int): Long = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
    }
}
