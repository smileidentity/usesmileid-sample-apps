package com.usesmileid.sampleapps.ui.screens

import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performScrollToIndex
import androidx.compose.ui.unit.Dp
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleJobStore
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJobFilter
import com.usesmileid.sampleapps.ui.model.startOfDayMillis
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/** The Verifications header: Select only when there is something to select, and every filter chip on one row. */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [36], qualifiers = "w393dp-h852dp-xhdpi")
class VerificationsHeaderTest {
    @get:Rule val compose = createComposeRule()

    @Test
    fun an_empty_list_offers_nothing_to_select() {
        show(jobs = emptyList())

        assertNothingToSelect()
    }

    @Test
    fun a_list_still_loading_offers_nothing_to_select() {
        show(jobs = null)

        assertNothingToSelect()
    }

    @Test
    fun a_list_with_rows_offers_select() {
        show(jobs = JOBS)

        compose.onNodeWithTag(UseSmileIDSampleTestIds.SELECT_TOGGLE).assertExists()
    }

    @Test
    fun select_mode_keeps_cancel_even_once_the_list_empties() {
        show(jobs = emptyList(), selectMode = true)

        compose.onNodeWithTag(UseSmileIDSampleTestIds.SELECT_TOGGLE).assertExists()
    }

    @Test
    fun the_title_stays_put_when_select_is_hidden() {
        show(jobs = JOBS)
        val withRows = titleTop()

        show(jobs = emptyList())

        assertEquals(withRows, titleTop())
    }

    @Test
    @Config(qualifiers = "w393dp-h480dp-xhdpi")
    fun the_chip_row_keeps_its_scroll_when_the_header_scrolls_away_and_back() {
        show(jobs = JOBS)
        val error = UseSmileIDSampleTestIds.filterChip(UseSmileIDSampleJobFilter.entries.last().id)
        compose.onNodeWithTag(error, useUnmergedTree = true).performScrollTo()
        val scrolledTo = compose.onNodeWithTag(error, useUnmergedTree = true).getBoundsInRoot().left

        compose.onNodeWithTag(UseSmileIDSampleTestIds.VERIFICATIONS_SCREEN).performScrollToIndex(JOBS.size + 3)
        compose.onNodeWithTag(UseSmileIDSampleTestIds.VERIFICATIONS_SCREEN).performScrollToIndex(0)

        assertEquals(scrolledTo, compose.onNodeWithTag(error, useUnmergedTree = true).getBoundsInRoot().left)
    }

    @Test
    fun every_filter_chip_sits_on_one_row() {
        show(jobs = JOBS)

        val tops = UseSmileIDSampleJobFilter.entries.map { filter ->
            compose.onNodeWithTag(UseSmileIDSampleTestIds.filterChip(filter.id), useUnmergedTree = true).getBoundsInRoot().top
        }
        assertEquals("chip tops $tops", 1, tops.distinct().size)
    }

    private val shown = mutableStateOf<UseSmileIDSampleVerificationsState?>(null)

    private fun show(jobs: List<UseSmileIDSampleJob>?, selectMode: Boolean = false) {
        val first = shown.value == null
        shown.value = UseSmileIDSampleVerificationsState(
            jobs = jobs,
            counts = UseSmileIDSampleJobFilter.entries.associateWith { f -> jobs.orEmpty().count(f::matches) },
            selectMode = selectMode,
            todayStartMillis = startOfDayMillis(FIXED_NOW),
        )
        if (first) {
            compose.setContent {
                UseSmileIDSampleTheme(darkTheme = false) {
                    shown.value?.let { state ->
                        VerificationsScreen(
                            state = state,
                            onFilterChange = {},
                            onSelectModeChange = {},
                            onSelectionChange = { _, _ -> },
                            onJobClick = {},
                            onRemove = {},
                        )
                    }
                }
            }
        }
        compose.waitForIdle()
    }

    private fun assertNothingToSelect() {
        compose.onNodeWithTag(UseSmileIDSampleTestIds.SELECT_TOGGLE).assertDoesNotExist()
        compose.onNodeWithText("Select").assertDoesNotExist()
        compose.onAllNodes(hasClickAction() and hasText("Select")).assertCountEquals(0)
    }

    private fun titleTop(): Dp = compose.onNodeWithText("Verifications").getBoundsInRoot().top

    private companion object {
        const val FIXED_NOW = 1_784_202_612_000L
        val JOBS = UseSmileIDSampleJobStore.fixtures(FIXED_NOW)
    }
}
