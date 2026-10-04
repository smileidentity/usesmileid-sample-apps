package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.Immutable
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct

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
enum class UseSmileIDSampleCaptureAs(val id: String) {
    GenericDocument("genericDocument"),
    GreenBook("greenBook"),
    Passport("passport"),
    ;

    companion object {
        /** The sheet's first row, which clears the override so the document decides. */
        const val MATCH_DOCUMENT_ID = "matchDocument"
    }
}

enum class UseSmileIDSampleDocumentOrientation(val id: String) {
    Landscape("landscape"),
    Portrait("portrait"),
}

/** The frame ratios the sheet offers, as width over height. */
enum class UseSmileIDSampleAspectRatio(val id: String, val ratio: Float?) {
    Off("off", null),
    Card("card", 1.586f),
    Passport("passport", 1.309f),
    Booklet("booklet", 0.748f),
}

/** The words the capture-as lines are built from, in one language. */
class UseSmileIDSampleCaptureAsWording(
    val captureAs: (UseSmileIDSampleCaptureAs) -> String,
    val orientation: (UseSmileIDSampleDocumentOrientation) -> String,
    val frontAndBack: String,
    val frontOnly: String,
    val matches: (captureAs: String) -> String,
    val chosen: (captureAs: String) -> String,
    val genericSummary: (captureAs: String, orientation: String, sides: String) -> String,
    val genericNamedSummary: (name: String, orientation: String, sides: String) -> String,
    val matchNamed: (captureAs: String) -> String,
)

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
    /** Null is Match document: the row decides, per [resolvedCaptureAs]. */
    val captureAsOverride: UseSmileIDSampleCaptureAs? = null,
    val genericDocument: UseSmileIDSampleGenericDocument = UseSmileIDSampleGenericDocument(),
    val idNumber: String = "",
) {
    /** What the SDK will be handed for this form. */
    val resolvedCaptureAs: UseSmileIDSampleResolvedCaptureAs
        get() = resolvedCaptureAs(document, captureAsOverride, genericDocument)

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

/** The type "Capture as" resolves to: a preset, or a GenericDocument built from [genericDocument]. */
@Immutable
data class UseSmileIDSampleResolvedCaptureAs(
    val captureAs: UseSmileIDSampleCaptureAs,
    val genericDocument: UseSmileIDSampleGenericDocument,
    /** Whether the document decided it, rather than an override. */
    val matched: Boolean,
) {
    val hasBackSide: Boolean
        get() = when (captureAs) {
            UseSmileIDSampleCaptureAs.GenericDocument -> genericDocument.hasBackSide
            UseSmileIDSampleCaptureAs.GreenBook -> false
            UseSmileIDSampleCaptureAs.Passport -> true
        }

    /** The SDK's captureBothSides default, which the app leaves unset: false for a passport. */
    val captureBothSides: Boolean
        get() = captureAs != UseSmileIDSampleCaptureAs.Passport

    /** The trigger text from `spec/catalogue-rules.json` captureAs. */
    fun triggerText(words: UseSmileIDSampleCaptureAsWording): String {
        val sides = if (captureBothSides && hasBackSide) words.frontAndBack else words.frontOnly
        val orientation = words.orientation(genericDocument.orientation).lowercase()
        val name = words.captureAs(captureAs)
        return when {
            captureAs != UseSmileIDSampleCaptureAs.GenericDocument -> if (matched) words.matches(name) else words.chosen(name)
            matched -> words.genericSummary(name, orientation, sides)
            else -> words.genericNamedSummary(genericDocument.displayName, orientation, sides)
        }
    }

    /** The sheet's Match row, naming what the document resolves to. */
    fun matchRowLabel(words: UseSmileIDSampleCaptureAsWording): String = words.matchNamed(words.captureAs(captureAs))
}

/** The one place the match table lives: keyed on sub-type and code, never format, with the row's has_back for the rest. */
fun resolvedCaptureAs(
    document: UseSmileIDSampleDocument?,
    override: UseSmileIDSampleCaptureAs?,
    genericDocument: UseSmileIDSampleGenericDocument,
): UseSmileIDSampleResolvedCaptureAs = when {
    override != null -> UseSmileIDSampleResolvedCaptureAs(override, genericDocument, matched = false)
    document?.subType == GREEN_BOOK_SUB_TYPE ->
        UseSmileIDSampleResolvedCaptureAs(UseSmileIDSampleCaptureAs.GreenBook, UseSmileIDSampleGenericDocument(), matched = true)
    document?.code == PASSPORT_CODE ->
        UseSmileIDSampleResolvedCaptureAs(UseSmileIDSampleCaptureAs.Passport, UseSmileIDSampleGenericDocument(), matched = true)
    else -> UseSmileIDSampleResolvedCaptureAs(
        UseSmileIDSampleCaptureAs.GenericDocument,
        UseSmileIDSampleGenericDocument(hasBackSide = document?.hasBack ?: true),
        matched = true,
    )
}

/** The only sub-type the API lists, and the one document the SDK refuses on Enhanced Document Verification. */
const val GREEN_BOOK_SUB_TYPE = "green_book"

/** Whether [product] lists this row: the SDK refuses the Green Book on Enhanced Document Verification. */
fun UseSmileIDSampleDocument.isListedOn(product: UseSmileIDSampleProduct): Boolean =
    !(product == UseSmileIDSampleProduct.EnhancedDocumentVerification && subType == GREEN_BOOK_SUB_TYPE)

private const val PASSPORT_CODE = "PASSPORT"
