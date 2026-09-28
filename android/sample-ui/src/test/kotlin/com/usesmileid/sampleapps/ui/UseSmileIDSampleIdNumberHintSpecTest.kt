package com.usesmileid.sampleapps.ui

import com.usesmileid.sampleapps.ui.state.TokenJson
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdNumberHint
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleKycIdType
import com.usesmileid.sampleapps.ui.state.parseTokenJson
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** spec/id-number-hints.json: the hint, that it fits its own regex, and that Kotlin's engine compiles every case. */
class UseSmileIDSampleIdNumberHintSpecTest {

    private val cases = ((parseTokenJson(spec("id-number-hints.json")) as TokenJson.Obj).members.getValue("cases") as TokenJson.Arr)
        .items.map { it as TokenJson.Obj }
        .map { it.text("regex") to (it.members["hint"] as? TokenJson.Str)?.value }

    @Test
    fun the_file_has_cases_inside_and_outside_the_subset() {
        assertTrue(cases.count { it.second != null } > 20)
        assertTrue(cases.any { it.second == null })
    }

    @Test
    fun every_hint_matches_the_spec() = cases.forEach { (regex, hint) ->
        assertEquals(regex, hint, UseSmileIDSampleIdNumberHint.example(regex))
    }

    @Test
    fun every_example_matches_its_own_regex() = cases.forEach { (regex, hint) ->
        if (hint != null) assertTrue("$hint against $regex", Regex(regex).matches(hint))
    }

    @Test
    fun every_regex_compiles_here() = cases.forEach { (regex, _) -> Regex(regex) }

    @Test
    fun the_number_is_trimmed_and_must_match_the_whole_regex() {
        assertTrue(UseSmileIDSampleIdNumberHint.accepts("^[0-9]{1,9}$", " 12345678 "))
        assertFalse(UseSmileIDSampleIdNumberHint.accepts("^[0-9]{1,9}$", "AO12345678"))
        assertFalse(UseSmileIDSampleIdNumberHint.accepts("^[0-9]{1,9}$", ""))
    }

    @Test
    fun a_regex_this_engine_cannot_compile_checks_nothing() {
        assertTrue(UseSmileIDSampleIdNumberHint.accepts("^[0-9", "anything"))
        val type = UseSmileIDSampleKycIdType("X", "X", "Tax number", "^[0-9")
        assertEquals("Enter your Tax number", UseSmileIDSampleIdNumberHint.placeholder(type))
        assertNull(UseSmileIDSampleIdNumberHint.error(type, "anything"))
    }

    @Test
    fun the_field_waits_for_a_type_then_shows_the_example() {
        assertEquals("Choose an ID type first", UseSmileIDSampleIdNumberHint.placeholder(null))
        val type = UseSmileIDSampleKycIdType("NIN", "NIN", "National ID", "^[0-9]{11}$")
        assertEquals("e.g. 00000000000", UseSmileIDSampleIdNumberHint.placeholder(type))
        assertEquals("Doesn't match the National ID format, e.g. 00000000000", UseSmileIDSampleIdNumberHint.error(type, "123"))
    }
}
