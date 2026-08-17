package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * A snackbar: a dark bar with a message and an underlined action, spanning the width it is given.
 *
 * Keeps the `sample_toast*` ids: the design node is named "toast", and renaming would churn four apps.
 */
@Composable
fun UseSmileIDSampleToast(
    message: String,
    modifier: Modifier = Modifier,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null,
) {
    Surface(
        modifier = modifier
            .fillMaxWidth()
            .defaultMinSize(minHeight = SmileDimens.sizeControlMd)
            .testTag(UseSmileIDSampleTestIds.TOAST),
        shape = RoundedCornerShape(SNACKBAR_RADIUS),
        color = UseSmileIDSampleTheme.colors.textTitle,
        shadowElevation = SNACKBAR_ELEVATION,
    ) {
        // FlowRow so a cramped action moves onto its own line whole; a Row breaks "Undo" in half.
        FlowRow(
            modifier = Modifier.padding(
                horizontal = SmileDimens.spacingMd,
                vertical = SmileDimens.spacingSm,
            ),
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
            verticalArrangement = Arrangement.spacedBy(SmileDimens.space4),
            itemVerticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = message,
                style = UseSmileIDSampleTheme.type.bannerTextFont.copy(
                    fontSize = SNACKBAR_TEXT_SIZE,
                    fontWeight = FontWeight.SemiBold,
                ),
                color = UseSmileIDSampleTheme.colors.background,
                modifier = Modifier.weight(1f),
            )
            if (actionLabel != null && onAction != null) {
                Text(
                    text = actionLabel,
                    style = UseSmileIDSampleTheme.type.linkFont.copy(
                        fontSize = SNACKBAR_TEXT_SIZE,
                        fontWeight = FontWeight.Bold,
                        textDecoration = TextDecoration.Underline,
                    ),
                    color = UseSmileIDSampleTheme.colors.background,
                    softWrap = false,
                    textAlign = TextAlign.Center,
                    // Clickable before the sizing modifiers, so the tap target is the padded box.
                    modifier = Modifier
                        .testTag(UseSmileIDSampleTestIds.TOAST_UNDO)
                        .clickable(role = Role.Button, onClick = onAction)
                        .minimumInteractiveComponentSize()
                        .padding(horizontal = SmileDimens.spacingXs),
                )
            }
        }
    }
}

private val SNACKBAR_RADIUS = 14.dp
private val SNACKBAR_TEXT_SIZE = 13.sp
private val SNACKBAR_ELEVATION = 10.dp
