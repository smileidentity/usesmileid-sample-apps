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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.sp
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The pushed-screen app bar: a dark-filled circular back control, a title, and an optional trailing action. */
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
        // A fixed row height, so a longer title cannot grow the bar and drop the header on one screen.
        modifier = modifier
            .fillMaxWidth()
            .windowInsetsPadding(WindowInsets.statusBars)
            .padding(horizontal = SmileDimens.spacingMd)
            .defaultMinSize(minHeight = HEADER_ROW_HEIGHT * LocalDensity.current.fontScale.coerceAtLeast(1f))
            .padding(bottom = SmileDimens.spacingXs)
            .tagged(testId),
        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        UseSmileIDSampleTopAppBarButton(
            contentDescription = backContentDescription,
            onClick = onBack,
            emphasis = UseSmileIDSampleTopAppBarEmphasis.Filled,
        ) { tint -> ArrowBackGlyph(tint = tint) }

        Text(
            text = title,
            style = UseSmileIDSampleTheme.type.textStyleTitle.copy(fontSize = TITLE_SIZE),
            color = UseSmileIDSampleTheme.colors.textTitle,
            textAlign = TextAlign.Center,
            // Wraps rather than caps: ellipsising a title is the clipping the predicate forbids.
            modifier = Modifier.weight(1f),
        )

        // Holds the action's width even with no action, so the title sits identically either way.
        if (action != null) action() else Box(Modifier.size(SmileDimens.space40))
    }
}

/** Filled is the dark control used for back and the Scan token torch; Tonal is the light trailing action; Destructive is the soft-red delete. */
enum class UseSmileIDSampleTopAppBarEmphasis { Filled, Tonal, Destructive }

/** One circular 40dp app-bar control; Material expands the touch target around it. */
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
        UseSmileIDSampleTopAppBarEmphasis.Tonal -> colors.surfaceTile to colors.textTitle
        UseSmileIDSampleTopAppBarEmphasis.Destructive -> colors.badge.errorBackground to colors.badge.errorText
    }
    Surface(
        onClick = onClick,
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

private val TITLE_SIZE = 15.sp

private val HEADER_ROW_HEIGHT = 40.dp
