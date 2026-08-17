package com.usesmileid.sampleapps.ui

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleResult
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleFlowResult
import java.lang.reflect.Modifier
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class UseSmileIDSampleResultSpecTest {

    private val schema: String by lazy { spec("result-card.schema.json") }

    @Test
    fun the_model_carries_exactly_the_schema_fields() {
        val expected = schemaProperties()
        assertTrue("extracted no properties from the schema", expected.isNotEmpty())
        assertEquals(expected.sorted(), modelFields().sorted())
    }

    @Test
    fun every_field_the_schema_requires_is_present() {
        val required = QUOTED.findAll(schema.substringAfter("\"required\"").substringBefore("]"))
            .map { it.groupValues[1] }
            .toList()
        assertTrue("extracted no required fields", required.isNotEmpty())
        assertEquals(emptyList<String>(), required.filterNot { it in modelFields() })
    }

    @Test
    fun the_callback_counts_are_integers() {
        val counts = instanceFields().filter { it.name.endsWith("CallbackCount") }.map { it.name to it.type }
        assertEquals(
            listOf(
                "resultCallbackCount" to Int::class.javaPrimitiveType,
                "refreshCallbackCount" to Int::class.javaPrimitiveType,
            ).sortedBy { it.first },
            counts.sortedBy { it.first },
        )
    }

    @Test
    fun the_route_values_are_the_ones_the_schema_enumerates() {
        val enum = QUOTED.findAll(schema.substringAfter("\"enum\"").substringBefore("]"))
            .map { it.groupValues[1] }
            .toList()
        assertEquals(enum, UseSmileIDSampleFlowRoute.entries.map { it.id })
    }

    @Test
    fun the_sdk_version_stays_null_on_android() {
        assertNull(UseSmileIDSampleFlowResult().snapshot.sdkVersion)
    }

    private fun schemaProperties(): List<String> =
        PROPERTY.findAll(schema.substringAfter("\"properties\"")).map { it.groupValues[1] }.toList()

    private fun modelFields(): List<String> = instanceFields().map { it.name }

    private fun instanceFields() = UseSmileIDSampleResult::class.java.declaredFields
        .filterNot { it.isSynthetic || Modifier.isStatic(it.modifiers) }

    private companion object {
        val PROPERTY = Regex("\"(\\w+)\"\\s*:\\s*\\{")
        val QUOTED = Regex("\"([A-Za-z]+)\"")
    }
}
