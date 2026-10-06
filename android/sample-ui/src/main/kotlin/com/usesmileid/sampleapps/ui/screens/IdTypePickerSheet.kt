package com.usesmileid.sampleapps.ui.screens

import com.usesmileid.sampleapps.ui.UseSmileIDSampleStrings
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
        title = UseSmileIDSampleStrings.pickerIdTypeTitle,
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        testId = UseSmileIDSampleTestIds.ID_TYPE_SHEET,
    ) {
        CataloguePicker(
            catalogue = catalogue,
            loadingLabel = UseSmileIDSampleStrings.pickerIdTypeLoading,
            failedLabel = UseSmileIDSampleStrings.pickerIdTypeLoadFailed,
            query = query,
            onQueryChange = onQueryChange,
            searchPlaceholder = UseSmileIDSampleStrings.pickerIdTypeSearch,
            searchTestId = UseSmileIDSampleTestIds.ID_TYPE_SEARCH,
            label = { it.label },
            emptyTestId = UseSmileIDSampleTestIds.ID_TYPE_EMPTY,
            emptyLabel = UseSmileIDSampleStrings.pickerIdTypeNoMatch(query),
            nothingToList = UseSmileIDSampleStrings.pickerIdTypeEmpty(country?.name ?: UseSmileIDSampleStrings.pickerThisCountry) to UseSmileIDSampleStrings.pickerChooseAnotherCountry,
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
