package com.usesmileid.sampleapps.ui

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.state.TokenJson
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleAspectRatio
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureAs
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueData
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueFamily
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueJson
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueRules
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCountry
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleDocument
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleDocumentOrientation
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleForms
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleGenericDocument
import com.usesmileid.sampleapps.ui.state.parseTokenJson
import com.usesmileid.sampleapps.ui.state.resolvedCaptureAs
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
        val product = (case.members["product"] as? TokenJson.Str)?.value
            ?.let { id -> UseSmileIDSampleProduct.entries.first { it.id == id } }
            ?: UseSmileIDSampleProduct.DocumentVerification
        val actual = UseSmileIDSampleCatalogueRules.documents(input, case.text("country"), product)
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
            "passport" -> UseSmileIDSampleCatalogueFamily.Passport
            else -> UseSmileIDSampleCatalogueFamily.Document
        }
        val actual = UseSmileIDSampleCatalogueRules.countries(data, family).map { it.code to it.name }
        val expected = case.list("expected").map { it.text("code") to it.text("name") }
        assertEquals(case.text("name"), expected, actual)
    }

    @Test
    fun capture_as_cases() = rules.cases("captureAs").forEach { case ->
        val name = case.text("name")
        val expected = case.members.getValue("expected") as TokenJson.Obj
        val setting = (case.members["captureBothSides"] as? TokenJson.Bool)?.value ?: true
        val resolved = resolvedCaptureAs(
            documentOf(case.members.getValue("document") as TokenJson.Obj),
            captureAsOf(case.text("captureAs")),
            (case.members["genericDocument"] as? TokenJson.Obj)?.let(::genericDocumentOf) ?: UseSmileIDSampleGenericDocument(),
        )
        val type = when (resolved.captureAs) {
            UseSmileIDSampleCaptureAs.GenericDocument -> "generic"
            else -> resolved.captureAs.id
        }
        assertEquals(name, expected.text("documentType"), type)
        if (type == "generic") {
            assertEquals(name, expected.text("displayName"), resolved.genericDocument.displayName)
            assertEquals(name, (expected.members.getValue("hasBackSide") as TokenJson.Bool).value, resolved.genericDocument.hasBackSide)
            assertEquals(name, expected.text("orientation"), resolved.genericDocument.orientation.id)
        }
        assertEquals(name, (expected.members.getValue("matched") as TokenJson.Bool).value, resolved.matched)
        assertEquals(name, (expected.members.getValue("captureBothSides") as TokenJson.Bool).value, resolved.captureBothSides(setting))
        assertEquals(name, expected.text("triggerText"), resolved.triggerText(setting))
        assertEquals(name, expected.text("matchRowLabel"), resolvedCaptureAs(documentOf(case.members.getValue("document") as TokenJson.Obj), null, UseSmileIDSampleGenericDocument()).matchRowLabel)
    }

    @Test
    fun capture_as_reset_cases() = (rules.section("captureAs").members.getValue("resets") as TokenJson.Obj).cases().forEach { case ->
        val forms = UseSmileIDSampleForms()
        forms.setCountry(UseSmileIDSampleCountry("ZA", "South Africa"))
        forms.setDocument(documentOf(case.members.getValue("document") as TokenJson.Obj))
        forms.setCaptureAs(captureAsOf(case.text("captureAs")))
        val change = case.members.getValue("change") as TokenJson.Obj
        (change.members["document"] as? TokenJson.Obj)?.let { forms.setDocument(documentOf(it)) }
        (change.members["country"] as? TokenJson.Obj)?.let { forms.setCountry(UseSmileIDSampleCountry(it.text("code"), it.text("name"))) }
        assertEquals(case.text("name"), captureAsOf(case.text("expected")), forms.idDetails.captureAsOverride)
    }

    @Test
    fun the_trigger_placeholder_is_the_specs() {
        assertEquals(rules.section("captureAs").text("triggerPlaceholder"), UseSmileIDSampleCaptureAs.MATCH_DOCUMENT_LABEL)
    }

    private fun captureAsOf(id: String): UseSmileIDSampleCaptureAs? =
        if (id == UseSmileIDSampleCaptureAs.MATCH_DOCUMENT_ID) null else UseSmileIDSampleCaptureAs.entries.first { it.id == id }

    private fun documentOf(row: TokenJson.Obj) = UseSmileIDSampleDocument(
        code = row.text("code"),
        subType = (row.members["subType"] as? TokenJson.Str)?.value,
        name = row.text("name"),
        hasBack = (row.members.getValue("hasBack") as TokenJson.Bool).value,
        format = (row.members.getValue("format") as TokenJson.Num).literal.toInt(),
    )

    private fun genericDocumentOf(sheet: TokenJson.Obj) = UseSmileIDSampleGenericDocument(
        displayName = sheet.text("displayName"),
        hasBackSide = (sheet.members.getValue("hasBackSide") as TokenJson.Bool).value,
        orientation = UseSmileIDSampleDocumentOrientation.entries.first { it.id == sheet.text("orientation") },
        aspectRatio = UseSmileIDSampleAspectRatio.entries.first { it.id == sheet.text("aspectRatio") },
    )

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

internal fun TokenJson.Obj.cases(section: String) = section(section).cases()

internal fun TokenJson.Obj.cases() = (members.getValue("cases") as TokenJson.Arr).items.map { it as TokenJson.Obj }

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
