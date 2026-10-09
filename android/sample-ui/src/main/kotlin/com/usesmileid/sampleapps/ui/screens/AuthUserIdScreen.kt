package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import com.smileid.designsystem.SmileDimens
import com.smileid.designsystem.smileCardStrokeWidth
import com.usesmileid.sampleapps.ui.UseSmileIDSampleStrings
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleOptionRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleProductTile
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTextInput
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBar
import com.usesmileid.sampleapps.ui.components.tagged
import com.usesmileid.sampleapps.ui.localizedTitle
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** SmartSelfie Authentication's user ID: typed, or picked from earlier runs that enrolled one. Never made up, because the SDK authenticates only an enrolled user. */
@Composable
fun AuthUserIdScreen(
    userId: String,
    previousUserIds: List<String>,
    onUserIdChange: (String) -> Unit,
    onRegister: () -> Unit,
    onBack: () -> Unit,
    onContinue: () -> Unit,
    modifier: Modifier = Modifier,
    contentPadding: PaddingValues = PaddingValues(),
) {
    val chosen = userId.trim()
    Column(
        modifier = modifier
            .fillMaxSize()
            .testTag(UseSmileIDSampleTestIds.AUTH_USER_ID_SCREEN),
    ) {
        UseSmileIDSampleTopAppBar(title = UseSmileIDSampleProduct.SmartSelfieAuth.localizedTitle(), onBack = onBack)
        LazyColumn(
            modifier = Modifier.weight(1f),
            contentPadding = PaddingValues(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingLg),
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
        ) {
            item {
                Column(modifier = Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
                    UseSmileIDSampleProductTile(product = UseSmileIDSampleProduct.SmartSelfieAuth, size = SmileDimens.space64)
                }
            }
            if (previousUserIds.isEmpty()) {
                item {
                    Heading(UseSmileIDSampleStrings.authUserIdEmptyTitle)
                    Body(UseSmileIDSampleStrings.authUserIdPreviousBody)
                }
                item { Heading(UseSmileIDSampleStrings.authUserIdRun) }
                item { RegisterCard(onClick = onRegister) }
                item { Or() }
                item { UserIdField(userId = userId, onUserIdChange = onUserIdChange) }
            } else {
                item { UserIdField(userId = userId, onUserIdChange = onUserIdChange) }
                item { Or() }
                item {
                    Heading(UseSmileIDSampleStrings.authUserIdPrevious)
                    Body(UseSmileIDSampleStrings.authUserIdPreviousBody)
                }
                itemsIndexed(previousUserIds) { index, previous ->
                    UseSmileIDSampleOptionRow(
                        label = previous,
                        selected = previous == chosen,
                        onClick = { onUserIdChange(previous) },
                        testId = UseSmileIDSampleTestIds.authUserIdOption(index),
                    )
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

@Composable
private fun UserIdField(userId: String, onUserIdChange: (String) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs)) {
        Heading(UseSmileIDSampleStrings.authUserIdEnter)
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
    }
}

@Composable
private fun RegisterCard(onClick: () -> Unit) {
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
            modifier = Modifier.padding(SmileDimens.spacingSm),
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            UseSmileIDSampleProductTile(product = UseSmileIDSampleProduct.SmartSelfieEnrollment)
            Text(
                text = UseSmileIDSampleProduct.SmartSelfieEnrollment.localizedTitle(),
                style = UseSmileIDSampleTheme.type.textStyleBodyStrong,
                color = colors.card.title,
            )
        }
    }
}

@Composable
private fun Heading(text: String) {
    Text(
        text = text,
        style = UseSmileIDSampleTheme.type.textStyleTitle,
        color = UseSmileIDSampleTheme.colors.textTitle,
        modifier = Modifier.semantics { heading() },
    )
}

@Composable
private fun Body(text: String) {
    Text(
        text = text,
        style = UseSmileIDSampleTheme.type.textStyleCaption,
        color = UseSmileIDSampleTheme.colors.textMuted,
        modifier = Modifier.padding(top = SmileDimens.spacingXxs),
    )
}

@Composable
private fun Or() {
    Text(
        text = UseSmileIDSampleStrings.authUserIdOr,
        style = UseSmileIDSampleTheme.type.textStyleCaption,
        color = UseSmileIDSampleTheme.colors.textMuted,
        textAlign = TextAlign.Center,
        modifier = Modifier.fillMaxWidth(),
    )
}
