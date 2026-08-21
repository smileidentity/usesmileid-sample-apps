package com.usesmileid.sampleapps.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.Text
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import com.smileid.designsystem.smileProfileHues
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.ui.UseSmileIDSampleTestIds
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleAvatar
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleIcon
import com.usesmileid.sampleapps.ui.components.hue
import com.usesmileid.sampleapps.ui.components.iconRes
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleProductCard
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleProductGrid
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleProfileEnvChip
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleResultLine
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionHeader
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSessionCard
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSessionEndedBanner
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProductSection
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleResult
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** What the products header and session strip render, so the screen stays free of clock and store. */
data class UseSmileIDSampleProductsState(
    val environment: UseSmileIDSampleEnvironment,
    val initials: String,
    /** The active profile's avatar hue, so every screen showing it agrees. */
    val avatarColor: Color = smileProfileHues.first(),
    val sessionId: String? = null,
    val sessionRemaining: String? = null,
    val sessionEnded: Boolean = false,
    /** Surfaced here only while a flow is in flight; the full card lives on verification details. */
    val result: UseSmileIDSampleResult? = null,
)

/** The products grid, the entry point every flow starts from. */
@Composable
fun ProductsScreen(
    state: UseSmileIDSampleProductsState,
    onProductClick: (UseSmileIDSampleProduct) -> Unit,
    onProfileClick: () -> Unit,
    onScanClick: () -> Unit,
    modifier: Modifier = Modifier,
    contentPadding: PaddingValues = PaddingValues(),
) {
    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .testTag(UseSmileIDSampleTestIds.PRODUCTS_SCREEN)
            .windowInsetsPadding(WindowInsets.statusBars),
        contentPadding = contentPadding,
        verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
    ) {
        item {
            Column(
                modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXxs),
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = "Smile ID",
                        style = UseSmileIDSampleTheme.type.textStyleHeadingPage,
                        color = UseSmileIDSampleTheme.colors.textTitle,
                        modifier = Modifier.weight(1f),
                    )
                    UseSmileIDSampleProfileEnvChip(environment = state.environment)
                    // The chip is display-only; this button owns profile switching.
                    UseSmileIDSampleAvatar(
                        initials = state.initials,
                        containerColor = state.avatarColor,
                        modifier = Modifier
                            .testTag(UseSmileIDSampleTestIds.PROFILE_AVATAR_BUTTON)
                            .minimumInteractiveComponentSize()
                            .clickable(
                                role = Role.Button,
                                onClickLabel = "Switch profile",
                                onClick = onProfileClick,
                            ),
                    )
                }
                Text(
                    text = "Try our suite of products powered by our library",
                    style = UseSmileIDSampleTheme.type.textStyleBodySm,
                    color = UseSmileIDSampleTheme.colors.textMuted,
                )
            }
        }

        val result = state.result
        if (result != null && result.inFlight) {
            item {
                UseSmileIDSampleResultLine(
                    result = result,
                    modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                )
            }
        }

        if (state.sessionEnded) {
            item {
                UseSmileIDSampleSessionEndedBanner(
                    onScan = onScanClick,
                    modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                )
            }
        } else if (state.sessionId != null && state.sessionRemaining != null) {
            item {
                UseSmileIDSampleSessionCard(
                    sessionId = state.sessionId,
                    remaining = state.sessionRemaining,
                    modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                )
            }
        }

        UseSmileIDSampleProductSection.entries.forEach { section ->
            val products = UseSmileIDSampleProduct.of(section)
            item {
                Column(
                    modifier = Modifier.padding(horizontal = SmileDimens.spacingMd),
                    verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                ) {
                    UseSmileIDSampleSectionHeader(text = section.label)
                    UseSmileIDSampleProductGrid(itemCount = products.size) { index ->
                        val product = products[index]
                        val id = product.iconRes
                        UseSmileIDSampleProductCard(
                            title = product.label,
                            onClick = { onProductClick(product) },
                            hue = product.hue,
                            testId = UseSmileIDSampleTestIds.productCard(product.id),
                            icon = id?.let { { tint -> UseSmileIDSampleIcon(id = it, tint = tint) } },
                            ghost = id?.let {
                                { tint -> UseSmileIDSampleIcon(id = it, tint = tint, size = GHOST_SIZE) }
                            },
                        )
                    }
                }
            }
        }

        // Trailing space, so the last card clears the floating nav bar.
        item { Spacer(modifier = Modifier.height(SmileDimens.space64 * 2)) }
    }
}

private val GHOST_SIZE = SmileDimens.space64 + SmileDimens.space4
