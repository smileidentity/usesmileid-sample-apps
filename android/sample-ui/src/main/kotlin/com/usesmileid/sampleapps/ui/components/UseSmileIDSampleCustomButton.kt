package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import com.smileid.designsystem.SmileDimens
import com.usesmileid.presentation.flow.dsl.ButtonSlotScope
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The sample's own continue button, drawn by the SDK in its continue slots while Custom continue is on. */
@Composable
fun UseSmileIDSampleCustomContinueButton(onClick: () -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true) {
    UseSmileIDSampleButton(
        text = CUSTOM_CONTINUE_LABEL,
        onClick = onClick,
        modifier = modifier,
        enabled = enabled,
        testId = UseSmileIDSampleTestIds.CUSTOM_CONTINUE,
    )
}

/** The sample's own cancel button, for the SDK's cancel slots: the continue button's outlined twin. */
@Composable
fun UseSmileIDSampleCustomCancelButton(onClick: () -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true) {
    val colour = UseSmileIDSampleTheme.colors.button.primaryBackground
    OutlinedButton(
        onClick = onClick,
        modifier = modifier
            .fillMaxWidth()
            .defaultMinSize(minHeight = SmileDimens.sizeControlLg)
            .tagged(UseSmileIDSampleTestIds.CUSTOM_CANCEL),
        enabled = enabled,
        shape = RoundedCornerShape(SmileDimens.radiusControl),
        border = BorderStroke(
            SmileDimens.borderWidthThin,
            if (enabled) colour else UseSmileIDSampleTheme.colors.button.disabledBackground,
        ),
        colors = ButtonDefaults.outlinedButtonColors(
            contentColor = colour,
            disabledContentColor = UseSmileIDSampleTheme.colors.button.disabledText,
        ),
    ) {
        Text(
            text = CUSTOM_CANCEL_LABEL,
            style = UseSmileIDSampleTheme.type.buttonFont,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(vertical = SmileDimens.space4),
        )
    }
}

/** The continue slots' content; the SDK's scope decides what the tap does and when it is allowed. */
val useSmileIDSampleCustomContinueSlot: @Composable ButtonSlotScope.() -> Unit = {
    UseSmileIDSampleCustomContinueButton(onClick = onClick, enabled = enabled)
}

/** The cancel slots' content. */
val useSmileIDSampleCustomCancelSlot: @Composable ButtonSlotScope.() -> Unit = {
    UseSmileIDSampleCustomCancelButton(onClick = onClick, enabled = enabled)
}

internal const val CUSTOM_CONTINUE_LABEL = "Custom continue"
internal const val CUSTOM_CANCEL_LABEL = "Custom cancel"
