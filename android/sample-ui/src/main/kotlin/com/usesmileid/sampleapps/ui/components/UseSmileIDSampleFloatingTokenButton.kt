package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** Reaches the token session from inside a form, where the nav bar's token affordance is covered. */
@Composable
fun UseSmileIDSampleFloatingTokenButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Surface(
        onClick = onClick,
        modifier = modifier
            .size(SmileDimens.space48)
            .semantics { contentDescription = "Token session" }
            .testTag(UseSmileIDSampleTestIds.TOKEN_FLOAT),
        shape = CircleShape,
        color = UseSmileIDSampleTheme.colors.primary,
        shadowElevation = SmileDimens.space4,
    ) {
        Box(contentAlignment = Alignment.Center) {
            ScanMarkGlyph(tint = UseSmileIDSampleTheme.colors.onPrimary)
        }
    }
}
