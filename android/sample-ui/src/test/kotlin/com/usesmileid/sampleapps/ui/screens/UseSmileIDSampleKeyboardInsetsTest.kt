package com.usesmileid.sampleapps.ui.screens

import android.view.View
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.core.graphics.Insets
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.avatarColorForProfile
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/** A screen with a field keeps its action above the keyboard: edge to edge, nothing else lifts it. */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [36], qualifiers = "w411dp-h891dp-xhdpi")
class UseSmileIDSampleKeyboardInsetsTest {
    @get:Rule val compose = createComposeRule()

    @Test
    fun the_details_form_keeps_continue_above_the_keyboard() = assertAboveKeyboard(UseSmileIDSampleTestIds.USER_DETAILS_CONTINUE) {
        UserDetailsScreen(
            productLabel = "Enhanced KYC",
            details = UseSmileIDSampleUserDetails(),
            profile = null,
            profileColor = avatarColorForProfile(0),
            saveToProfile = true,
            onFieldChange = { _, _ -> },
            onSaveToProfileChange = {},
            onProfileClick = {},
            onBack = {},
            onContinue = {},
        )
    }

    @Test
    fun a_profile_keeps_save_above_the_keyboard() = assertAboveKeyboard(UseSmileIDSampleTestIds.PROFILE_CONFIG_SAVE) {
        ProfileConfigScreen(
            title = "Bank XYZ",
            defaults = UseSmileIDSampleUserDetails(),
            organisation = "Bank XYZ",
            onOrganisationChange = {},
            onFieldChange = { _, _ -> },
            onBack = {},
            onSave = {},
        )
    }

    @Test
    fun the_scan_sheet_keeps_its_token_field_above_the_keyboard() = assertAboveKeyboard(UseSmileIDSampleTestIds.TOKEN_SIMULATE) {
        ScanTokenScreen(onBack = {}, onLink = {}, onSimulate = { _, _, _ -> }, onPaste = { null })
    }

    @Test
    fun the_scan_sheet_keeps_its_token_field_above_the_keyboard_over_the_camera() = assertAboveKeyboard(UseSmileIDSampleTestIds.TOKEN_SIMULATE) {
        ScanTokenScreen(
            onBack = {},
            onLink = {},
            onSimulate = { _, _, _ -> },
            onPaste = { null },
            viewfinder = { modifier, _, _ -> Box(modifier) },
        )
    }

    @Test
    fun the_camera_copy_stays_under_the_bar_above_the_keyboard() {
        raiseKeyboard {
            ScanTokenScreen(
                onBack = {},
                onLink = {},
                onSimulate = { _, _, _ -> },
                onPaste = { null },
                viewfinder = { modifier, _, _ -> Box(modifier) },
            )
        }

        val barBottom = compose.onNodeWithContentDescription("Back").getBoundsInRoot().bottom
        val copyTop = compose.onNodeWithText("Point at a Smile token QR").getBoundsInRoot().top
        assertTrue("the copy starts at $copyTop, over a bar ending at $barBottom", copyTop >= barBottom)
    }

    /** Raises a keyboard over [content] and checks [tag] ends where the keyboard starts, or above it. */
    private fun assertAboveKeyboard(tag: String, content: @Composable () -> Unit) {
        raiseKeyboard(content)

        val windowBottom = compose.onRoot().getBoundsInRoot().bottom
        val actionBottom = compose.onNodeWithTag(tag, useUnmergedTree = true).getBoundsInRoot().bottom
        val keyboard = with(compose.density) { KEYBOARD_PX.toDp() }
        assertTrue("$tag ends at $actionBottom, under a keyboard reaching ${windowBottom - keyboard}", actionBottom <= windowBottom - keyboard)
    }

    /** Shows [content] with a keyboard raised over it. */
    private fun raiseKeyboard(content: @Composable () -> Unit) {
        lateinit var view: View
        compose.setContent {
            view = LocalView.current
            UseSmileIDSampleTheme { content() }
        }
        compose.runOnIdle {
            ViewCompat.dispatchApplyWindowInsets(
                view,
                WindowInsetsCompat.Builder()
                    .setInsets(WindowInsetsCompat.Type.ime(), Insets.of(0, 0, 0, KEYBOARD_PX))
                    .setVisible(WindowInsetsCompat.Type.ime(), true)
                    .build(),
            )
        }
        compose.waitForIdle()
    }

    private companion object {
        /** A phone keyboard's 300dp at xhdpi: taller than any navigation bar, so only the keyboard's inset can clear it. */
        const val KEYBOARD_PX = 600
    }
}
