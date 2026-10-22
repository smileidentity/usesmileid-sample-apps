package com.usesmileid.sampleapps.android.navigation

import com.usesmileid.njia.NjiaKit
import com.usesmileid.njia.decodeGraph
import com.usesmileid.njia.navigator
import com.usesmileid.njia.stepOf
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Test

/** njia's wizard, driven by the app's facts, walks the same forms the shell's journey rules pick. */
class UseSmileIDSampleNjiaFactsTest {

    private val graph by lazy {
        val dir = requireNotNull(System.getProperty("sampleapps.spec.dir")) { "sampleapps.spec.dir is not set; see app/build.gradle.kts" }
        UseSmileIDSampleNjiaCodec.decodeGraph(File(dir, USE_SMILE_ID_SAMPLE_NJIA_GRAPH).readText())
    }

    @Test
    fun `every product walks the forms its token leaves, then the run its launch asked for`() {
        for (product in UseSmileIDSampleProduct.entries) {
            for (bindsUserDetails in listOf(false, true)) {
                for (bindsIdDetails in listOf(false, true)) {
                    for (route in UseSmileIDSampleFlowRoute.entries) {
                        val case = "$product binds user $bindsUserDetails id $bindsIdDetails $route"
                        assertEquals(case, expected(product, bindsUserDetails, bindsIdDetails, route), walked(product, bindsUserDetails, bindsIdDetails, route))
                    }
                }
            }
        }
    }

    @Test
    fun `facts name only what a run needs`() {
        assertEquals(emptySet<UseSmileIDSampleFact>(), useSmileIDSampleFacts(UseSmileIDSampleProduct.SmartSelfieEnrollment, bindsIdDetails = false, UseSmileIDSampleFlowRoute.Shell))
        assertEquals(
            setOf(UseSmileIDSampleFact.NeedsUserId, UseSmileIDSampleFact.FullScreenRun),
            useSmileIDSampleFacts(UseSmileIDSampleProduct.SmartSelfieAuth, bindsIdDetails = false, UseSmileIDSampleFlowRoute.Fullscreen),
        )
    }

    /** The shell's journey rules: consent unless bound, the auth user ID, ID details unless bound, then the run. */
    private fun expected(product: UseSmileIDSampleProduct, bindsUser: Boolean, bindsId: Boolean, route: UseSmileIDSampleFlowRoute) = buildList {
        if (!bindsUser) add(UseSmileIDSampleStep.ConsentDetailsForm)
        when {
            product == UseSmileIDSampleProduct.SmartSelfieAuth -> add(UseSmileIDSampleStep.AuthUserId)
            product.needsIdDetails && !bindsId -> add(UseSmileIDSampleStep.IdDetailsForm)
        }
        add(if (route == UseSmileIDSampleFlowRoute.Fullscreen) UseSmileIDSampleStep.SdkFlowFullScreen else UseSmileIDSampleStep.SdkFlow)
    }

    /** A product tap from the products tab, then `next` from each form until the run is on top. */
    private fun walked(product: UseSmileIDSampleProduct, bindsUser: Boolean, bindsId: Boolean, route: UseSmileIDSampleFlowRoute): List<UseSmileIDSampleStep> {
        val facts = useSmileIDSampleFacts(product, bindsId, route)
        val engine = NjiaKit.start(graph, facts)
        engine.navigator(engine.state.entries.last()).go(graph.firstStepFor(facts, bindsUser), arg = product.id)
        val runs = setOf(UseSmileIDSampleStep.SdkFlow, UseSmileIDSampleStep.SdkFlowFullScreen)
        val walked = mutableListOf<UseSmileIDSampleStep>()
        while (true) {
            val kind = graph.stepOf(engine.state.entries.last()).kind
            walked += kind
            if (kind in runs || walked.size > RUN_LENGTH) return walked
            engine.navigator(engine.state.entries.last()).next()
        }
    }

    private companion object {
        /** The wizard has five steps, so a longer walk is a loop. */
        const val RUN_LENGTH = 5
    }
}
