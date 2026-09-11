package com.usesmileid.sampleapps.ui.theme

import androidx.compose.ui.graphics.Color
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class UseSmileIDSampleThemeOverrideTest {
    @Test
    fun `both theme scenarios override and the shipped branding does not`() {
        assertNull(UseSmileIDSampleThemeScenario.BrandDefault.override)

        val partner = UseSmileIDSampleThemeScenario.PartnerOverride.override
        val clashing = UseSmileIDSampleThemeScenario.ClashingHost.override

        assertNotNull(partner)
        assertNotNull(clashing)
        // Far from the defaults on every axis, or the scenario hides the collision it exists to show.
        assertNotEquals(partner, clashing)
        assertNotNull(clashing?.fontFamily)
    }

    /**
     * The override is stated in the SDK's own types, which is what makes an SDK rename a build
     * failure here rather than a silent drift between this UI and the SDK it draws around.
     */
    @Test
    fun `the override is stated in the SDK colour type`() {
        val partner = UseSmileIDSampleThemeScenario.PartnerOverride.override

        assertEquals(partner?.primaryColor?.light, partner?.primaryColor?.dark)
        assertNotEquals(partner?.primaryColor, partner?.secondaryColor)
        assertEquals(Color.White, partner?.primaryForeground?.light)
    }
}
