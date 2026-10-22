package com.usesmileid.sampleapps.android

import com.usesmileid.njia.NjiaKit
import com.usesmileid.njia.NjiaPresentation
import com.usesmileid.njia.decodeGraph
import com.usesmileid.njia.stepOf
import com.usesmileid.njia.steps
import com.usesmileid.sampleapps.android.navigation.USE_SMILE_ID_SAMPLE_NJIA_GRAPH
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleDeepLinks
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleFact
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleNjiaCodec
import com.usesmileid.sampleapps.android.navigation.UseSmileIDSampleStep
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Asserts the app's links against `spec/routes.json`, the four-platform route contract, through
 * `spec/njia-graph.json`: a renamed path or step otherwise kills a deep link with no compile error.
 * Values are extracted with a bracket-depth scan plus key regexes: `org.json` is only a stub here.
 */
class UseSmileIDSampleRoutesSpecTest {

    private val graph by lazy { UseSmileIDSampleNjiaCodec.decodeGraph(spec(USE_SMILE_ID_SAMPLE_NJIA_GRAPH)) }

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
    fun every_spec_askedis_the_graph_step_the_android_column_names_linked_at_its_path() {
        for (route in specRoutes) {
            val step = graph.steps.firstOrNull { it.id == route.id }
            assertNotNull("${route.id}: no step in the graph", step)
            assertEquals("${route.id}: link", route.path.removePrefix("/"), step!!.link)
            assertEquals("${route.id}: android", "UseSmileIDSampleStep.${step.kind.name}", route.android.substringBefore(KIND_SEPARATOR))
        }
    }

    @Test
    fun every_step_id_is_its_kind_wire_name() {
        for (step in graph.steps) assertEquals(step.kind.wireName, step.id)
    }

    @Test
    fun a_spec_sheet_is_a_sheet_step_and_nothing_else_is() {
        for (route in specRoutes) {
            val sheet = graph.steps.first { it.id == route.id }.presentation == NjiaPresentation.Sheet
            assertEquals("${route.id}: sheet", route.isSheet, sheet)
        }
    }

    /** Every link opens at its own step, with the stack a user would have had, once its product's facts are set. */
    @Test
    fun every_spec_link_opens_at_its_step() {
        for (route in specRoutes) {
            val link = requireNotNull(UseSmileIDSampleDeepLinks.linkOf(route.sampleUri())) { "${route.id}: no link" }
            val asked = link.route ?: UseSmileIDSampleFlowRoute.Shell
            val engine = requireNotNull(NjiaKit.openLink(graph, link.path, factsFor(asked))) { "${route.id}: ${link.path} opened nothing" }
            val expected = if (route.id == RUN && asked == UseSmileIDSampleFlowRoute.Fullscreen) UseSmileIDSampleStep.SdkFlowFullScreen.wireName else route.id
            assertEquals("${route.id}: top", expected, engine.state.entries.last().step)
        }
    }

    /** One URI, two presentations: the run opens full screen unless its `route` asks for the shell. */
    @Test
    fun the_run_link_opens_full_screen_unless_it_asks_for_the_shell() {
        val run = specRoutes.first { it.id == RUN }
        assertEquals(UseSmileIDSampleFlowRoute.Fullscreen, UseSmileIDSampleDeepLinks.linkOf(run.sampleUri())?.route)
        val shell = UseSmileIDSampleDeepLinks.linkOf(run.sampleUri() + "?route=shell&probes=true")
        assertEquals(UseSmileIDSampleFlowRoute.Shell, shell?.route)
        val engine = requireNotNull(NjiaKit.openLink(graph, shell!!.path, factsFor(UseSmileIDSampleFlowRoute.Shell)))
        assertEquals(UseSmileIDSampleStep.SdkFlow, graph.stepOf(engine.state.entries.last()).kind)
    }

    /** Parsing is case-insensitive, so a constant reaches its spec id only while they differ by case alone. */
    @Test
    fun the_flow_askedenum_matches_the_spec_values_up_to_case() {
        val routeArg = specRoutes.first { it.id == RUN }.args.first { it.name == "route" }
        val specValues = requireNotNull(ENUM_VALUES.find(routeArg.type)) {
            "sdkFlow.route type is not enum(...): ${routeArg.type}"
        }.groupValues[1].split(",")
        assertEquals(specValues, UseSmileIDSampleFlowRoute.entries.map { it.id })
        for (entry in UseSmileIDSampleFlowRoute.entries) {
            assertEquals("constant ${entry.name} must be its id up to case", entry.id, entry.name.lowercase())
        }
        assertEquals("spec default", routeArg.default, UseSmileIDSampleFlowRoute.Fullscreen.id)
    }

    /** The graph's one link outside the spec is the run's full-screen form; the dev gallery is in neither. */
    @Test
    fun the_only_links_outside_the_spec_are_the_full_screen_run() {
        val spec = specRoutes.map { it.path.removePrefix("/") }.toSet()
        assertEquals(listOf("flow/:productId/run-fullscreen"), graph.steps.mapNotNull { it.link }.filterNot { it in spec })
        assertNull(UseSmileIDSampleDeepLinks.linkOf(UseSmileIDSampleDeepLinks.COMPONENT_GALLERY))
        assertNull(UseSmileIDSampleDeepLinks.linkOf("another-scheme://products"))
    }

    /** Every fact a link might need: the run's forms all shown, on [route]. */
    private fun factsFor(route: UseSmileIDSampleFlowRoute): Set<UseSmileIDSampleFact> =
        setOf(UseSmileIDSampleFact.NeedsUserId, UseSmileIDSampleFact.NeedsIdDetails) +
            if (route == UseSmileIDSampleFlowRoute.Fullscreen) setOf(UseSmileIDSampleFact.FullScreenRun) else emptySet()

    /** The route's path under this app's scheme, each parameter filled with a sample value. */
    private fun SpecRoute.sampleUri(): String =
        UseSmileIDSampleDeepLinks.SCHEME + "://" + path.removePrefix("/").replace(PATH_PARAM) { "sample-${it.groupValues[1]}" }

    @Test
    fun the_scheme_is_the_android_entry_in_app_identity() {
        val entry = androidIdentity(if (BuildConfig.SOURCE_MODE) "sourceMode" else "apps")
        assertEquals(entry.required("urlScheme"), BuildConfig.URL_SCHEME)
        assertEquals(BuildConfig.URL_SCHEME, UseSmileIDSampleDeepLinks.SCHEME)
    }

    @Test
    fun the_application_id_is_the_android_entry_in_app_identity() {
        val entry = androidIdentity(if (BuildConfig.SOURCE_MODE) "sourceMode" else "apps")
        val suffix = if (BuildConfig.DEBUG) entry.optional("debugSuffix").orEmpty() else ""
        assertEquals(entry.required("applicationId") + suffix, BuildConfig.APPLICATION_ID)
    }

    /** A source build installs beside the store app, so it claims none of the registry schemes. */
    @Test
    fun source_mode_schemes_are_distinct_from_every_registry_scheme() {
        val identity = spec("app-identity.json")
        val registry = identity.jsonArrayObjects("apps").map { it.required("urlScheme") }.toSet()
        val source = identity.jsonArrayObjects("sourceMode").mapNotNull { it.optional("urlScheme") }
        assertTrue("no source-mode schemes in spec/app-identity.json", source.isNotEmpty())
        source.forEach { assertTrue("$it is also a registry scheme", it !in registry) }
    }

    /** The launcher label is a second copy of the spec's display name, and both stores list under it. */
    @Test
    fun the_launcher_label_is_the_android_entry_in_app_identity() {
        val entry = androidIdentity("apps")
        val strings = File(specDir(), "../android/app/src/main/res/values/strings.xml").readText()
        val label = requireNotNull(Regex("<string name=\"app_name\"[^>]*>([^<]+)</string>").find(strings)) {
            "no app_name in strings.xml"
        }.groupValues[1]
        assertEquals(label, entry.required("displayName"))
    }

    /** The intent filter and label take the build's identity, the same value BuildConfig carries. */
    @Test
    fun the_manifest_takes_its_scheme_and_label_from_the_build() {
        val manifest = File(specDir(), "../android/app/src/main/AndroidManifest.xml").readText()
        assertTrue("the intent filter hard-codes its scheme", "android:scheme=\"\${usesmileidSampleScheme}\"" in manifest)
        assertTrue("the launcher label is hard-coded", "android:label=\"\${usesmileidSampleLabel}\"" in manifest)
    }

    private data class SpecRoute(
        val id: String,
        val path: String,
        val presentation: String,
        val android: String,
        val args: List<SpecArg>,
    ) {
        val isSheet: Boolean get() = presentation.endsWith("Sheet")
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

    private fun androidIdentity(block: String): String =
        spec("app-identity.json").jsonArrayObjects(block).firstOrNull { it.optional("platform") == "android" }
            ?: error("no android entry under \"$block\" in spec/app-identity.json")

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
        /** How `spec/routes.json` joins the run's two step kinds, one per presentation. */
        const val KIND_SEPARATOR = " | "
        const val RUN = "sdkFlow"
        val PATH_PARAM = Regex(":([A-Za-z][A-Za-z0-9]*)")
        val ENUM_VALUES = Regex("enum\\(([^)]*)\\)")
    }
}
