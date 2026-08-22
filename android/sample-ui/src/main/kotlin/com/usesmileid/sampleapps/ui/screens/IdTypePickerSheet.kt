package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleFullHeightBottomSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleOptionRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSearchField
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCountry
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdType

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
