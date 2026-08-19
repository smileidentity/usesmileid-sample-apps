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
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
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
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleScanStatus
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBar
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBarButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBarEmphasis
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScanState
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleSimulatedBindings
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleSimulatedSpan
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenDecode
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenDecoder
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import com.usesmileid.sampleapps.ui.state.toCountdown
import kotlinx.coroutines.delay
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
    viewfinder: (@Composable (Modifier, enabled: Boolean, onCandidate: (String) -> Unit) -> Unit)? = null,
) {
    // Saveable, because a token the user typed must survive recreation like every other typed value (R6).
    var token by rememberSaveable { mutableStateOf("") }
    var rejection by rememberSaveable { mutableStateOf<String?>(null) }
    var span by rememberSaveable { mutableStateOf(UseSmileIDSampleSimulatedSpan.FifteenMinutes) }
    var bindsConsent by rememberSaveable { mutableStateOf(false) }
    var bindsDetails by rememberSaveable { mutableStateOf(false) }
    var mintExpanded by rememberSaveable { mutableStateOf(false) }

    var scan by remember { mutableStateOf<UseSmileIDSampleScanState>(UseSmileIDSampleScanState.Searching) }
    // Held apart from the display state: the credential has no business in something a pill renders.
    var linked by remember { mutableStateOf<UseSmileIDSampleTokenSession?>(null) }
    val haptics = LocalHapticFeedback.current

    // Scanned, pasted or typed, a candidate is judged here and nowhere else. Decoding is not
    // verification, so this proves the token parses — never that it is valid.
    val judge: (String, Boolean) -> Unit = { candidate, fromField ->
        if (!fromField) scan = UseSmileIDSampleScanState.Found
        when (val decoded = UseSmileIDSampleTokenDecoder.decode(candidate)) {
            is UseSmileIDSampleTokenDecode.Decoded -> {
                rejection = null
                linked = decoded.session
                scan = UseSmileIDSampleScanState.Linked(
                    handle = decoded.session.id,
                    remaining = decoded.session.remaining(System.currentTimeMillis()).toCountdown(),
                )
            }
            // The field's own error sits under the field, where the person is looking; a scanned code
            // has no field to annotate, so it answers in the status pill instead. Never both.
            is UseSmileIDSampleTokenDecode.Rejected -> if (fromField) {
                rejection = decoded.reason
            } else {
                scan = UseSmileIDSampleScanState.Rejected(decoded.reason)
            }
        }
    }

    // Acknowledge in the hand as well as on screen: a scanner people hold up to a code is exactly
    // where a silent success feels like a freeze.
    LaunchedEffect(scan) {
        when (scan) {
            UseSmileIDSampleScanState.Found -> haptics.performHapticFeedback(HapticFeedbackType.SegmentTick)
            is UseSmileIDSampleScanState.Rejected -> haptics.performHapticFeedback(HapticFeedbackType.Reject)
            is UseSmileIDSampleScanState.Linked -> {
                haptics.performHapticFeedback(HapticFeedbackType.Confirm)
                // Held long enough to be read, then the screen leaves. Navigating on the same frame as
                // the decode is what made a successful scan look like nothing happening at all.
                delay(LINKED_DWELL_MILLIS)
                linked?.let(onLink)
            }
            UseSmileIDSampleScanState.Searching -> Unit
        }
    }

    val titleStyle = UseSmileIDSampleTheme.type.textStyleTitle
    val titleColor = UseSmileIDSampleTheme.colors.textTitle
    val captionStyle = UseSmileIDSampleTheme.type.textStyleCaption.copy(fontSize = SCAN_BODY_SIZE)
    val captionColor = UseSmileIDSampleTheme.colors.textMuted

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
            if (viewfinder == null) {
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
                    ScanCopy(text = SCAN_TITLE, style = titleStyle, color = titleColor, scrimmed = false)
                    ScanCopy(text = SCAN_CAPTION, style = captionStyle, color = captionColor, scrimmed = false)
                }
            } else {
                // Over a live camera the glyph is the framing reticle, so it stays centred and the
                // status moves to the bottom edge — where a sheet this tall would otherwise push it off
                // screen entirely.
                viewfinder(Modifier.matchParentSize(), scan is UseSmileIDSampleScanState.Searching) {
                    judge(it, false)
                }
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    UseSmileIDSampleScanGlyph(tint = scan.reticleTint())
                }
                UseSmileIDSampleScanStatus(
                    state = scan,
                    onRetry = {
                        // Back to searching re-enables the scanner, which clears its last-seen code so
                        // the very same QR can be read again — a retry that cannot read the code it just
                        // refused would be a button that does nothing.
                        rejection = null
                        scan = UseSmileIDSampleScanState.Searching
                    },
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(SmileDimens.spacingMd),
                )
            }
        }
        UseSmileIDSampleScanSheet(
            state = UseSmileIDSampleScanSheetState(
                token = token,
                rejection = rejection,
                span = span,
                bindings = UseSmileIDSampleSimulatedBindings(consent = bindsConsent, userDetails = bindsDetails),
                expanded = mintExpanded,
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
            onLink = { judge(token, true) },
            onExpandToggle = { mintExpanded = !mintExpanded },
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

/** The reticle answers with colour before anyone reads the words. */
@Composable
private fun UseSmileIDSampleScanState.reticleTint(): Color = when (this) {
    UseSmileIDSampleScanState.Searching -> UseSmileIDSampleTheme.colors.textInverse
    UseSmileIDSampleScanState.Found -> UseSmileIDSampleTheme.colors.infoFill
    is UseSmileIDSampleScanState.Linked -> UseSmileIDSampleTheme.colors.successFill
    is UseSmileIDSampleScanState.Rejected -> UseSmileIDSampleTheme.colors.errorFill
}

private const val SCAN_TITLE = "Point at a Smile token QR"
private const val SCAN_CAPTION =
    "Line up the code inside the frame to link this device to a verification session."
private val SCAN_BODY_SIZE = 12.5.sp

/** Long enough to read "Session linked" and its handle, short enough not to feel like a wait. */
private const val LINKED_DWELL_MILLIS = 900L
private const val SCRIM_ALPHA = 0.85f
