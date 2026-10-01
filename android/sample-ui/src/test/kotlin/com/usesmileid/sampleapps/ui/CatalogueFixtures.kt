package com.usesmileid.sampleapps.ui

import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleFixtureCatalogueSource
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment.Sandbox
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleApiEnabledCountry
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueData
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueFamily
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueJson
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueRules
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCountry
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleDocument
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleKycIdType
import kotlinx.coroutines.runBlocking

/** The rows spec/catalogue-fixture.json yields, read through the same decoder and rules the app runs. */
internal object CatalogueFixtures {
    val json: String by lazy { spec("catalogue-fixture.json") }

    val data: UseSmileIDSampleCatalogueData by lazy {
        val source = UseSmileIDSampleFixtureCatalogueSource(json)
        runBlocking {
            UseSmileIDSampleCatalogueData(
                idTypes = requireNotNull(UseSmileIDSampleCatalogueJson.idTypes(source.supportedIdTypes(Sandbox))),
                documents = requireNotNull(UseSmileIDSampleCatalogueJson.documents(source.supportedDocuments(Sandbox, "en-GB"))),
            )
        }
    }

    val enabled: List<UseSmileIDSampleApiEnabledCountry> by lazy {
        val source = UseSmileIDSampleFixtureCatalogueSource(json)
        runBlocking { requireNotNull(UseSmileIDSampleCatalogueJson.enabledCountries(source.servicesConfig(Sandbox, "", "en-GB"))) }
    }

    val kenya = UseSmileIDSampleCountry("KE", "Kenya")
    val southAfrica = UseSmileIDSampleCountry("ZA", "South Africa")

    fun countries(family: UseSmileIDSampleCatalogueFamily): List<UseSmileIDSampleCountry> =
        UseSmileIDSampleCatalogueRules.countries(data, family)

    fun idTypes(country: String): List<UseSmileIDSampleKycIdType> = UseSmileIDSampleCatalogueRules.idTypes(data.idTypes, country)

    fun documents(
        country: String,
        product: UseSmileIDSampleProduct = UseSmileIDSampleProduct.DocumentVerification,
    ): List<UseSmileIDSampleDocument> = UseSmileIDSampleCatalogueRules.documents(data.documents, country, product)
}
