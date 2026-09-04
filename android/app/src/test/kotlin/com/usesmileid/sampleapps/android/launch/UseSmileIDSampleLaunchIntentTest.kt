package com.usesmileid.sampleapps.android.launch

import android.content.Intent
import androidx.core.net.toUri
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class UseSmileIDSampleLaunchIntentTest {

    @Test
    fun `a deep link's probes query reaches the launch args`() {
        val intent = Intent(Intent.ACTION_VIEW, "$SCHEME://flow/biometricKyc/run?probes=true".toUri())

        assertTrue(intent.useSmileIDSampleLaunchArgs().probes)
    }

    @Test
    fun `a deep link without the query leaves probes at its default`() {
        val intent = Intent(Intent.ACTION_VIEW, "$SCHEME://flow/biometricKyc/run".toUri())

        assertFalse(intent.useSmileIDSampleLaunchArgs().probes)
    }

    /** An opaque URI has no query to read, and asking one for a parameter throws. */
    @Test
    fun `an opaque uri is skipped rather than parsed`() {
        val intent = Intent(Intent.ACTION_VIEW, "mailto:someone@example.com".toUri())

        assertFalse(intent.useSmileIDSampleLaunchArgs().probes)
    }

    /** Only `probes` is read off a link; letting one seed the others contradicts R9. */
    @Test
    fun `a link cannot seed any other argument`() {
        val intent = Intent(
            Intent.ACTION_VIEW,
            "$SCHEME://flow/x/run?probes=true&seedJobs=true&seedProfiles=true&route=shell".toUri(),
        )

        val args = intent.useSmileIDSampleLaunchArgs()
        assertTrue(args.probes)
        assertFalse(args.seedJobs)
        assertFalse(args.seedProfiles)
        assertEquals(UseSmileIDSampleFlowRoute.Fullscreen, args.route)
    }

    @Test
    fun `a null intent is the declared defaults`() {
        assertFalse(null.useSmileIDSampleLaunchArgs().probes)
    }

    private companion object {
        const val SCHEME = "usesmileid-sample-android"
    }
}
