package com.usesmileid.sampleapps.ui.golden

import androidx.compose.runtime.Composable
import com.usesmileid.sampleapps.ui.screens.AuthUserIdScreen
import org.junit.Test

/** The authentication user ID screen in each state `spec/screens.json` names. */
class AuthUserIdGoldenTest : GoldenTest() {

    @Test
    fun no_jobs() = goldens("screen_auth_user_id_no_jobs") { AuthUserId(userId = "", previous = emptyList()) }

    @Test
    fun previous_ids() = goldens("screen_auth_user_id_previous") { AuthUserId(userId = "", previous = PREVIOUS) }

    @Test
    fun selected() = goldens("screen_auth_user_id_selected") { AuthUserId(userId = PREVIOUS[0], previous = PREVIOUS) }

    @Test
    fun typed() = goldens("screen_auth_user_id_typed") { AuthUserId(userId = "user_01typedbyhand0000000000", previous = PREVIOUS) }

    @Test
    fun no_jobs_max_font_scale() = assertSurvivesMaxFontScale { AuthUserId(userId = "", previous = emptyList()) }

    @Test
    fun previous_ids_max_font_scale() = assertSurvivesMaxFontScale { AuthUserId(userId = PREVIOUS[0], previous = PREVIOUS) }

    @Composable
    private fun AuthUserId(userId: String, previous: List<String>) = AuthUserIdScreen(
        userId = userId,
        previousUserIds = previous,
        onUserIdChange = {},
        onRegister = {},
        onBack = {},
        onContinue = {},
    )

    private companion object {
        val PREVIOUS = listOf(
            "user_01m4gahg4ceceatsw25mc5dd1h",
            "user_01r4l94gahg4ceceatsw25mc5d",
            "user_01r4l94gahg4ceceatsw25mc51",
        )
    }
}
