package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleResult
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * Every field in `spec/result-card.schema.json`, published into the accessibility tree under its own id.
 *
 * Expanded by default: a collapsed field is absent from that tree, so a flow would have to tap it open first.
 */
@Composable
fun UseSmileIDSampleResultCard(
    result: UseSmileIDSampleResult,
    modifier: Modifier = Modifier,
) {
    var expanded by rememberSaveable { mutableStateOf(true) }
    val colors = UseSmileIDSampleTheme.colors
    Surface(
        modifier = modifier.fillMaxWidth().tagged(UseSmileIDSampleTestIds.RESULT_CARD),
        shape = RoundedCornerShape(SmileDimens.radiusSurface),
        color = colors.surfaceAlt,
    ) {
        Column(modifier = Modifier.padding(vertical = SmileDimens.spacingSm)) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(
                        role = Role.Button,
                        onClickLabel = if (expanded) "Collapse SDK result" else "Expand SDK result",
                        onClick = { expanded = !expanded },
                    )
                    .defaultMinSize(minHeight = SmileDimens.space40)
                    .padding(horizontal = SmileDimens.spacingMd),
                horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "SDK RESULT",
                    style = UseSmileIDSampleTheme.type.textStyleOverline,
                    color = colors.textMuted,
                    modifier = Modifier.weight(1f),
                )
                Text(
                    text = if (expanded) "Hide" else "Show",
                    style = UseSmileIDSampleTheme.type.textStyleCaption,
                    color = colors.textLink,
                )
            }
            if (expanded) {
                ResultField("Scenario", result.activeScenario.id, UseSmileIDSampleTestIds.RESULT_ACTIVE_SCENARIO)
                ResultField("Theme", result.activeTheme.id, UseSmileIDSampleTestIds.RESULT_ACTIVE_THEME)
                ResultField("Route", result.route.id, UseSmileIDSampleTestIds.RESULT_ROUTE)
                ResultField("Job id", result.jobId, UseSmileIDSampleTestIds.RESULT_JOB_ID)
                ResultField("User id", result.userId, UseSmileIDSampleTestIds.RESULT_USER_ID)
                ResultField("Job status", result.jobStatus.id, UseSmileIDSampleTestIds.RESULT_JOB_STATUS)
                ResultField(
                    label = "Result callbacks",
                    value = result.resultCallbackCount.toString(),
                    testId = UseSmileIDSampleTestIds.RESULT_RESULT_COUNT,
                )
                ResultField(
                    label = "Refresh callbacks",
                    value = result.refreshCallbackCount.toString(),
                    testId = UseSmileIDSampleTestIds.RESULT_REFRESH_COUNT,
                )
                ResultField("Last error", result.lastError, UseSmileIDSampleTestIds.RESULT_LAST_ERROR)
                ResultField("SDK version", result.sdkVersion, UseSmileIDSampleTestIds.RESULT_SDK_VERSION)
            }
        }
    }
}

/** The three fields that say whether a run is live and what it is running as; the rest stay on the card. */
@Composable
fun UseSmileIDSampleResultLine(
    result: UseSmileIDSampleResult,
    modifier: Modifier = Modifier,
) {
    val colors = UseSmileIDSampleTheme.colors
    Surface(
        modifier = modifier.fillMaxWidth().tagged(UseSmileIDSampleTestIds.RESULT_CARD),
        shape = RoundedCornerShape(SmileDimens.radiusSurface),
        color = colors.surfaceAlt,
    ) {
        Row(
            modifier = Modifier
                .defaultMinSize(minHeight = SmileDimens.space40)
                .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingXs),
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = "SDK",
                style = UseSmileIDSampleTheme.type.textStyleOverline,
                color = colors.textMuted,
            )
            ResultValue(
                value = result.jobStatus.id,
                testId = UseSmileIDSampleTestIds.RESULT_JOB_STATUS,
                modifier = Modifier.weight(1f),
            )
            ResultValue(value = result.activeScenario.id, testId = UseSmileIDSampleTestIds.RESULT_ACTIVE_SCENARIO)
            ResultValue(value = result.route.id, testId = UseSmileIDSampleTestIds.RESULT_ROUTE)
        }
    }
}

/** A null value still renders, because an id missing from the tree and one with no value are different failures. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun ResultField(label: String, value: String?, testId: String) {
    FlowRow(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingXxs),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
    ) {
        Text(
            text = label,
            style = UseSmileIDSampleTheme.type.textStyleCaption,
            color = UseSmileIDSampleTheme.colors.textMuted,
        )
        ResultValue(value = value, testId = testId)
    }
}

@Composable
private fun ResultValue(value: String?, testId: String, modifier: Modifier = Modifier) {
    Text(
        text = value ?: NULL_VALUE,
        style = UseSmileIDSampleTheme.type.textStyleCaption,
        color = UseSmileIDSampleTheme.colors.textBody,
        modifier = modifier.tagged(testId),
    )
}

/** The rendering of a null field. Stable, because flows assert on it to prove a value was absent. */
private const val NULL_VALUE = "—"
