package com.usesmileid.sampleapps.ui.model

import androidx.compose.runtime.Immutable
import com.usesmileid.sampleapps.ui.state.TokenJson
import com.usesmileid.sampleapps.ui.state.parseTokenJson
import com.usesmileid.sampleapps.ui.state.string

/** The generated third-party notices, as the screen renders them. */
@Immutable
data class UseSmileIDSampleLicenses(
    val openSource: List<UseSmileIDSampleNotice> = emptyList(),
    val googleServices: List<UseSmileIDSampleNotice> = emptyList(),
    /** Keyed by licence id, so two hundred Apache components share one copy of the text. */
    val texts: Map<String, String> = emptyMap(),
) {
    val isEmpty: Boolean get() = openSource.isEmpty() && googleServices.isEmpty()
}

/** One dependency a partner ships, and what it is licensed under. */
@Immutable
data class UseSmileIDSampleNotice(
    val artifact: String,
    val version: String,
    val licenses: List<UseSmileIDSampleLicenseRef>,
)

/** `id` is null for terms of service: there is no text to ship, only the page that is the licence. */
@Immutable
data class UseSmileIDSampleLicenseRef(val id: String?, val name: String, val url: String)

/** Reads `scripts/generate_licenses.py`'s output. Hand-parsed: `sample-ui` carries no JSON dependency. */
fun parseUseSmileIDSampleLicenses(json: String): UseSmileIDSampleLicenses {
    val root = parseTokenJson(json) as? TokenJson.Obj ?: return UseSmileIDSampleLicenses()
    return UseSmileIDSampleLicenses(
        openSource = root.notices("openSource", "licenses"),
        googleServices = root.notices("googleServices", "terms"),
        texts = (root.members["licenseTexts"] as? TokenJson.Obj)
            ?.members
            ?.mapNotNull { (id, value) -> (value as? TokenJson.Str)?.let { id to it.value } }
            ?.toMap()
            .orEmpty(),
    )
}

private fun TokenJson.Obj.notices(key: String, licencesKey: String): List<UseSmileIDSampleNotice> =
    (members[key] as? TokenJson.Arr)
        ?.items
        ?.filterIsInstance<TokenJson.Obj>()
        ?.mapNotNull { entry ->
            val artifact = entry.string("artifact") ?: return@mapNotNull null
            UseSmileIDSampleNotice(
                artifact = artifact,
                version = entry.string("version").orEmpty(),
                licenses = (entry.members[licencesKey] as? TokenJson.Arr)
                    ?.items
                    ?.filterIsInstance<TokenJson.Obj>()
                    ?.map { licence ->
                        UseSmileIDSampleLicenseRef(
                            id = licence.string("id"),
                            name = licence.string("name").orEmpty(),
                            url = licence.string("url").orEmpty(),
                        )
                    }
                    .orEmpty(),
            )
        }
        .orEmpty()
