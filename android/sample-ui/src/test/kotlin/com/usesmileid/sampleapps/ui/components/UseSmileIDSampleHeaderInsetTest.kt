package com.usesmileid.sampleapps.ui.components

import android.view.View
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.calculateEndPadding
import androidx.compose.foundation.layout.calculateStartPadding
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.core.graphics.Insets
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/** A header keeps a small gap below the status bar on a phone with a top camera cutout, which the bar ends flush with. */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [36], qualifiers = "w411dp-h891dp-xhdpi")
class UseSmileIDSampleHeaderInsetTest {
    @get:Rule val compose = createComposeRule()

    @Test
    fun on_a_cutout_phone_the_back_button_sits_a_small_gap_below_the_status_bar() {
        showTopAppBar(STATUS_BAR_PX, cutoutTop = CUTOUT_PX)

        assertEquals(px(STATUS_BAR_PX) + SmileDimens.spacingSm, backTop())
    }

    @Test
    fun on_a_phone_without_a_cutout_the_back_button_stays_against_the_status_bar() {
        showTopAppBar(PLAIN_STATUS_BAR_PX, cutoutTop = 0)

        assertEquals(px(PLAIN_STATUS_BAR_PX), backTop())
    }

    @Test
    fun without_a_status_bar_the_back_button_keeps_its_place() {
        showTopAppBar(statusBar = null, cutoutTop = 0)

        assertEquals(0.dp, backTop())
    }

    @Test
    fun a_tab_header_gets_the_gap_only_under_a_top_cutout() {
        lateinit var view: View
        compose.setContent {
            view = LocalView.current
            Box(Modifier.size(useSmileIDSampleHeaderTopGap()).testTag(GAP))
        }
        compose.waitForIdle()
        assertEquals(0.dp, gap())

        dispatchInsets(view, STATUS_BAR_PX, Insets.of(0, CUTOUT_PX, 0, 0))
        assertEquals(SmileDimens.spacingSm, gap())

        dispatchInsets(view, PLAIN_STATUS_BAR_PX, Insets.NONE)
        assertEquals(0.dp, gap())

        // Landscape: the cutout moves to the side and the status bar stays on top.
        dispatchInsets(view, STATUS_BAR_PX, Insets.of(CUTOUT_PX, 0, 0, 0))
        assertEquals(0.dp, gap())
    }

    @Test
    fun inside_the_large_screen_frame_the_status_bar_is_outside_so_no_gap_is_added() {
        lateinit var view: View
        compose.setContent {
            view = LocalView.current
            CompositionLocalProvider(LocalUseSmileIDSampleLargeScreenFramed provides true) {
                Box(Modifier.size(useSmileIDSampleHeaderTopGap()).testTag(GAP))
            }
        }
        dispatchInsets(view, STATUS_BAR_PX, Insets.of(0, CUTOUT_PX, 0, 0))

        assertEquals(0.dp, gap())
    }

    @Test
    fun a_tab_list_adds_the_gap_on_top_and_keeps_its_other_padding() {
        lateinit var view: View
        lateinit var padding: PaddingValues
        compose.setContent {
            view = LocalView.current
            padding = useSmileIDSampleHeaderContentPadding(PaddingValues(start = 1.dp, top = 2.dp, end = 3.dp, bottom = 4.dp))
        }
        dispatchInsets(view, STATUS_BAR_PX, Insets.of(0, CUTOUT_PX, 0, 0))

        assertEquals(2.dp + SmileDimens.spacingSm, padding.calculateTopPadding())
        assertEquals(1.dp, padding.calculateStartPadding(LayoutDirection.Ltr))
        assertEquals(3.dp, padding.calculateEndPadding(LayoutDirection.Ltr))
        assertEquals(4.dp, padding.calculateBottomPadding())
    }

    private fun showTopAppBar(statusBar: Int?, cutoutTop: Int) {
        lateinit var view: View
        compose.setContent {
            view = LocalView.current
            UseSmileIDSampleTheme { UseSmileIDSampleTopAppBar(title = "Open-source licenses", onBack = {}, backContentDescription = BACK) }
        }
        if (statusBar != null) dispatchInsets(view, statusBar, Insets.of(0, cutoutTop, 0, 0))
        compose.waitForIdle()
    }

    private fun dispatchInsets(view: View, statusBarPx: Int, cutout: Insets) {
        compose.runOnIdle {
            ViewCompat.dispatchApplyWindowInsets(
                view,
                WindowInsetsCompat.Builder()
                    .setInsets(WindowInsetsCompat.Type.statusBars(), Insets.of(0, statusBarPx, 0, 0))
                    .setVisible(WindowInsetsCompat.Type.statusBars(), true)
                    .setInsets(WindowInsetsCompat.Type.displayCutout(), cutout)
                    .build(),
            )
        }
        compose.waitForIdle()
    }

    private fun gap(): Dp = compose.onNodeWithTag(GAP).getBoundsInRoot().run { bottom - top }

    private fun backTop(): Dp = compose.onNodeWithContentDescription(BACK).getBoundsInRoot().top

    private fun px(value: Int): Dp = with(compose.density) { value.toDp() }

    private companion object {
        const val GAP = "gap"
        const val BACK = "Back"

        /** A punch-hole phone's 37dp status bar at xhdpi, sized by Android to clear its 35dp cutout. */
        const val STATUS_BAR_PX = 74
        const val CUTOUT_PX = 70

        /** The standard 24dp status bar of a phone without a cutout. */
        const val PLAIN_STATUS_BAR_PX = 48
    }
}
