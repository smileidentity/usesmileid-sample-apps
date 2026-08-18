package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.sp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.TorchGlyph
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleScanGlyph
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleScanSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBar
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBarButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBarEmphasis
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** Scan token. No camera by design; simulate is what makes the session states reachable without a QR code. */
@Composable
fun ScanTokenScreen(
    onBack: () -> Unit,
    onSimulate: () -> Unit,
    onPaste: () -> Unit,
    modifier: Modifier = Modifier,
    torchOn: Boolean = false,
    onTorchToggle: () -> Unit = {},
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .testTag(UseSmileIDSampleTestIds.SCAN_TOKEN_SCREEN),
    ) {
        UseSmileIDSampleTopAppBar(title = "Scan token", onBack = onBack) {
            UseSmileIDSampleTopAppBarButton(
                contentDescription = if (torchOn) "Turn torch off" else "Turn torch on",
                onClick = onTorchToggle,
                emphasis = UseSmileIDSampleTopAppBarEmphasis.Filled,
            ) { tint -> TorchGlyph(tint = tint) }
        }
        Column(
            // Scrolls because the glyph is fixed: at 2x its copy no longer fits above the sheet.
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(SmileDimens.spacingMd),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm, Alignment.CenterVertically),
        ) {
            Box(contentAlignment = Alignment.Center) { UseSmileIDSampleScanGlyph() }
            Text(
                text = "Point at a Smile token QR",
                style = UseSmileIDSampleTheme.type.textStyleTitle,
                color = UseSmileIDSampleTheme.colors.textTitle,
                textAlign = TextAlign.Center,
            )
            Text(
                text = "Line up the code inside the frame to link this device to a verification session.",
                    style = UseSmileIDSampleTheme.type.textStyleCaption.copy(fontSize = SCAN_BODY_SIZE),
                color = UseSmileIDSampleTheme.colors.textMuted,
                textAlign = TextAlign.Center,
            )
        }
        UseSmileIDSampleScanSheet(onPaste = onPaste, onSimulate = onSimulate)
    }
}

private val SCAN_BODY_SIZE = 12.5.sp
