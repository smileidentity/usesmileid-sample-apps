package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.sp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.TorchGlyph
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleScanGlyph
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleScanSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleScanSheetState
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBar
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBarButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBarEmphasis
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleSimulatedBindings
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleSimulatedSpan
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenDecode
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenDecoder
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * Scan token. A token arrives from the host's camera, by hand, or from a simulated scan, and every
 * route links a session only after the token decodes.
 *
 * @param onPaste the host's clipboard, because reading it is platform-owned; null when it holds no text.
 * @param viewfinder the host's camera preview, given the same candidate handler the sheet uses so a
 *   scanned code, a pasted one and a typed one are all judged by one decode. Absent — in a golden, or
 *   in an SDK repo's development sample that does not carry a camera — the screen keeps the glyph.
 */
@Composable
fun ScanTokenScreen(
    onBack: () -> Unit,
    onLink: (UseSmileIDSampleTokenSession) -> Unit,
    onSimulate: (UseSmileIDSampleSimulatedSpan, UseSmileIDSampleSimulatedBindings) -> Unit,
    onPaste: () -> String?,
    modifier: Modifier = Modifier,
    torchOn: Boolean = false,
    onTorchToggle: () -> Unit = {},
    viewfinder: (@Composable (Modifier, onCandidate: (String) -> Unit) -> Unit)? = null,
) {
    // Saveable, because a token the user typed must survive recreation like every other typed value (R6).
    var token by rememberSaveable { mutableStateOf("") }
    var rejection by rememberSaveable { mutableStateOf<String?>(null) }
    var span by rememberSaveable { mutableStateOf(UseSmileIDSampleSimulatedSpan.FifteenMinutes) }
    var bindsConsent by rememberSaveable { mutableStateOf(false) }
    var bindsDetails by rememberSaveable { mutableStateOf(false) }

    // Scanned, pasted or typed, a candidate is judged here and nowhere else. Decoding is not
    // verification, so this proves the token parses — never that it is valid.
    val judge: (String) -> Unit = { candidate ->
        when (val decoded = UseSmileIDSampleTokenDecoder.decode(candidate)) {
            is UseSmileIDSampleTokenDecode.Decoded -> onLink(decoded.session)
            is UseSmileIDSampleTokenDecode.Rejected -> rejection = decoded.reason
        }
    }

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
        Box(modifier = Modifier.weight(1f).fillMaxWidth()) {
            // Behind the glyph, which becomes the framing guide the design already draws.
            viewfinder?.invoke(Modifier.matchParentSize(), judge)
            Column(
                // Scrolls because the glyph is fixed: at 2x its copy no longer fits above the sheet.
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(SmileDimens.spacingMd),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm, Alignment.CenterVertically),
            ) {
                Box(contentAlignment = Alignment.Center) { UseSmileIDSampleScanGlyph() }
                ScanCopy(
                    text = "Point at a Smile token QR",
                    style = UseSmileIDSampleTheme.type.textStyleTitle,
                    color = UseSmileIDSampleTheme.colors.textTitle,
                    scrimmed = viewfinder != null,
                )
                ScanCopy(
                    text = "Line up the code inside the frame to link this device to a verification session.",
                    style = UseSmileIDSampleTheme.type.textStyleCaption.copy(fontSize = SCAN_BODY_SIZE),
                    color = UseSmileIDSampleTheme.colors.textMuted,
                    scrimmed = viewfinder != null,
                )
            }
        }
        UseSmileIDSampleScanSheet(
            state = UseSmileIDSampleScanSheetState(
                token = token,
                rejection = rejection,
                span = span,
                bindings = UseSmileIDSampleSimulatedBindings(consent = bindsConsent, userDetails = bindsDetails),
            ),
            onTokenChange = {
                token = it
                rejection = null
            },
            onPaste = {
                val pasted = onPaste()
                if (pasted.isNullOrBlank()) {
                    rejection = "The clipboard holds no text to paste."
                } else {
                    token = pasted
                    rejection = null
                }
            },
            onLink = { judge(token) },
            onSpanSelect = { span = it },
            onBindingsChange = {
                bindsConsent = it.consent
                bindsDetails = it.userDetails
            },
            onSimulate = {
                onSimulate(span, UseSmileIDSampleSimulatedBindings(consent = bindsConsent, userDetails = bindsDetails))
            },
        )
    }
}

/** Over a live camera the design's copy needs a ground of its own to stay legible. */
@Composable
private fun ScanCopy(text: String, style: TextStyle, color: Color, scrimmed: Boolean) {
    Text(
        text = text,
        style = style,
        color = color,
        textAlign = TextAlign.Center,
        modifier = if (!scrimmed) {
            Modifier
        } else {
            Modifier
                .background(
                    color = UseSmileIDSampleTheme.colors.surface.copy(alpha = SCRIM_ALPHA),
                    shape = RoundedCornerShape(SmileDimens.radiusField),
                )
                .padding(horizontal = SmileDimens.spacingSm, vertical = SmileDimens.spacingXxs)
        },
    )
}

private val SCAN_BODY_SIZE = 12.5.sp
private const val SCRIM_ALPHA = 0.85f
