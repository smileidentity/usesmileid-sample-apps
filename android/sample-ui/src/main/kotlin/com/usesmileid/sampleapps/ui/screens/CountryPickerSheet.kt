package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
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
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSkeletonRows
import com.usesmileid.sampleapps.ui.components.rememberUseSmileIDSampleSkeletonVisible
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogue
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCountry

/** The country picker. A full-height sheet, because the list is long enough that a partial one fights the keyboard. */
@Composable
fun CountryPickerSheet(
    catalogue: UseSmileIDSampleCatalogue<UseSmileIDSampleCountry>,
    selected: UseSmileIDSampleCountry?,
    query: String,
    onQueryChange: (String) -> Unit,
    onSelect: (UseSmileIDSampleCountry) -> Unit,
    onRetry: () -> Unit,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
) {
    UseSmileIDSampleFullHeightBottomSheet(
        title = "Country",
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        testId = UseSmileIDSampleTestIds.COUNTRY_SHEET,
    ) {
        CataloguePicker(
            catalogue = catalogue,
            what = "countries",
            query = query,
            onQueryChange = onQueryChange,
            searchPlaceholder = "Search country",
            searchTestId = UseSmileIDSampleTestIds.COUNTRY_SEARCH,
            label = { it.name },
            emptyTestId = UseSmileIDSampleTestIds.COUNTRY_EMPTY,
            emptyLabel = "No country matches “$query”",
            nothingToList = "No countries for this product" to "Try another product",
            onRetry = onRetry,
            leadingCircle = true,
        ) { country ->
            UseSmileIDSampleOptionRow(
                label = country.name,
                selected = country.code == selected?.code,
                onClick = { onSelect(country) },
                leadingText = country.flag,
                testId = UseSmileIDSampleTestIds.countryOption(country.code),
            )
        }
    }
}

/** One picker's body: skeleton rows while loading, an error with Retry, an empty state without one, and a search. */
@Composable
internal fun <T> CataloguePicker(
    catalogue: UseSmileIDSampleCatalogue<T>,
    what: String,
    query: String,
    onQueryChange: (String) -> Unit,
    searchPlaceholder: String,
    searchTestId: String,
    label: (T) -> String,
    emptyTestId: String,
    emptyLabel: String,
    nothingToList: Pair<String, String>,
    onRetry: () -> Unit,
    leadingCircle: Boolean = false,
    row: @Composable (T) -> Unit,
) {
    val loading = catalogue is UseSmileIDSampleCatalogue.Loading
    val skeleton = rememberUseSmileIDSampleSkeletonVisible(loading)
    UseSmileIDSampleSearchField(
        query = query,
        onQueryChange = onQueryChange,
        placeholder = searchPlaceholder,
        testId = searchTestId,
        enabled = catalogue is UseSmileIDSampleCatalogue.Ready && !skeleton,
    )
    when {
        skeleton -> UseSmileIDSampleSkeletonRows(
            announcement = "Loading $what",
            leadingCircle = leadingCircle,
            testId = UseSmileIDSampleTestIds.CATALOGUE_LOADING,
        )
        // The first 300 ms draw nothing, so a fast answer never flashes a skeleton.
        loading -> Unit
        catalogue is UseSmileIDSampleCatalogue.Failed -> UseSmileIDSampleEmptyState(
            text = "Couldn't load $what",
            supportingText = "Check your connection, then try again",
            testId = UseSmileIDSampleTestIds.CATALOGUE_ERROR,
            onRetry = onRetry,
            retryTestId = UseSmileIDSampleTestIds.CATALOGUE_RETRY,
        )
        catalogue is UseSmileIDSampleCatalogue.Ready -> {
            val matches = catalogue.items.filter { label(it).contains(query.trim(), ignoreCase = true) }
            if (matches.isEmpty()) {
                UseSmileIDSampleEmptyState(text = emptyLabel, testId = emptyTestId)
            } else {
                Column(
                    modifier = Modifier.verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
                ) {
                    matches.forEach { row(it) }
                }
            }
        }
        else -> UseSmileIDSampleEmptyState(
            text = nothingToList.first,
            supportingText = nothingToList.second,
            testId = emptyTestId,
        )
    }
}
