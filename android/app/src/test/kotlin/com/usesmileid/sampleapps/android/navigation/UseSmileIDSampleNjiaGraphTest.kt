package com.usesmileid.sampleapps.android.navigation

import com.usesmileid.njia.NjiaGraph
import com.usesmileid.njia.decodeGraph
import com.usesmileid.njia.steps
import com.usesmileid.njia.validate
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Test

/** Reads `spec/njia-graph.json` with the app's own kinds and facts, as the shell will. */
class UseSmileIDSampleNjiaGraphTest {

    private val text: String by lazy {
        val dir = requireNotNull(System.getProperty("sampleapps.spec.dir")) { "sampleapps.spec.dir is not set; see app/build.gradle.kts" }
        File(dir, USE_SMILE_ID_SAMPLE_NJIA_GRAPH).readText()
    }

    private val graph: NjiaGraph<UseSmileIDSampleStep, UseSmileIDSampleFact> by lazy { UseSmileIDSampleNjiaCodec.decodeGraph(text) }

    @Test
    fun `the graph is valid`() {
        assertEquals(emptyList<Any>(), graph.validate())
    }

    @Test
    fun `every kind the app names is a step in the graph, once`() {
        assertEquals(UseSmileIDSampleStep.entries.toList(), graph.steps.map { it.kind }.sortedBy { it.ordinal })
    }

    @Test
    fun `every fact the app names is one a skipWhen reads`() {
        val conditions = graph.nodes.mapNotNull { it.skipWhen } + graph.steps.mapNotNull { it.skipWhen }
        assertEquals(UseSmileIDSampleFact.entries.toSet(), conditions.flatMap { it.allOf + it.noneOf }.toSet())
    }
}
