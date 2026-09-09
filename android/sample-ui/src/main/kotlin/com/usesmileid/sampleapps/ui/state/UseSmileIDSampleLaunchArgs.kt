package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.Immutable
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario

/** How long the host holds the camera before handing off, so the SDK meets a contended device. */
sealed interface UseSmileIDSampleHoldCamera {
    data object Keep : UseSmileIDSampleHoldCamera

    data class Millis(val value: Long) : UseSmileIDSampleHoldCamera
}

/** Rendered in the argument's own vocabulary, so a report cannot drift from what the parser accepts. */
fun UseSmileIDSampleHoldCamera.describe(): String = when (this) {
    UseSmileIDSampleHoldCamera.Keep -> "holdCamera=${UseSmileIDSampleLaunchArgs.HOLD_CAMERA_KEEP}"
    is UseSmileIDSampleHoldCamera.Millis -> "holdCamera=${value}ms"
}

/** The canonical arguments from `spec/launch-args.json`; reading an Intent is the shell's job. */
@Immutable
data class UseSmileIDSampleLaunchArgs(
    val scenario: UseSmileIDSampleScenario = UseSmileIDSampleScenario.Normal,
    val theme: UseSmileIDSampleThemeScenario = UseSmileIDSampleThemeScenario.BrandDefault,
    val route: UseSmileIDSampleFlowRoute = UseSmileIDSampleFlowRoute.Fullscreen,
    val autostart: UseSmileIDSampleProduct? = null,
    /** Automation precondition only — see `spec/launch-args.json`. */
    val seedJobs: Boolean = false,
    /** The design's three profiles instead of the one empty starter; in memory, so per launch. */
    val seedProfiles: Boolean = false,
    /** Reveals the result card on a release build. Always on in debug, so only a release run needs it. */
    val probes: Boolean = false,
    val appLocale: String? = null,
    val holdCamera: UseSmileIDSampleHoldCamera? = null,
    /** Seconds a transient notice stays — see `spec/launch-args.json`. Automation only. */
    val noticeWindow: Int? = null,
) {
    companion object {
        const val SCENARIO = "scenario"
        const val THEME = "theme"
        const val ROUTE = "route"
        const val AUTOSTART = "autostart"
        const val SEED_JOBS = "seedJobs"
        const val SEED_PROFILES = "seedProfiles"
        const val PROBES = "probes"
        const val APP_LOCALE = "appLocale"
        const val HOLD_CAMERA = "holdCamera"
        const val NOTICE_WINDOW = "noticeWindow"

        val names =
            listOf(SCENARIO, THEME, ROUTE, AUTOSTART, SEED_JOBS, SEED_PROFILES, PROBES, APP_LOCALE, HOLD_CAMERA, NOTICE_WINDOW)

        internal const val HOLD_CAMERA_KEEP = "keep"

        /** An unrecognised value falls back to its default, which is safe only because the card reports it. */
        fun from(raw: Map<String, Any?>): UseSmileIDSampleLaunchArgs {
            val defaults = UseSmileIDSampleLaunchArgs()
            return UseSmileIDSampleLaunchArgs(
                scenario = UseSmileIDSampleScenario.entries.firstOrNull { it.id == raw.string(SCENARIO) }
                    ?: defaults.scenario,
                theme = UseSmileIDSampleThemeScenario.entries.firstOrNull { it.id == raw.string(THEME) }
                    ?: defaults.theme,
                route = UseSmileIDSampleFlowRoute.entries.firstOrNull { it.id == raw.string(ROUTE) }
                    ?: defaults.route,
                autostart = UseSmileIDSampleProduct.entries.firstOrNull { it.id == raw.string(AUTOSTART) },
                seedJobs = raw.boolean(SEED_JOBS) ?: defaults.seedJobs,
                seedProfiles = raw.boolean(SEED_PROFILES) ?: defaults.seedProfiles,
                probes = raw.boolean(PROBES) ?: defaults.probes,
                appLocale = raw.string(APP_LOCALE),
                holdCamera = raw.holdCamera(),
                noticeWindow = raw.noticeWindow(),
            )
        }

        /** Positive seconds; anything else falls back to the product's own window. */
        private fun Map<String, Any?>.noticeWindow(): Int? =
            string(NOTICE_WINDOW)?.toIntOrNull()?.takeIf { it > 0 }

        private fun Map<String, Any?>.string(name: String): String? =
            this[name]?.toString()?.trim()?.takeIf { it.isNotEmpty() }

        /** `am start` sends `--ez` as a Boolean and `-e` as a String, and automation uses both. */
        private fun Map<String, Any?>.boolean(name: String): Boolean? = when (val value = this[name]) {
            is Boolean -> value
            else -> value?.toString()?.trim()?.lowercase()?.toBooleanStrictOrNull()
        }

        private fun Map<String, Any?>.holdCamera(): UseSmileIDSampleHoldCamera? {
            val value = string(HOLD_CAMERA) ?: return null
            if (value.equals(HOLD_CAMERA_KEEP, ignoreCase = true)) return UseSmileIDSampleHoldCamera.Keep
            return value.toLongOrNull()
                ?.takeIf { it > 0 }
                ?.let { UseSmileIDSampleHoldCamera.Millis(it) }
        }
    }
}
