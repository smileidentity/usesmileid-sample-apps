package com.usesmileid.sampleapps.android.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.android.UseSmileIDSampleTabRootBar
import com.usesmileid.sampleapps.android.step
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleNavItem
import com.usesmileid.njia.compose.NjiaSteps
import com.usesmileid.njia.compose.njiaSteps
import com.usesmileid.sampleapps.android.flow.SdkFlowScreen

/** What draws each of the graph's step kinds; a kind with no screen here fails before the first frame. */
internal val UseSmileIDSampleSteps: NjiaSteps<UseSmileIDSampleStep, UseSmileIDSampleFact> = njiaSteps {
    // Inside the tab's root rather than over the display, so a sheet over the root covers the bar too.
    decorate { content ->
        val tab = UseSmileIDSampleNavItem.entries.firstOrNull { it.step == step.kind }
        if (tab == null) {
            content()
        } else {
            Box(Modifier.fillMaxSize()) {
                content()
                UseSmileIDSampleTabRootBar(tab, navigator, Modifier.align(Alignment.BottomCenter))
            }
        }
    }
    step(UseSmileIDSampleStep.Products) { ProductsScreen(this) }
    step(UseSmileIDSampleStep.Verifications) { VerificationsScreen(this) }
    step(UseSmileIDSampleStep.Settings) { SettingsScreen(this) }
    step(UseSmileIDSampleStep.Licenses) { LicensesScreen(this) }
    step(UseSmileIDSampleStep.CaptureMode) { CaptureModeSheet(this) }
    step(UseSmileIDSampleStep.Submission) { SubmissionSheet(this) }
    step(UseSmileIDSampleStep.Appearance) { AppearanceSheet(this) }
    step(UseSmileIDSampleStep.Language) { LanguageSheet(this) }
    step(UseSmileIDSampleStep.ScenarioDrawer) { ScenarioDrawerSheet(this) }
    step(UseSmileIDSampleStep.VerificationDetails) { VerificationDetailsScreen(this) }
    step(UseSmileIDSampleStep.ProfileSwitch) { ProfileSwitchSheet(this) }
    step(UseSmileIDSampleStep.Profiles) { ProfilesScreen(this) }
    step(UseSmileIDSampleStep.NewProfile) { NewProfileSheet(this) }
    step(UseSmileIDSampleStep.ProfileConfig) { ProfileConfigScreen(this) }
    step(UseSmileIDSampleStep.ScanToken) { ScanTokenScreen(this) }
    step(UseSmileIDSampleStep.CountryPicker) { CountryPickerSheet(this) }
    step(UseSmileIDSampleStep.IdTypePicker) { IdTypePickerSheet(this) }
    step(UseSmileIDSampleStep.DocumentPicker) { DocumentPickerSheet(this) }
    step(UseSmileIDSampleStep.CaptureAs) { CaptureAsSheet(this) }
    step(UseSmileIDSampleStep.GenericDocument) { GenericDocumentSheet(this) }
    step(UseSmileIDSampleStep.ConsentDetailsForm) { ConsentDetailsFormScreen(this) }
    step(UseSmileIDSampleStep.AuthUserId) { AuthUserIdScreen(this) }
    step(UseSmileIDSampleStep.IdDetailsForm) { IdDetailsFormScreen(this) }
    step(UseSmileIDSampleStep.SdkFlow) { SdkFlowScreen(this) }
    step(UseSmileIDSampleStep.SdkFlowFullScreen) { SdkFlowScreen(this) }
}
