package com.usesmileid.sampleapps.ui.state

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * The gate-to-scanner hand-off. Claiming is what keeps a forgotten run from being resurrected by a
 * later unrelated scan, and the saver is what survives a rotation held over a QR code.
 */
class UseSmileIDSampleRunIntentTest {

    @Test
    fun `claiming reads the run once and leaves nothing behind`() {
        val interrupted = UseSmileIDSampleInterruptedRun()
        interrupted.send(UseSmileIDSampleRunIntent("biometricKyc", UseSmileIDSampleFlowRoute.Shell))

        assertEquals(
            UseSmileIDSampleRunIntent("biometricKyc", UseSmileIDSampleFlowRoute.Shell),
            interrupted.claim(),
        )
        assertNull("a second claim must not resume the same run again", interrupted.claim())
    }

    @Test
    fun `nothing to claim when no gate sent anything`() {
        assertNull(UseSmileIDSampleInterruptedRun().claim())
    }

    @Test
    fun `the newest interruption wins`() {
        val interrupted = UseSmileIDSampleInterruptedRun()
        interrupted.send(UseSmileIDSampleRunIntent("documentVerification", UseSmileIDSampleFlowRoute.Fullscreen))
        interrupted.send(UseSmileIDSampleRunIntent("biometricKyc", UseSmileIDSampleFlowRoute.Shell))

        assertEquals("biometricKyc", interrupted.claim()?.productId)
    }

    @Test
    fun `a claimed run survives a rotation in either presentation`() {
        UseSmileIDSampleFlowRoute.entries.forEach { route ->
            val intent = UseSmileIDSampleRunIntent("enhancedKyc", route)
            assertEquals("$route must survive being saved", intent, UseSmileIDSampleRunIntent.of(intent.saved()))
        }
    }

    @Test
    fun `nothing saved restores as nothing rather than as a half-built run`() {
        assertNull(UseSmileIDSampleRunIntent.of(emptyList()))
        assertNull("a product with no presentation is not a run", UseSmileIDSampleRunIntent.of(listOf("biometricKyc")))
        assertNull("an unknown presentation is not a run", UseSmileIDSampleRunIntent.of(listOf("biometricKyc", "carousel")))
        assertNull("a blank product is not a run", UseSmileIDSampleRunIntent.of(listOf("", "shell")))
    }
}
