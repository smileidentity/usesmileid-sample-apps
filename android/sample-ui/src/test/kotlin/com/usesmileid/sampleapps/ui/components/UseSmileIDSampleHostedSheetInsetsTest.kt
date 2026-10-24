package com.usesmileid.sampleapps.ui.components

import android.view.View
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.material3.Text
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.unit.dp
import androidx.core.graphics.Insets
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/** A sheet a navigation host draws pads for the keyboard: edge to edge, nothing else lifts its fields above it. */
@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [36], qualifiers = "w411dp-h891dp-xhdpi")
class UseSmileIDSampleHostedSheetInsetsTest {
    @get:Rule val compose = createComposeRule()

    @Test
    fun a_hosted_sheet_keeps_its_content_above_the_keyboard() {
        lateinit var view: View
        compose.setContent {
            view = LocalView.current
            UseSmileIDSampleTheme {
                Box(Modifier.fillMaxSize()) {
                    Box(Modifier.align(Alignment.BottomCenter)) {
                        UseSmileIDSampleBottomSheet(onDismissRequest = {}) {
                            Text("Last name", Modifier.testTag(FIELD).height(48.dp))
                        }
                    }
                }
            }
        }
        compose.runOnIdle {
            ViewCompat.dispatchApplyWindowInsets(
                view,
                WindowInsetsCompat.Builder()
                    .setInsets(WindowInsetsCompat.Type.ime(), Insets.of(0, 0, 0, KEYBOARD_PX))
                    .setVisible(WindowInsetsCompat.Type.ime(), true)
                    .build(),
            )
        }
        compose.waitForIdle()

        val windowBottom = compose.onRoot().getBoundsInRoot().bottom
        val fieldBottom = compose.onNodeWithTag(FIELD).getBoundsInRoot().bottom
        val keyboard = with(compose.density) { KEYBOARD_PX.toDp() }
        assertTrue("the field ends at $fieldBottom, under a keyboard reaching ${windowBottom - keyboard}", fieldBottom <= windowBottom - keyboard)
    }

    private companion object {
        const val FIELD = "field"

        /** A phone keyboard's 300dp at xhdpi: taller than any navigation bar, so only the keyboard's inset can clear it. */
        const val KEYBOARD_PX = 600
    }
}
