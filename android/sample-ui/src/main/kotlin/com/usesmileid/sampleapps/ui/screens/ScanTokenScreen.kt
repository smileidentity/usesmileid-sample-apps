package com.usesmileid.sampleapps.ui.screens

import com.usesmileid.sampleapps.ui.UseSmileIDSampleStrings
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.LocalResources
import androidx.compose.ui.res.stringResource
import androidx.annotation.StringRes
import com.usesmileid.sampleapps.ui.R
import com.usesmileid.sampleapps.ui.message
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLinkStyles
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.withLink
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.min
import androidx.compose.ui.unit.sp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.FlashGlyph
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleScanGlyph
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleScanSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleScanSheetState
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleScanStatus
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBar
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBarButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBarEmphasis
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
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
 * @param reason why the screen opened when something sent the user here, in place of the generic
 *   caption; null when it was opened deliberately. Typed so the eight hosts cannot word it differently.
 * @param onPaste the host's clipboard, because reading it is platform-owned; null when it holds no text.
 * @param viewfinder the host's camera preview, given the same candidate handler the sheet uses so a
 *   scanned code, a pasted one and a typed one are all judged by one decode. Absent — in a golden, or
 *   in an SDK repo's development sample that does not carry a camera — the screen keeps the glyph.
 * @param acceptsTaps false while the screen is still arriving, so a second tap on whatever opened it cannot land on the sheet.
 */
@Composable
fun ScanTokenScreen(
    onBack: () -> Unit,
    onLink: (UseSmileIDSampleTokenSession) -> Unit,
    onSimulate: (UseSmileIDSampleSimulatedSpan, UseSmileIDSampleSimulatedBindings, UseSmileIDSampleEnvironment) -> Unit,
    onPaste: () -> String?,
    modifier: Modifier = Modifier,
    reason: UseSmileIDSampleScanReason? = null,
    torchOn: Boolean = false,
    onTorchToggle: () -> Unit = {},
    viewfinder: (@Composable (Modifier, enabled: Boolean, onCandidate: (String) -> Unit) -> Unit)? = null,
    acceptsTaps: Boolean = true,
) {
    // Saveable, because a token the user typed must survive recreation like every other typed value (R6).
    var token by rememberSaveable { mutableStateOf("") }
    var rejection by rememberSaveable { mutableStateOf<String?>(null) }
    var span by rememberSaveable { mutableStateOf(UseSmileIDSampleSimulatedSpan.FifteenMinutes) }
    var environment by rememberSaveable { mutableStateOf(UseSmileIDSampleEnvironment.Sandbox) }
    var bindsConsent by rememberSaveable { mutableStateOf(false) }
    var bindsDetails by rememberSaveable { mutableStateOf(false) }
    var mintExpanded by rememberSaveable { mutableStateOf(false) }

    var scan by remember { mutableStateOf<UseSmileIDSampleScanState>(UseSmileIDSampleScanState.Searching) }
    // Held apart from the display state: the credential has no business in something a pill renders.
    var linked by remember { mutableStateOf<UseSmileIDSampleTokenSession?>(null) }
    val haptics = LocalHapticFeedback.current
    // Read here: a token is judged in a callback, outside composition.
    val resources = LocalResources.current

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
                rejection = decoded.reason.message(resources)
            } else {
                scan = UseSmileIDSampleScanState.Rejected(decoded.reason.message(resources))
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

    val caption = reason?.let { stringResource(it.caption) } ?: UseSmileIDSampleStrings.scanLineUp
    val title = UseSmileIDSampleStrings.scanPoint
    val titleStyle = UseSmileIDSampleTheme.type.textStyleTitle
    val titleColor = UseSmileIDSampleTheme.colors.textTitle
    val captionStyle = UseSmileIDSampleTheme.type.textStyleCaption.copy(fontSize = SCAN_BODY_SIZE)
    val captionColor = UseSmileIDSampleTheme.colors.textMuted

    Column(
        modifier = modifier
            .fillMaxSize()
            .testTag(UseSmileIDSampleTestIds.SCAN_TOKEN_SCREEN),
    ) {
        UseSmileIDSampleTopAppBar(title = UseSmileIDSampleStrings.scanTitle, onBack = onBack) {
            UseSmileIDSampleTopAppBarButton(
                contentDescription = if (torchOn) UseSmileIDSampleStrings.scanFlashOff else UseSmileIDSampleStrings.scanFlashOn,
                onClick = onTorchToggle,
                emphasis = UseSmileIDSampleTopAppBarEmphasis.Filled,
            ) { tint -> FlashGlyph(tint = tint) }
        }
        BoxWithConstraints(modifier = Modifier.weight(1f).fillMaxWidth()) {
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
                    ScanCopy(text = title, style = titleStyle, color = titleColor)
                    ScanCopy(text = caption, style = captionStyle, color = captionColor)
                    PortalLine(style = captionStyle, color = captionColor)
                }
            } else {
                viewfinder(Modifier.matchParentSize(), scan is UseSmileIDSampleScanState.Searching) {
                    judge(it, false)
                }
                val searching = scan is UseSmileIDSampleScanState.Searching
                // Sized to the space, not the design's fixed 279dp: the sheet takes the lower half here.
                val reticleSize = min(maxWidth * RETICLE_WIDTH_FRACTION, maxHeight * RETICLE_HEIGHT_FRACTION)
                // 45% at rest, firming to full strength the moment the scanner has something.
                val reticleAlpha by animateFloatAsState(if (searching) RETICLE_IDLE_ALPHA else 1f)
                Column(
                    modifier = Modifier.fillMaxSize().padding(SmileDimens.spacingMd),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingMd, Alignment.CenterVertically),
                ) {
                    UseSmileIDSampleScanGlyph(
                        tint = scan.reticleTint(),
                        modifier = Modifier.alpha(reticleAlpha),
                        size = reticleSize,
                    )
                    // Straight on the camera: a container here was a white slab over the preview.
                    if (searching) {
                        ScanCopy(text = title, style = titleStyle.overCamera(), color = UseSmileIDSampleTheme.colors.textInverse)
                        ScanCopy(text = caption, style = captionStyle.overCamera(), color = UseSmileIDSampleTheme.colors.textInverse)
                        PortalLine(style = captionStyle.overCamera(), color = UseSmileIDSampleTheme.colors.textInverse)
                    } else {
                        UseSmileIDSampleScanStatus(
                            state = scan,
                            onRetry = {
                                // Re-enables the scanner, clearing its last-seen code so the same QR reads.
                                rejection = null
                                scan = UseSmileIDSampleScanState.Searching
                            },
                        )
                    }
                }
            }
        }
        UseSmileIDSampleScanSheet(
            state = UseSmileIDSampleScanSheetState(
                token = token,
                rejection = rejection,
                span = span,
                environment = environment,
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
                    rejection = resources.getString(R.string.sample_scan_clipboard_empty)
                } else {
                    token = pasted
                    rejection = null
                }
            },
            onLink = { if (acceptsTaps) judge(token, true) },
            onExpandToggle = { mintExpanded = !mintExpanded },
            onSpanSelect = { span = it },
            onEnvironmentSelect = { environment = it },
            onBindingsChange = {
                bindsConsent = it.consent
                bindsDetails = it.userDetails
            },
            onSimulate = {
                if (acceptsTaps) onSimulate(
                    span,
                    UseSmileIDSampleSimulatedBindings(consent = bindsConsent, userDetails = bindsDetails),
                    environment,
                )
            },
        )
    }
}

/** Where a real token comes from, as a phrase: a raw URL breaks mid-word on the narrowest phone at the largest type. */
@Composable
private fun PortalLine(style: TextStyle, color: Color) {
    val linkStyle = TextLinkStyles(
        SpanStyle(color = UseSmileIDSampleTheme.colors.textLink, textDecoration = TextDecoration.Underline),
    )
    val prefix = UseSmileIDSampleStrings.scanPortalPrefix
    val link = UseSmileIDSampleStrings.scanPortalLink
    val suffix = UseSmileIDSampleStrings.scanPortalSuffix
    val text = buildAnnotatedString {
        append(prefix)
        withLink(LinkAnnotation.Url(PORTAL_URL, linkStyle)) { append(link) }
        append(suffix)
    }
    Text(
        text = text,
        style = style,
        color = color,
        textAlign = TextAlign.Center,
        modifier = Modifier.fillMaxWidth().testTag(UseSmileIDSampleTestIds.TOKEN_PORTAL_LINK),
    )
}

@Composable
private fun ScanCopy(text: String, style: TextStyle, color: Color) {
    Text(
        text = text,
        style = style,
        color = color,
        textAlign = TextAlign.Center,
        // Explicit, because centred copy that is not width-bound clips at both edges instead of wrapping.
        modifier = Modifier.fillMaxWidth(),
    )
}

/** Legible on whatever the camera is pointed at, without putting a slab between the two. */
@Composable
private fun TextStyle.overCamera(): TextStyle = copy(
    shadow = Shadow(
        color = UseSmileIDSampleTheme.colors.textTitle,
        blurRadius = COPY_SHADOW_BLUR,
    ),
)

/** The reticle answers with colour before anyone reads the words. */
@Composable
private fun UseSmileIDSampleScanState.reticleTint(): Color = when (this) {
    UseSmileIDSampleScanState.Searching -> UseSmileIDSampleTheme.colors.textInverse
    UseSmileIDSampleScanState.Found -> UseSmileIDSampleTheme.colors.infoFill
    is UseSmileIDSampleScanState.Linked -> UseSmileIDSampleTheme.colors.successFill
    is UseSmileIDSampleScanState.Rejected -> UseSmileIDSampleTheme.colors.errorFill
}

/** Why the scanner opened. The copy lives here so the golden pins the sentence the app ships. */
enum class UseSmileIDSampleScanReason(@StringRes val caption: Int) {
    SessionEnded(R.string.sample_scan_reason_session_ended),
    SessionNeeded(R.string.sample_scan_reason_needed),
}
private const val PORTAL_URL = "https://portal.usesmileid.com/security-settings"
private val SCAN_BODY_SIZE = 12.5.sp

/** Long enough to read "Session linked" and its handle, short enough not to feel like a wait. */
private const val LINKED_DWELL_MILLIS = 900L
/** The design's own reticle opacity, which is what keeps it from competing with the preview. */
private const val RETICLE_IDLE_ALPHA = 0.45f
private const val RETICLE_WIDTH_FRACTION = 0.72f
private const val RETICLE_HEIGHT_FRACTION = 0.52f
private const val COPY_SHADOW_BLUR = 8f
