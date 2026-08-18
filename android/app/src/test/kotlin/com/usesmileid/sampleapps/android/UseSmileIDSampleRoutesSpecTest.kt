package com.usesmileid.sampleapps.android

import com.ramcosta.composedestinations.generated.NavGraphs
import com.ramcosta.composedestinations.generated.destinations.SdkFlowScreenDestination
import com.ramcosta.composedestinations.spec.DestinationSpec
import com.ramcosta.composedestinations.spec.NavGraphSpec
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleDeepLinks
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Asserts the generated destinations against `spec/routes.json`, the four-platform route
 * contract: a renamed parameter or edited URI otherwise kills a deep link with no compile error.
 * Extraction is regex over the raw text: `org.json` is only a stub on this classpath.
 */
class UseSmileIDSampleRoutesSpecTest {

    private val destinationsByName: Map<String, DestinationSpec> by lazy {
        NavGraphs.root.allDestinations().associateBy { it::class.simpleName.orEmpty() }
    }

    private val specRoutes: List<SpecRoute> by lazy {
        spec("routes.json")
            .substringAfter("\"routes\": [")
            .substringBefore("\"automationEntry\"")
            .split("\n    {")
            .drop(1)
            .map { chunk ->
                SpecRoute(
                    id = chunk.required("id"),
                    path = chunk.required("path"),
                    android = chunk.required("android"),
                    args = ARG_OBJECT.findAll(chunk.argsArray()).map { arg ->
                        SpecArg(
                            name = arg.value.required("name"),
                            type = arg.value.required("type"),
                            required = arg.value.required("required") == "true",
                            default = arg.value.optional("default"),
                        )
                    }.toList(),
                )
            }
    }

    @Test
    fun every_spec_route_has_a_destination_registering_its_deep_link() {
        assertTrue("extracted no routes", specRoutes.isNotEmpty())
        for (route in specRoutes) {
            val destination = destinationsByName[route.android]
            assertNotNull("${route.id}: no generated destination named ${route.android}", destination)
            val patterns = destination!!.deepLinks.mapNotNull { it.uriPattern }
            assertTrue(
                "${route.id}: expected ${route.expectedUriPattern()} among $patterns",
                route.expectedUriPattern() in patterns,
            )
        }
    }

    @Test
    fun destination_arguments_match_the_spec_names_and_optionality() {
        for (route in specRoutes) {
            val destination = destinationsByName.getValue(route.android)
            val byName = destination.arguments.associateBy { it.name }
            for (arg in route.args) {
                val named = byName[arg.name]
                assertNotNull("${route.id}: argument '${arg.name}' is not on ${route.android}", named)
                val optional = named!!.argument.isDefaultValuePresent || named.argument.isNullable
                assertEquals("${route.id}.${arg.name}: optionality", !arg.required, optional)
            }
            // A mandatory argument the spec does not declare would break every spec-built URI.
            val required = destination.arguments
                .filter { !it.argument.isDefaultValuePresent && !it.argument.isNullable }
                .map { it.name }
            assertEquals("${route.id}: required arguments", route.args.filter { it.required }.map { it.name }, required)
        }
    }

    /** Parsing is case-insensitive, so a constant reaches its spec id only while they differ by case alone. */
    @Test
    fun the_flow_route_enum_matches_the_spec_values_up_to_case() {
        val routeArg = specRoutes.first { it.id == "sdkFlow" }.args.first { it.name == "route" }
        val specValues = ENUM_VALUES.find(routeArg.type)!!.groupValues[1].split(",")
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
        assertEquals("shell", direction.route.substringAfter("?route=").lowercase())
    }

    @Test
    fun the_only_destinations_outside_the_spec_are_the_dev_allowlist() {
        val bound = specRoutes.map { it.android }.toSet()
        val extras = destinationsByName.keys.filterNot { it in bound }
        assertEquals(listOf("ComponentGalleryScreenDestination"), extras)
    }

    @Test
    fun the_scheme_is_the_android_entry_in_app_identity() {
        val scheme = ANDROID_URL_SCHEME.find(spec("app-identity.json"))!!.groupValues[1]
        assertEquals(scheme, UseSmileIDSampleDeepLinks.SCHEME)
    }

    private fun SpecRoute.expectedUriPattern(): String {
        val path = path.removePrefix("/").replace(PATH_PARAM) { "{${it.groupValues[1]}}" }
        val query = args.filterNot { it.required }.joinToString("&") { "${it.name}={${it.name}}" }
        return UseSmileIDSampleDeepLinks.SCHEME + "://" + path + if (query.isEmpty()) "" else "?$query"
    }

    private data class SpecRoute(val id: String, val path: String, val android: String, val args: List<SpecArg>)
    private data class SpecArg(val name: String, val type: String, val required: Boolean, val default: String?)

    private fun String.argsArray(): String = ARGS_ARRAY.find(this)?.groupValues?.get(1).orEmpty()
    private fun String.required(key: String): String =
        requireNotNull(optional(key)) { "no \"$key\" in route chunk:\n$this" }
    private fun String.optional(key: String): String? {
        val match = Regex("\"$key\"\\s*:\\s*(?:\"([^\"]*)\"|([A-Za-z0-9._-]+))").find(this) ?: return null
        return match.groupValues[1].ifEmpty { match.groupValues[2] }.ifEmpty { null }
    }

    private fun NavGraphSpec.allDestinations(): List<DestinationSpec> =
        destinations + nestedNavGraphs.flatMap { it.allDestinations() }

    private fun spec(name: String): String {
        val dir = requireNotNull(System.getProperty("sampleapps.spec.dir")) {
            "sampleapps.spec.dir is not set; see app/build.gradle.kts"
        }
        val file = File(dir, name)
        assertTrue("spec/$name not found at ${file.absolutePath}", file.isFile)
        return file.readText()
    }

    private companion object {
        val PATH_PARAM = Regex(":([A-Za-z]+)")
        val ARGS_ARRAY = Regex("\"args\"\\s*:\\s*\\[([\\s\\S]*?)\\]")
        val ARG_OBJECT = Regex("\\{[^}]*\\}")
        val ENUM_VALUES = Regex("enum\\(([^)]*)\\)")
        val ANDROID_URL_SCHEME = Regex("\"platform\"\\s*:\\s*\"android\"[\\s\\S]*?\"urlScheme\"\\s*:\\s*\"([^\"]+)\"")
    }
}
