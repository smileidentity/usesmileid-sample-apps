package com.usesmileid.sampleapps.ui.golden

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleToast
import com.usesmileid.sampleapps.ui.screens.NewProfileSheet
import com.usesmileid.sampleapps.ui.screens.ProfileConfigScreen
import com.usesmileid.sampleapps.ui.screens.ProfilesScreen
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleProfile
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleProfiles
import org.junit.Test

/** The profiles screens and the sheet they own; the switch sheet belongs to Products, which presents it. */
class ProfileGoldenTest : GoldenTest() {

    @Test
    fun profiles() = goldens("screen_profiles") { Profiles() }

    @Test
    fun profiles_max_font_scale() = assertSurvivesMaxFontScale { Profiles() }

    @Test
    fun profiles_first_run() = goldens("screen_profiles_first_run") { Profiles(STARTER) }

    @Test
    fun profiles_first_run_max_font_scale() = assertSurvivesMaxFontScale { Profiles(STARTER) }

    /** Creating one does not activate it, so the confirmation carries the offer. */
    @Test
    fun profiles_created() = goldens("screen_profiles_created") {
        Box(modifier = Modifier.fillMaxSize()) {
            Profiles(WITH_CREATED)
            UseSmileIDSampleToast(
                message = "${CREATED.organisation} created",
                actionLabel = "Make active",
                onAction = {},
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingLg),
            )
        }
    }

    @Test
    fun profile_config_other() = goldens("screen_profile_config_other") { Config(PROFILES.all[1]) }

    @Test
    fun profile_config_max_font_scale() = assertSurvivesMaxFontScale { Config(PROFILES.all[1]) }

    @Test
    fun profile_config_active() = goldens("screen_profile_config_active") { Config(PROFILES.active!!, isActive = true) }

    /** Only the names came from the sheet, so the contact rows show their placeholders. */
    @Test
    fun profile_config_newly_created() = goldens("screen_profile_config_new") { Config(CREATED) }

    @Test
    fun new_profile_sheet_empty() = goldens("sheet_new_profile_empty", fullWindow = true) { NewProfile() }

    @Test
    fun new_profile_sheet_filled() = goldens("sheet_new_profile_filled", fullWindow = true) { NewProfile(FILLED) }

    @Test
    fun new_profile_sheet_max_font_scale() =
        assertSurvivesMaxFontScale(rootTestId = UseSmileIDSampleTestIds.NEW_PROFILE_SHEET) { NewProfile(FILLED) }

    private companion object {
        val PROFILES = ProfileFixtures.Seeded
        val STARTER = ProfileFixtures.None
        val CREATED = ProfileFixtures.Created
        val WITH_CREATED = ProfileFixtures.WithCreated

        val FILLED = UseSmileIDSampleNewProfileFields(
            name = "Sahara Pay",
            firstName = "Ngozi",
            lastName = "Eze",
            email = "ngozi@saharapay.example",
        )
    }

    @Composable
    private fun Profiles(profiles: UseSmileIDSampleProfiles = PROFILES) = ProfilesScreen(
        profiles = profiles.all,
        activeId = profiles.activeId,
        onProfileClick = {},
        onCreate = {},
        onBack = {},
    )

    @Composable
    private fun Config(profile: UseSmileIDSampleProfile, isActive: Boolean = false) = ProfileConfigScreen(
        organisation = profile.title,
        defaults = profile.defaults,
        name = profile.organisation,
        onNameChange = {},
        onFieldChange = { _, _ -> },
        onBack = {},
        onSave = {},
        isActive = isActive,
        onDelete = {},
    )

    @Composable
    private fun NewProfile(fields: UseSmileIDSampleNewProfileFields = UseSmileIDSampleNewProfileFields()) =
        Box(modifier = Modifier.fillMaxSize()) {
            Profiles()
            NewProfileSheet(
                name = fields.name,
                firstName = fields.firstName,
                lastName = fields.lastName,
                email = fields.email,
                phone = fields.phone,
                onNameChange = {},
                onFirstNameChange = {},
                onLastNameChange = {},
                onEmailChange = {},
                onPhoneChange = {},
                onSave = {},
                onDismissRequest = {},
            )
        }
}

/** The sheet's five fields as one value, so the two states differ by a fixture rather than five arguments. */
internal data class UseSmileIDSampleNewProfileFields(
    val name: String = "",
    val firstName: String = "",
    val lastName: String = "",
    val email: String = "",
    val phone: String = "",
)
