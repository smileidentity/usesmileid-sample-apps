package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * The pushed-screen app bar: a dark-filled circular back control, a title, and an optional trailing
 * circular action.
 *
 * The visual back control is in addition to the platform gesture, never instead of it — the caller
 * still lets system back pop the destination.
 */
@Composable
fun UseSmileIDSampleTopAppBar(
    title: String,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    backContentDescription: String = "Back",
    testId: String? = null,
    action: @Composable (() -> Unit)? = null,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .windowInsetsPadding(WindowInsets.statusBars)
            .padding(horizontal = SmileDimens.spacingMd)
            .defaultMinSize(minHeight = SmileDimens.space48)
            .tagged(testId),
        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        UseSmileIDSampleTopAppBarButton(
            contentDescription = backContentDescription,
            onClick = onBack,
            emphasis = UseSmileIDSampleTopAppBarEmphasis.Filled,
        ) { tint -> BackArrowGlyph(tint = tint) }

        Text(
            text = title,
            style = UseSmileIDSampleTheme.type.textStyleTitle,
            color = UseSmileIDSampleTheme.colors.textTitle,
            // The title yields to the two controls rather than pushing the trailing one off-screen,
            // and wraps instead of capping: a long product name needs more than two lines at 2x, and
            // ellipsising a screen title is the clipping the font-scale predicate forbids.
            modifier = Modifier.weight(1f),
        )

        // Holds the trailing control's width even when there is none, so the title sits identically
        // on a bar with an action and one without.
        if (action != null) action() else Box(Modifier.size(SmileDimens.space40))
    }
}

/** Filled is the dark control used for back and the Scan token torch; Tonal is the light trailing action. */
enum class UseSmileIDSampleTopAppBarEmphasis { Filled, Tonal }

/** One circular 40dp app-bar control. The glyph is handed the tint its emphasis resolves to. */
@Composable
fun UseSmileIDSampleTopAppBarButton(
    contentDescription: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    emphasis: UseSmileIDSampleTopAppBarEmphasis = UseSmileIDSampleTopAppBarEmphasis.Tonal,
    testId: String? = null,
    glyph: @Composable (Color) -> Unit,
) {
    val colors = UseSmileIDSampleTheme.colors
    val (container, tint) = when (emphasis) {
        UseSmileIDSampleTopAppBarEmphasis.Filled -> colors.textTitle to colors.textInverse
        UseSmileIDSampleTopAppBarEmphasis.Tonal -> colors.surfaceAlt to colors.textTitle
    }
    Surface(
        onClick = onClick,
        // 40dp by design; Material still expands the touch target to the platform minimum around it.
        modifier = modifier
            .size(SmileDimens.space40)
            .semantics { this.contentDescription = contentDescription }
            .tagged(testId),
        shape = CircleShape,
        color = container,
    ) {
        Box(contentAlignment = Alignment.Center) { glyph(tint) }
    }
}
