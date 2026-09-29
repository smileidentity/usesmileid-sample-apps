package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.Immutable

/** A country from the Smile ID API; the flag is derived from the ISO code, so no table is needed. */
@Immutable
data class UseSmileIDSampleCountry(val code: String, val name: String) {
    /** Two regional-indicator letters, which every platform renders as the country's flag. */
    val flag: String
        get() = code.uppercase().takeIf { it.length == 2 && it.all { c -> c in 'A'..'Z' } }
            ?.map { String(Character.toChars(REGIONAL_INDICATOR_A + (it - 'A'))) }
            ?.joinToString("")
            ?: GLOBE_EMOJI

    private companion object {
        const val REGIONAL_INDICATOR_A = 0x1F1E6
        const val GLOBE_EMOJI = "🌍"
    }
}

/** A KYC ID type from `supported_id_types`; [id] is [type] with `_2`, `_3` on a repeat (spec/catalogue-rules.json). */
@Immutable
data class UseSmileIDSampleKycIdType(
    val id: String,
    val type: String,
    val label: String,
    val regex: String,
)

/** A document from `supported_documents`; a standalone sub-type row carries [subType] and submits the parent [code]. */
@Immutable
data class UseSmileIDSampleDocument(
    val code: String,
    val subType: String? = null,
    val name: String,
    val hasBack: Boolean,
    val format: Int,
) {
    val id: String get() = subType?.let { "${code}_$it" } ?: code
}

/** How the SDK photographs the chosen document, each the SDK's own type; never what the server receives. */
enum class UseSmileIDSampleCaptureAs(val id: String, val label: String) {
    GenericDocument("genericDocument", "Generic document"),
    GreenBook("greenBook", "Green Book preset"),
    Passport("passport", "Passport preset"),
}

enum class UseSmileIDSampleDocumentOrientation(val id: String, val label: String) {
    Landscape("landscape", "Landscape"),
    Portrait("portrait", "Portrait"),
}

/** The frame ratios the sheet offers, as width over height. */
enum class UseSmileIDSampleAspectRatio(val id: String, val label: String, val ratio: Float?) {
    Off("off", "Off", null),
    Card("card", "Card 1.586", 1.586f),
    Passport("passport", "Passport 1.309", 1.309f),
    Booklet("booklet", "Booklet 0.748", 0.748f),
}

/** What the generic-document sheet builds, as the SDK's GenericDocument takes it. */
@Immutable
data class UseSmileIDSampleGenericDocument(
    val displayName: String = "Document",
    val hasBackSide: Boolean = true,
    val orientation: UseSmileIDSampleDocumentOrientation = UseSmileIDSampleDocumentOrientation.Landscape,
    val aspectRatio: UseSmileIDSampleAspectRatio = UseSmileIDSampleAspectRatio.Off,
)

/** The ID-details form, holding whole rows because a flow rebuilt after process death has no catalogue to resolve a code. */
@Immutable
data class UseSmileIDSampleIdDetails(
    val country: UseSmileIDSampleCountry? = null,
    val idType: UseSmileIDSampleKycIdType? = null,
    val document: UseSmileIDSampleDocument? = null,
    val captureAs: UseSmileIDSampleCaptureAs = UseSmileIDSampleCaptureAs.GenericDocument,
    val genericDocument: UseSmileIDSampleGenericDocument = UseSmileIDSampleGenericDocument(),
    val idNumber: String = "",
) {
    /** Whether Continue can enable for [family]: every field it shows is set, and the number fits its type. */
    fun isComplete(family: UseSmileIDSampleCatalogueFamily): Boolean = when (family) {
        UseSmileIDSampleCatalogueFamily.Document -> country != null && document != null
        UseSmileIDSampleCatalogueFamily.Passport -> country != null
        UseSmileIDSampleCatalogueFamily.Kyc -> {
            val type = idType
            country != null && type != null && UseSmileIDSampleIdNumberHint.accepts(type.regex, idNumber)
        }
    }
}
