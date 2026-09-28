package com.usesmileid.sampleapps.android

import com.usesmileid.presentation.flow.config.DocumentCaptureMode
import com.usesmileid.presentation.flow.config.DocumentOrientation
import com.usesmileid.presentation.flow.config.DocumentType
import com.usesmileid.presentation.flow.config.DocumentVerificationParams
import com.usesmileid.presentation.flow.dsl.UseSmileIDFlowBuilder
import com.usesmileid.sampleapps.android.flow.FlowLaunchSnapshot
import com.usesmileid.sampleapps.android.flow.applying
import com.usesmileid.sampleapps.android.flow.documentCaptureFor
import com.usesmileid.sampleapps.android.flow.toSdk
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleAspectRatio
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureAs
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureMode
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCountry
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCustomDocument
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleDocument
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleDocumentOrientation
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.float
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/** spec/catalogue-rules.json captureAs: what "Capture as" hands the SDK, and that the server always gets the code. */
class DocumentCaptureMappingTest {

    private val cases = Json.parseToJsonElement(
        File(requireNotNull(System.getProperty("sampleapps.spec.dir")), "catalogue-rules.json").readText(),
    ).jsonObject.getValue("captureAs").jsonObject.getValue("cases").jsonArray.map { it.jsonObject }

    @Test
    fun every_case_maps_as_the_spec_says() {
        assertTrue(cases.size >= 8)
        cases.forEach { case ->
            val name = case.getValue("name").jsonPrimitive.content
            val details = detailsOf(case)
            val expected = case.getValue("expected").jsonObject
            val capture = documentCaptureFor(details)
            val type = capture.documentType
            when (expected.getValue("documentType").jsonPrimitive.content) {
                "passport" -> assertEquals(name, DocumentType.Passport, type)
                "greenBook" -> assertEquals(name, DocumentType.SouthAfricaGreenBook, type)
                else -> {
                    val generic = type as DocumentType.GenericDocument
                    assertEquals(name, expected.getValue("displayName").jsonPrimitive.content, generic.displayName)
                    assertEquals(name, expected.getValue("hasBackSide").jsonPrimitive.boolean, generic.hasBackSide)
                    expected["orientation"]?.let {
                        assertEquals(name, it.jsonPrimitive.content, generic.orientation.name.lowercase())
                    }
                    expected["knownAspectRatio"]?.let {
                        assertEquals(name, it.jsonPrimitive.float, requireNotNull(generic.knownAspectRatio), 0.0001f)
                    }
                }
            }
            val both = expected.getValue("captureBothSides").jsonPrimitive
            assertEquals(name, both.booleanOrNull ?: type.hasBackSide, capture.captureBothSides)
            assertEquals(name, expected.getValue("idType").jsonPrimitive.content, submittedIdType(details))
        }
    }

    @Test
    fun the_aspect_ratios_are_the_specs() {
        val ratios = Json.parseToJsonElement(
            File(requireNotNull(System.getProperty("sampleapps.spec.dir")), "catalogue-rules.json").readText(),
        ).jsonObject.getValue("captureAs").jsonObject.getValue("aspectRatios").jsonObject
        UseSmileIDSampleAspectRatio.entries.forEach {
            assertEquals(ratios.getValue(it.id).jsonPrimitive.contentOrNull?.toFloat(), it.ratio)
        }
    }

    @Test
    fun capture_mode_reaches_the_sdk_as_its_three_values() {
        assertEquals(DocumentCaptureMode.AutoCapture, UseSmileIDSampleCaptureMode.Auto.toSdk())
        assertEquals(DocumentCaptureMode.ManualCapture, UseSmileIDSampleCaptureMode.Manual.toSdk())
        assertEquals(DocumentCaptureMode.AutoCaptureWithManualFallback(), UseSmileIDSampleCaptureMode.AutoWithFallback.toSdk())
    }

    @Test
    fun a_custom_portrait_document_keeps_its_orientation() {
        val custom = UseSmileIDSampleCustomDocument(orientation = UseSmileIDSampleDocumentOrientation.Portrait)
        val type = documentCaptureFor(UseSmileIDSampleIdDetails(captureAs = UseSmileIDSampleCaptureAs.Custom, custom = custom))
            .documentType as DocumentType.GenericDocument
        assertEquals(DocumentOrientation.Portrait, type.orientation)
    }

    private fun detailsOf(case: JsonObject): UseSmileIDSampleIdDetails {
        val document = case.getValue("document").jsonObject
        val custom = case["custom"]?.jsonObject
        return UseSmileIDSampleIdDetails(
            country = UseSmileIDSampleCountry("ZA", "South Africa"),
            document = UseSmileIDSampleDocument(
                code = document.getValue("code").jsonPrimitive.content,
                subType = document["subType"]?.jsonPrimitive?.contentOrNull,
                name = document.getValue("name").jsonPrimitive.content,
                hasBack = document.getValue("hasBack").jsonPrimitive.boolean,
                format = document.getValue("format").jsonPrimitive.int,
            ),
            captureAs = UseSmileIDSampleCaptureAs.entries.first { it.id == case.getValue("captureAs").jsonPrimitive.content },
            custom = custom?.let {
                UseSmileIDSampleCustomDocument(
                    displayName = it.getValue("displayName").jsonPrimitive.content,
                    hasBackSide = it.getValue("hasBackSide").jsonPrimitive.boolean,
                    orientation = UseSmileIDSampleDocumentOrientation.entries.first { o -> o.id == it.getValue("orientation").jsonPrimitive.content },
                    aspectRatio = UseSmileIDSampleAspectRatio.entries.first { r -> r.id == it.getValue("aspectRatio").jsonPrimitive.content },
                )
            } ?: UseSmileIDSampleCustomDocument(),
        )
    }

    /** What the builder puts in DocumentVerificationParams, whatever "Capture as" chose. */
    private fun submittedIdType(details: UseSmileIDSampleIdDetails): String? {
        val snapshot = FlowLaunchSnapshot(
            product = UseSmileIDSampleProduct.DocumentVerification,
            route = UseSmileIDSampleFlowRoute.Fullscreen,
            userDetails = UseSmileIDSampleUserDetails(firstName = "Ada", lastName = "Okafor", email = "ada@example.com"),
            idDetails = details,
            scenario = UseSmileIDSampleScenario.Normal,
            theme = UseSmileIDSampleThemeScenario.BrandDefault,
            sandbox = true,
            allowAgentMode = false,
            enableEnhancedLiveness = true,
            consentStep = true,
            instructionsStep = true,
            previewStep = true,
            userId = "user",
            partnerId = "p-1",
            partnerName = "Test",
            callbackUrl = "",
        )
        val params: DocumentVerificationParams? = UseSmileIDFlowBuilder().apply { applying(snapshot) }.documentVerificationParams
        return params?.idType
    }
}
