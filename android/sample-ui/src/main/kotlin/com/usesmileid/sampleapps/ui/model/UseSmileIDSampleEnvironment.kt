package com.usesmileid.sampleapps.ui.model

import java.net.URI

/** Sandbox or production; there is no third case, and the SDK's own `SmileIDUrls` resolves to the same two hosts. */
enum class UseSmileIDSampleEnvironment(val id: String, val label: String, val host: String) {
    Sandbox("sandbox", "Sandbox", "testapi.smileidentity.com"),
    Production("production", "Production", "api.smileidentity.com"),
    ;

    /** The base URL that host serves, in the trailing-slash form Retrofit and the SDK's constants both take. */
    val baseUrl: String get() = "https://$host/"
}

/** A token's `api_url` onto an environment. On the parsed host, never the whole string: a real claim carries a `/v3` path and no trailing slash, so a string compare misses, and misses silently. */
fun environmentFor(apiUrl: String?): UseSmileIDSampleEnvironment? {
    val host = apiUrlHost(apiUrl) ?: return null
    return UseSmileIDSampleEnvironment.entries.firstOrNull { it.host == host }
}

/** The host an `api_url` names, so a rejection can say which one it saw. Null when the value carries none. */
fun apiUrlHost(apiUrl: String?): String? = apiUrl
    ?.trim()
    ?.takeIf { it.isNotEmpty() }
    ?.let { runCatching { URI(it).host }.getOrNull() }
    ?.lowercase()
