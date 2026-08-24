package com.usesmileid.sampleapps.ui.state

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class UseSmileIDSampleRunIntentTest {

    @Test
    fun `reading does not consume, so an abandoned composition cannot swallow the run`() {
        val interrupted = UseSmileIDSampleInterruptedRun()
        val sent = UseSmileIDSampleRunIntent("biometricKyc", UseSmileIDSampleFlowRoute.Shell)
        interrupted.send(sent)

        assertEquals(sent, interrupted.pending)
        assertEquals("reading twice must still find it", sent, interrupted.pending)

        interrupted.clear()
        assertNull("clearing is what ends the hand-off", interrupted.pending)
    }

    @Test
    fun `nothing pending when no gate sent anything`() {
        assertNull(UseSmileIDSampleInterruptedRun().pending)
    }

    @Test
    fun `the newest interruption wins`() {
        val interrupted = UseSmileIDSampleInterruptedRun()
        interrupted.send(UseSmileIDSampleRunIntent("documentVerification", UseSmileIDSampleFlowRoute.Fullscreen))
        interrupted.send(UseSmileIDSampleRunIntent("biometricKyc", UseSmileIDSampleFlowRoute.Shell))

        assertEquals("biometricKyc", interrupted.pending?.productId)
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
