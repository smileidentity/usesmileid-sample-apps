package com.usesmileid.sampleapps.ui.state

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class UseSmileIDSampleSettingsTest {

    @Test
    fun `enhanced smart selfie ships on, which is the head-turn challenge`() {
        assertTrue(UseSmileIDSampleSettings().enhancedSmartSelfie)
        assertFalse(UseSmileIDSampleSettings().agentMode)
    }

    @Test
    fun `turning agent mode on from the default state turns enhanced off`() {
        val updated = UseSmileIDSampleSettings().withSetting(UseSmileIDSampleSetting.AgentMode, true)
        assertTrue(updated.agentMode)
        assertFalse("the pair the SDK refuses must never be persisted", updated.enhancedSmartSelfie)
    }

    @Test
    fun `turning enhanced on turns agent mode off`() {
        val agentOnly = UseSmileIDSampleSettings(enhancedSmartSelfie = false, agentMode = true)
        val updated = agentOnly.withSetting(UseSmileIDSampleSetting.EnhancedSmartSelfie, true)
        assertTrue(updated.enhancedSmartSelfie)
        assertFalse(updated.agentMode)
    }

    @Test
    fun `turning either off leaves the other alone, so both can be off`() {
        val neither = UseSmileIDSampleSettings().withSetting(UseSmileIDSampleSetting.EnhancedSmartSelfie, false)
        assertFalse(neither.enhancedSmartSelfie)
        assertFalse(neither.agentMode)

        val agentOnly = neither.withSetting(UseSmileIDSampleSetting.AgentMode, true)
        assertFalse(agentOnly.withSetting(UseSmileIDSampleSetting.AgentMode, false).enhancedSmartSelfie)
    }

    @Test
    fun `no reachable state sets both, whichever order the rows are tapped in`() {
        val taps = listOf(UseSmileIDSampleSetting.EnhancedSmartSelfie, UseSmileIDSampleSetting.AgentMode)
        taps.forEach { first ->
            taps.forEach { second ->
                listOf(true, false).forEach { firstValue ->
                    listOf(true, false).forEach { secondValue ->
                        val end = UseSmileIDSampleSettings()
                            .withSetting(first, firstValue)
                            .withSetting(second, secondValue)
                        assertFalse(
                            "$first=$firstValue then $second=$secondValue set both",
                            end.agentMode && end.enhancedSmartSelfie,
                        )
                    }
                }
            }
        }
    }

    @Test
    fun `the other four rows move nothing but themselves`() {
        val others = listOf(
            UseSmileIDSampleSetting.DarkMode,
            UseSmileIDSampleSetting.ConsentStep,
            UseSmileIDSampleSetting.InstructionsStep,
            UseSmileIDSampleSetting.PreviewStep,
        )
        others.forEach { setting ->
            val defaults = UseSmileIDSampleSettings()
            val updated = defaults.withSetting(setting, !defaults[setting])
            assertEquals(!defaults[setting], updated[setting])
            UseSmileIDSampleSetting.entries.filter { it != setting }.forEach {
                assertEquals("$setting moved $it", defaults[it], updated[it])
            }
        }
    }
}
