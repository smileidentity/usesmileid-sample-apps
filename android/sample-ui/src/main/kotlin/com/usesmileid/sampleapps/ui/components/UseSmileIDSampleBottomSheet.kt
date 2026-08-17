package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.text.style.TextOverflow
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The partial sheet: a grab handle over a scrim, sized to its content. Presence is the caller's route, not a remembered boolean. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UseSmileIDSampleBottomSheet(
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
    title: String? = null,
    testId: String? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    ModalBottomSheet(
        onDismissRequest = onDismissRequest,
        modifier = modifier.publishTestTags().tagged(testId),
        sheetState = rememberModalBottomSheetState(),
        shape = RoundedCornerShape(topStart = SmileDimens.radiusSheet, topEnd = SmileDimens.radiusSheet),
        containerColor = UseSmileIDSampleTheme.colors.surface,
        contentColor = UseSmileIDSampleTheme.colors.textTitle,
        scrimColor = UseSmileIDSampleTheme.colors.overlayScrim,
        dragHandle = { GrabHandle() },
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = SmileDimens.spacingMd)
                .padding(bottom = SmileDimens.spacingLg),
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
        ) {
            if (title != null) {
                Text(
                    text = title,
                    style = UseSmileIDSampleTheme.type.textStyleHeadingSection,
                    color = UseSmileIDSampleTheme.colors.textTitle,
                )
            }
            content()
        }
    }
}

/** The full-height sheet: a back header instead of a handle, for the long picker lists. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UseSmileIDSampleFullHeightBottomSheet(
    title: String,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
    testId: String? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    ModalBottomSheet(
        onDismissRequest = onDismissRequest,
        modifier = modifier.fillMaxHeight().publishTestTags().tagged(testId),
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        shape = RoundedCornerShape(topStart = SmileDimens.radiusSheet, topEnd = SmileDimens.radiusSheet),
        containerColor = UseSmileIDSampleTheme.colors.surface,
        contentColor = UseSmileIDSampleTheme.colors.textTitle,
        scrimColor = UseSmileIDSampleTheme.colors.overlayScrim,
        dragHandle = null,
        // The sheet reaches the top of the screen, so it owns its status-bar inset.
        contentWindowInsets = { WindowInsets.statusBars },
    ) {
        Column(modifier = Modifier.fillMaxWidth()) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingXs),
                horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                UseSmileIDSampleTopAppBarButton(
                    contentDescription = "Close $title",
                    onClick = onDismissRequest,
                    emphasis = UseSmileIDSampleTopAppBarEmphasis.Filled,
                ) { tint -> ArrowBackGlyph(tint = tint) }
                Text(
                    text = title,
                    style = UseSmileIDSampleTheme.type.textStyleHeadingSection,
                    color = UseSmileIDSampleTheme.colors.textTitle,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = SmileDimens.spacingMd),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
                content = content,
            )
        }
    }
}

/** A sheet is its own window, outside where the shell publishes tags, so without this no sheet id reaches automation. */
@OptIn(ExperimentalComposeUiApi::class)
private fun Modifier.publishTestTags(): Modifier = semantics { testTagsAsResourceId = true }

/** The 44x5 pill the design puts on partial sheets. */
@Composable
private fun GrabHandle() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = SmileDimens.spacingSm),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier
                .size(width = SmileDimens.sizeControlMd, height = SmileDimens.space4)
                .background(
                    color = UseSmileIDSampleTheme.colors.border,
                    shape = RoundedCornerShape(SmileDimens.radiusChip),
                ),
        )
    }
}
