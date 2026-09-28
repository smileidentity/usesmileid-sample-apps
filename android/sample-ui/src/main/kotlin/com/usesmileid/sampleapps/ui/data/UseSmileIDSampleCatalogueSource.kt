package com.usesmileid.sampleapps.ui.data

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.state.TokenJson
import com.usesmileid.sampleapps.ui.state.parseTokenJson
import java.io.IOException

/** The ID form's two lists as raw response bodies, so the network stays in the shell and one decoder reads live and fixture alike. */
interface UseSmileIDSampleCatalogueSource {

    /** `GET /v3/services/supported_id_types`, every country. */
    suspend fun supportedIdTypes(environment: UseSmileIDSampleEnvironment): String

    /** `GET /v3/services/supported_documents?continent=AFRICA&locale=…`. */
    suspend fun supportedDocuments(environment: UseSmileIDSampleEnvironment, locale: String): String
}

/** `catalogue=fixture`: the two bodies from `spec/catalogue-fixture.json`, with no network. */
class UseSmileIDSampleFixtureCatalogueSource(fixtureJson: String) : UseSmileIDSampleCatalogueSource {
    private val root = parseTokenJson(fixtureJson) as? TokenJson.Obj
        ?: throw IllegalArgumentException("catalogue fixture is not a JSON object")
    private val idTypes = root.body("supported_id_types")
    private val documents = root.body("supported_documents")

    override suspend fun supportedIdTypes(environment: UseSmileIDSampleEnvironment): String = idTypes

    override suspend fun supportedDocuments(environment: UseSmileIDSampleEnvironment, locale: String): String = documents

    private fun TokenJson.Obj.body(key: String): String =
        (members[key] as? TokenJson.Obj)?.let(::encode)
            ?: throw IllegalArgumentException("catalogue fixture has no $key")
}

/** `catalogue=unreachable`: every call fails at once, which is how a flow reaches the error state. */
object UseSmileIDSampleUnreachableCatalogueSource : UseSmileIDSampleCatalogueSource {
    override suspend fun supportedIdTypes(environment: UseSmileIDSampleEnvironment): String =
        throw IOException("catalogue=unreachable")

    override suspend fun supportedDocuments(environment: UseSmileIDSampleEnvironment, locale: String): String =
        throw IOException("catalogue=unreachable")
}

/** Writes a parsed value back out, so the fixture hands the store the same kind of body the API does. */
private fun encode(value: TokenJson): String = when (value) {
    is TokenJson.Obj -> value.members.entries.joinToString(",", "{", "}") { (k, v) -> "${quote(k)}:${encode(v)}" }
    is TokenJson.Arr -> value.items.joinToString(",", "[", "]") { encode(it) }
    is TokenJson.Str -> quote(value.value)
    is TokenJson.Num -> value.literal
    is TokenJson.Bool -> value.value.toString()
    TokenJson.Null -> "null"
}

private fun quote(text: String): String = buildString {
    append('"')
    text.forEach { c ->
        when {
            c == '"' -> append("\\\"")
            c == '\\' -> append("\\\\")
            c < ' ' -> append("\\u%04x".format(c.code))
            else -> append(c)
        }
    }
    append('"')
}
