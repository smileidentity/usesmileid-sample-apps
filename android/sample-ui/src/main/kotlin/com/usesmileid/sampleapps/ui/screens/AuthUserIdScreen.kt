package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
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
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextOverflow
import com.smileid.designsystem.SmileDimens
import com.smileid.designsystem.smileCardStrokeWidth
import com.smileid.designsystem.smileLabelSize
import com.smileid.designsystem.smileLabelTracking
import com.usesmileid.sampleapps.ui.UseSmileIDSampleStrings
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.StatusPill
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleProductTile
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionLabel
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRowChevron
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
    /** The newest run per enrolled user, newest first. */
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
                ListSection(label = UseSmileIDSampleStrings.authUserIdRun, hint = UseSmileIDSampleStrings.authUserIdRunBody)
                EnrollmentRow(onClick = onRegister)
            } else {
                ListSection(label = UseSmileIDSampleStrings.authUserIdPrevious, hint = UseSmileIDSampleStrings.authUserIdPreviousHint)
                Column(verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs)) {
                    previousUsers.forEachIndexed { index, job ->
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
            Spacer(modifier = Modifier.height(SmileDimens.spacingXs))
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

/** An earlier user, laid out like a verifications row. */
@Composable
private fun PreviousUserRow(job: UseSmileIDSampleJob, time: String, latest: Boolean, selected: Boolean, onClick: () -> Unit, testId: String) {
    val colors = UseSmileIDSampleTheme.colors
    val stacks = LocalDensity.current.fontScale > 1f
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .selectable(selected = selected, role = Role.RadioButton, onClick = onClick)
            .tagged(testId),
        shape = UseSmileIDSampleTheme.shapes.card,
        color = colors.card.background,
        border = if (selected) BorderStroke(SmileDimens.borderWidthThin, colors.primary) else BorderStroke(smileCardStrokeWidth, colors.cardStroke),
    ) {
        Row(
            modifier = Modifier
                .defaultMinSize(minHeight = SmileDimens.space64)
                .padding(SmileDimens.spacingSm),
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            UseSmileIDSampleProductTile(product = job.product)
            val lines = if (stacks) Int.MAX_VALUE else 1
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs)) {
                Text(
                    text = job.product.localizedTitle(),
                    style = UseSmileIDSampleTheme.type.textStyleBodyStrong,
                    color = colors.card.title,
                    maxLines = lines,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(
                    text = "${job.middleUserId} · $time",
                    style = UseSmileIDSampleTheme.type.textStyleCaption,
                    color = colors.textMuted,
                    maxLines = lines,
                    overflow = TextOverflow.Ellipsis,
                )
                if (latest && stacks) LatestPill()
            }
            if (latest && !stacks) LatestPill()
        }
    }
}

/** The newest user's pill. */
@Composable
private fun LatestPill() {
    val badge = UseSmileIDSampleTheme.colors.badge
    StatusPill(label = UseSmileIDSampleStrings.authUserIdLatest, background = badge.infoBackground, foreground = badge.infoText)
}

/** Starts SmartSelfie Enrollment. */
@Composable
private fun EnrollmentRow(onClick: () -> Unit) {
    val colors = UseSmileIDSampleTheme.colors
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(role = Role.Button, onClick = onClick)
            .tagged(UseSmileIDSampleTestIds.AUTH_USER_ID_REGISTER),
        shape = UseSmileIDSampleTheme.shapes.card,
        color = colors.card.background,
        border = BorderStroke(smileCardStrokeWidth, colors.cardStroke),
    ) {
        Row(
            modifier = Modifier
                .defaultMinSize(minHeight = SmileDimens.space64)
                .padding(SmileDimens.spacingSm),
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            UseSmileIDSampleProductTile(product = UseSmileIDSampleProduct.SmartSelfieEnrollment)
            Text(
                text = UseSmileIDSampleProduct.SmartSelfieEnrollment.localizedTitle(),
                style = UseSmileIDSampleTheme.type.textStyleBodyStrong,
                color = colors.card.title,
                modifier = Modifier.weight(1f),
            )
            UseSmileIDSampleSettingRowChevron()
        }
    }
}

/** A section label with its hint. */
@Composable
private fun ListSection(label: String, hint: String) {
    Column(verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs)) {
        UseSmileIDSampleSectionLabel(text = label)
        Caption(hint)
    }
}

/** OR between two hairlines. */
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

/** Muted supporting copy. */
@Composable
private fun Caption(text: String) {
    Text(text = text, style = UseSmileIDSampleTheme.type.textStyleCaption, color = UseSmileIDSampleTheme.colors.textMuted)
}
