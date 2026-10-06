package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.UseSmileIDSampleStrings
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleBottomSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleOptionRow
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleLanguage

/** System, then each shipped language under its own name. */
@Composable
fun LanguageSheet(
    selected: UseSmileIDSampleLanguage,
    deviceLanguages: List<String>,
    onSelect: (UseSmileIDSampleLanguage) -> Unit,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
) {
    UseSmileIDSampleBottomSheet(
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        title = UseSmileIDSampleStrings.languageTitle,
        testId = UseSmileIDSampleTestIds.LANGUAGE_SHEET,
    ) {
        UseSmileIDSampleLanguage.entries.forEach { language ->
            UseSmileIDSampleOptionRow(
                label = language.label(deviceLanguages),
                selected = language == selected,
                onClick = { onSelect(language) },
                testId = UseSmileIDSampleTestIds.languageOption(language.id),
            )
        }
    }
}

/** System names the language the device resolves to; a named language is its own name. */
@Composable
fun UseSmileIDSampleLanguage.label(deviceLanguages: List<String>): String =
    if (this == UseSmileIDSampleLanguage.System) {
        UseSmileIDSampleStrings.languageSystem(resolved(deviceLanguages).endonym)
    } else {
        endonym
    }
