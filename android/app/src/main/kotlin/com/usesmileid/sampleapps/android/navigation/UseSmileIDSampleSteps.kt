package com.usesmileid.sampleapps.android.navigation

import androidx.compose.runtime.CompositionLocalProvider
import com.usesmileid.njia.NjiaPresentation
import com.usesmileid.njia.compose.NjiaSteps
import com.usesmileid.njia.compose.njiaSteps
import com.usesmileid.sampleapps.android.flow.SdkFlowScreen
import com.usesmileid.sampleapps.ui.components.LocalUseSmileIDSampleSheetHosted

/** What draws each of the graph's step kinds; a kind with no screen here fails before the first frame. */
internal val UseSmileIDSampleSteps: NjiaSteps<UseSmileIDSampleStep, UseSmileIDSampleFact> = njiaSteps {
    // njia draws a sheet step's window and scrim, so the sample's sheets draw only their panel there.
    decorate { content ->
        CompositionLocalProvider(LocalUseSmileIDSampleSheetHosted provides (step.presentation == NjiaPresentation.Sheet)) { content() }
    }
    step(UseSmileIDSampleStep.Products) { ProductsScreen(this) }
    step(UseSmileIDSampleStep.Verifications) { VerificationsScreen(this) }
    step(UseSmileIDSampleStep.Settings) { SettingsScreen(this) }
    step(UseSmileIDSampleStep.Licenses) { LicensesScreen(this) }
    step(UseSmileIDSampleStep.CaptureMode) { CaptureModeSheet(this) }
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
