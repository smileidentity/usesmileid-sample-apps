package com.usesmileid.sampleapps.ui

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleHoldCamera
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleLaunchArgs
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class UseSmileIDSampleLaunchArgsSpecTest {

    private val specArgs: List<Pair<String, String?>> by lazy {
        NAME_AND_DEFAULT.findAll(spec("launch-args.json"))
            .map { it.groupValues[1] to it.groupValues[2].takeIf { raw -> raw != "null" }?.trim('"') }
            .toList()
    }

    @Test
    fun the_canonical_names_match_the_spec() {
        assertTrue("extracted no launch arguments", specArgs.isNotEmpty())
        assertEquals(specArgs.map { it.first }, UseSmileIDSampleLaunchArgs.names)
    }

    @Test
    fun the_defaults_match_the_spec() {
        val defaults = UseSmileIDSampleLaunchArgs()
        assertEquals(
            specArgs.toMap(),
            mapOf(
                UseSmileIDSampleLaunchArgs.SCENARIO to defaults.scenario.id,
                UseSmileIDSampleLaunchArgs.THEME to defaults.theme.id,
                UseSmileIDSampleLaunchArgs.ROUTE to defaults.route.id,
                UseSmileIDSampleLaunchArgs.AUTOSTART to defaults.autostart?.id,
                UseSmileIDSampleLaunchArgs.SANDBOX to defaults.sandbox?.toString(),
                UseSmileIDSampleLaunchArgs.SEED_JOBS to defaults.seedJobs.toString(),
                UseSmileIDSampleLaunchArgs.APP_LOCALE to defaults.appLocale,
                UseSmileIDSampleLaunchArgs.HOLD_CAMERA to defaults.holdCamera?.toString(),
            ),
        )
    }

    @Test
    fun an_empty_launch_is_the_declared_defaults() {
        assertEquals(UseSmileIDSampleLaunchArgs(), UseSmileIDSampleLaunchArgs.from(emptyMap()))
    }

    @Test
    fun every_argument_is_read_from_its_canonical_name() {
        val args = UseSmileIDSampleLaunchArgs.from(
            mapOf(
                UseSmileIDSampleLaunchArgs.SCENARIO to "expiredToken",
                UseSmileIDSampleLaunchArgs.THEME to "clashingHost",
                UseSmileIDSampleLaunchArgs.ROUTE to "shell",
                UseSmileIDSampleLaunchArgs.AUTOSTART to "biometricKyc",
                UseSmileIDSampleLaunchArgs.SANDBOX to "false",
                UseSmileIDSampleLaunchArgs.APP_LOCALE to "fr-FR",
                UseSmileIDSampleLaunchArgs.HOLD_CAMERA to "keep",
            ),
        )
        assertEquals(UseSmileIDSampleScenario.ExpiredToken, args.scenario)
        assertEquals(UseSmileIDSampleFlowRoute.Shell, args.route)
        assertEquals(UseSmileIDSampleProduct.BiometricKyc, args.autostart)
        assertEquals(false, args.sandbox)
        assertEquals("fr-FR", args.appLocale)
        assertEquals(UseSmileIDSampleHoldCamera.Keep, args.holdCamera)
    }

    /** Unset, not `true`: the Settings toggle owns the environment where no argument was passed. */
    @Test
    fun an_absent_sandbox_argument_stays_unset() {
        assertNull(UseSmileIDSampleLaunchArgs.from(emptyMap()).sandbox)
    }

    @Test
    fun the_sandbox_flag_reads_either_extra_type() {
        assertEquals(false, UseSmileIDSampleLaunchArgs.from(mapOf("sandbox" to false)).sandbox)
        assertEquals(false, UseSmileIDSampleLaunchArgs.from(mapOf("sandbox" to "FALSE")).sandbox)
    }

    @Test
    fun hold_camera_accepts_milliseconds_as_well_as_keep() {
        assertEquals(
            UseSmileIDSampleHoldCamera.Millis(1500),
            UseSmileIDSampleLaunchArgs.from(mapOf("holdCamera" to "1500")).holdCamera,
        )
        assertNull(UseSmileIDSampleLaunchArgs.from(mapOf("holdCamera" to "soon")).holdCamera)
    }

    @Test
    fun an_unrecognised_value_falls_back_to_its_default() {
        val args = UseSmileIDSampleLaunchArgs.from(mapOf("scenario" to "typo", "route" to "sheet"))
        assertEquals(UseSmileIDSampleScenario.Normal, args.scenario)
        assertEquals(UseSmileIDSampleFlowRoute.Fullscreen, args.route)
    }

    private companion object {
        /** Non-greedy to the first `default` after each name, so an arg's own `values` list is skipped. */
        val NAME_AND_DEFAULT =
            Regex("\"name\"\\s*:\\s*\"(\\w+)\"[\\s\\S]*?\"default\"\\s*:\\s*(\"[^\"]*\"|null|true|false)")
    }
}
