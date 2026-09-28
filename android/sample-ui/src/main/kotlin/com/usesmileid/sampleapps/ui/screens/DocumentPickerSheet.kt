package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleFullHeightBottomSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleOptionRow
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogue
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCountry
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleDocument

/** The document products' picker: the country's supported documents, a standalone sub-type as its own row. */
@Composable
fun DocumentPickerSheet(
    country: UseSmileIDSampleCountry?,
    catalogue: UseSmileIDSampleCatalogue<UseSmileIDSampleDocument>,
    selected: UseSmileIDSampleDocument?,
    query: String,
    onQueryChange: (String) -> Unit,
    onSelect: (UseSmileIDSampleDocument) -> Unit,
    onRetry: () -> Unit,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
) {
    UseSmileIDSampleFullHeightBottomSheet(
        title = "Document",
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        testId = UseSmileIDSampleTestIds.DOCUMENT_SHEET,
    ) {
        CataloguePicker(
            catalogue = catalogue,
            what = "documents",
            query = query,
            onQueryChange = onQueryChange,
            searchPlaceholder = "Search document",
            searchTestId = UseSmileIDSampleTestIds.DOCUMENT_SEARCH,
            label = { it.name },
            emptyTestId = UseSmileIDSampleTestIds.DOCUMENT_EMPTY,
            emptyLabel = "No document matches “$query”",
            nothingToList = "No documents for ${country?.name ?: "this country"}" to "Choose another country",
            onRetry = onRetry,
        ) { document ->
            UseSmileIDSampleOptionRow(
                label = document.name,
                selected = document.id == selected?.id,
                onClick = { onSelect(document) },
                testId = UseSmileIDSampleTestIds.documentOption(document.id),
            )
        }
    }
}
