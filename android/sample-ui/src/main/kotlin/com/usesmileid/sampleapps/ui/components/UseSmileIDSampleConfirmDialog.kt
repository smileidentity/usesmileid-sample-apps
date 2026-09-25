package com.usesmileid.sampleapps.ui.components

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The platform's own alert, asking before an action that deletes something; the confirm action is destructive. */
@Composable
fun UseSmileIDSampleConfirmDialog(
    title: String,
    text: String,
    confirmLabel: String,
    confirmTestId: String,
    onConfirm: () -> Unit,
    onDismissRequest: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismissRequest,
        modifier = Modifier.publishTestTags(),
        title = { Text(title) },
        text = { Text(text) },
        confirmButton = {
            TextButton(onClick = onConfirm, modifier = Modifier.testTag(confirmTestId)) {
                Text(confirmLabel, color = UseSmileIDSampleTheme.colors.badge.errorText)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismissRequest) { Text("Cancel") }
        },
    )
}
