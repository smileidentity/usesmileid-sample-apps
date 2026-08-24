package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleSimulatedBindings
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleSimulatedSpan
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** What the sheet renders, so the screen owns the entry state and the sheet stays stateless. */
@Immutable
data class UseSmileIDSampleScanSheetState(
    val token: String = "",
    /** Why the entered token is not a session — shown under the field, never the token itself. */
    val rejection: String? = null,
    val span: UseSmileIDSampleSimulatedSpan = UseSmileIDSampleSimulatedSpan.FifteenMinutes,
    /** Which host the minted token's `api_url` names, which is the whole of how a run picks its environment. */
    val environment: UseSmileIDSampleEnvironment = UseSmileIDSampleEnvironment.Sandbox,
    val bindings: UseSmileIDSampleSimulatedBindings = UseSmileIDSampleSimulatedBindings(),
    /** The mint controls start closed so the viewfinder keeps its height. */
    val expanded: Boolean = false,
)

/**
 * The sheet under the scanner: manual entry, and a simulated scan that mints its own fixture token.
 * Simulate is a product feature, not scaffolding — it is how a flow reaches the session states with
 * no QR source, and what it mints is chosen here rather than hard-coded.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun UseSmileIDSampleScanSheet(
    state: UseSmileIDSampleScanSheetState,
    onTokenChange: (String) -> Unit,
    onPaste: () -> Unit,
    onLink: () -> Unit,
    onExpandToggle: () -> Unit,
    onSpanSelect: (UseSmileIDSampleSimulatedSpan) -> Unit,
    onEnvironmentSelect: (UseSmileIDSampleEnvironment) -> Unit,
    onBindingsChange: (UseSmileIDSampleSimulatedBindings) -> Unit,
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
            UseSmileIDSampleTextInput(
                value = state.token,
                onValueChange = onTokenChange,
                placeholder = "Or enter token manually",
                isError = state.rejection != null,
                errorMessage = state.rejection,
                // The token is a bearer credential and 900 characters long: nobody proofreads it, and
                // masked it stays out of screenshots and out of a failed run's hierarchy dump.
                masked = true,
                testId = UseSmileIDSampleTestIds.TOKEN_MANUAL_ENTRY,
                leading = { tint ->
                    Box(modifier = Modifier.size(SmileDimens.sizeIconMd), contentAlignment = Alignment.Center) {
                        ScanMarkGlyph(tint = tint)
                    }
                },
                trailing = {
                    Text(
                        text = "Paste",
                        style = UseSmileIDSampleTheme.type.linkFont.copy(
                            fontSize = SHEET_ACTION_SIZE,
                            fontWeight = FontWeight.Bold,
                        ),
                        color = colors.primary,
                        softWrap = false,
                        modifier = Modifier
                            .testTag(UseSmileIDSampleTestIds.TOKEN_PASTE)
                            .clickable(role = Role.Button, onClick = onPaste)
                            .minimumInteractiveComponentSize()
                            .padding(horizontal = SmileDimens.spacingXs),
                    )
                },
            )
            // Only once there is something to link, so the default sheet keeps the design's two rows.
            if (state.token.isNotBlank()) {
                UseSmileIDSampleButton(text = "Link token", onClick = onLink)
            }
            // Collapsed by default, and that is the point: this is a scanner, and the mint controls are a
            // probe affordance. Expanded they took enough height to leave the viewfinder a letterbox.
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(role = Role.Button) { onExpandToggle() }
                    .padding(vertical = SmileDimens.spacingXxs),
                horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                UseSmileIDSampleSectionLabel(text = "SIMULATED SCAN", modifier = Modifier.weight(1f))
                Box(modifier = Modifier.size(SmileDimens.sizeIconMd), contentAlignment = Alignment.Center) {
                    if (state.expanded) {
                        ChevronDownGlyph(tint = colors.textMuted)
                    } else {
                        ChevronRightGlyph(tint = colors.textMuted)
                    }
                }
            }
            if (state.expanded) {
            FlowRow(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
            ) {
                UseSmileIDSampleSimulatedSpan.entries.forEach { span ->
                    ScanSheetChip(
                        label = span.label,
                        selected = state.span == span,
                        role = Role.RadioButton,
                        onClick = { onSpanSelect(span) },
                    )
                }
            }
            // Minting is where a run picks an environment, because there is no app-side control left.
            FlowRow(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
            ) {
                UseSmileIDSampleEnvironment.entries.forEach { environment ->
                    ScanSheetChip(
                        label = environment.label,
                        selected = state.environment == environment,
                        role = Role.RadioButton,
                        onClick = { onEnvironmentSelect(environment) },
                    )
                }
            }
            FlowRow(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
            ) {
                ScanSheetChip(
                    label = "Binds consent",
                    selected = state.bindings.consent,
                    role = Role.Checkbox,
                    onClick = { onBindingsChange(state.bindings.copy(consent = !state.bindings.consent)) },
                )
                ScanSheetChip(
                    label = "Binds details",
                    selected = state.bindings.userDetails,
                    role = Role.Checkbox,
                    onClick = { onBindingsChange(state.bindings.copy(userDetails = !state.bindings.userDetails)) },
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

/** The filter chip's shape without its count, because what a simulated scan mints has no count. */
@Composable
private fun ScanSheetChip(label: String, selected: Boolean, role: Role, onClick: () -> Unit) {
    val colors = UseSmileIDSampleTheme.colors
    Surface(
        modifier = Modifier
            .minimumInteractiveComponentSize()
            .selectable(selected = selected, role = role, onClick = onClick),
        shape = RoundedCornerShape(SmileDimens.radiusChip),
        color = if (selected) colors.primary else colors.filterChip.background,
        border = if (selected) null else BorderStroke(SmileDimens.borderWidthHairline, colors.filterChip.border),
    ) {
        Text(
            text = label,
            style = UseSmileIDSampleTheme.type.filterChipFont.copy(
                fontSize = SHEET_ACTION_SIZE,
                fontWeight = FontWeight.Bold,
            ),
            color = if (selected) colors.onPrimary else colors.filterChip.label,
            modifier = Modifier
                .defaultMinSize(minHeight = SmileDimens.space32)
                .padding(horizontal = SmileDimens.spacingSm, vertical = SmileDimens.spacingXs),
        )
    }
}

private val SHEET_ACTION_SIZE = 13.sp
