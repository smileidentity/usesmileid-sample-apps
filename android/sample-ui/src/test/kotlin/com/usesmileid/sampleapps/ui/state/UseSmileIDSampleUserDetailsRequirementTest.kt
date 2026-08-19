package com.usesmileid.sampleapps.ui.state

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** The rule the SDK applies at `build()`, minus what the token binds. */
class UseSmileIDSampleUserDetailsRequirementTest {

    @Test
    fun `no token leaves the SDK's whole rule outstanding`() {
        val requirement = null.userDetailsRequirement()
        assertTrue(requirement.bindsNothing)
        assertFalse(requirement.isSatisfied)
        assertTrue(requirement.firstName && requirement.lastName && requirement.contact)
    }

    @Test
    fun `a field the token binds is not asked for`() {
        val requirement = bindings(givenNames = true, email = true).userDetailsRequirement()
        assertFalse(requirement.firstName)
        assertTrue(requirement.lastName)
        assertFalse("a bound email satisfies the contact rule", requirement.contact)
        assertFalse(requirement.bindsNothing)
        assertFalse(requirement.isSatisfied)
    }

    @Test
    fun `either contact field satisfies the contact rule, which is a rule about one of two`() {
        assertFalse(bindings(email = true).userDetailsRequirement().contact)
        assertFalse(bindings(phoneNumber = true).userDetailsRequirement().contact)
        assertTrue(bindings(givenNames = true, lastName = true).userDetailsRequirement().contact)
    }

    @Test
    fun `both names plus one contact leaves nothing to ask`() {
        val bindings = bindings(givenNames = true, lastName = true, phoneNumber = true)
        assertTrue(bindings.userDetailsRequirement().isSatisfied)
        assertTrue("the relaxation flag reads the same rule", bindings.bindsRequiredUserDetails)
    }

    @Test
    fun `names without a contact satisfy nothing, which is where the form used to let a run through`() {
        val bindings = bindings(givenNames = true, lastName = true)
        assertFalse(bindings.userDetailsRequirement().isSatisfied)
        assertFalse(bindings.bindsRequiredUserDetails)
    }

    @Test
    fun `typed values cover what the token left out and nothing more is demanded`() {
        val requirement = bindings(givenNames = true, email = true).userDetailsRequirement()
        assertFalse(UseSmileIDSampleUserDetails().satisfies(requirement))
        assertTrue(UseSmileIDSampleUserDetails(lastName = "Okafor").satisfies(requirement))
    }

    @Test
    fun `an unbound form needs both names and a contact`() {
        val requirement = null.userDetailsRequirement()
        assertFalse(UseSmileIDSampleUserDetails(firstName = "Ada", lastName = "Okafor").satisfies(requirement))
        assertTrue(
            UseSmileIDSampleUserDetails(firstName = "Ada", lastName = "Okafor", phone = "+10000000000")
                .satisfies(requirement),
        )
    }

    @Test
    fun `only the name rows render as provided, because the contact rule is one of two`() {
        val requirement = bindings(givenNames = true, lastName = true, email = true).userDetailsRequirement()
        assertTrue(requirement.supplies(UseSmileIDSampleUserField.FirstName))
        assertTrue(requirement.supplies(UseSmileIDSampleUserField.LastName))
        assertFalse(requirement.supplies(UseSmileIDSampleUserField.Email))
        assertFalse(requirement.supplies(UseSmileIDSampleUserField.Phone))
    }

    @Test
    fun `a contact row stops saying optional exactly when one is required`() {
        val outstanding = null.userDetailsRequirement()
        assertEquals("Email", outstanding.labelFor(UseSmileIDSampleUserField.Email))
        assertEquals("Phone", outstanding.labelFor(UseSmileIDSampleUserField.Phone))
        val bound = bindings(email = true).userDetailsRequirement()
        assertEquals("Email (optional)", bound.labelFor(UseSmileIDSampleUserField.Email))
        assertEquals("First name", outstanding.labelFor(UseSmileIDSampleUserField.FirstName))
    }

    @Test
    fun `the prompt names what is outstanding and nothing else`() {
        assertEquals(
            "Required: first name, last name, an email or phone number.",
            null.userDetailsRequirement().prompt,
        )
        assertEquals(
            "Last name is required.",
            bindings(givenNames = true, email = true).userDetailsRequirement().prompt,
        )
        assertEquals(
            "An email or phone number is required.",
            bindings(givenNames = true, lastName = true).userDetailsRequirement().prompt,
        )
        assertEquals(
            "Tap any field to edit.",
            bindings(givenNames = true, lastName = true, email = true).userDetailsRequirement().prompt,
        )
    }

    private fun bindings(
        givenNames: Boolean = false,
        lastName: Boolean = false,
        email: Boolean = false,
        phoneNumber: Boolean = false,
    ) = UseSmileIDSampleTokenBindings(
        givenNames = givenNames,
        lastName = lastName,
        email = email,
        phoneNumber = phoneNumber,
    )
}
