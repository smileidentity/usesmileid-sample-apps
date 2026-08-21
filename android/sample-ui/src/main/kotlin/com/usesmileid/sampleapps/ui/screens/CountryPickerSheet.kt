package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleEmptyState
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleFullHeightBottomSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleOptionRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSearchField
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCountry
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The country picker. A full-height sheet, because the list is long enough that a partial one fights the keyboard. */
@Composable
fun CountryPickerSheet(
    selected: UseSmileIDSampleCountry?,
    query: String,
    onQueryChange: (String) -> Unit,
    onSelect: (UseSmileIDSampleCountry) -> Unit,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val matches = UseSmileIDSampleCountry.entries.filter { it.label.contains(query, ignoreCase = true) }
    UseSmileIDSampleFullHeightBottomSheet(
        title = "Country",
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        testId = UseSmileIDSampleTestIds.COUNTRY_SHEET,
    ) {
        UseSmileIDSampleSearchField(
            query = query,
            onQueryChange = onQueryChange,
            placeholder = "Search country",
            testId = UseSmileIDSampleTestIds.COUNTRY_SEARCH,
        )
        PickerList(
            empty = matches.isEmpty(),
            emptyLabel = "No country matches \u201c$query\u201d",
            emptyTestId = UseSmileIDSampleTestIds.COUNTRY_EMPTY,
        ) {
            matches.forEach { country ->
                UseSmileIDSampleOptionRow(
                    label = country.label,
                    selected = country == selected,
                    onClick = { onSelect(country) },
                    leadingText = country.flag,
                    testId = UseSmileIDSampleTestIds.countryOption(country.code),
                )
            }
        }
    }
}

/** An empty result is a state a search must have, or a typo looks like a broken sheet. */
@Composable
internal fun PickerList(
    empty: Boolean,
    emptyLabel: String,
    emptyTestId: String,
    content: @Composable () -> Unit,
) {
    if (empty) {
        UseSmileIDSampleEmptyState(text = emptyLabel, testId = emptyTestId)
        return
    }
    Column(
        modifier = Modifier.verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
    ) {
        content()
    }
}
