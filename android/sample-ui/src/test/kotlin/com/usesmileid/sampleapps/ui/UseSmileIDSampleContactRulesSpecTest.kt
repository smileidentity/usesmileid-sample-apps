package com.usesmileid.sampleapps.ui

import com.usesmileid.sampleapps.ui.state.TokenJson
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleContactRules
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetailsRequirement
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserField
import com.usesmileid.sampleapps.ui.state.parseTokenJson
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** spec/contact-rules.json: what each email and phone number submits, and that no form checks either. */
class UseSmileIDSampleContactRulesSpecTest {

    private val file = parseTokenJson(spec("contact-rules.json")) as TokenJson.Obj

    private val cases = (file.members.getValue("cases") as TokenJson.Arr).items.map { it as TokenJson.Obj }

    private fun field(name: String) = if (name == "email") UseSmileIDSampleUserField.Email else UseSmileIDSampleUserField.Phone

    @Test
    fun every_case_submits_as_the_spec_says() = cases.forEach { case ->
        val field = field(case.text("field"))
        val value = case.text("value")
        assertEquals("$field '$value'", case.text("submits"), UseSmileIDSampleContactRules.submitted(field, value))
    }

    @Test
    fun no_contact_holds_the_form_back() {
        val named = UseSmileIDSampleUserDetails(firstName = "Ada", lastName = "Okafor")
        cases.filter { it.text("submits").isNotEmpty() }.forEach { case ->
            val value = case.text("value")
            val details = if (case.text("field") == "email") named.copy(email = value) else named.copy(phone = value)
            assertTrue("${case.text("field")} '$value'", details.satisfies(UseSmileIDSampleUserDetailsRequirement()))
        }
    }

    @Test
    fun the_submitted_phone_has_no_separators() {
        assertEquals("+254700000000", UseSmileIDSampleUserDetails(phone = "+254 700 000 000").submittedPhone)
        assertNull(UseSmileIDSampleUserDetails(phone = "  ").submittedPhone)
    }
}
