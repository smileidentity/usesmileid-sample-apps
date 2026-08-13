package com.usesmileid.sampleapps.android.gallery

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.Density
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleAvatar
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSearchField
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionLabel
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatusBadge
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSwitch
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTextInput
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleToast
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/**
 * Every primitive in every state, on one scrolling surface.
 *
 * A dev-only surface, so it lives in the shell rather than in `sample-ui`, and it is deliberately
 * not an entry in `spec/routes.json` — it is not part of the journey the four apps share. Its ids
 * are `dev_*` rather than `sample_*` for the same reason: the `sample_*` namespace is the spec's.
 */
const val COMPONENT_GALLERY_TAG = "dev_component_gallery"
const val COMPONENT_GALLERY_FONT_SCALE_TAG = "dev_gallery_font_scale"

/** Android's largest accessibility font scale, which is the one the no-clipping predicate means. */
private const val MAX_FONT_SCALE = 2f

@Composable
fun ComponentGalleryScreen() {
    var text by rememberSaveable { mutableStateOf("") }
    var query by rememberSaveable { mutableStateOf("") }
    var switched by rememberSaveable { mutableStateOf(true) }
    var largeText by rememberSaveable { mutableStateOf(false) }
    val density = LocalDensity.current

    Column(
        modifier = Modifier
            .testTag(COMPONENT_GALLERY_TAG)
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(SmileDimens.spacingMd),
        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
    ) {
        Text(
            text = "Component gallery",
            style = UseSmileIDSampleTheme.type.textStyleHeadingPage,
            color = UseSmileIDSampleTheme.colors.textTitle,
        )

        // The scale is overridden here rather than in system settings because some OEM builds refuse
        // `settings put system font_scale` from the shell, which leaves the max-font-scale predicate
        // unverifiable on the device. The control sits outside the override so it does not grow too.
        Row(
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            UseSmileIDSampleSwitch(
                checked = largeText,
                onCheckedChange = { largeText = it },
                testId = COMPONENT_GALLERY_FONT_SCALE_TAG,
            )
            Text(
                text = if (largeText) "Font scale ${MAX_FONT_SCALE.toInt()}.0" else "Font scale 1.0",
                style = UseSmileIDSampleTheme.type.textStyleBodySm,
                color = UseSmileIDSampleTheme.colors.textBody,
            )
        }

        CompositionLocalProvider(
            LocalDensity provides Density(
                density = density.density,
                fontScale = if (largeText) MAX_FONT_SCALE else 1f,
            ),
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm)) {
                GallerySection("TYPOGRAPHY") {
                    Text(
                        text = "Verification Rgy 0123",
                        style = UseSmileIDSampleTheme.type.textStyleHeadingCard,
                        color = UseSmileIDSampleTheme.colors.textTitle,
                    )
                    Text(
                        text = "Verification Rgy 0123",
                        style = UseSmileIDSampleTheme.type.textStyleBody,
                        color = UseSmileIDSampleTheme.colors.textBody,
                    )
                    Text(
                        text = "Verification Rgy 0123",
                        style = UseSmileIDSampleTheme.type.textStyleCaption,
                        color = UseSmileIDSampleTheme.colors.textMuted,
                    )
                }

                GallerySection("AVATAR") {
                    // FlowRow, not Row: at the largest font scale four avatars no longer fit on one
                    // line, and a Row squeezes the last one out of round instead of wrapping it.
                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
                        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
                        itemVerticalAlignment = Alignment.CenterVertically,
                    ) {
                        UseSmileIDSampleAvatar(initials = "HW")
                        UseSmileIDSampleAvatar(initials = "KO")
                        UseSmileIDSampleAvatar(initials = "")
                        UseSmileIDSampleAvatar(
                            initials = "SM",
                            containerColor = UseSmileIDSampleTheme.colors.accent,
                        )
                    }
                }

                GallerySection("BUTTON") {
                    UseSmileIDSampleButton(text = "Continue", onClick = {})
                    UseSmileIDSampleButton(text = "Continue", onClick = {}, enabled = false)
                    UseSmileIDSampleButton(text = "Continue", onClick = {}, loading = true)
                    UseSmileIDSampleButton(text = "SmartSelfie Authentication and enrolment", onClick = {})
                }

                GallerySection("TEXT INPUT") {
                    UseSmileIDSampleTextInput(
                        value = text,
                        onValueChange = { text = it },
                        placeholder = "ID number",
                    )
                    UseSmileIDSampleTextInput(value = "AO12345678", onValueChange = {}, placeholder = "ID number")
                    UseSmileIDSampleTextInput(
                        value = "12",
                        onValueChange = {},
                        isError = true,
                        errorMessage = "ID number must be 10 characters",
                    )
                    UseSmileIDSampleTextInput(
                        value = "Locked",
                        onValueChange = {},
                        enabled = false,
                        placeholder = "ID number",
                    )
                }

                GallerySection("SEARCH FIELD") {
                    UseSmileIDSampleSearchField(
                        query = query,
                        onQueryChange = { query = it },
                        placeholder = "Search countries",
                    )
                    UseSmileIDSampleSearchField(query = "Kenya", onQueryChange = {}, placeholder = "Search countries")
                }

                GallerySection("SWITCH") {
                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
                        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
                        itemVerticalAlignment = Alignment.CenterVertically,
                    ) {
                        UseSmileIDSampleSwitch(checked = switched, onCheckedChange = { switched = it })
                        UseSmileIDSampleSwitch(checked = !switched, onCheckedChange = { switched = !it })
                        UseSmileIDSampleSwitch(checked = true, onCheckedChange = null, enabled = false)
                        UseSmileIDSampleSwitch(checked = false, onCheckedChange = null, enabled = false)
                    }
                }

                GallerySection("STATUS BADGE") {
                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                    ) {
                        UseSmileIDSampleStatus.entries.forEach { UseSmileIDSampleStatusBadge(status = it) }
                    }
                }

                GallerySection("TOAST") {
                    UseSmileIDSampleToast(message = "Verification removed")
                    UseSmileIDSampleToast(
                        message = "Verification removed",
                        actionLabel = "Undo",
                        onAction = {},
                    )
                }
            }
        }
    }
}

@Composable
private fun GallerySection(label: String, content: @Composable () -> Unit) {
    HorizontalDivider(color = UseSmileIDSampleTheme.colors.border)
    UseSmileIDSampleSectionLabel(text = label)
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
    ) {
        content()
    }
}
