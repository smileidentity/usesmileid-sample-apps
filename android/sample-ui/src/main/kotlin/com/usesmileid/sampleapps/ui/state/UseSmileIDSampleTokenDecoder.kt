package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.Immutable
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.apiUrlHost
import com.usesmileid.sampleapps.ui.model.environmentFor
import java.security.MessageDigest
import kotlin.io.encoding.Base64

/**
 * What a v3 token binds. The SDK reads the same claim and exposes presence flags only, because every
 * PII value in it is swapped for a vault token before signing — `country` and `idType` are the two
 * that arrive in plaintext.
 */
@Immutable
data class UseSmileIDSampleTokenBindings(
    val givenNames: Boolean = false,
    val lastName: Boolean = false,
    val email: Boolean = false,
    val phoneNumber: Boolean = false,
    val consent: UseSmileIDSampleTokenConsent? = null,
    val country: String? = null,
    val idType: String? = null,
    /** The vault reference standing in for the ID number, which is the only form a token carries it in. */
    val idNumberReference: String? = null,
    /** A webhook URL or a `callback_` id; the server injects it over whatever the body carried. */
    val callbackUrl: String? = null,
) {
    /** Redacted like the session's: every one of these is a claim value, and one is a vault reference. */
    override fun toString(): String = "UseSmileIDSampleTokenBindings(" +
        "givenNames=$givenNames, lastName=$lastName, email=$email, phoneNumber=$phoneNumber, " +
        "consent=${consent != null}, country=${country != null}, idType=${idType != null}, " +
        "idNumberReference=${idNumberReference != null}, callbackUrl=${callbackUrl != null})"
}

/**
 * The consent record bound into the token. `granted` is `true` or absent by construction, mirroring
 * the SDK reading `granted: false` as no binding at all.
 */
@Immutable
data class UseSmileIDSampleTokenConsent(
    val granted: Boolean? = null,
    val grantedAt: String? = null,
    val noticeLanguage: String? = null,
    val noticePrivacyPolicyUrl: String? = null,
) {
    /** True when the token alone satisfies consent — which is when the SDK drops its consent screen. */
    val isComplete: Boolean
        get() = granted == true &&
            !grantedAt.isNullOrBlank() &&
            !noticeLanguage.isNullOrBlank() &&
            !noticePrivacyPolicyUrl.isNullOrBlank()
}

/**
 * Whether the token binds enough for the SDK to stop requiring `userDetails`. A duplicate of the
 * SDK's own `bindsRequiredUserDetails`, which is `internal`; the unit tests pin both to its rules.
 */
val UseSmileIDSampleTokenBindings.bindsRequiredUserDetails: Boolean
    get() = userDetailsRequirement().isSatisfied

/**
 * Whether the token carries every ID parameter [product] submits. Stricter than Document Verification's
 * validator, which accepts a null `idType`: the form is where the document type is chosen (§4.2).
 */
fun UseSmileIDSampleTokenBindings.bindsIdDetails(product: UseSmileIDSampleProduct): Boolean = when (product) {
    UseSmileIDSampleProduct.EnhancedKyc, UseSmileIDSampleProduct.BiometricKyc ->
        !country.isNullOrBlank() && !idType.isNullOrBlank() && !idNumberReference.isNullOrBlank()
    UseSmileIDSampleProduct.DocumentVerification, UseSmileIDSampleProduct.EnhancedDocumentVerification ->
        !country.isNullOrBlank() && !idType.isNullOrBlank()
    else -> true
}

/** Either the session a token describes, or why it is not one. */
sealed interface UseSmileIDSampleTokenDecode {
    /** The session the claims describe — decoded only, never verified: the sample holds no signing key. */
    data class Decoded(val session: UseSmileIDSampleTokenSession) : UseSmileIDSampleTokenDecode

    /** Names the claim or the structure that failed. Never a value, bar the `api_url` host, which is a public API host. */
    data class Rejected(val reason: String) : UseSmileIDSampleTokenDecode
}

/**
 * Reads the claims a session is made of. **Decoding is not verification:** the sample holds no
 * signing key, so a decoded token is only a claim about itself and a rejection is the one honest
 * response to a token that will not parse.
 *
 * The SDK's own `UseSmileIDJwtDecoder` is public but `DecodedToken.tokenPayload` is `internal`, so a
 * host cannot reach the parsed claim through it. Until that accessor widens, this is a documented
 * duplicate of two SDK rules — a field binds iff the claim carries it as a non-empty string, and a
 * consent object binds only when `granted` is boolean `true`.
 */
object UseSmileIDSampleTokenDecoder {

    /** Decoded when the segments, the iat/exp pair and the api_url all read; otherwise Rejected, naming the first failure. */
    fun decode(token: String): UseSmileIDSampleTokenDecode {
        val segments = token.trim().split(".")
        if (segments.size != SEGMENTS || segments.any { !it.matches(BASE64_URL) }) {
            return reject("A token is three dot-separated base64url segments; this is not.")
        }
        val claims = base64Url(segments[1])
            ?: return reject("The token's payload segment is not base64url.")
        val json = parseTokenJson(claims) as? TokenJson.Obj
            ?: return reject("The token's payload segment is not a JSON object.")
        val issuedAt = json.seconds("iat") ?: return reject("The token carries no numeric iat claim.")
        val expires = json.seconds("exp") ?: return reject("The token carries no numeric exp claim.")
        if (expires <= issuedAt) return reject("The token's exp claim is not after its iat claim.")
        // Refused rather than defaulted: a silent sandbox fallback sends a production token to the
        // wrong host and comes back as a 401 that reads like a bad token.
        val apiUrl = json.string("api_url")?.takeIf { it.isNotBlank() }
            ?: return reject("The token carries no api_url claim, so nothing says which environment it was minted for.")
        val environment = environmentFor(apiUrl) ?: return reject(
            apiUrlHost(apiUrl)
                ?.let { "The token's api_url names $it, which is not a Smile ID environment." }
                ?: "The token's api_url is not a URL, so it names no environment.",
        )
        return UseSmileIDSampleTokenDecode.Decoded(
            UseSmileIDSampleTokenSession(
                id = handle(token.trim(), json.string("jti")),
                token = token.trim(),
                issuedAtMillis = issuedAt * MILLIS_PER_SECOND,
                expiresAtMillis = expires * MILLIS_PER_SECOND,
                bindings = json.obj("payload")?.bindings() ?: UseSmileIDSampleTokenBindings(),
                partnerId = json.string("partner_id")?.takeIf { it.isNotBlank() },
                environment = environment,
            ),
        )
    }

    /** The session a token describes, or null. A stored token that no longer decodes is no session. */
    fun session(token: String): UseSmileIDSampleTokenSession? =
        (decode(token) as? UseSmileIDSampleTokenDecode.Decoded)?.session

    /** A display handle, never a prefix of the credential: the token's own `jti`, else a digest of it. */
    private fun handle(token: String, jti: String?): String =
        jti?.takeIf { it.isNotBlank() } ?: digest(token)

    private fun digest(token: String): String = MessageDigest.getInstance(DIGEST)
        .digest(token.toByteArray(Charsets.UTF_8))
        .take(HANDLE_BYTES)
        .joinToString("") { byte -> "%02x".format(byte) }

    private fun TokenJson.Obj.bindings() = UseSmileIDSampleTokenBindings(
        givenNames = binds("given_names"),
        lastName = binds("last_name"),
        email = binds("email"),
        phoneNumber = binds("phone_number"),
        consent = obj("consent")?.consent(),
        // isNotBlank, unlike the presence flags: these are read as values, and a blank one would win.
        country = string("country")?.takeIf { it.isNotBlank() },
        idType = string("id_type")?.takeIf { it.isNotBlank() },
        idNumberReference = string("id_number")?.takeIf { it.isNotBlank() },
        callbackUrl = string("callback_url")?.takeIf { it.isNotBlank() },
    )

    /** An empty consent object is no consent, and a non-boolean `granted` never counts toward one. */
    private fun TokenJson.Obj.consent(): UseSmileIDSampleTokenConsent? {
        if (members.isEmpty()) return null
        return UseSmileIDSampleTokenConsent(
            granted = boolean("granted")?.takeIf { it },
            grantedAt = string("granted_at"),
            noticeLanguage = string("notice_language"),
            noticePrivacyPolicyUrl = string("notice_privacy_policy_url"),
        )
    }

    /** A field is token-bound iff the claim carries it as a non-empty string. */
    private fun TokenJson.Obj.binds(key: String): Boolean = string(key)?.isNotEmpty() == true

    private fun base64Url(segment: String): String? = runCatching {
        String(PAYLOAD_BASE64.decode(segment), Charsets.UTF_8)
    }.getOrNull()

    private fun reject(reason: String) = UseSmileIDSampleTokenDecode.Rejected(reason)

    private const val SEGMENTS = 3
    private const val MILLIS_PER_SECOND = 1000L
    private const val HANDLE_BYTES = 4
    private const val DIGEST = "SHA-256"
    private val BASE64_URL = Regex("[A-Za-z0-9_-]+")

    /** Padding-optional: JWT segments are minted without it, and a pasted one may carry it. */
    private val PAYLOAD_BASE64 = Base64.UrlSafe.withPadding(Base64.PaddingOption.PRESENT_OPTIONAL)
}
