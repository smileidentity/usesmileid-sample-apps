package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.Immutable
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct

/** Which list a product's form reads: the KYC products name an ID type, the document products a document. */
enum class UseSmileIDSampleCatalogueFamily { Kyc, Document }

/** Null for the products that ask for no ID details. */
val UseSmileIDSampleProduct.catalogueFamily: UseSmileIDSampleCatalogueFamily?
    get() = when (this) {
        UseSmileIDSampleProduct.BiometricKyc, UseSmileIDSampleProduct.EnhancedKyc -> UseSmileIDSampleCatalogueFamily.Kyc
        UseSmileIDSampleProduct.DocumentVerification, UseSmileIDSampleProduct.EnhancedDocumentVerification ->
            UseSmileIDSampleCatalogueFamily.Document
        else -> null
    }

/** One picker's list: still arriving, arrived, arrived with nothing the form can use, or failed. */
@Immutable
sealed interface UseSmileIDSampleCatalogue<out T> {
    data object Loading : UseSmileIDSampleCatalogue<Nothing>

    data class Ready<T>(val items: List<T>) : UseSmileIDSampleCatalogue<T>

    data object Empty : UseSmileIDSampleCatalogue<Nothing>

    data class Failed(val reason: String) : UseSmileIDSampleCatalogue<Nothing>
}

/** An ID type as `supported_id_types` returns it. */
@Immutable
data class UseSmileIDSampleApiIdType(
    val country: String,
    val type: String,
    val label: String,
    val regex: String,
    val requiredFields: List<String>,
)

/** One country's entry in `supported_documents`, with its documents as the API lists them. */
@Immutable
data class UseSmileIDSampleApiCountryDocuments(
    val country: UseSmileIDSampleCountry,
    val documents: List<UseSmileIDSampleApiDocument>,
)

@Immutable
data class UseSmileIDSampleApiDocument(
    val code: String,
    val name: String,
    val hasBack: Boolean,
    val format: Int,
    val subTypes: List<UseSmileIDSampleApiSubType> = emptyList(),
)

@Immutable
data class UseSmileIDSampleApiSubType(
    val id: String,
    val name: String,
    val hasBack: Boolean,
    val format: Int,
    val displayStandalone: Boolean,
)

/** Both responses a run of the form reads; fetched together because the KYC countries need names from the second. */
@Immutable
data class UseSmileIDSampleCatalogueData(
    val idTypes: List<UseSmileIDSampleApiIdType>,
    val documents: List<UseSmileIDSampleApiCountryDocuments>,
)

/** The pure rules from `spec/catalogue-rules.json`, run on whatever the server returns. */
object UseSmileIDSampleCatalogueRules {

    /** What the SDK fills in plus the two names the user-details form collects; anything else drops a type. */
    val allowedRequiredFields = setOf(
        "country", "first_name", "id_number", "id_type", "last_name", "partner_id", "partner_params", "timestamp",
    )

    fun idTypes(all: List<UseSmileIDSampleApiIdType>, country: String): List<UseSmileIDSampleKycIdType> {
        val seen = mutableMapOf<String, Int>()
        return all
            .filter { it.country == country && allowedRequiredFields.containsAll(it.requiredFields) }
            .map { type ->
                val count = seen.merge(type.type, 1, Int::plus) ?: 1
                UseSmileIDSampleKycIdType(
                    id = if (count == 1) type.type else "${type.type}_$count",
                    type = type.type,
                    label = type.label,
                    regex = type.regex,
                )
            }
    }

    /** [product] leaves out a row the SDK refuses on it: the Green Book on Enhanced Document Verification. */
    fun documents(
        all: List<UseSmileIDSampleApiCountryDocuments>,
        country: String,
        product: UseSmileIDSampleProduct = UseSmileIDSampleProduct.DocumentVerification,
    ): List<UseSmileIDSampleDocument> =
        all.firstOrNull { it.country.code == country }?.documents.orEmpty()
            .filter { it.code.isNotEmpty() }
            .flatMap { document ->
                listOf(UseSmileIDSampleDocument(document.code, null, document.name, document.hasBack, document.format)) +
                    document.subTypes.filter { it.displayStandalone }.map {
                        UseSmileIDSampleDocument(document.code, it.id, it.name, it.hasBack, it.format)
                    }
            }
            .filter { it.isListedOn(product) }

    fun countries(data: UseSmileIDSampleCatalogueData, family: UseSmileIDSampleCatalogueFamily): List<UseSmileIDSampleCountry> {
        val named = data.documents.map { it.country }
        return when (family) {
            UseSmileIDSampleCatalogueFamily.Document -> named.filter { documents(data.documents, it.code).isNotEmpty() }
            UseSmileIDSampleCatalogueFamily.Kyc -> {
                val listed = data.idTypes.map { it.country }.distinct().filter { idTypes(data.idTypes, it).isNotEmpty() }
                named.filter { it.code in listed } +
                    listed.filter { code -> named.none { it.code == code } }.map { UseSmileIDSampleCountry(it, it) }
            }
        }
    }
}

/** Reads the two response bodies; readers ignore unknown keys, as status refresh does. Null when malformed. */
object UseSmileIDSampleCatalogueJson {

    fun idTypes(body: String): List<UseSmileIDSampleApiIdType>? {
        val root = parseTokenJson(body) as? TokenJson.Obj ?: return null
        val items = root.members["id_types"] as? TokenJson.Arr ?: return null
        return items.items.mapNotNull { item ->
            val o = item as? TokenJson.Obj ?: return@mapNotNull null
            UseSmileIDSampleApiIdType(
                country = o.string("country") ?: return@mapNotNull null,
                type = o.string("type") ?: return@mapNotNull null,
                label = o.string("label") ?: return@mapNotNull null,
                regex = o.string("regex").orEmpty(),
                requiredFields = (o.members["required_fields"] as? TokenJson.Arr)?.items
                    ?.mapNotNull { (it as? TokenJson.Str)?.value }.orEmpty(),
            )
        }
    }

    fun documents(body: String): List<UseSmileIDSampleApiCountryDocuments>? {
        val root = parseTokenJson(body) as? TokenJson.Obj ?: return null
        val items = root.members["valid_documents"] as? TokenJson.Arr ?: return null
        return items.items.mapNotNull { item ->
            val o = item as? TokenJson.Obj ?: return@mapNotNull null
            val country = o.obj("country") ?: return@mapNotNull null
            UseSmileIDSampleApiCountryDocuments(
                country = UseSmileIDSampleCountry(
                    code = country.string("code") ?: return@mapNotNull null,
                    name = country.string("name") ?: return@mapNotNull null,
                ),
                documents = (o.members["id_types"] as? TokenJson.Arr)?.items.orEmpty().mapNotNull(::document),
            )
        }
    }

    private fun document(item: TokenJson): UseSmileIDSampleApiDocument? {
        val o = item as? TokenJson.Obj ?: return null
        return UseSmileIDSampleApiDocument(
            code = o.string("code") ?: return null,
            name = o.string("name") ?: return null,
            hasBack = o.boolean("has_back") ?: true,
            format = o.int("format") ?: 1,
            subTypes = (o.members["sub_types"] as? TokenJson.Arr)?.items.orEmpty().mapNotNull { sub ->
                val s = sub as? TokenJson.Obj ?: return@mapNotNull null
                UseSmileIDSampleApiSubType(
                    id = s.string("id") ?: return@mapNotNull null,
                    name = s.string("name") ?: return@mapNotNull null,
                    hasBack = s.boolean("has_back") ?: true,
                    format = s.int("format") ?: 1,
                    displayStandalone = s.boolean("display_standalone") ?: false,
                )
            },
        )
    }

    private fun TokenJson.Obj.int(key: String): Int? = (members[key] as? TokenJson.Num)?.literal?.toIntOrNull()
}
