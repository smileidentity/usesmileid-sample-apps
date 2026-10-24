package com.usesmileid.sampleapps.ui.golden

import android.provider.Settings
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.components.LocalUseSmileIDSampleSheetHosted
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSkeletonGate
import com.usesmileid.sampleapps.ui.screens.CountryPickerSheet
import com.usesmileid.sampleapps.ui.screens.LanguageSheet
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogue
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleLanguage
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import org.junit.Before
import org.junit.Test
import org.robolectric.RuntimeEnvironment

/** The partial and full-height sheets as a navigation host draws them: the panel only, over the host's scrim, as on the modal goldens. */
class HostedSheetGoldenTest : GoldenTest() {

    /** A pulsing skeleton never lets the test idle, so these record the reduced-motion rows the platform also draws. */
    @Before
    fun reduceMotion() {
        Settings.Global.putFloat(RuntimeEnvironment.getApplication().contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 0f)
    }

    @Test
    fun language_sheet_hosted() = goldens("sheet_language_hosted", fullWindow = true) {
        Hosted { LanguageSheet(selected = UseSmileIDSampleLanguage.System, deviceLanguages = listOf("en-US"), onSelect = {}, onDismissRequest = {}) }
    }

    @Test
    fun country_picker_hosted() = goldens(
        "sheet_country_picker_loading_hosted",
        fullWindow = true,
        // Past the skeleton's delay, which the modal sheet's own entrance spends before its capture.
        interact = { advance(UseSmileIDSampleSkeletonGate.DELAY_MILLIS + 100) },
    ) {
        Hosted {
            CountryPickerSheet(
                catalogue = UseSmileIDSampleCatalogue.Loading,
                selected = null,
                query = "",
                onQueryChange = {},
                onSelect = {},
                onRetry = {},
                onDismissRequest = {},
            )
        }
    }

    /** The host's frame: its scrim over the screen and the sheet's step at the bottom, as njia draws a sheet step. */
    @Composable
    private fun Hosted(sheet: @Composable () -> Unit) = Box(Modifier.fillMaxSize().background(UseSmileIDSampleTheme.colors.overlayScrim)) {
        Box(Modifier.align(Alignment.BottomCenter)) {
            CompositionLocalProvider(LocalUseSmileIDSampleSheetHosted provides true, content = sheet)
        }
    }
}
