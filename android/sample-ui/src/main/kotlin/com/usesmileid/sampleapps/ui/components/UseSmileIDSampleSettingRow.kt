package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextAlign
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * A settings row: a tinted glyph tile, a title with an optional supporting line, and a trailing
 * control.
 *
 * The three variants are the trailing control — a switch, a chevron, or nothing for the destructive
 * row. The text column takes the remaining width so it wraps at 2x instead of pushing the control
 * off the row.
 */
@Composable
fun UseSmileIDSampleSettingRow(
    title: String,
    modifier: Modifier = Modifier,
    supportingText: String? = null,
    testId: String? = null,
    onClick: (() -> Unit)? = null,
    leading: @Composable ((Color) -> Unit)? = null,
    trailing: @Composable (() -> Unit)? = null,
) {
    val colors = UseSmileIDSampleTheme.colors
    Row(
        modifier = modifier
            .fillMaxWidth()
            .then(if (onClick != null) Modifier.clickable(role = Role.Button, onClick = onClick) else Modifier)
            .defaultMinSize(minHeight = SmileDimens.space64)
            .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingSm)
            .tagged(testId),
        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (leading != null) {
            Surface(
                modifier = Modifier.size(SmileDimens.space40),
                shape = RoundedCornerShape(SmileDimens.radiusSm),
                color = colors.surfaceAlt,
            ) {
                Box(contentAlignment = Alignment.Center) { leading(colors.textTitle) }
            }
        }
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
        ) {
            Text(
                text = title,
                style = UseSmileIDSampleTheme.type.textStyleBodyStrong,
                color = colors.textTitle,
            )
            if (supportingText != null) {
                Text(
                    text = supportingText,
                    style = UseSmileIDSampleTheme.type.textStyleBodySm,
                    color = colors.textMuted,
                )
            }
        }
        trailing?.invoke()
    }
}

/** The ABOUT and LEGAL rows: the trailing chevron that says the row pushes a screen. */
@Composable
fun UseSmileIDSampleSettingRowChevron() =
    ChevronRightGlyph(tint = UseSmileIDSampleTheme.colors.textMuted)

/** Sign out — full width, centred, error-coloured, and with no leading tile. */
@Composable
fun UseSmileIDSampleDestructiveRow(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    testId: String? = null,
) {
    Surface(
        onClick = onClick,
        modifier = modifier
            .fillMaxWidth()
            .minimumInteractiveComponentSize()
            .tagged(testId),
        shape = RoundedCornerShape(SmileDimens.radiusField),
        color = UseSmileIDSampleTheme.colors.surface,
    ) {
        Box(
            modifier = Modifier.padding(SmileDimens.spacingSm),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = text,
                style = UseSmileIDSampleTheme.type.textStyleBodyStrong,
                color = UseSmileIDSampleTheme.colors.errorFill,
                textAlign = TextAlign.Center,
            )
        }
    }
}
