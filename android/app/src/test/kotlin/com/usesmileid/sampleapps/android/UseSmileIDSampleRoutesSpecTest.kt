package com.usesmileid.sampleapps.android

import com.ramcosta.composedestinations.generated.NavGraphs
import com.ramcosta.composedestinations.generated.destinations.SdkFlowScreenDestination
import com.ramcosta.composedestinations.spec.DestinationSpec
import com.ramcosta.composedestinations.spec.NavGraphSpec
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleDeepLinks
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleSheetLinks
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Asserts the generated destinations against `spec/routes.json`, the four-platform route
 * contract: a renamed parameter or edited URI otherwise kills a deep link with no compile error.
 * Values are extracted with a bracket-depth scan plus key regexes: `org.json` is only a stub here.
 */
class UseSmileIDSampleRoutesSpecTest {

    private val destinationsByName: Map<String, DestinationSpec> by lazy {
        NavGraphs.root.allDestinations().associateBy { it::class.simpleName.orEmpty() }
    }

    private val specRoutes: List<SpecRoute> by lazy {
        val routes = spec("routes.json").jsonArrayObjects("routes").map { chunk ->
            SpecRoute(
                id = chunk.required("id"),
                path = chunk.required("path"),
                presentation = chunk.required("presentation"),
                android = chunk.required("android"),
                args = chunk.jsonArrayObjects("args").map { arg ->
                    SpecArg(
                        name = arg.required("name"),
                        type = arg.required("type"),
                        required = arg.required("required") == "true",
                        default = arg.optional("default"),
                    )
                },
            )
        }
        // Guarded here, not in one test, so no consumer can pass vacuously on a parse miss.
        check(routes.isNotEmpty()) { "extracted no routes from spec/routes.json" }
        routes
    }

    @Test
    fun every_spec_route_has_a_destination_registering_exactly_its_deep_link() {
        for (route in specRoutes.filterNot { it.isSheet }) {
            val destination = destinationsByName[route.destination]
            assertNotNull("${route.id}: no generated destination named ${route.destination}", destination)
            // Exact, not inclusion: an extra pattern is a second claim on the route, possibly
            // under a scheme app-identity.json reserves.
            assertEquals(
                "${route.id}: deep links",
                listOf(route.expectedUriPattern()),
                destination!!.deepLinks.mapNotNull { it.uriPattern },
            )
        }
    }

    /**
     * R12: a sheet is a layer, so its path must resolve to the OWNER's link plus the sheet, and no
     * destination may claim the path itself — re-adding one is what left the scrim covering nothing.
     */
    @Test
    fun every_sheet_route_resolves_to_its_owner_and_no_destination_claims_it() {
        val sheets = specRoutes.filter { it.isSheet }
        check(sheets.isNotEmpty()) { "no sheet routes extracted from spec/routes.json" }
        for (route in sheets) {
            val uri = route.expectedUriPattern()
            val link = requireNotNull(UseSmileIDSampleSheetLinks.resolve(uri)) { "${route.id}: $uri resolves to no sheet" }
            assertEquals("${route.id}: sheet", route.sheet, "UseSmileIDSampleSheet." + link.sheet.name)
            val owner = specRoutes.first { it.destination == route.destination && !it.isSheet }
            assertEquals("${route.id}: owner link", owner.expectedUriPattern(), link.ownerUri)
            assertNotNull("${route.id}: no destination named ${route.destination}", destinationsByName[route.destination])
            val claimed = destinationsByName.filterValues { spec -> spec.deepLinks.any { it.uriPattern == uri } }
            assertEquals("${route.id}: destinations claiming the sheet path", emptySet<String>(), claimed.keys)
        }
    }

    /** The other side of the resolver: it must not swallow a route the graph owns, with or without a query. */
    @Test
    fun the_sheet_resolver_leaves_every_other_route_to_the_graph() {
        for (route in specRoutes.filterNot { it.isSheet }) {
            assertNull("${route.id} is not a sheet", UseSmileIDSampleSheetLinks.resolve(route.expectedUriPattern()))
        }
        // launch-args.yaml opens the drawer with ?probes=true, which the launch args read off the intent.
        val drawer = specRoutes.first { it.id == "scenarioDrawer" }
        assertNotNull(UseSmileIDSampleSheetLinks.resolve(drawer.expectedUriPattern() + "?probes=true"))
    }

    @Test
    fun destination_arguments_match_the_spec_names_and_optionality() {
        for (route in specRoutes) {
            val destination = destinationsByName.getValue(route.destination)
            // Set equality both ways: even an optional Android-only argument drifts the
            // four-platform contract, because it becomes real query-param surface.
            assertEquals(
                "${route.id}: argument names",
                route.args.map { it.name }.toSet(),
                destination.arguments.map { it.name }.toSet(),
            )
            val byName = destination.arguments.associateBy { it.name }
            for (arg in route.args) {
                val named = byName.getValue(arg.name)
                val optional = named.argument.isDefaultValuePresent || named.argument.isNullable
                assertEquals("${route.id}.${arg.name}: optionality", !arg.required, optional)
            }
        }
    }

    /** Parsing is case-insensitive, so a constant reaches its spec id only while they differ by case alone. */
    @Test
    fun the_flow_route_enum_matches_the_spec_values_up_to_case() {
        val routeArg = specRoutes.first { it.id == "sdkFlow" }.args.first { it.name == "route" }
        val specValues = requireNotNull(ENUM_VALUES.find(routeArg.type)) {
            "sdkFlow.route type is not enum(...): ${routeArg.type}"
        }.groupValues[1].split(",")
        assertEquals(specValues, UseSmileIDSampleFlowRoute.entries.map { it.id })
        for (entry in UseSmileIDSampleFlowRoute.entries) {
            assertEquals("constant ${entry.name} must be its id up to case", entry.id, entry.name.lowercase())
        }
        assertEquals("spec default", routeArg.default, UseSmileIDSampleFlowRoute.Fullscreen.id)
        val generatedDefault = SdkFlowScreenDestination.arguments.first { it.name == "route" }.argument.defaultValue
        assertEquals(UseSmileIDSampleFlowRoute.Fullscreen, generatedDefault)
    }

    @Test
    fun a_direction_the_app_builds_stays_within_the_spec_values() {
        val direction = SdkFlowScreenDestination(productId = "biometricKyc", route = UseSmileIDSampleFlowRoute.Shell)
        assertEquals("shell", direction.route.substringAfter("?route=").substringBefore("&").lowercase())
    }

    @Test
    fun the_only_destinations_outside_the_spec_are_the_dev_allowlist() {
        val bound = specRoutes.map { it.destination }.toSet()
        val extras = destinationsByName.keys.filterNot { it in bound }.sorted()
        assertEquals(listOf("ComponentGalleryScreenDestination"), extras)
    }

    @Test
    fun the_scheme_is_the_android_entry_in_app_identity() {
        val entry = requireNotNull(ANDROID_APP_ENTRY.find(spec("app-identity.json"))) {
            "no flat android app entry in spec/app-identity.json"
        }.value
        assertEquals(UseSmileIDSampleDeepLinks.SCHEME, entry.required("urlScheme"))
    }

    /** The intent filter is a third copy of the scheme; drift there kills every deep link at the OS. */
    @Test
    fun the_manifest_intent_filter_claims_the_same_scheme() {
        val manifest = File(specDir(), "../android/app/src/main/AndroidManifest.xml").readText()
        val scheme = requireNotNull(Regex("android:scheme=\"([^\"]+)\"").find(manifest)) {
            "no android:scheme in AndroidManifest.xml"
        }.groupValues[1]
        assertEquals(UseSmileIDSampleDeepLinks.SCHEME, scheme)
    }

    private fun SpecRoute.expectedUriPattern(): String {
        val path = path.removePrefix("/").replace(PATH_PARAM) { "{${it.groupValues[1]}}" }
        val query = args.filterNot { it.required }.joinToString("&") { "${it.name}={${it.name}}" }
        return UseSmileIDSampleDeepLinks.SCHEME + "://" + path + if (query.isEmpty()) "" else "?$query"
    }

    private data class SpecRoute(
        val id: String,
        val path: String,
        val presentation: String,
        val android: String,
        val args: List<SpecArg>,
    ) {
        /** A sheet's cell names the destination that owns it and the sheet it opens; every other route names its own. */
        val isSheet: Boolean get() = presentation.endsWith("Sheet")
        val destination: String get() = android.substringBefore(SHEET_SEPARATOR)
        val sheet: String get() = android.substringAfter(SHEET_SEPARATOR, missingDelimiterValue = "")
    }
    private data class SpecArg(val name: String, val type: String, val required: Boolean, val default: String?)

    /** The objects of the named array, by bracket depth with string awareness, so neither nesting nor a reformat can silently truncate. */
    private fun String.jsonArrayObjects(key: String): List<String> {
        val keyAt = indexOf("\"$key\"")
        require(keyAt >= 0) { "no \"$key\" in:\n${take(200)}" }
        val open = indexOf('[', keyAt)
        require(open >= 0) { "\"$key\" is not an array" }
        val objects = mutableListOf<String>()
        var depth = 0
        var inString = false
        var escaped = false
        var objStart = -1
        for (i in open until length) {
            val c = this[i]
            when {
                escaped -> escaped = false
                c == '\\' && inString -> escaped = true
                c == '"' -> inString = !inString
                inString -> {}
                c == '{' || c == '[' -> {
                    if (depth == 1 && c == '{') objStart = i
                    depth++
                }
                c == '}' || c == ']' -> {
                    depth--
                    if (depth == 1 && c == '}') objects += substring(objStart, i + 1)
                    if (depth == 0) return objects
                }
            }
        }
        error("unterminated \"$key\" array")
    }

    private fun String.required(key: String): String =
        requireNotNull(optional(key)) { "no \"$key\" in:\n$this" }

    private fun String.optional(key: String): String? {
        val match = Regex("\"$key\"\\s*:\\s*(?:\"([^\"]*)\"|([A-Za-z0-9._-]+))").find(this) ?: return null
        return match.groupValues[1].ifEmpty { match.groupValues[2] }.ifEmpty { null }
    }

    private fun NavGraphSpec.allDestinations(): List<DestinationSpec> =
        destinations + nestedNavGraphs.flatMap { it.allDestinations() }

    private fun specDir(): File = File(
        requireNotNull(System.getProperty("sampleapps.spec.dir")) {
            "sampleapps.spec.dir is not set; see app/build.gradle.kts"
        },
    )

    private fun spec(name: String): String {
        val file = File(specDir(), name)
        assertTrue("spec/$name not found at ${file.absolutePath}", file.isFile)
        return file.readText()
    }

    private companion object {
        /** How `spec/routes.json` joins a sheet's owning destination to the sheet it opens. */
        const val SHEET_SEPARATOR = " + "
        val PATH_PARAM = Regex(":([A-Za-z][A-Za-z0-9]*)")
        val ENUM_VALUES = Regex("enum\\(([^)]*)\\)")
        /** Bounded to one flat object so the match cannot walk into a neighbouring entry's scheme. */
        val ANDROID_APP_ENTRY = Regex("\\{[^{}]*\"platform\"\\s*:\\s*\"android\"[^{}]*\\}")
    }
}
