package com.usesmileid.sampleapps.ui

import androidx.compose.runtime.Composable
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.v2.runComposeUiTest
import com.usesmileid.sampleapps.ui.golden.ROBOLECTRIC_SDK
import com.usesmileid.sampleapps.ui.screens.label
import com.usesmileid.sampleapps.ui.state.TokenJson
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleAppearance
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleLanguage
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenBindings
import com.usesmileid.sampleapps.ui.state.parseTokenJson
import com.usesmileid.sampleapps.ui.state.userDetailsRequirement
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [ROBOLECTRIC_SDK])
@OptIn(ExperimentalTestApi::class)
class UseSmileIDSampleLocalizedTextTest {

    @Test
    fun `the prompt names what is outstanding and nothing else`() {
        val prompts = read {
            listOf(
                null.userDetailsRequirement().prompt(),
                UseSmileIDSampleTokenBindings(givenNames = true, email = true).userDetailsRequirement().prompt(),
                UseSmileIDSampleTokenBindings(givenNames = true, lastName = true).userDetailsRequirement().prompt(),
                UseSmileIDSampleTokenBindings(givenNames = true, lastName = true, email = true).userDetailsRequirement().prompt(),
            )
        }
        assertEquals(
            listOf(
                "Required: first name, last name, an email or phone number.",
                "Last name is required.",
                "An email or phone number is required.",
                "Tap any field to edit.",
            ),
            prompts,
        )
    }

    @Test
    fun `the System theme label names the device's theme and the others name themselves`() {
        val labels = read {
            listOf(false, true).flatMap { dark -> UseSmileIDSampleAppearance.entries.map { it.label(dark) } }
        }
        assertEquals(listOf("System (Light)", "Light", "Dark", "System (Dark)", "Light", "Dark"), labels)
    }

    @Test
    fun `the System language label names the shipped language the device resolves to`() {
        val labels = read {
            listOf(
                UseSmileIDSampleLanguage.System.label(listOf("fr-CA", "en-US")),
                UseSmileIDSampleLanguage.System.label(listOf("de-DE", "iw-IL")),
                UseSmileIDSampleLanguage.System.label(listOf("de-DE")),
                UseSmileIDSampleLanguage.Arabic.label(listOf("en-US")),
            )
        }
        assertEquals(listOf("System (Français)", "System (עברית)", "System (English)", "العربية"), labels)
    }

    @Test
    @Config(qualifiers = "ar")
    fun `an Arabic device reads the Arabic source`() {
        val arabic = parseTokenJson(spec("l10n/app/ar.json")) as TokenJson.Obj
        val expected = listOf("settings_title", "settings_language", "profile_config_delete_title")
            .map { (arabic.members.getValue(it) as TokenJson.Str).value }
        val actual = read {
            listOf(
                UseSmileIDSampleStrings.settingsTitle,
                UseSmileIDSampleStrings.settingsLanguage,
                UseSmileIDSampleStrings.profileConfigDeleteTitle("Kazi"),
            )
        }
        assertEquals(expected.dropLast(1) + expected.last().replace("{profile}", "Kazi"), actual)
    }

    private fun <T> read(block: @Composable () -> T): T {
        var value: T? = null
        runComposeUiTest {
            setContent { value = block() }
            waitForIdle()
        }
        @Suppress("UNCHECKED_CAST")
        return value as T
    }
}
