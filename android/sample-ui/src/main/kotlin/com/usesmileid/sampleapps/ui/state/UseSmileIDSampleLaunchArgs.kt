package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.Immutable
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario

/** How long the host holds the camera before handing off, so the SDK meets a contended device. */
sealed interface UseSmileIDSampleHoldCamera {
    /** Held for the whole run, so the contention is still in place when the SDK asks for the camera. */
    data object Keep : UseSmileIDSampleHoldCamera

    data class Millis(val value: Long) : UseSmileIDSampleHoldCamera
}

/**
 * The canonical automation arguments from `spec/launch-args.json`.
 *
 * The names are identical on all four platforms and only the delivery mechanism differs, so parsing
 * lives here and reading an `Intent` stays the shell's job.
 */
@Immutable
data class UseSmileIDSampleLaunchArgs(
    val scenario: UseSmileIDSampleScenario = UseSmileIDSampleScenario.Normal,
    val theme: UseSmileIDSampleThemeScenario = UseSmileIDSampleThemeScenario.BrandDefault,
    val route: UseSmileIDSampleFlowRoute = UseSmileIDSampleFlowRoute.Fullscreen,
    val autostart: UseSmileIDSampleProduct? = null,
    val sandbox: Boolean = true,
    val appLocale: String? = null,
    val holdCamera: UseSmileIDSampleHoldCamera? = null,
) {
    companion object {
        const val SCENARIO = "scenario"
        const val THEME = "theme"
        const val ROUTE = "route"
        const val AUTOSTART = "autostart"
        const val SANDBOX = "sandbox"
        const val APP_LOCALE = "appLocale"
        const val HOLD_CAMERA = "holdCamera"

        /** Asserted against `spec/launch-args.json` by a unit test. */
        val names = listOf(SCENARIO, THEME, ROUTE, AUTOSTART, SANDBOX, APP_LOCALE, HOLD_CAMERA)

        private const val HOLD_CAMERA_KEEP = "keep"

        /**
         * Values arrive as whatever the host's mechanism produced, so each is read leniently and an
         * unrecognised one falls back to its default rather than failing the launch. That is safe
         * only because the result card publishes what the run actually got: a flow asserting on
         * `sample_result_active_scenario` catches the typo that a silent default would hide.
         */
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
                sandbox = raw.boolean(SANDBOX) ?: defaults.sandbox,
                appLocale = raw.string(APP_LOCALE),
                holdCamera = raw.holdCamera(),
            )
        }

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
