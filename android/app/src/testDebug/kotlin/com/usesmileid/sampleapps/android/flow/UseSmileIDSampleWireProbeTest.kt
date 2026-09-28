package com.usesmileid.sampleapps.android.flow

import org.junit.Assert.assertEquals
import org.junit.Test

/** The probe reads the three keys whether the SDK nests them as an escaped JSON string or not. */
class UseSmileIDSampleWireProbeTest {

    @Test
    fun reads_the_keys_from_the_escaped_builder_configuration() {
        val body = """{"metadata":[{"name":"builder_configuration_object","value":"{\"auto_capture_enabled\":\"manual\",""" +
            """\"allow_gallery_upload\":true,\"capture_both_sides\":false}"}]}"""
        assertEquals(
            listOf("auto_capture_enabled=\"manual\"", "capture_both_sides=false", "allow_gallery_upload=true"),
            wireKeysIn(body),
        )
    }

    @Test
    fun reads_plain_keys_too() {
        assertEquals(listOf("auto_capture_enabled=\"auto_capture_only\""), wireKeysIn("""{"auto_capture_enabled":"auto_capture_only"}"""))
    }

    @Test
    fun finds_nothing_in_a_body_without_them() {
        assertEquals(emptyList<String>(), wireKeysIn("""{"job_id":"x"}"""))
    }
}
