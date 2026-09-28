package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleBottomSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleFilterChip
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionLabel
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSwitch
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTextInput
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleAspectRatio
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCustomDocument
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleDocumentOrientation

/** Builds the GenericDocument that "Capture as: Custom" hands the SDK. Nothing is kept until Done. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun CustomDocumentSheet(
    initial: UseSmileIDSampleCustomDocument,
    onDone: (UseSmileIDSampleCustomDocument) -> Unit,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var draft by rememberSaveable(stateSaver = CustomDocumentSaver) { mutableStateOf(initial) }
    UseSmileIDSampleBottomSheet(
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        title = "Custom document",
        testId = UseSmileIDSampleTestIds.CUSTOM_DOCUMENT_SHEET,
    ) {
        UseSmileIDSampleSectionLabel(text = "DISPLAY NAME")
        UseSmileIDSampleTextInput(
            value = draft.displayName,
            onValueChange = { draft = draft.copy(displayName = it) },
            placeholder = "Document",
            testId = UseSmileIDSampleTestIds.CUSTOM_DOCUMENT_NAME,
        )
        UseSmileIDSampleSettingRow(
            title = "Back side",
            supportingText = "Capture the back after the front",
            trailing = {
                UseSmileIDSampleSwitch(
                    checked = draft.hasBackSide,
                    onCheckedChange = { draft = draft.copy(hasBackSide = it) },
                    testId = UseSmileIDSampleTestIds.CUSTOM_DOCUMENT_BACK_SIDE,
                )
            },
        )
        UseSmileIDSampleSectionLabel(text = "ORIENTATION")
        FlowRow(horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs)) {
            UseSmileIDSampleDocumentOrientation.entries.forEach { orientation ->
                UseSmileIDSampleFilterChip(
                    label = orientation.label,
                    count = null,
                    selected = orientation == draft.orientation,
                    onClick = { draft = draft.copy(orientation = orientation) },
                    testId = UseSmileIDSampleTestIds.customDocumentOrientation(orientation.id),
                )
            }
        }
        UseSmileIDSampleSectionLabel(text = "ASPECT RATIO")
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
        ) {
            UseSmileIDSampleAspectRatio.entries.forEach { ratio ->
                UseSmileIDSampleFilterChip(
                    label = ratio.label,
                    count = null,
                    selected = ratio == draft.aspectRatio,
                    onClick = { draft = draft.copy(aspectRatio = ratio) },
                    testId = UseSmileIDSampleTestIds.customDocumentAspectRatio(ratio.id),
                )
            }
        }
        UseSmileIDSampleButton(
            text = "Done",
            onClick = { onDone(draft.copy(displayName = draft.displayName.trim().ifEmpty { "Document" })) },
            modifier = Modifier.fillMaxWidth(),
            testId = UseSmileIDSampleTestIds.CUSTOM_DOCUMENT_DONE,
        )
    }
}

private val CustomDocumentSaver = androidx.compose.runtime.saveable.listSaver<UseSmileIDSampleCustomDocument, String>(
    save = { listOf(it.displayName, it.hasBackSide.toString(), it.orientation.name, it.aspectRatio.name) },
    restore = { (name, back, orientation, ratio) ->
        UseSmileIDSampleCustomDocument(
            displayName = name,
            hasBackSide = back != "false",
            orientation = UseSmileIDSampleDocumentOrientation.entries.firstOrNull { it.name == orientation }
                ?: UseSmileIDSampleDocumentOrientation.Landscape,
            aspectRatio = UseSmileIDSampleAspectRatio.entries.firstOrNull { it.name == ratio } ?: UseSmileIDSampleAspectRatio.Off,
        )
    },
)
