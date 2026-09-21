package com.usesmileid.sampleapps.ui.components

import androidx.compose.runtime.Composable
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.SemanticsNode
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.v2.runComposeUiTest
import com.usesmileid.sampleapps.ui.golden.ROBOLECTRIC_SDK
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** The app bar's controls have to be reachable one at a time, which a screenshot cannot show. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [ROBOLECTRIC_SDK], qualifiers = "w411dp-h891dp-xhdpi")
@OptIn(ExperimentalTestApi::class)
class UseSmileIDSampleTopAppBarSemanticsTest {

    private data class Announced(val label: String, val button: Boolean, val header: Boolean)

    private fun bar(action: (@Composable () -> Unit)?): List<Announced> {
        lateinit var announced: List<Announced>
        runComposeUiTest {
            setContent {
                UseSmileIDSampleTheme(darkTheme = false) {
                    UseSmileIDSampleTopAppBar(title = TITLE, onBack = {}, action = action)
                }
            }
            announced = onRoot().fetchSemanticsNode().labelled()
        }
        return announced
    }

    private fun SemanticsNode.labelled(): List<Announced> {
        val found = mutableListOf<Announced>()
        fun walk(node: SemanticsNode) {
            val label = node.config.getOrNull(SemanticsProperties.ContentDescription)?.firstOrNull()
                ?: node.config.getOrNull(SemanticsProperties.Text)?.firstOrNull()?.text
            if (!label.isNullOrEmpty()) {
                found += Announced(
                    label = label,
                    button = node.config.getOrNull(SemanticsProperties.Role) == Role.Button,
                    header = node.config.getOrNull(SemanticsProperties.Heading) != null,
                )
            }
            node.children.forEach(::walk)
        }
        walk(this)
        return found
    }

    // The configuration most screens use, and the one a merge collapses first.
    @Test
    fun `with no action the back control and the title stay apart`() {
        val nodes = bar(action = null)

        assertEquals(listOf(BACK, TITLE), nodes.map { it.label })
        assertEquals("the back control is a button", true, nodes.first().button)
        assertEquals("the header is the title", true, nodes.last().header)
        assertEquals(
            "a title announced as a button offers an action it does not have",
            false,
            nodes.last().button,
        )
    }

    @Test
    fun `with an action all three are separately reachable`() {
        val nodes = bar(action = { UseSmileIDSampleTopAppBarButton(DELETE, onClick = {}) { TrashGlyph(it) } })

        assertEquals(listOf(BACK, TITLE, DELETE), nodes.map { it.label })
    }

    // The symptom a merge produces, asserted without naming the strings it would join.
    @Test
    fun `no node carries more than one label`() {
        val merged = listOf(
            bar(action = null),
            bar(action = { UseSmileIDSampleTopAppBarButton(DELETE, onClick = {}) { TrashGlyph(it) } }),
        ).flatten().filter { it.label.contains('\n') }.map { it.label.replace("\n", " + ") }

        assertEquals(emptyList<String>(), merged)
    }

    private companion object {
        const val BACK = "Back"
        const val TITLE = "Verification details"
        const val DELETE = "Hide verification from the app list"
    }
}
