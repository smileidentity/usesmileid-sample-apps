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
import com.usesmileid.sampleapps.ui.SampleTestIds
import com.usesmileid.sampleapps.ui.theme.SampleTheme

/** The three destinations the nav bar switches between. The token affordance is not one of them. */
enum class SampleNavItem(val testId: String, val label: String) {
    Products(SampleTestIds.NAV_PRODUCTS, "Products"),
    Verifications(SampleTestIds.NAV_VERIFICATIONS, "Verifications"),
    Settings(SampleTestIds.NAV_SETTINGS, "Settings"),
}

/**
 * A floating pill holding the three tabs, plus a **visually detached** circular token button.
 *
 * The token affordance is modelled separately from the tabs on purpose: it navigates rather than
 * switching tab, and it is what carries the session countdown ring (`TokenRing`, U2).
 *
 * Icons, the countdown ring, elevation and the select-mode hidden state land with the composites
 * (U2); this is the shell's walking skeleton, so it is labels and behaviour only.
 */
@Composable
fun SampleNavBar(
    selected: SampleNavItem,
    onSelect: (SampleNavItem) -> Unit,
    onTokenClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        // The app draws edge to edge, so the bar owns its own bottom inset. Without it the bar
        // sits under the system navigation bar: half-hidden, untappable, and — because the
        // accessibility tree clips to the content view — reported to UI automation with zero
        // bounds, so a flow cannot see it at all. Neither a unit test nor a golden catches that.
        modifier = modifier
            .windowInsetsPadding(WindowInsets.navigationBars)
            .padding(SmileDimens.spacingSm),
        horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Surface(
            shape = RoundedCornerShape(SmileDimens.radiusPill),
            color = SampleTheme.colors.surface,
            border = BorderStroke(SmileDimens.borderWidthHairline, SampleTheme.colors.border),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                SampleNavItem.entries.forEach { item ->
                    NavBarTab(item = item, selected = item == selected, onClick = { onSelect(item) })
                }
            }
        }
        Surface(
            modifier = Modifier.size(SmileDimens.sizeControlMd),
            shape = CircleShape,
            color = SampleTheme.colors.primary,
            contentColor = SampleTheme.colors.onPrimary,
        ) {
            Box(
                modifier = Modifier
                    .testTag(SampleTestIds.NAV_TOKEN)
                    .clickable(onClick = onTokenClick),
                contentAlignment = Alignment.Center,
            ) {
                Text(text = "QR", style = MaterialTheme.typography.labelSmall)
            }
        }
    }
}

@Composable
private fun NavBarTab(item: SampleNavItem, selected: Boolean, onClick: () -> Unit) {
    Text(
        text = item.label,
        style = MaterialTheme.typography.labelLarge,
        color = if (selected) SampleTheme.colors.primary else SampleTheme.colors.textMuted,
        textAlign = TextAlign.Center,
        modifier = Modifier
            .testTag(item.testId)
            .selectable(selected = selected, role = Role.Tab, onClick = onClick)
            .padding(horizontal = SmileDimens.spacingSm, vertical = SmileDimens.spacingSm),
    )
}
