package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleFullHeightBottomSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleOptionRow
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogue
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCountry
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleKycIdType

/** The ID-type picker. Its list depends on the country, which is why the trigger opening it is disabled without one. */
@Composable
fun IdTypePickerSheet(
    country: UseSmileIDSampleCountry?,
    catalogue: UseSmileIDSampleCatalogue<UseSmileIDSampleKycIdType>,
    selected: UseSmileIDSampleKycIdType?,
    query: String,
    onQueryChange: (String) -> Unit,
    onSelect: (UseSmileIDSampleKycIdType) -> Unit,
    onRetry: () -> Unit,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
) {
    UseSmileIDSampleFullHeightBottomSheet(
        title = "ID type",
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        testId = UseSmileIDSampleTestIds.ID_TYPE_SHEET,
    ) {
        CataloguePicker(
            catalogue = catalogue,
            what = "ID types",
            query = query,
            onQueryChange = onQueryChange,
            searchPlaceholder = "Search ID type",
            searchTestId = UseSmileIDSampleTestIds.ID_TYPE_SEARCH,
            label = { it.label },
            emptyTestId = UseSmileIDSampleTestIds.ID_TYPE_EMPTY,
            emptyLabel = "No ID type matches “$query”",
            nothingToList = "No ID types for ${country?.name ?: "this country"}" to "Choose another country",
            onRetry = onRetry,
        ) { idType ->
            UseSmileIDSampleOptionRow(
                label = idType.label,
                selected = idType.id == selected?.id,
                onClick = { onSelect(idType) },
                testId = UseSmileIDSampleTestIds.idTypeOption(idType.id),
            )
        }
    }
}
