package com.usesmileid.sampleapps.ui

import com.usesmileid.sampleapps.ui.state.TokenJson
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueData
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueFamily
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueJson
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueRules
import com.usesmileid.sampleapps.ui.state.parseTokenJson
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Every case in spec/catalogue-rules.json, through the decoder and rules the app runs on the API's answer. */
class UseSmileIDSampleCatalogueRulesSpecTest {

    private val rules = parseTokenJson(spec("catalogue-rules.json")) as TokenJson.Obj

    @Test
    fun the_allowed_required_fields_are_the_specs() {
        val allowed = (rules.section("idTypes").members["allowedRequiredFields"] as TokenJson.Arr).strings().toSet()
        assertEquals(allowed, UseSmileIDSampleCatalogueRules.allowedRequiredFields)
    }

    @Test
    fun id_type_cases() = rules.cases("idTypes").forEach { case ->
        val input = requireNotNull(UseSmileIDSampleCatalogueJson.idTypes("{\"id_types\":${encode(case.members.getValue("input"))}}"))
        val actual = UseSmileIDSampleCatalogueRules.idTypes(input, case.text("country")).map { listOf(it.id, it.type, it.label) }
        val expected = case.list("expected").map { listOf(it.text("id"), it.text("type"), it.text("label")) }
        assertEquals(case.text("name"), expected, actual)
    }

    @Test
    fun document_cases() = rules.cases("documents").forEach { case ->
        val input = requireNotNull(
            UseSmileIDSampleCatalogueJson.documents("{\"valid_documents\":${encode(case.members.getValue("input"))}}"),
        )
        val actual = UseSmileIDSampleCatalogueRules.documents(input, case.text("country"))
            .map { listOf(it.id, it.code, it.subType, it.name, it.hasBack, it.format) }
        val expected = case.list("expected").map {
            listOf(
                it.text("id"), it.text("code"), (it.members["subType"] as? TokenJson.Str)?.value, it.text("name"),
                (it.members["hasBack"] as TokenJson.Bool).value, (it.members["format"] as TokenJson.Num).literal.toInt(),
            )
        }
        assertEquals(case.text("name"), expected, actual)
    }

    @Test
    fun country_cases() = rules.cases("countries").forEach { case ->
        val input = case.members.getValue("input")
        val data = if (input is TokenJson.Str) CatalogueFixtures.data else decode(input as TokenJson.Obj)
        val family = when (case.text("family")) {
            "kyc" -> UseSmileIDSampleCatalogueFamily.Kyc
            else -> UseSmileIDSampleCatalogueFamily.Document
        }
        val actual = UseSmileIDSampleCatalogueRules.countries(data, family).map { it.code to it.name }
        val expected = case.list("expected").map { it.text("code") to it.text("name") }
        assertEquals(case.text("name"), expected, actual)
    }

    @Test
    fun every_section_has_cases() {
        listOf("idTypes", "documents", "countries", "captureAs").forEach {
            assertTrue("$it has no cases", rules.cases(it).isNotEmpty())
        }
    }

    private fun decode(input: TokenJson.Obj) = UseSmileIDSampleCatalogueData(
        idTypes = requireNotNull(UseSmileIDSampleCatalogueJson.idTypes(encode(input.members.getValue("supported_id_types")))),
        documents = requireNotNull(UseSmileIDSampleCatalogueJson.documents(encode(input.members.getValue("supported_documents")))),
    )
}

internal fun TokenJson.Obj.section(key: String) = members.getValue(key) as TokenJson.Obj

internal fun TokenJson.Obj.cases(section: String) = (section(section).members.getValue("cases") as TokenJson.Arr).items.map { it as TokenJson.Obj }

internal fun TokenJson.Obj.text(key: String) = (members.getValue(key) as TokenJson.Str).value

internal fun TokenJson.Obj.list(key: String) = (members.getValue(key) as TokenJson.Arr).items.map { it as TokenJson.Obj }

internal fun TokenJson.Arr.strings() = items.map { (it as TokenJson.Str).value }

/** Back to text, so a case's input goes through the same decoder a response body does. */
internal fun encode(value: TokenJson): String = when (value) {
    is TokenJson.Obj -> value.members.entries.joinToString(",", "{", "}") { (k, v) -> "${quote(k)}:${encode(v)}" }
    is TokenJson.Arr -> value.items.joinToString(",", "[", "]") { encode(it) }
    is TokenJson.Str -> quote(value.value)
    is TokenJson.Num -> value.literal
    is TokenJson.Bool -> value.value.toString()
    TokenJson.Null -> "null"
}

private fun quote(text: String) = "\"" + text.replace("\\", "\\\\").replace("\"", "\\\"") + "\""
