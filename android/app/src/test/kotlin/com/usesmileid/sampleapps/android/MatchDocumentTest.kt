package com.usesmileid.sampleapps.android

import com.usesmileid.presentation.flow.config.DocumentType
import com.usesmileid.sampleapps.android.flow.FlowLaunchSnapshot
import com.usesmileid.sampleapps.android.flow.FlowPreflight
import com.usesmileid.sampleapps.android.flow.documentTypeFor
import com.usesmileid.sampleapps.android.flow.preflight
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueJson
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueRules
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/**
 * Match document on every fixture row of both document products. The pinned SDK release keeps its job-type rules
 * out of public API, so the refusal is asserted as the sample's rule: the Green Book never reaches Enhanced
 * Document Verification.
 */
class MatchDocumentTest {

    private val documents = requireNotNull(
        UseSmileIDSampleCatalogueJson.documents(
            Json.parseToJsonElement(
                File(requireNotNull(System.getProperty("sampleapps.spec.dir")), "catalogue-fixture.json").readText(),
            ).jsonObject.getValue("supported_documents").toString(),
        ),
    )

    @Test
    fun match_never_builds_a_pair_the_sdk_refuses() {
        var greenBooks = 0
        listOf(UseSmileIDSampleProduct.DocumentVerification, UseSmileIDSampleProduct.EnhancedDocumentVerification).forEach { product ->
            val rows = documents.flatMap { listed ->
                UseSmileIDSampleCatalogueRules.documents(documents, listed.country.code, product).map { listed.country to it }
            }
            assertTrue("$product lists no rows", rows.isNotEmpty())
            rows.forEach { (country, document) ->
                val details = UseSmileIDSampleIdDetails(country = country, document = document)
                val type = documentTypeFor(details)
                if (type == DocumentType.SouthAfricaGreenBook) greenBooks++
                if (product == UseSmileIDSampleProduct.EnhancedDocumentVerification) {
                    assertNotEquals("${document.id} on $product", DocumentType.SouthAfricaGreenBook, type)
                }
                assertEquals("${document.id} on $product", FlowPreflight.Ready, preflight(snapshotOf(product, details)))
            }
        }
        assertEquals("the Green Book row is matched on Document Verification only", 1, greenBooks)
    }

    private fun snapshotOf(product: UseSmileIDSampleProduct, details: UseSmileIDSampleIdDetails) = FlowLaunchSnapshot(
        product = product,
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
}
