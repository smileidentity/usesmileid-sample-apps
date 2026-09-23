package com.usesmileid.sampleapps.android

import android.app.Dialog
import android.graphics.Color
import android.view.Window
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.core.graphics.ColorUtils
import androidx.core.view.WindowCompat
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleBottomSheet
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowDialog
import org.robolectric.shadows.ShadowLooper

/** System-bar contrast in both presentations, whatever the device's night mode. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class UseSmileIDSampleSystemBarsTest {

    @Test
    @Config(qualifiers = "night")
    fun `a light app on a dark device draws dark icons on the pushed window`() {
        assertIcons(window = shell(darkMode = false), dark = false)
    }

    @Test
    @Config(qualifiers = "notnight")
    fun `a dark app on a light device draws light icons on the pushed window`() {
        assertIcons(window = shell(darkMode = true), dark = true)
    }

    @Test
    @Config(qualifiers = "night")
    fun `the shipped activity keeps a light app's icons dark on a dark device`() {
        val activity = Robolectric.buildActivity(UseSmileIDSampleActivity::class.java).setup().get()
        ShadowLooper.idleMainLooper()
        assertIcons(window = activity.window, dark = false)
    }

    @Test
    @Config(sdk = [25], qualifiers = "notnight")
    fun `below API 26 a light app keeps a navigation bar its white buttons show on`() {
        val window = compose(darkMode = false) { }.window
        // Over a white page, so a translucent light scrim cannot pass for a dark one.
        val drawn = ColorUtils.compositeColors(window.navigationBarColor, Color.WHITE)
        assertTrue("a dark bar", ColorUtils.calculateLuminance(drawn) < 0.5)
    }

    // Material 3 derives the sheet window's bars from its content colour.
    @Test
    @Config(qualifiers = "night")
    fun `a light app on a dark device draws dark icons over a sheet`() {
        assertIcons(window = sheet(darkMode = false), dark = false)
    }

    @Test
    @Config(qualifiers = "notnight")
    fun `a dark app on a light device draws light icons over a sheet`() {
        assertIcons(window = sheet(darkMode = true), dark = true)
    }

    private fun shell(darkMode: Boolean): Window = compose(darkMode) { }.window

    private fun sheet(darkMode: Boolean): Window {
        compose(darkMode) { UseSmileIDSampleBottomSheet(onDismissRequest = {}) { Text("Sheet") } }
        val dialog: Dialog? = ShadowDialog.getLatestDialog()
        assertNotNull("the sheet opens a window of its own", dialog)
        return dialog!!.window!!
    }

    private fun compose(darkMode: Boolean, content: @Composable () -> Unit): ComponentActivity {
        val activity = Robolectric.buildActivity(ComponentActivity::class.java).setup().get()
        activity.setContent {
            UseSmileIDSampleTheme(darkTheme = darkMode) {
                UseSmileIDSampleSystemBars(darkMode)
                content()
            }
        }
        ShadowLooper.idleMainLooper()
        return activity
    }

    private fun assertIcons(window: Window, dark: Boolean) {
        val controller = WindowCompat.getInsetsController(window, window.decorView)
        assertEquals("status bar icons", !dark, controller.isAppearanceLightStatusBars)
        assertEquals("navigation bar icons", !dark, controller.isAppearanceLightNavigationBars)
    }
}
