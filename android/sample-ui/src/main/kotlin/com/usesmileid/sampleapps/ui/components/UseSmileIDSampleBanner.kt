package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import com.smileid.designsystem.SmileDimens
import com.smileid.designsystem.smileCardStrokeWidth
import com.usesmileid.sampleapps.ui.R
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** Which accent a banner carries: warning for a failure the user can act on, error for one that is final. */
enum class UseSmileIDSampleBannerTone { Warning, Error }

/** The design system's banner: a neutral surface with the tone's accent edge and glyph, a title over the message, and at most one action. */
@Composable
fun UseSmileIDSampleBanner(
    title: String,
    message: String,
    tone: UseSmileIDSampleBannerTone,
    modifier: Modifier = Modifier,
    actionLabel: String? = null,
    onAction: () -> Unit = {},
    actionProminent: Boolean = true,
    testId: String? = null,
    actionTestId: String? = null,
) {
    val colors = UseSmileIDSampleTheme.colors
    val accent = tone.accent()
    Surface(
        modifier = modifier.fillMaxWidth().tagged(testId),
        shape = RoundedCornerShape(SmileDimens.radiusField),
        color = colors.banner.background,
        // The card stroke, as the session-ended banner takes: banner.border carries one light value in both schemes.
        border = BorderStroke(smileCardStrokeWidth, colors.cardStroke),
    ) {
        // Intrinsic height so the edge spans the text and the action, whichever wraps.
        Row(modifier = Modifier.height(IntrinsicSize.Min)) {
            Box(
                modifier = Modifier
                    .width(ACCENT_WIDTH)
                    .fillMaxHeight()
                    .background(accent),
            )
            Row(
                modifier = Modifier.padding(SmileDimens.spacingMd),
                horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
                verticalAlignment = Alignment.Top,
            ) {
                UseSmileIDSampleIcon(id = tone.glyph(), tint = accent)
                Column(modifier = Modifier.weight(1f)) {
                    Text(text = title, style = UseSmileIDSampleTheme.type.textStyleBodyStrong, color = colors.banner.title)
                    Spacer(Modifier.height(SmileDimens.spacingXxs))
                    Text(text = message, style = UseSmileIDSampleTheme.type.textStyleBodySm, color = colors.banner.text)
                    if (actionLabel != null && actionProminent) {
                        Spacer(Modifier.height(SmileDimens.spacingMd))
                        UseSmileIDSampleButton(text = actionLabel, onClick = onAction, testId = actionTestId)
                    } else if (actionLabel != null) {
                        Text(
                            text = actionLabel,
                            style = UseSmileIDSampleTheme.type.linkFont,
                            color = colors.primary,
                            modifier = Modifier
                                .align(Alignment.End)
                                // Clickable before the sizing modifiers, so the tap target is the padded box.
                                .clickable(role = Role.Button, onClick = onAction)
                                .minimumInteractiveComponentSize()
                                .padding(horizontal = SmileDimens.spacingXs)
                                .tagged(actionTestId),
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun UseSmileIDSampleBannerTone.accent(): Color = when (this) {
    UseSmileIDSampleBannerTone.Warning -> UseSmileIDSampleTheme.colors.banner.warningAccent
    UseSmileIDSampleBannerTone.Error -> UseSmileIDSampleTheme.colors.banner.errorAccent
}

private fun UseSmileIDSampleBannerTone.glyph(): Int = when (this) {
    UseSmileIDSampleBannerTone.Warning -> R.drawable.sample_ic_warning
    UseSmileIDSampleBannerTone.Error -> R.drawable.sample_ic_cancel
}

/** The banner contract's leading edge. */
private val ACCENT_WIDTH = 3.dp
