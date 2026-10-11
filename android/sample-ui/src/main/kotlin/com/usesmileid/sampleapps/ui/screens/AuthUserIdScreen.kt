package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import com.smileid.designsystem.SmileDimens
import com.smileid.designsystem.smileCardStrokeWidth
import com.smileid.designsystem.smileLabelSize
import com.smileid.designsystem.smileLabelTracking
import com.usesmileid.sampleapps.ui.UseSmileIDSampleStrings
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.CheckGlyph
import com.usesmileid.sampleapps.ui.components.StatusPill
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleProductTile
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionLabel
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionSurface
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRowChevron
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRowDivider
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTextInput
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBar
import com.usesmileid.sampleapps.ui.components.tagged
import com.usesmileid.sampleapps.ui.localizedTitle
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.timeLabels
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** SmartSelfie Authentication's user ID: typed, or picked from earlier runs that enrolled one. Never made up, because the SDK authenticates only an enrolled user. */
@Composable
fun AuthUserIdScreen(
    userId: String,
    /** The newest run per enrolled user, newest first; each row names the product and time it came from. */
    previousUsers: List<UseSmileIDSampleJob>,
    onUserIdChange: (String) -> Unit,
    onRegister: () -> Unit,
    onBack: () -> Unit,
    onContinue: () -> Unit,
    modifier: Modifier = Modifier,
    contentPadding: PaddingValues = PaddingValues(),
) {
    val chosen = userId.trim()
    // The app's locale: the JVM default does not follow the override.
    val locale = LocalConfiguration.current.locales[0]
    val times = remember(previousUsers, locale) { previousUsers.timeLabels(locale) }
    Column(
        modifier = modifier
            .fillMaxSize()
            .imePadding()
            .testTag(UseSmileIDSampleTestIds.AUTH_USER_ID_SCREEN),
    ) {
        UseSmileIDSampleTopAppBar(title = UseSmileIDSampleProduct.SmartSelfieAuth.localizedTitle(), onBack = onBack)
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = SmileDimens.spacingMd),
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
        ) {
            UseSmileIDSampleSectionLabel(text = UseSmileIDSampleStrings.authUserIdSection)
            UseSmileIDSampleTextInput(
                value = userId,
                onValueChange = onUserIdChange,
                placeholder = UseSmileIDSampleStrings.authUserIdPlaceholder,
                keyboardOptions = KeyboardOptions(
                    capitalization = KeyboardCapitalization.None,
                    autoCorrectEnabled = false,
                    imeAction = ImeAction.Done,
                ),
                testId = UseSmileIDSampleTestIds.AUTH_USER_ID_INPUT,
            )
            Caption(UseSmileIDSampleStrings.authUserIdHint)
            OrDivider()
            if (previousUsers.isEmpty()) {
                UseSmileIDSampleSectionSurface(label = UseSmileIDSampleStrings.authUserIdRun) {
                    EnrollmentRow(onClick = onRegister)
                }
                Caption(UseSmileIDSampleStrings.authUserIdRunBody)
            } else {
                UseSmileIDSampleSectionSurface(label = UseSmileIDSampleStrings.authUserIdPrevious) {
                    previousUsers.forEachIndexed { index, job ->
                        if (index > 0) UseSmileIDSampleSettingRowDivider()
                        PreviousUserRow(
                            job = job,
                            time = times.getValue(job.id),
                            latest = index == 0,
                            selected = job.userId == chosen,
                            onClick = { onUserIdChange(job.userId) },
                            testId = UseSmileIDSampleTestIds.authUserIdOption(index),
                        )
                    }
                }
            }
        }
        UseSmileIDSampleButton(
            text = UseSmileIDSampleStrings.commonContinue,
            onClick = onContinue,
            enabled = chosen.isNotEmpty(),
            testId = UseSmileIDSampleTestIds.AUTH_USER_ID_CONTINUE,
            modifier = Modifier
                .fillMaxWidth()
                .padding(contentPadding)
                .padding(SmileDimens.spacingMd),
        )
    }
}

/** One earlier user: the ID in body weight because it is the value, the product and time beneath with LATEST on the newest, and a check when it is in the field. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun PreviousUserRow(job: UseSmileIDSampleJob, time: String, latest: Boolean, selected: Boolean, onClick: () -> Unit, testId: String) {
    val colors = UseSmileIDSampleTheme.colors
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .selectable(selected = selected, role = Role.RadioButton, onClick = onClick)
            .defaultMinSize(minHeight = SmileDimens.space64)
            .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingSm)
            .tagged(testId),
        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs)) {
            Text(text = job.userId, style = UseSmileIDSampleTheme.type.textStyleBody, color = colors.textTitle)
            // A FlowRow so the chip drops under the product and time at large text rather than clipping them.
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
                itemVerticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "${job.product.localizedTitle()} · $time",
                    style = UseSmileIDSampleTheme.type.textStyleCaption,
                    color = colors.textMuted,
                )
                if (latest) {
                    StatusPill(
                        label = UseSmileIDSampleStrings.authUserIdLatest,
                        background = colors.badge.infoBackground,
                        foreground = colors.badge.infoText,
                    )
                }
            }
        }
        if (selected) CheckGlyph(tint = colors.primary)
    }
}

/** The settings-row shape with the enrolment product's own hue tile, since the setting row's tile is neutral. */
@Composable
private fun EnrollmentRow(onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(role = Role.Button, onClick = onClick)
            .defaultMinSize(minHeight = SmileDimens.space64)
            .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingSm)
            .tagged(UseSmileIDSampleTestIds.AUTH_USER_ID_REGISTER),
        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        UseSmileIDSampleProductTile(product = UseSmileIDSampleProduct.SmartSelfieEnrollment)
        Text(
            text = UseSmileIDSampleProduct.SmartSelfieEnrollment.localizedTitle(),
            style = UseSmileIDSampleTheme.type.textStyleBodyStrong,
            color = UseSmileIDSampleTheme.colors.textTitle,
            modifier = Modifier.weight(1f),
        )
        UseSmileIDSampleSettingRowChevron()
    }
}

/** A hairline either side of OR, so the field and the card below read as two ways to the same ID. */
@Composable
private fun OrDivider() {
    val colors = UseSmileIDSampleTheme.colors
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = SmileDimens.spacingXs),
        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        HorizontalDivider(modifier = Modifier.weight(1f), thickness = smileCardStrokeWidth, color = colors.cardStroke)
        Text(
            text = UseSmileIDSampleStrings.authUserIdOr,
            style = UseSmileIDSampleTheme.type.textStyleOverline.copy(fontSize = smileLabelSize, letterSpacing = smileLabelTracking),
            color = colors.textMuted,
        )
        HorizontalDivider(modifier = Modifier.weight(1f), thickness = smileCardStrokeWidth, color = colors.cardStroke)
    }
}

/** Muted supporting copy under a field or card. */
@Composable
private fun Caption(text: String) {
    Text(text = text, style = UseSmileIDSampleTheme.type.textStyleCaption, color = UseSmileIDSampleTheme.colors.textMuted)
}
