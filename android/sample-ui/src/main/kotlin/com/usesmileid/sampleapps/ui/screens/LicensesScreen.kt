package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.R
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleEmptyState
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleIcon
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionLabel
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRowDivider
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBar
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleLicenses
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleNotice
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * The notices the app ships rather than links to: Apache-2.0 §4 asks that they travel with the
 * distribution. Two sections because some of the dependencies are not open source at all — they
 * declare Google's own terms, and listing those under an open-source heading would be wrong.
 *
 * A flat list rather than the rounded section cards every other screen uses: this one has no design
 * frame, and two hundred rows inside one card would compose all of them at once.
 */
@Composable
fun LicensesScreen(
    licenses: UseSmileIDSampleLicenses,
    onBack: () -> Unit,
    onOpenUrl: (String) -> Unit,
    modifier: Modifier = Modifier,
    contentPadding: PaddingValues = PaddingValues(),
) {
    // One at a time: two copies of the Apache text open at once is a screen nobody can read.
    var expanded by remember { mutableStateOf<String?>(null) }

    Column(
        modifier = modifier
            .fillMaxSize()
            .testTag(UseSmileIDSampleTestIds.LICENSES_SCREEN),
    ) {
        UseSmileIDSampleTopAppBar(title = "Open-source licenses", onBack = onBack)
        LazyColumn(contentPadding = contentPadding) {
            if (licenses.isEmpty) {
                item {
                    // Generated at build time, so an empty list means the asset did not ship.
                    UseSmileIDSampleEmptyState(
                        text = "No notices bundled",
                        supportingText = "The generated licenses.json is missing from this build",
                        testId = UseSmileIDSampleTestIds.LICENSES_EMPTY,
                    )
                }
                return@LazyColumn
            }

            label("OPEN-SOURCE COMPONENTS — ${licenses.openSource.size}")
            items(licenses.openSource, key = { it.artifact }) { notice ->
                NoticeRow(
                    notice = notice,
                    text = notice.licenses.firstNotNullOfOrNull { licenses.texts[it.id] },
                    expanded = expanded == notice.artifact,
                    onClick = { expanded = notice.artifact.takeIf { expanded != it } },
                    onOpenUrl = onOpenUrl,
                )
            }

            if (licenses.googleServices.isNotEmpty()) {
                label("UNDER GOOGLE'S OWN TERMS — ${licenses.googleServices.size}")
                items(licenses.googleServices, key = { it.artifact }) { notice ->
                    NoticeRow(
                        notice = notice,
                        // A terms page is the licence, so there is no text to ship for these.
                        text = null,
                        expanded = expanded == notice.artifact,
                        onClick = { expanded = notice.artifact.takeIf { expanded != it } },
                        onOpenUrl = onOpenUrl,
                    )
                }
            }
        }
    }
}

@Composable
private fun NoticeRow(
    notice: UseSmileIDSampleNotice,
    text: String?,
    expanded: Boolean,
    onClick: () -> Unit,
    onOpenUrl: (String) -> Unit,
) {
    Surface(color = UseSmileIDSampleTheme.colors.surface) {
        Column {
            UseSmileIDSampleSettingRow(
                title = notice.artifact,
                supportingText = "${notice.version} · ${notice.licenses.joinToString(", ") { it.name }}",
                onClick = onClick,
                leading = { tint -> UseSmileIDSampleIcon(id = R.drawable.sample_ic_setting_licenses, tint = tint) },
                testId = UseSmileIDSampleTestIds.licenseRow(notice.artifact),
            )
            if (expanded) {
                ExpandedLicence(notice = notice, text = text, onOpenUrl = onOpenUrl)
            }
            UseSmileIDSampleSettingRowDivider()
        }
    }
}

/** The licence text where it ships with us, and the page that carries it where it does not. */
@Composable
private fun ExpandedLicence(notice: UseSmileIDSampleNotice, text: String?, onOpenUrl: (String) -> Unit) {
    val body = text ?: notice.licenses.firstOrNull { it.url.isNotBlank() }?.let { licence ->
        "The text ships with the component itself. Tap to open ${licence.url}"
    }
    Text(
        text = body ?: "No licence text was recorded for this component.",
        style = UseSmileIDSampleTheme.type.textStyleCaption,
        color = UseSmileIDSampleTheme.colors.textMuted,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = SmileDimens.spacingMd)
            .padding(bottom = SmileDimens.spacingSm)
            .testTag(UseSmileIDSampleTestIds.licenseText(notice.artifact)),
    )
    if (text != null) return
    notice.licenses.firstOrNull { it.url.isNotBlank() }?.let { licence ->
        UseSmileIDSampleSettingRow(
            title = "Open ${licence.name}",
            onClick = { onOpenUrl(licence.url) },
            testId = UseSmileIDSampleTestIds.licenseLink(notice.artifact),
        )
    }
}

private fun LazyListScope.label(text: String) = item {
    UseSmileIDSampleSectionLabel(
        text = text,
        modifier = Modifier.padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingXs),
    )
}
