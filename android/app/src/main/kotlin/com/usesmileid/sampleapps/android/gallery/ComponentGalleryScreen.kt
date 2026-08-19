package com.usesmileid.sampleapps.android.gallery

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.Density
import com.smileid.designsystem.SmileDimens
import com.smileid.designsystem.smileProductHues
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.components.ChevronRightGlyph
import com.usesmileid.sampleapps.ui.components.ProductMarkGlyph
import com.usesmileid.sampleapps.ui.components.TorchGlyph
import com.usesmileid.sampleapps.ui.components.TrashGlyph
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleAvatar
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleBottomSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleDataFieldRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleDateGroupHeader
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleDestructiveRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleFilterChip
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleFloatingTokenButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleFullHeightBottomSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleJobRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleKeyValueEditRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleNavBar
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleNavItem
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleOptionRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleProductCard
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleProductGrid
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleProfileEnvChip
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleProfileRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleScanGlyph
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleScanSheet
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleScanSheetState
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSearchField
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionHeader
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSessionCard
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSessionEndedBanner
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSectionLabel
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSelectTrigger
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSelectionBar
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSelectionCheckbox
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRow
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSettingRowChevron
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleStatusBadge
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSwipeAction
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleSwitch
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTextInput
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleToast
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBar
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBarButton
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTopAppBarEmphasis
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme
import kotlinx.coroutines.launch

/** Every primitive and composite in every state. Dev-only, so it belongs to the shell and is deliberately not a `spec/routes.json` entry; `dev_*` ids keep the `sample_*` namespace the spec's. */
const val COMPONENT_GALLERY_TAG = "dev_component_gallery"
const val COMPONENT_GALLERY_FONT_SCALE_TAG = "dev_gallery_font_scale"
const val COMPONENT_GALLERY_ANCHOR_TAG = "dev_gallery_anchor"

/** Android's largest accessibility font scale — the one the no-clipping predicate means. */
private const val MAX_FONT_SCALE = 2f

private enum class GallerySheet { None, Partial, FullHeight }

/**
 * The font-scale toggle is in-app rather than a device setting because some OEM builds refuse
 * `settings put system font_scale`. Its own row sits outside the override it applies, so the
 * controls stay operable at 2x.
 */
@Composable
fun ComponentGalleryScreen() {
    var largeText by rememberSaveable { mutableStateOf(false) }
    val density = LocalDensity.current
    val listState = rememberLazyListState()
    val scope = rememberCoroutineScope()
    val sections = gallerySections()

    Column(modifier = Modifier.fillMaxSize().testTag(COMPONENT_GALLERY_TAG)) {
        Row(
            modifier = Modifier.padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingXs),
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

        // Anchors, so the last of 27 sections is reachable without a long scroll.
        LazyRow(
            modifier = Modifier.padding(bottom = SmileDimens.spacingXs),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = SmileDimens.spacingMd),
            horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
        ) {
            itemsIndexed(sections) { index, section ->
                UseSmileIDSampleFilterChip(
                    label = section.label,
                    count = index + 1,
                    selected = false,
                    onClick = { scope.launch { listState.animateScrollToItem(index) } },
                    testId = "${COMPONENT_GALLERY_ANCHOR_TAG}_${section.label.lowercase()}",
                )
            }
        }

        CompositionLocalProvider(
            LocalDensity provides Density(
                density = density.density,
                fontScale = if (largeText) MAX_FONT_SCALE else 1f,
            ),
        ) {
            LazyColumn(
                state = listState,
                modifier = Modifier.fillMaxSize(),
                contentPadding = androidx.compose.foundation.layout.PaddingValues(SmileDimens.spacingMd),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
            ) {
                itemsIndexed(sections) { _, section ->
                    GallerySection(section.label) { section.content() }
                }
                // Flush with the viewport edge, the last component reports clipped bounds to automation.
                item { Spacer(modifier = Modifier.height(SmileDimens.space64)) }
            }
        }
    }
}

private class GallerySectionSpec(val label: String, val content: @Composable () -> Unit)

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun gallerySections(): List<GallerySectionSpec> {
    var text by rememberSaveable { mutableStateOf("") }
    var query by rememberSaveable { mutableStateOf("") }
    var switched by rememberSaveable { mutableStateOf(true) }
    var firstName by rememberSaveable { mutableStateOf("") }
    var lastName by rememberSaveable { mutableStateOf("Asante") }
    var selectedProfile by rememberSaveable { mutableStateOf(0) }
    var selectedCountry by rememberSaveable { mutableStateOf(1) }
    var selectedFilter by rememberSaveable { mutableStateOf(0) }
    var checked by rememberSaveable { mutableStateOf(false) }
    var selectedCount by rememberSaveable { mutableStateOf(0) }
    var sheet by rememberSaveable { mutableStateOf(GallerySheet.None) }
    var sessionProgress by rememberSaveable { mutableStateOf(0.65f) }
    var swipedAway by rememberSaveable { mutableStateOf(false) }

    if (sheet == GallerySheet.Partial) {
        UseSmileIDSampleBottomSheet(onDismissRequest = { sheet = GallerySheet.None }, title = "Switch profile") {
            UseSmileIDSampleProfileRow(
                organisation = "UpTech Finance",
                supportingText = "Kwame Asante",
                initials = "KA",
                selected = true,
                onClick = {},
            )
            UseSmileIDSampleProfileRow(
                organisation = "Kazi Microlending",
                supportingText = "Amina Diallo",
                initials = "AD",
                selected = false,
                onClick = {},
            )
        }
    }
    if (sheet == GallerySheet.FullHeight) {
        UseSmileIDSampleFullHeightBottomSheet(title = "Country", onDismissRequest = { sheet = GallerySheet.None }) {
            UseSmileIDSampleSearchField(query = query, onQueryChange = { query = it }, placeholder = "Search country")
            COUNTRIES.forEachIndexed { index, (flag, name) ->
                UseSmileIDSampleOptionRow(
                    label = name,
                    selected = index == selectedCountry,
                    onClick = { selectedCountry = index },
                    leadingText = flag,
                )
            }
        }
    }

    return listOf(
        GallerySectionSpec("TYPOGRAPHY") {
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
        },
        GallerySectionSpec("AVATAR") {
            // A Row squeezes the last avatar out of round at 2x instead of wrapping it.
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingSm),
                itemVerticalAlignment = Alignment.CenterVertically,
            ) {
                UseSmileIDSampleAvatar(initials = "HW")
                UseSmileIDSampleAvatar(initials = "KO")
                UseSmileIDSampleAvatar(initials = "")
                UseSmileIDSampleAvatar(initials = "SM", containerColor = UseSmileIDSampleTheme.colors.accent)
            }
        },
        GallerySectionSpec("BUTTON") {
            UseSmileIDSampleButton(text = "Continue", onClick = {})
            UseSmileIDSampleButton(text = "Continue", onClick = {}, enabled = false)
            UseSmileIDSampleButton(text = "Continue", onClick = {}, loading = true)
            UseSmileIDSampleButton(text = "SmartSelfie Authentication and enrolment", onClick = {})
        },
        GallerySectionSpec("TEXT INPUT") {
            UseSmileIDSampleTextInput(value = text, onValueChange = { text = it }, placeholder = "ID number")
            UseSmileIDSampleTextInput(value = "AO12345678", onValueChange = {}, placeholder = "ID number")
            UseSmileIDSampleTextInput(
                value = "12",
                onValueChange = {},
                isError = true,
                errorMessage = "ID number must be 10 characters",
            )
            UseSmileIDSampleTextInput(value = "Locked", onValueChange = {}, enabled = false, placeholder = "ID number")
        },
        GallerySectionSpec("SEARCH FIELD") {
            UseSmileIDSampleSearchField(
                query = query,
                onQueryChange = { query = it },
                placeholder = "Search countries",
            )
            UseSmileIDSampleSearchField(query = "Kenya", onQueryChange = {}, placeholder = "Search countries")
        },
        GallerySectionSpec("SWITCH") {
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
        },
        GallerySectionSpec("STATUS BADGE") {
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
            ) {
                UseSmileIDSampleStatus.entries.forEach { UseSmileIDSampleStatusBadge(status = it) }
            }
        },
        GallerySectionSpec("TOAST") {
            UseSmileIDSampleToast(message = "Verification removed")
            UseSmileIDSampleToast(message = "Verification removed", actionLabel = "Undo", onAction = {})
        },
        GallerySectionSpec("TOP APP BAR") {
            UseSmileIDSampleTopAppBar(title = "Verification details", onBack = {})
            UseSmileIDSampleTopAppBar(title = "Verification details", onBack = {}) {
                UseSmileIDSampleTopAppBarButton(contentDescription = "Delete", onClick = {}) { tint ->
                    TrashGlyph(tint = tint)
                }
            }
            UseSmileIDSampleTopAppBar(title = "Scan token", onBack = {}) {
                UseSmileIDSampleTopAppBarButton(
                    contentDescription = "Torch",
                    onClick = {},
                    emphasis = UseSmileIDSampleTopAppBarEmphasis.Filled,
                ) { tint -> TorchGlyph(tint = tint) }
            }
            UseSmileIDSampleTopAppBar(title = "Enhanced Document Verification", onBack = {})
        },
        GallerySectionSpec("BOTTOM SHEET") {
            UseSmileIDSampleButton(text = "Partial sheet with handle", onClick = { sheet = GallerySheet.Partial })
            UseSmileIDSampleButton(text = "Full-height sheet with header", onClick = { sheet = GallerySheet.FullHeight })
        },
        GallerySectionSpec("DATA FIELD ROW") {
            UseSmileIDSampleDataFieldRow(label = "Created_at", value = "2026-07-16T11:50:12.253Z")
            UseSmileIDSampleDataFieldRow(label = "Job_id", value = "job_01ky31za…", onCopy = {})
            UseSmileIDSampleDataFieldRow(label = "Status", value = "202 Accepted")
            UseSmileIDSampleDataFieldRow(label = "User_id", value = "user_01ky31za…", onCopy = {})
        },
        GallerySectionSpec("KEY VALUE EDIT ROW") {
            UseSmileIDSampleKeyValueEditRow(
                label = "First name",
                value = firstName,
                onValueChange = { firstName = it },
                placeholder = "Add first name",
                required = true,
            )
            UseSmileIDSampleKeyValueEditRow(
                label = "Last name",
                value = lastName,
                onValueChange = { lastName = it },
                required = true,
            )
            UseSmileIDSampleKeyValueEditRow(
                label = "Email (optional)",
                value = "",
                onValueChange = {},
                placeholder = "name@company.com",
            )
            UseSmileIDSampleKeyValueEditRow(
                label = "Country",
                value = "Kenya",
                onValueChange = {},
                enabled = false,
            )
        },
        GallerySectionSpec("SETTING ROW") {
            UseSmileIDSampleSettingRow(
                title = "Smile to capture",
                supportingText = "Passive capture — smile detection",
                leading = { tint -> ProductMarkGlyph(tint = tint) },
                trailing = { UseSmileIDSampleSwitch(checked = switched, onCheckedChange = { switched = it }) },
            )
            UseSmileIDSampleSettingRow(
                title = "Documentation",
                supportingText = "docs.smileidentity.com",
                onClick = {},
                leading = { tint -> ProductMarkGlyph(tint = tint) },
                trailing = { UseSmileIDSampleSettingRowChevron() },
            )
            UseSmileIDSampleSettingRow(
                title = "Terms of Service",
                onClick = {},
                leading = { tint -> ProductMarkGlyph(tint = tint) },
                trailing = { UseSmileIDSampleSettingRowChevron() },
            )
            UseSmileIDSampleDestructiveRow(text = "Sign out", onClick = {})
        },
        GallerySectionSpec("PROFILE ROW") {
            PROFILES.forEachIndexed { index, (org, person, initials) ->
                UseSmileIDSampleProfileRow(
                    organisation = org,
                    supportingText = person,
                    initials = initials,
                    selected = index == selectedProfile,
                    onClick = { selectedProfile = index },
                )
            }
        },
        GallerySectionSpec("OPTION ROW") {
            COUNTRIES.forEachIndexed { index, (flag, name) ->
                UseSmileIDSampleOptionRow(
                    label = name,
                    selected = index == selectedCountry,
                    onClick = { selectedCountry = index },
                    leadingText = flag,
                )
            }
            UseSmileIDSampleOptionRow(label = "National ID", selected = false, onClick = {})
            UseSmileIDSampleOptionRow(label = "Passport", selected = true, onClick = {})
        },
        GallerySectionSpec("SELECT TRIGGER") {
            UseSmileIDSampleSelectTrigger(value = null, placeholder = "Select country", onClick = {})
            UseSmileIDSampleSelectTrigger(value = "Kenya", placeholder = "Select country", onClick = {})
            UseSmileIDSampleSelectTrigger(
                value = null,
                placeholder = "Select ID type",
                onClick = {},
                enabled = false,
            )
            UseSmileIDSampleSelectTrigger(
                value = null,
                placeholder = "Select country",
                onClick = {},
                leading = { tint -> ChevronRightGlyph(tint = tint) },
            )
        },
        GallerySectionSpec("FILTER CHIP") {
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
            ) {
                FILTERS.forEachIndexed { index, (label, count) ->
                    UseSmileIDSampleFilterChip(
                        label = label,
                        count = count,
                        selected = index == selectedFilter,
                        onClick = { selectedFilter = index },
                    )
                }
            }
        },
        GallerySectionSpec("DATE GROUP HEADER") {
            UseSmileIDSampleDateGroupHeader(relative = "TODAY", absolute = "THU, 16 JUL 2026")
            UseSmileIDSampleDateGroupHeader(relative = "YESTERDAY", absolute = "WED, 15 JUL 2026")
        },
        GallerySectionSpec("JOB ROW") {
            UseSmileIDSampleJobRow(
                product = UseSmileIDSampleProduct.SmartSelfieEnrollment,
                jobId = "7d2f01aa…",
                time = "13:03:41",
                status = UseSmileIDSampleStatus.Clear,
                onClick = {},
            )
            UseSmileIDSampleJobRow(
                product = UseSmileIDSampleProduct.EnhancedDocumentVerification,
                jobId = "b6e4d90f…",
                time = "12:36:59",
                status = UseSmileIDSampleStatus.Blocked,
                onClick = {},
            )
            Row(
                horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                UseSmileIDSampleSelectionCheckbox(checked = checked, onCheckedChange = { checked = it })
                UseSmileIDSampleJobRow(
                    product = UseSmileIDSampleProduct.BiometricKyc,
                    jobId = "c41b8a2e…",
                    time = "11:50:12",
                    status = UseSmileIDSampleStatus.Attention,
                )
            }
        },
        GallerySectionSpec("SELECTION CHECKBOX") {
            FlowRow(horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs)) {
                UseSmileIDSampleSelectionCheckbox(checked = checked, onCheckedChange = { checked = it })
                UseSmileIDSampleSelectionCheckbox(checked = !checked, onCheckedChange = { checked = !it })
            }
        },
        GallerySectionSpec("SELECTION BAR") {
            UseSmileIDSampleSelectionBar(
                selectedCount = selectedCount,
                onRemove = { selectedCount = 0 },
            )
            UseSmileIDSampleButton(text = "Select one more", onClick = { selectedCount++ })
        },
        GallerySectionSpec("PRODUCT GRID") {
            val hues = UseSmileIDSampleProduct.entries.mapNotNull { smileProductHues[it.id] }
            UseSmileIDSampleSectionHeader(text = "Authentication")
            UseSmileIDSampleProductGrid(itemCount = PRODUCTS.size) { index ->
                UseSmileIDSampleProductCard(
                    title = PRODUCTS[index],
                    onClick = {},
                    hue = hues[index % hues.size],
                )
            }
            UseSmileIDSampleProductCard(
                title = "Enhanced KYC",
                onClick = {},
                hue = hues.last(),
                enabled = false,
            )
        },
        GallerySectionSpec("PROFILE ENV CHIP") {
            FlowRow(horizontalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs)) {
                UseSmileIDSampleProfileEnvChip(environment = UseSmileIDSampleEnvironment.Sandbox)
                UseSmileIDSampleProfileEnvChip(environment = UseSmileIDSampleEnvironment.Production)
            }
        },
        GallerySectionSpec("NAV BAR AND TOKEN RING") {
            UseSmileIDSampleNavBar(
                selected = UseSmileIDSampleNavItem.Products,
                onSelect = {},
                onTokenClick = {},
            )
            UseSmileIDSampleNavBar(
                selected = UseSmileIDSampleNavItem.Verifications,
                onSelect = {},
                onTokenClick = {},
                sessionProgress = sessionProgress,
            )
            UseSmileIDSampleButton(
                text = "Ring: ${(sessionProgress * 100).toInt()}%",
                onClick = { sessionProgress = if (sessionProgress <= 0f) 1f else sessionProgress - 0.25f },
            )
        },
        GallerySectionSpec("SESSION CARD") {
            UseSmileIDSampleSessionCard(sessionId = "9f3a", remaining = "3:20")
            UseSmileIDSampleSessionEndedBanner(onScan = {})
        },
        GallerySectionSpec("SCAN") {
            Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                UseSmileIDSampleScanGlyph()
            }
            UseSmileIDSampleScanSheet(
                state = UseSmileIDSampleScanSheetState(),
                onTokenChange = {},
                onPaste = {},
                onLink = {},
                onExpandToggle = {},
                onSpanSelect = {},
                onBindingsChange = {},
                onSimulate = {},
            )
            Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.CenterEnd) {
                UseSmileIDSampleFloatingTokenButton(onClick = {})
            }
        },
        GallerySectionSpec("SWIPE ACTION") {
            UseSmileIDSampleSwipeAction(onRemove = { swipedAway = true }) {
                UseSmileIDSampleJobRow(
                    product = UseSmileIDSampleProduct.DocumentVerification,
                    jobId = if (swipedAway) "Removed — tap Reset" else "Swipe me left",
                    time = "13:03:41",
                    status = UseSmileIDSampleStatus.Clear,
                )
            }
            UseSmileIDSampleButton(text = "Reset", onClick = { swipedAway = false })
        },
    )
}

private val PRODUCTS = listOf(
    "SmartSelfie Enrollment",
    "SmartSelfie Authentication",
    "Document Verification",
    "Enhanced Document Verification",
    "Biometric KYC",
)

private val PROFILES = listOf(
    Triple("UpTech Finance", "Kwame Asante", "KA"),
    Triple("Kazi Microlending", "Amina Diallo", "AD"),
    Triple("PesaLink", "Tunde Okafor", "TO"),
)

private val COUNTRIES = listOf(
    "🇳🇬" to "Nigeria",
    "🇰🇪" to "Kenya",
    "🇬🇭" to "Ghana",
    "🇿🇦" to "South Africa",
)

private val FILTERS = listOf("All" to 11, "Clear" to 6, "Attention" to 2, "Blocked" to 2)

@Composable
private fun GallerySection(label: String, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs)) {
        HorizontalDivider(color = UseSmileIDSampleTheme.colors.border)
        UseSmileIDSampleSectionLabel(text = label)
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(SmileDimens.spacingXs),
        ) {
            content()
        }
    }
}
