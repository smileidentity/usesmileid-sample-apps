package com.usesmileid.sampleapps.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextAlign
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** The three destinations the nav bar switches between. The token affordance is not one of them. */
enum class UseSmileIDSampleNavItem(val testId: String, val label: String) {
    Products(UseSmileIDSampleTestIds.NAV_PRODUCTS, "Products"),
    Verifications(UseSmileIDSampleTestIds.NAV_VERIFICATIONS, "Verifications"),
    Settings(UseSmileIDSampleTestIds.NAV_SETTINGS, "Settings"),
}

/**
 * A floating pill holding the three tabs, plus a visually detached circular token button. The
 * token affordance is modelled separately because it navigates rather than switching tab, and it
 * is what will carry the session countdown ring.
 */
@Composable
fun UseSmileIDSampleNavBar(
    selected: UseSmileIDSampleNavItem,
    onSelect: (UseSmileIDSampleNavItem) -> Unit,
    onTokenClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        // The app draws edge to edge, so the bar owns its bottom inset. Without it the bar sits
        // under the system navigation bar and reports zero bounds to UI automation.
        modifier = modifier
            .windowInsetsPadding(WindowInsets.navigationBars)
            .padding(SmileDimens.spacingSm),
        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Surface(
            shape = RoundedCornerShape(SmileDimens.radiusPill),
            color = UseSmileIDSampleTheme.colors.surface,
            border = BorderStroke(SmileDimens.borderWidthHairline, UseSmileIDSampleTheme.colors.border),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                UseSmileIDSampleNavItem.entries.forEach { item ->
                    NavBarTab(item = item, selected = item == selected, onClick = { onSelect(item) })
                }
            }
        }
        Surface(
            modifier = Modifier.size(SmileDimens.sizeControlMd),
            shape = CircleShape,
            color = UseSmileIDSampleTheme.colors.primary,
            contentColor = UseSmileIDSampleTheme.colors.onPrimary,
        ) {
            Box(
                modifier = Modifier
                    .testTag(UseSmileIDSampleTestIds.NAV_TOKEN)
                    .clickable(onClick = onTokenClick),
                contentAlignment = Alignment.Center,
            ) {
                Text(text = "QR", style = MaterialTheme.typography.labelSmall)
            }
        }
    }
}

@Composable
private fun NavBarTab(item: UseSmileIDSampleNavItem, selected: Boolean, onClick: () -> Unit) {
    Text(
        text = item.label,
        style = MaterialTheme.typography.labelLarge,
        color = if (selected) UseSmileIDSampleTheme.colors.primary else UseSmileIDSampleTheme.colors.textMuted,
        textAlign = TextAlign.Center,
        modifier = Modifier
            .testTag(item.testId)
            .selectable(selected = selected, role = Role.Tab, onClick = onClick)
            .padding(horizontal = SmileDimens.spacingSm, vertical = SmileDimens.spacingSm),
    )
}
