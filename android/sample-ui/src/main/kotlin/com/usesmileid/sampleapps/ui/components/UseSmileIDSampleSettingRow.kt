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
import androidx.compose.foundation.BorderStroke
import androidx.compose.material3.HorizontalDivider
import androidx.compose.ui.unit.dp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** A settings row: a glyph tile, a title with an optional supporting line, and a trailing control. */
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
                    modifier = Modifier.size(TILE_SIZE),
                shape = RoundedCornerShape(TILE_RADIUS),
                color = colors.surfaceTile,
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
                    style = UseSmileIDSampleTheme.type.textStyleCaption,
                    color = colors.textMuted,
                )
            }
        }
        trailing?.invoke()
    }
}

/** The trailing chevron that says the row pushes a screen. */
@Composable
fun UseSmileIDSampleSettingRowChevron() =
    ChevronRightGlyph(tint = UseSmileIDSampleTheme.colors.textMuted, size = CHEVRON_SIZE)

/** The rule between rows inside one section card. */
@Composable
fun UseSmileIDSampleSettingRowDivider() = HorizontalDivider(
    thickness = SmileDimens.borderWidthHairline,
    color = UseSmileIDSampleTheme.colors.card.border,
)

/** Sign out: full width, centred, error-coloured. */
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
        shape = RoundedCornerShape(SmileDimens.radiusSurface),
        color = UseSmileIDSampleTheme.colors.surface,
        border = BorderStroke(SmileDimens.borderWidthHairline, UseSmileIDSampleTheme.colors.card.border),
    ) {
        Box(
            modifier = Modifier.padding(SmileDimens.spacingSm),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                // The soft error text, at the button size — errorFill is the saturated pill colour.
                text = text,
                style = UseSmileIDSampleTheme.type.textStyleButton,
                color = UseSmileIDSampleTheme.colors.badge.errorText,
                textAlign = TextAlign.Center,
            )
        }
    }
}

private val TILE_SIZE = 38.dp
private val TILE_RADIUS = 11.dp
private val CHEVRON_SIZE = 14.dp
