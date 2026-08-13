package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * The sheet under the scanner: a manual-entry row with Paste, above a primary simulate button.
 *
 * Simulate is a product feature, not debug scaffolding — it is what makes every token-session flow
 * testable with no QR code to point a camera at, which is the whole reason automation can reach the
 * session states at all.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun UseSmileIDSampleScanSheet(
    onPaste: () -> Unit,
    onSimulate: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = UseSmileIDSampleTheme.colors
    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(topStart = SmileDimens.radiusSheet, topEnd = SmileDimens.radiusSheet),
        color = colors.surface,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .windowInsetsPadding(WindowInsets.navigationBars)
                .padding(SmileDimens.spacingMd),
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
        ) {
            Surface(
                modifier = Modifier.fillMaxWidth().testTag(UseSmileIDSampleTestIds.TOKEN_MANUAL_ENTRY),
                shape = RoundedCornerShape(SmileDimens.radiusField),
                color = colors.surfaceAlt,
                border = BorderStroke(SmileDimens.borderWidthHairline, colors.border),
            ) {
                FlowRow(
                    modifier = Modifier
                        .defaultMinSize(minHeight = SmileDimens.sizeControlMd)
                        .padding(horizontal = SmileDimens.spacingSm, vertical = SmileDimens.spacingXs),
                    horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                    verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                    itemVerticalAlignment = Alignment.CenterVertically,
                ) {
                    Box(modifier = Modifier.size(SmileDimens.sizeIconMd), contentAlignment = Alignment.Center) {
                        ScanMarkGlyph(tint = colors.textMuted)
                    }
                    Text(
                        text = "Or enter token manually",
                        style = UseSmileIDSampleTheme.type.textStyleBody,
                        color = colors.textTitle,
                        modifier = Modifier.weight(1f),
                    )
                    Text(
                        text = "Paste",
                        style = UseSmileIDSampleTheme.type.linkFont,
                        color = colors.primary,
                        softWrap = false,
                        modifier = Modifier
                            .testTag(UseSmileIDSampleTestIds.TOKEN_PASTE)
                            .semantics { role = Role.Button }
                            .minimumInteractiveComponentSize()
                            .padding(horizontal = SmileDimens.spacingXs),
                    )
                }
            }
            UseSmileIDSampleButton(
                text = "Simulate a successful scan",
                onClick = onSimulate,
                testId = UseSmileIDSampleTestIds.TOKEN_SIMULATE,
            )
        }
    }
}
