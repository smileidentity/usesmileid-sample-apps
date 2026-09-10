package com.usesmileid.sampleapps.ui.golden

import com.usesmileid.sampleapps.ui.spec
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Every state in `spec/screens.json` has a golden in light and dark, or an exemption saying why it cannot. */
class ScreenStateGoldenTest {

    private val goldens = mapOf(
        "products.default" to "screen_products",
        "products.tokenLinked" to "screen_products_token_linked",
        "products.tokenLinkedLate" to "screen_products_token_linked_late",
        "products.tokenExpired" to "screen_products_token_expired",
        "profileSwitchSheet.default" to "sheet_profile_switch",
        "verifications.default" to "screen_verifications",
        "verifications.selectMode" to "screen_verifications_select",
        "verifications.itemsSelected" to "screen_verifications_selected",
        "verifications.afterDelete" to "screen_verifications_after_delete",
        "verifications.swipeToDelete" to "screen_verifications_swipe_open",
        "verificationDetails.attention" to "screen_verification_details_attention",
        "verificationDetails.clear" to "screen_verification_details_clear",
        "verificationDetails.blocked" to "screen_verification_details_blocked",
        "verificationDetails.processing" to "screen_verification_details_processing",
        "userDetails.empty" to "screen_user_details_empty",
        "userDetails.editing" to "screen_user_details_editing",
        "userDetails.complete" to "screen_user_details_complete",
        "kycIdForm.empty" to "screen_kyc_form_empty",
        "kycIdForm.selected" to "screen_kyc_form_selected",
        "countryPickerSheet.default" to "sheet_country_picker",
        "idTypePickerSheet.default" to "sheet_id_type_picker",
        "settings.default" to "screen_settings",
        "settings.altProfile" to "screen_settings_alt_profile",
        "settings.newlyCreatedProfile" to "screen_settings_new_profile",
        "profiles.default" to "screen_profiles",
        "profiles.created" to "screen_profiles_created",
        "profileConfig.activeProfile" to "screen_profile_config_active",
        "profileConfig.otherProfile" to "screen_profile_config_other",
        "profileConfig.newlyCreated" to "screen_profile_config_new",
        "newProfileSheet.empty" to "sheet_new_profile_empty",
        "newProfileSheet.filled" to "sheet_new_profile_filled",
        "scanToken.default" to "screen_scan_token",
        "scanToken.redirected" to "screen_scan_token_redirected",
        "licenses.default" to "screen_licenses",
        "licenses.empty" to "screen_licenses_empty",
        "scenarioDrawer.flowScenarios" to "sheet_scenario_drawer_flow",
        "scenarioDrawer.themeScenarios" to "sheet_scenario_drawer_theme",
    )

    private val exempt = mapOf(
        "consent.notAgreed" to "the SDK's own screen: this app decides whether the step runs, never draws it",
        "consent.agreed" to "the SDK's own screen: this app decides whether the step runs, never draws it",
        "products.supersededListLayout" to
            "a layout the spec keeps only so nobody rebuilds it; there is no composable to render",
        "verifications.refreshing" to
            "the list has no pull affordance: the gesture is the details screen's and the list's own is deferred",
    )

    @Test
    fun every_spec_state_has_a_golden_or_a_declared_reason() {
        val states = specStates()
        assertTrue("extracted no states from spec/screens.json", states.isNotEmpty())
        assertEquals(
            "spec/screens.json and the golden inventory have drifted: a state with no golden is never seen",
            states,
            goldens.keys + exempt.keys,
        )
    }

    @Test
    fun no_state_is_both_recorded_and_exempt() {
        assertEquals(emptySet<String>(), goldens.keys intersect exempt.keys)
    }

    /** Two states sharing one baseline would leave one of them with no picture of its own. */
    @Test
    fun each_state_has_its_own_golden() {
        assertEquals(goldens.size, goldens.values.toSet().size)
    }

    @Test
    fun every_named_golden_is_recorded_by_a_test() {
        val recorded = goldenNamesInTests()
        assertTrue("parsed no golden names from the golden package", recorded.isNotEmpty())
        assertEquals(emptySet<String>(), goldens.values.toSet() - recorded)
    }

    @Test
    fun every_named_golden_has_a_light_and_a_dark_baseline() {
        val recorded = File(SCREENSHOTS)
        assertTrue("baselines not found at ${recorded.absolutePath}", recorded.isDirectory)
        val missing = goldens.values.flatMap { listOf("${it}_light.png", "${it}_dark.png") }
            .filterNot { File(recorded, it).isFile }
        assertEquals(emptyList<String>(), missing)
    }

    private fun specStates(): Set<String> {
        val json = spec("screens.json")
        val states = mutableSetOf<String>()
        var screen: String? = null
        SCREEN_OR_STATE.findAll(json).forEach { match ->
            val (id, state) = match.destructured
            if (id.isNotEmpty()) screen = id else states += "${requireNotNull(screen)}.$state"
        }
        // A pattern that reads fewer states than the file holds would drop one silently, which is
        // the failure this whole test exists to prevent. Counted against the raw keys, not trusted.
        assertEquals("read fewer states than screens.json holds", STATE_KEY.findAll(json).count(), states.size)
        return states
    }

    /** Every file in the package, not one: splitting a screen's goldens out later must not red this. */
    private fun goldenNamesInTests(): Set<String> {
        val here = File(TESTS)
        assertTrue("golden tests not found at ${here.absolutePath}", here.isDirectory)
        val body = here.walkTopDown().filter { it.extension == "kt" }.joinToString("\n") { it.readText() }
        return GOLDEN_CALL.findAll(body).map { it.groupValues[1] }.toSet()
    }

    private companion object {
        const val SCREENSHOTS = "src/test/screenshots"
        const val TESTS = "src/test/kotlin/com/usesmileid/sampleapps/ui/golden"

        /** A screen id is the only `"id"` followed by `"title"`; states then belong to the last one seen. */
        val SCREEN_OR_STATE =
            Regex("\"id\"\\s*:\\s*\"([^\"]+)\"\\s*,\\s*\"title\"|\"state\"\\s*:\\s*\"([^\"]+)\"")

        /** Counted, so a state the pattern above cannot read is a failure rather than an omission. */
        val STATE_KEY = Regex("\"state\"\\s*:")

        /** Roborazzi names its output from this argument, so a renamed golden is a renamed baseline. */
        val GOLDEN_CALL = Regex("goldens\\(\\s*(?:name\\s*=\\s*)?\"([a-z0-9_]+)\"")
    }
}
