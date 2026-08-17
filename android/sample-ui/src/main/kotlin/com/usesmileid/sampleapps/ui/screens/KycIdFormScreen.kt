package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.input.KeyboardCapitalization
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.R
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleFloatingTokenButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionLabel
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSelectTrigger
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleIcon
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTriggerEmoji
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTextInput
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBar
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdDetails

/** The ID-details form. ID type is disabled until a country is chosen, because the types depend on it. */
@Composable
fun KycIdFormScreen(
    productLabel: String,
    details: UseSmileIDSampleIdDetails,
    onCountryClick: () -> Unit,
    onIdTypeClick: () -> Unit,
    onIdNumberChange: (String) -> Unit,
    onBack: () -> Unit,
    onContinue: () -> Unit,
    onTokenClick: () -> Unit,
    modifier: Modifier = Modifier,
    contentPadding: PaddingValues = PaddingValues(),
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .testTag(UseSmileIDSampleTestIds.KYC_FORM_SCREEN),
    ) {
        UseSmileIDSampleTopAppBar(title = productLabel, onBack = onBack)
        Box(modifier = Modifier.weight(1f)) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(contentPadding)
                    .padding(horizontal = SmileDimens.spacingMd),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
            ) {
                UseSmileIDSampleSectionLabel(text = "COUNTRY")
                UseSmileIDSampleSelectTrigger(
                    value = details.country?.label,
                    placeholder = "Select country",
                    onClick = onCountryClick,
                    testId = UseSmileIDSampleTestIds.COUNTRY_TRIGGER,
                    // The design leads with the chosen country's flag, falling back to a globe.
                    leading = { UseSmileIDSampleTriggerEmoji(details.country?.flag ?: GLOBE_EMOJI) },
                )
                UseSmileIDSampleSectionLabel(text = "ID TYPE")
                UseSmileIDSampleSelectTrigger(
                    value = details.idType?.label,
                    placeholder = if (details.country == null) "Choose a country first" else "Select ID type",
                    onClick = onIdTypeClick,
                    enabled = details.country != null,
                    testId = UseSmileIDSampleTestIds.ID_TYPE_TRIGGER,
                    // The design uses 🪪, which is Emoji 14 and renders as tofu below Android 13 —
                    // minSdk here is 26. The design set's own ID mark carries the same meaning at every level.
                    leading = { tint -> UseSmileIDSampleIcon(id = R.drawable.sample_ic_biometric_kyc, tint = tint) },
                )
                UseSmileIDSampleSectionLabel(text = "ID NUMBER")
                UseSmileIDSampleTextInput(
                    value = details.idNumber,
                    onValueChange = onIdNumberChange,
                    placeholder = "Enter ID number",
                    keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Characters),
                    testId = UseSmileIDSampleTestIds.ID_NUMBER_INPUT,
                )
            }
            UseSmileIDSampleFloatingTokenButton(
                onClick = onTokenClick,
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(SmileDimens.spacingMd),
            )
        }
        UseSmileIDSampleButton(
            text = "Continue",
            onClick = onContinue,
            enabled = details.isComplete,
            modifier = Modifier
                .fillMaxWidth()
                .padding(SmileDimens.spacingMd),
            testId = UseSmileIDSampleTestIds.KYC_CONTINUE,
        )
    }
}

/** The design's own leading emoji for the country picker. */
private const val GLOBE_EMOJI = "\ud83c\udf0d"
