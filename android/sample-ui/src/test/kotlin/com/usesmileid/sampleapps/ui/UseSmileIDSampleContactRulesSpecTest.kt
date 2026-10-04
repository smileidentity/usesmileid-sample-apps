package com.usesmileid.sampleapps.ui

import com.usesmileid.sampleapps.ui.state.TokenJson
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleContactRules
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetailsRequirement
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserField
import com.usesmileid.sampleapps.ui.state.parseTokenJson
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** spec/contact-rules.json: which emails and phone numbers pass, what each submits, and the error it shows. */
class UseSmileIDSampleContactRulesSpecTest {

    private val file = parseTokenJson(spec("contact-rules.json")) as TokenJson.Obj

    private val cases = (file.members.getValue("cases") as TokenJson.Arr).items.map { it as TokenJson.Obj }

    private fun field(name: String) = if (name == "email") UseSmileIDSampleUserField.Email else UseSmileIDSampleUserField.Phone

    @Test
    fun every_case_matches_the_spec() = cases.forEach { case ->
        val field = field(case.text("field"))
        val value = case.text("value")
        val valid = (case.members.getValue("valid") as TokenJson.Bool).value
        assertEquals("$field '$value'", valid, UseSmileIDSampleContactRules.problem(field, value) == null)
        if (valid) assertEquals("$field '$value'", case.text("submits"), UseSmileIDSampleContactRules.submitted(field, value))
    }

    @Test
    fun the_errors_are_the_spec_sentences() {
        val email = file.members.getValue("email") as TokenJson.Obj
        val phone = file.members.getValue("phone") as TokenJson.Obj
        assertEquals(UseSmileIDSampleContactRules.EMAIL_ERROR, UseSmileIDSampleContactRules.problem(UseSmileIDSampleUserField.Email, "ada"))
        assertEquals(UseSmileIDSampleContactRules.PHONE_ERROR, UseSmileIDSampleContactRules.problem(UseSmileIDSampleUserField.Phone, "0700"))
        assertEquals(email.text("error"), EnglishStrings("user_field_email_error"))
        assertEquals(phone.text("error"), EnglishStrings("user_field_phone_error"))
    }

    @Test
    fun a_bad_contact_keeps_the_form_from_continuing_and_a_blank_one_does_not() {
        val requirement = UseSmileIDSampleUserDetailsRequirement()
        val named = UseSmileIDSampleUserDetails(firstName = "Ada", lastName = "Okafor", email = "ada@example.com")
        assertTrue(named.satisfies(requirement))
        assertFalse(named.copy(phone = "0700000000").satisfies(requirement))
        assertFalse(named.copy(email = "ada@example").satisfies(requirement))
        assertNull(named.contactProblem)
    }

    @Test
    fun the_submitted_phone_has_no_separators() {
        assertEquals("+254700000000", UseSmileIDSampleUserDetails(phone = "+254 700 000 000").submittedPhone)
        assertNull(UseSmileIDSampleUserDetails(phone = "  ").submittedPhone)
    }
}
