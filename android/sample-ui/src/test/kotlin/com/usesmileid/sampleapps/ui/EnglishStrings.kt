package com.usesmileid.sampleapps.ui

import com.usesmileid.sampleapps.ui.state.TokenJson
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureAs
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureAsWording
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleDocumentOrientation
import com.usesmileid.sampleapps.ui.state.parseTokenJson

internal object EnglishStrings {
    private val values: Map<String, String> by lazy {
        val json = parseTokenJson(spec("l10n/app/en.json")) as TokenJson.Obj
        json.members.mapValues { (it.value as TokenJson.Str).value }
    }

    operator fun invoke(key: String, vararg arguments: Pair<String, Any>): String =
        arguments.fold(values.getValue(key)) { text, (name, value) -> text.replace("{$name}", value.toString()) }

    val captureAsWording = UseSmileIDSampleCaptureAsWording(
        captureAs = {
            when (it) {
                UseSmileIDSampleCaptureAs.GenericDocument -> this("capture_as_generic_document")
                UseSmileIDSampleCaptureAs.GreenBook -> this("capture_as_green_book")
                UseSmileIDSampleCaptureAs.Passport -> this("capture_as_passport")
            }
        },
        orientation = {
            when (it) {
                UseSmileIDSampleDocumentOrientation.Landscape -> this("generic_document_landscape")
                UseSmileIDSampleDocumentOrientation.Portrait -> this("generic_document_portrait")
            }
        },
        frontAndBack = this("capture_as_front_and_back"),
        frontOnly = this("capture_as_front_only"),
        matches = { this("capture_as_matches", "captureAs" to it) },
        chosen = { this("capture_as_chosen", "captureAs" to it) },
        genericSummary = { captureAs, orientation, sides ->
            this("capture_as_generic_summary", "captureAs" to captureAs, "orientation" to orientation, "sides" to sides)
        },
        genericNamedSummary = { name, orientation, sides ->
            this("capture_as_generic_named_summary", "name" to name, "orientation" to orientation, "sides" to sides)
        },
        matchNamed = { this("capture_as_match_named", "captureAs" to it) },
    )
}
