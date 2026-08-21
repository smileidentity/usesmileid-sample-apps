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
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdType
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

/** The ID-type picker. Its list depends on the country, which is why the trigger opening it is disabled without one. */
@Composable
fun IdTypePickerSheet(
    country: UseSmileIDSampleCountry?,
    selected: UseSmileIDSampleIdType?,
    query: String,
    onQueryChange: (String) -> Unit,
    onSelect: (UseSmileIDSampleIdType) -> Unit,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val matches = UseSmileIDSampleIdType.of(country).filter { it.label.contains(query, ignoreCase = true) }
    UseSmileIDSampleFullHeightBottomSheet(
        title = "ID type",
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        testId = UseSmileIDSampleTestIds.ID_TYPE_SHEET,
    ) {
        UseSmileIDSampleSearchField(
            query = query,
            onQueryChange = onQueryChange,
            placeholder = "Search ID type",
            testId = UseSmileIDSampleTestIds.ID_TYPE_SEARCH,
        )
        PickerList(
            empty = matches.isEmpty(),
            emptyLabel = if (query.isBlank()) "No ID type for this country" else "No ID type matches \u201c$query\u201d",
            emptyTestId = UseSmileIDSampleTestIds.ID_TYPE_EMPTY,
        ) {
            matches.forEach { idType ->
                UseSmileIDSampleOptionRow(
                    label = idType.label,
                    selected = idType == selected,
                    onClick = { onSelect(idType) },
                    testId = UseSmileIDSampleTestIds.idTypeOption(idType.id),
                )
            }
        }
    }
}

/** An empty result is a state a search must have, or a typo looks like a broken sheet. */
@Composable
private fun PickerList(
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
