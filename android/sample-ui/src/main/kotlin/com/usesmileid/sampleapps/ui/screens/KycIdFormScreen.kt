package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
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
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleIcon
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionLabel
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSelectTrigger
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTextInput
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBar
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTriggerEmoji
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureAs
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogue
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueFamily
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdNumberHint

/** The ID-details form: an ID type and number for KYC, a document and how to capture it otherwise. */
@Composable
fun KycIdFormScreen(
    productLabel: String,
    family: UseSmileIDSampleCatalogueFamily,
    details: UseSmileIDSampleIdDetails,
    /** The chosen country's list, which decides the second trigger's placeholder while it is still arriving. */
    countryList: UseSmileIDSampleCatalogue<*>,
    onCountryClick: () -> Unit,
    onIdTypeClick: () -> Unit,
    onDocumentClick: () -> Unit,
    onCaptureAsClick: () -> Unit,
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
            // Continue rides above the keyboard, so it is never under it and a tap never lands on the IME.
            .imePadding()
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
                    value = details.country?.name,
                    placeholder = "Select country",
                    onClick = onCountryClick,
                    testId = UseSmileIDSampleTestIds.COUNTRY_TRIGGER,
                    // The design leads with the chosen country's flag, falling back to a globe.
                    leading = { UseSmileIDSampleTriggerEmoji(details.country?.flag ?: GLOBE_EMOJI) },
                )
                when (family) {
                    UseSmileIDSampleCatalogueFamily.Kyc -> KycFields(details, countryList, onIdTypeClick, onIdNumberChange)
                    UseSmileIDSampleCatalogueFamily.Document -> DocumentFields(details, countryList, onDocumentClick, onCaptureAsClick)
                }
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
            enabled = details.isComplete(family),
            modifier = Modifier
                .fillMaxWidth()
                .padding(SmileDimens.spacingMd),
            testId = UseSmileIDSampleTestIds.KYC_CONTINUE,
        )
    }
}

@Composable
private fun KycFields(
    details: UseSmileIDSampleIdDetails,
    countryList: UseSmileIDSampleCatalogue<*>,
    onIdTypeClick: () -> Unit,
    onIdNumberChange: (String) -> Unit,
) {
    UseSmileIDSampleSectionLabel(text = "ID TYPE")
    UseSmileIDSampleSelectTrigger(
        value = details.idType?.label,
        placeholder = secondTriggerPlaceholder(details, countryList, loading = "Loading ID types…", ready = "Select ID type"),
        onClick = onIdTypeClick,
        enabled = details.country != null,
        testId = UseSmileIDSampleTestIds.ID_TYPE_TRIGGER,
        // Not the design's 🪪: Emoji 14 renders as tofu below Android 13, and minSdk here is 26.
        leading = { tint -> UseSmileIDSampleIcon(id = R.drawable.sample_ic_biometric_kyc, tint = tint) },
    )
    UseSmileIDSampleSectionLabel(text = "ID NUMBER")
    val error = UseSmileIDSampleIdNumberHint.error(details.idType, details.idNumber)
    UseSmileIDSampleTextInput(
        value = details.idNumber,
        onValueChange = onIdNumberChange,
        placeholder = UseSmileIDSampleIdNumberHint.placeholder(details.idType),
        enabled = details.idType != null,
        isError = error != null,
        errorMessage = error,
        keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Characters),
        testId = UseSmileIDSampleTestIds.ID_NUMBER_INPUT,
        errorTestId = UseSmileIDSampleTestIds.ID_NUMBER_ERROR,
    )
}

@Composable
private fun DocumentFields(
    details: UseSmileIDSampleIdDetails,
    countryList: UseSmileIDSampleCatalogue<*>,
    onDocumentClick: () -> Unit,
    onCaptureAsClick: () -> Unit,
) {
    UseSmileIDSampleSectionLabel(text = "DOCUMENT")
    UseSmileIDSampleSelectTrigger(
        value = details.document?.name,
        placeholder = secondTriggerPlaceholder(details, countryList, loading = "Loading documents…", ready = "Select document"),
        onClick = onDocumentClick,
        enabled = details.country != null,
        testId = UseSmileIDSampleTestIds.DOCUMENT_TRIGGER,
        leading = { tint -> UseSmileIDSampleIcon(id = R.drawable.sample_ic_document_verification, tint = tint) },
    )
    UseSmileIDSampleSectionLabel(text = "CAPTURE AS")
    UseSmileIDSampleSelectTrigger(
        value = when (details.captureAs) {
            UseSmileIDSampleCaptureAs.Custom -> "Custom: ${details.custom.displayName}"
            else -> details.captureAs.label
        },
        placeholder = UseSmileIDSampleCaptureAs.Automatic.label,
        onClick = onCaptureAsClick,
        enabled = details.document != null,
        testId = UseSmileIDSampleTestIds.CAPTURE_AS_TRIGGER,
        leading = { tint -> UseSmileIDSampleIcon(id = R.drawable.sample_ic_setting_preview, tint = tint) },
    )
}

/** Enabled while loading, with a muted "Loading…" in place of the prompt, so the form never looks stuck. */
private fun secondTriggerPlaceholder(
    details: UseSmileIDSampleIdDetails,
    countryList: UseSmileIDSampleCatalogue<*>,
    loading: String,
    ready: String,
): String = when {
    details.country == null -> "Choose a country first"
    countryList is UseSmileIDSampleCatalogue.Loading -> loading
    else -> ready
}

/** The leading emoji for the country picker. */
private const val GLOBE_EMOJI = "🌍"
