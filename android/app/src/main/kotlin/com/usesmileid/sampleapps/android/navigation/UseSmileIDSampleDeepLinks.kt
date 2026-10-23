package com.usesmileid.sampleapps.android.navigation

import com.usesmileid.sampleapps.android.BuildConfig
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute

/** A deep link as the graph reads it: the [path] it opens and, for the run, the [route] it asked for. */
internal data class UseSmileIDSampleLink(val path: String, val route: UseSmileIDSampleFlowRoute?)

/** The app's URIs: paths are shared across the four apps and are `spec/njia-graph.json`'s links; the scheme is per app. */
internal object UseSmileIDSampleDeepLinks {
    const val SCHEME = BuildConfig.URL_SCHEME
    private const val GALLERY = "debug/components"

    /** Dev-only, so in neither `spec/routes.json` nor the graph; still linkable, because reaching it cold is how a flow drives it. */
    const val COMPONENT_GALLERY = "$SCHEME://$GALLERY"

    /** The graph link [uri] opens, or null for one outside this app's scheme or the dev gallery. */
    fun linkOf(uri: String, scheme: String = SCHEME): UseSmileIDSampleLink? {
        val prefix = "$scheme://"
        if (!uri.startsWith(prefix)) return null
        val path = uri.removePrefix(prefix).substringBefore('#').substringBefore('?').trimEnd('/')
        if (path.isEmpty() || path == GALLERY) return null
        val segments = path.split('/')
        if (segments.size != RUN_SEGMENTS || segments[0] != FLOW || segments[2] != RUN) return UseSmileIDSampleLink(path, route = null)
        val asked = queryOf(uri)[ROUTE]
        // One URI, two presentations: `spec/routes.json` defaults the run to full screen, which the graph names apart.
        val route = UseSmileIDSampleFlowRoute.entries.firstOrNull { it.id == asked } ?: UseSmileIDSampleFlowRoute.Fullscreen
        return UseSmileIDSampleLink(if (route == UseSmileIDSampleFlowRoute.Fullscreen) "$path$FULL_SCREEN" else path, route)
    }

    /** The product a `flow/…` link runs, as its second segment names it. */
    fun productIdOf(link: UseSmileIDSampleLink): String? =
        link.path.split('/').takeIf { it.size >= 2 && it[0] == FLOW }?.get(1)

    private fun queryOf(uri: String): Map<String, String> =
        uri.substringAfter('?', "").substringBefore('#').split('&').filter { '=' in it }.associate { it.substringBefore('=') to it.substringAfter('=') }

    private const val FLOW = "flow"
    private const val RUN = "run"
    private const val ROUTE = "route"
    private const val RUN_SEGMENTS = 3
    private const val FULL_SCREEN = "-fullscreen"
}
