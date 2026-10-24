package com.usesmileid.sampleapps.ui.components

import com.usesmileid.sampleapps.ui.UseSmileIDSampleStrings
import androidx.compose.foundation.background
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.ime
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.union
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The partial sheet's panel: a grab handle over its content, sized to it; njia's sheet step draws the window, scrim and dismissal. */
@Composable
fun UseSmileIDSampleBottomSheet(
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
    title: String? = null,
    testId: String? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    SheetPanel(modifier.publishTestTags().tagged(testId)) {
        GrabHandle()
        PartialSheetBody(title, content)
    }
}

/** The partial sheet's title and content, scrolling rather than clipping. */
@Composable
private fun PartialSheetBody(title: String?, content: @Composable ColumnScope.() -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            // Scrolls rather than clips, so enlarged type cannot push a CTA out of reach.
            .verticalScroll(rememberScrollState())
            .padding(horizontal = SHEET_MARGIN)
            .padding(bottom = SmileDimens.spacingLg),
        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
    ) {
        if (title != null) {
            Text(
                text = title,
                style = UseSmileIDSampleTheme.type.textStyleHeadingSection.copy(fontWeight = FontWeight.Bold),
                color = UseSmileIDSampleTheme.colors.textTitle,
                modifier = Modifier.fillMaxWidth(),
            )
        }
        content()
    }
}

/** The full-height sheet's panel: a back header instead of a handle, for the long picker lists. */
@Composable
fun UseSmileIDSampleFullHeightBottomSheet(
    title: String,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
    testId: String? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    SheetPanel(modifier.fillMaxHeight().publishTestTags().tagged(testId)) {
        FullHeightSheetBody(title, onDismissRequest, content)
    }
}

/** The full-height sheet's back header over its content. */
@Composable
private fun FullHeightSheetBody(title: String, onDismissRequest: () -> Unit, content: @Composable ColumnScope.() -> Unit) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Row(
            // A sheet header is its own pattern: wider margins, and the title left of the back control.
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = SHEET_MARGIN, vertical = SmileDimens.spacingXs),
            horizontalArrangement = Arrangement.spacedBy(SHEET_HEADER_GAP),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            UseSmileIDSampleTopAppBarButton(
                contentDescription = UseSmileIDSampleStrings.commonCloseNamed(title),
                onClick = onDismissRequest,
                emphasis = UseSmileIDSampleTopAppBarEmphasis.Filled,
            ) { tint -> ArrowBackGlyph(tint = tint) }
            Text(
                text = title,
                style = UseSmileIDSampleTheme.type.textStyleTitle,
                color = UseSmileIDSampleTheme.colors.textTitle,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = SHEET_MARGIN),
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
            content = content,
        )
    }
}

/** The panel a sheet draws in njia's sheet layer: the sheet's shape and colours, the scrim being the host's. */
@Composable
private fun SheetPanel(modifier: Modifier, content: @Composable ColumnScope.() -> Unit) {
    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = UseSmileIDSampleTheme.shapes.sheet,
        color = UseSmileIDSampleTheme.colors.surface,
        contentColor = UseSmileIDSampleTheme.colors.textTitle,
    ) {
        // Edge to edge, so the panel insets its content past the system navigation bar and the keyboard itself.
        Column(modifier = Modifier.windowInsetsPadding(WindowInsets.navigationBars.union(WindowInsets.ime)), content = content)
    }
}

/** A dialog is its own window, and a sheet may sit under a host that publishes none, so each publishes its test tags for automation. */
@OptIn(ExperimentalComposeUiApi::class)
internal fun Modifier.publishTestTags(): Modifier = semantics { testTagsAsResourceId = true }

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
                    shape = UseSmileIDSampleTheme.shapes.chip,
                ),
        )
    }
}

private val SHEET_MARGIN = 20.dp
private val SHEET_HEADER_GAP = 10.dp
