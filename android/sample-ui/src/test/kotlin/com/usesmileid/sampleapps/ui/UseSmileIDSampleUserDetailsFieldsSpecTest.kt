package com.usesmileid.sampleapps.ui

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.state.TokenJson
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueJson
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenBindings
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetailsRequirement
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserField
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleApiField
import com.usesmileid.sampleapps.ui.state.boolean
import com.usesmileid.sampleapps.ui.state.entryFor
import com.usesmileid.sampleapps.ui.state.fieldsToCollectKey
import com.usesmileid.sampleapps.ui.state.parseTokenJson
import com.usesmileid.sampleapps.ui.state.readsIdTypes
import com.usesmileid.sampleapps.ui.state.userDetailsRequirement
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** spec/user-details-fields.json: which user-details rows the form shows for a product. */
class UseSmileIDSampleUserDetailsFieldsSpecTest {

    private val file = parseTokenJson(spec("user-details-fields.json")) as TokenJson.Obj

    private val cases = (file.members.getValue("cases") as TokenJson.Arr).items.map { it as TokenJson.Obj }

    @Test
    fun every_product_reads_the_spec_key() {
        val keys = file.members.getValue("productKeys") as TokenJson.Obj
        assertEquals(UseSmileIDSampleProduct.entries.map { it.id }.toSet(), keys.members.keys)
        UseSmileIDSampleProduct.entries.forEach { product ->
            assertEquals(product.id, (keys.members.getValue(product.id) as? TokenJson.Str)?.value, product.fieldsToCollectKey)
        }
    }

    @Test
    fun only_the_spec_products_read_id_type_entries() {
        val ids = (file.members.getValue("idTypeProducts") as TokenJson.Arr).items.map { (it as TokenJson.Str).value }.toSet()
        assertEquals(ids, UseSmileIDSampleProduct.entries.filter { it.readsIdTypes }.map { it.id }.toSet())
    }

    @Test
    fun every_case_matches_the_spec() = cases.forEach { case ->
        val name = case.text("name")
        val product = UseSmileIDSampleProduct.entries.single { it.id == case.text("product") }
        val fields = (case.members.getValue("fieldsToCollect") as? TokenJson.Obj)?.let(UseSmileIDSampleCatalogueJson::fieldsToCollect)
        val idTypeFields = (case.members["products"] as? TokenJson.Obj)?.let(UseSmileIDSampleCatalogueJson::idTypeFields)
        val bindings = (case.members.getValue("bindings") as TokenJson.Obj).let {
            UseSmileIDSampleTokenBindings(
                givenNames = it.boolean("givenNames") == true,
                lastName = it.boolean("lastName") == true,
                email = it.boolean("email") == true,
                phoneNumber = it.boolean("phoneNumber") == true,
            )
        }
        val requirement = bindings.userDetailsRequirement(product, fields, idTypeFields)
        val expect = case.members.getValue("expect") as TokenJson.Obj
        assertEquals("$name: firstName", expect.text("firstName"), requirement.outcome(UseSmileIDSampleUserField.FirstName))
        assertEquals("$name: lastName", expect.text("lastName"), requirement.outcome(UseSmileIDSampleUserField.LastName))
        assertEquals("$name: contact", expect.text("contact"), if (requirement.contact) "ask" else "provided")
        val typed = UseSmileIDSampleUserDetails(firstName = "Ada", lastName = "Okafor", email = "ada@example.com")
        (case.members["submit"] as? TokenJson.Arr)?.items.orEmpty().map { it as TokenJson.Obj }.forEach { pick ->
            val entry = idTypeFields.entryFor(product, pick.text("country"), pick.text("idType"))
            val sent = typed.withoutHiddenNames(UseSmileIDSampleUserDetailsRequirement(), entry)
            val at = "$name: ${pick.text("country")} ${pick.text("idType")}"
            assertEquals("$at firstName", pick.text("firstName"), if (sent.firstName.isEmpty()) "dropped" else "sent")
            assertEquals("$at lastName", pick.text("lastName"), if (sent.lastName.isEmpty()) "dropped" else "sent")
        }
    }

    @Test
    fun a_config_that_does_not_parse_keeps_the_token_rule() {
        assertNull(UseSmileIDSampleCatalogueJson.fieldsToCollect("not json"))
        assertEquals(emptyMap<String, Any>(), UseSmileIDSampleCatalogueJson.fieldsToCollect("""{"products": {}}"""))
        assertNull(UseSmileIDSampleCatalogueJson.idTypeFields("not json"))
        assertEquals(emptyMap<String, Any>(), UseSmileIDSampleCatalogueJson.idTypeFields("""{"fields_to_collect": {}}"""))
    }

    @Test
    fun an_id_type_entry_it_cannot_read_is_skipped() {
        val section = parseTokenJson(
            """{"enhanced_kyc": {"KE": [{"label": "No key"}, {"key_name": "NATIONAL_ID", "fields": [{"key_name": "given_names", "required": true}, {"label": "no key"}]}], "GH": "not a list"}, "biometric_kyc": "not an object"}""",
        ) as TokenJson.Obj
        assertEquals(
            mapOf(
                "enhanced_kyc" to mapOf(
                    "KE" to mapOf("NATIONAL_ID" to listOf(UseSmileIDSampleApiField("given_names", true))),
                    "GH" to emptyMap(),
                ),
                "biometric_kyc" to emptyMap(),
            ),
            UseSmileIDSampleCatalogueJson.idTypeFields(section),
        )
    }

    @Test
    fun hidden_names_never_hold_the_form_back_and_submit_nothing() {
        val requirement = UseSmileIDSampleUserDetailsRequirement(
            firstName = false,
            lastName = false,
            hidden = setOf(UseSmileIDSampleUserField.FirstName, UseSmileIDSampleUserField.LastName),
        )
        val typed = UseSmileIDSampleUserDetails(firstName = "Ada", lastName = "Okafor", email = "ada@example.com")
        assertTrue(UseSmileIDSampleUserDetails(email = "ada@example.com").satisfies(requirement))
        assertFalse(requirement.supplies(UseSmileIDSampleUserField.FirstName))
        assertEquals(UseSmileIDSampleUserDetails(email = "ada@example.com"), typed.withoutHiddenNames(requirement))
        assertEquals(typed, typed.withoutHiddenNames(UseSmileIDSampleUserDetailsRequirement()))
    }

    private fun UseSmileIDSampleUserDetailsRequirement.outcome(field: UseSmileIDSampleUserField): String = when {
        !shows(field) -> "hidden"
        supplies(field) -> "provided"
        else -> "ask"
    }
}
