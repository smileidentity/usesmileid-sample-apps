package com.usesmileid.sampleapps.android

import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import java.io.File
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLooper

/** On a large screen the app draws its own screens in the largest phone's frame, centred; a phone, and the full-screen SDK run, fill the window. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class UseSmileIDSampleLargeScreenFrameTest {
    @get:Rule
    val activities = UseSmileIDSampleActivities()

    private val frame = UseSmileIDSampleLargeScreen.frame

    @Test
    fun `the frame is the spec's android frame`() {
        val spec = Json.parseToJsonElement(File(specDir(), "large-screen-frame.json").readText()).jsonObject
        val android = spec.getValue("frames").jsonObject.getValue("android").jsonObject

        assertEquals(spec.getValue("largeScreenMinSide").jsonPrimitive.int.dp, UseSmileIDSampleLargeScreen.minSide)
        assertEquals(DpSize(android.getValue("width").jsonPrimitive.int.dp, android.getValue("height").jsonPrimitive.int.dp), frame)
    }

    @Test
    fun `a large screen draws the app in the largest phone's frame`() {
        assertEquals(frame, frameIn(800, 1280))
        assertEquals(frame, frameIn(600, 960))
        assertEquals(DpSize(frame.width, 800.dp), frameIn(1280, 800))
    }

    @Test
    fun `a phone draws the app across its whole window`() {
        assertNull(frameIn(frame.width.value.toInt(), frame.height.value.toInt()))
        assertNull(frameIn(frame.height.value.toInt(), frame.width.value.toInt()))
        assertNull(frameIn(599, 1280))
    }

    @Test
    fun `a side shorter than its frame keeps the safe area's length`() {
        assertEquals(DpSize(frame.width, 728.dp), largeScreenFrameSize(DpSize(1280.dp, 800.dp), DpSize(1280.dp, 728.dp)))
    }

    @Test
    @Config(qualifiers = "w800dp-h1280dp-mdpi")
    fun `a large screen centres the frame`() {
        val (root, screen) = drawn(framed = true)

        val left = (root.width - frame.width.value) / 2
        val top = (root.height - frame.height.value) / 2
        assertEquals(Rect(left, top, left + frame.width.value, top + frame.height.value), screen)
    }

    @Test
    @Config(qualifiers = "w800dp-h1280dp-mdpi")
    fun `the full-screen SDK run fills the window`() {
        val (root, screen) = drawn(framed = false)

        assertEquals(root, screen)
    }

    @Test
    @Config(qualifiers = "w384dp-h832dp-mdpi")
    fun `a phone fills its window`() {
        val (root, screen) = drawn(framed = true)

        assertEquals(root, screen)
    }

    private fun frameIn(width: Int, height: Int): DpSize? = DpSize(width.dp, height.dp).let { largeScreenFrameSize(it, it) }

    /** The window's bounds and the screen's, in px, which are dp at mdpi. */
    private fun drawn(framed: Boolean): Pair<Rect, Rect> {
        var root = Rect.Zero
        var screen = Rect.Zero
        val activity = activities.build(ComponentActivity::class.java).setup().get()
        activity.setContent {
            UseSmileIDSampleTheme(darkTheme = false) {
                Box(Modifier.fillMaxSize().onGloballyPositioned { root = it.boundsInRoot() }) {
                    UseSmileIDSampleLargeScreenFrame(framed = framed, modifier = Modifier.fillMaxSize()) {
                        Box(Modifier.fillMaxSize().onGloballyPositioned { screen = it.boundsInRoot() })
                    }
                }
            }
        }
        ShadowLooper.idleMainLooper()
        return root to screen
    }

    private fun specDir(): File = File(requireNotNull(System.getProperty("sampleapps.spec.dir")) { "sampleapps.spec.dir is not set; see app/build.gradle.kts" })
}
