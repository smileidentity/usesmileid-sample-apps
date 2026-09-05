package com.usesmileid.sampleapps.ui.golden

import androidx.compose.runtime.Composable
import com.usesmileid.sampleapps.ui.screens.ProfileConfigScreen
import com.usesmileid.sampleapps.ui.screens.ProfilesScreen
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleProfiles
import org.junit.Test

/** The profiles screens. The switch sheet and the new-profile sheet are verified on a device, not here, because a sheet is its own window. */
class ProfileGoldenTest : GoldenTest() {

    @Test
    fun profiles() = goldens("screen_profiles") { Profiles() }

    @Test
    fun profiles_max_font_scale() = assertSurvivesMaxFontScale { Profiles() }

    @Test
    fun profiles_first_run() = goldens("screen_profiles_first_run") { Profiles(STARTER) }

    @Test
    fun profiles_first_run_max_font_scale() = assertSurvivesMaxFontScale { Profiles(STARTER) }

    @Test
    fun profile_config() = goldens("screen_profile_config") { Config() }

    @Test
    fun profile_config_max_font_scale() = assertSurvivesMaxFontScale { Config() }

    @Test
    fun profile_config_active() = goldens("screen_profile_config_active") { Config(isActive = true) }

    private companion object {
        /** The design's three, so these goldens stay the Figma boards; a plain launch is [STARTER]. */
        val PROFILES = UseSmileIDSampleProfiles(UseSmileIDSampleProfiles.fixtures())
        val STARTER = UseSmileIDSampleProfiles()
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
    private fun Config(isActive: Boolean = false) = ProfileConfigScreen(
        organisation = PROFILES.active.organisation,
        defaults = PROFILES.active.defaults,
        onFieldChange = { _, _ -> },
        onBack = {},
        onSave = {},
        isActive = isActive,
    )
}
