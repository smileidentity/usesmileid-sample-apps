package com.usesmileid.sampleapps.android.flow

import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.unit.dp
import com.ramcosta.composedestinations.generated.destinations.SdkFlowScreenDestinationNavArgs
import com.usesmileid.bridge.dsl.builder.FaceDetectorMode
import com.usesmileid.bridge.mlkit.document.DocumentDetectorAnalyzer
import com.usesmileid.bridge.mlkit.face.FaceDetectorAnalyzer
import com.usesmileid.bridge.model.CaptureType
import com.usesmileid.core.exception.UseSmileIDValidationException
import com.usesmileid.core.models.JobType
import com.usesmileid.data.model.UserDetails
import com.usesmileid.presentation.flow.config.BiometricKYCParams
import com.usesmileid.presentation.flow.config.DocumentType
import com.usesmileid.presentation.flow.config.DocumentVerificationParams
import com.usesmileid.presentation.flow.config.EnhancedDocumentVerificationParams
import com.usesmileid.presentation.flow.config.EnhancedKYCParams
import com.usesmileid.presentation.flow.dsl.ScreensBuilder
import com.usesmileid.presentation.flow.dsl.UseSmileIDFlowBuilder
import com.usesmileid.presentation.flow.validation.ValidationState
import com.usesmileid.sampleapps.android.UseSmileIDSampleAppState
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import com.usesmileid.sampleapps.ui.state.bindsRequiredUserDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdType
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails
import java.net.URL
import java.util.UUID
import com.usesmileid.sampleapps.ui.R as SampleUiR

/** Read once at flow entry; never re-read while the flow runs (R2). */
data class FlowLaunchSnapshot(
    val product: UseSmileIDSampleProduct,
    val route: UseSmileIDSampleFlowRoute,
    val userDetails: UseSmileIDSampleUserDetails,
    val idDetails: UseSmileIDSampleIdDetails,
    val scenario: UseSmileIDSampleScenario,
    val theme: UseSmileIDSampleThemeScenario,
    val sandbox: Boolean,
    val userId: String,
    val partnerId: String,
    val partnerName: String,
    /** Live at entry only: a session that has run out is the gate's business, never the builder's. */
    val session: UseSmileIDSampleTokenSession? = null,
    /** A session existed and had run out — the one thing that routes back to the scanner (TOK-A5). */
    val sessionExpired: Boolean = false,
)

fun buildSnapshot(
    args: SdkFlowScreenDestinationNavArgs,
    app: UseSmileIDSampleAppState,
    userId: String,
): FlowLaunchSnapshot? {
    val product = UseSmileIDSampleProduct.entries.firstOrNull { it.id == args.productId } ?: return null
    // The clock is read here rather than through the app state's ticking value: the snapshot is taken
    // once at entry (R2), and subscribing the flow host to a once-a-second tick would recompose it —
    // which the SDK answers by re-running `build()` and tearing the run down.
    val entryMillis = System.currentTimeMillis()
    val session = app.session
    return FlowLaunchSnapshot(
        product = product,
        route = args.route,
        userDetails = app.forms.userDetails,
        idDetails = app.forms.idDetails,
        scenario = app.flowResult.scenario,
        theme = app.flowResult.theme,
        sandbox = app.launchArgs.sandbox,
        userId = userId,
        partnerId = app.profiles.active.id,
        partnerName = app.profiles.active.organisation,
        session = session?.takeUnless { it.hasExpired(entryMillis) },
        sessionExpired = session != null && session.hasExpired(entryMillis),
    )
}

/** The one place that decides what the SDK is handed (§8.1). */
fun UseSmileIDFlowBuilder.applying(snapshot: FlowLaunchSnapshot, onTokenRefreshed: () -> Unit = {}) {
    userDetails = UserDetails(
        givenNames = snapshot.userDetails.firstName,
        lastName = snapshot.userDetails.lastName,
        email = snapshot.userDetails.email.takeIf { it.isNotBlank() },
        phoneNumber = snapshot.userDetails.phone.takeIf { it.isNotBlank() },
    )
    if (snapshot.product == UseSmileIDSampleProduct.SmartSelfieAuth) userId = snapshot.userId
    applyIdParams(snapshot)
    screens { journeyFor(snapshot) }
    if (snapshot.product.capture) {
        ml {
            analyzers {
                forCaptureType(CaptureType.SELFIE) {
                    addAnalyzer(factory = FaceDetectorAnalyzer.Factory())
                    detectorMode = FaceDetectorMode.Default
                }
                if (snapshot.product.needsDocumentCapture) {
                    forCaptureType(CaptureType.DOCUMENT) {
                        addAnalyzer(factory = DocumentDetectorAnalyzer.Factory())
                    }
                }
            }
        }
    }
    network {
        config {
            jobType = snapshot.product.jobType
            val scanned = snapshot.liveSession
            token = scanned?.token ?: UseSmileIDSampleFlowTokens.token(
                expired = snapshot.scenario.startsExpired,
                nowMillis = System.currentTimeMillis(),
            )
            onTokenExpired = { previous ->
                onTokenRefreshed()
                when {
                    // The Portal mints by hand and there is no endpoint this sample may call, so the
                    // auth failure has to surface rather than be papered over with an invented token.
                    scanned != null -> previous
                    snapshot.scenario == UseSmileIDSampleScenario.BadRefresh -> UseSmileIDSampleFlowTokens.malformed()
                    else -> UseSmileIDSampleFlowTokens.token(expired = false, nowMillis = System.currentTimeMillis())
                }
            }
            partnerConfig {
                partnerId = snapshot.partnerId
                callbackUrl = CALLBACK_URL
                useSandbox = snapshot.sandbox
            }
        }
    }
    if (snapshot.theme == UseSmileIDSampleThemeScenario.PartnerOverride) {
        // Baseline Material3, because a hex literal in app code is a review failure.
        theme {
            val light = lightColorScheme()
            val dark = darkColorScheme()
            primaryColor = color(light = light.primary, dark = dark.primary)
            primaryForeground = color(light = light.onPrimary, dark = dark.onPrimary)
            secondaryColor = color(light = light.secondary, dark = dark.secondary)
            accentColor = color(light = light.tertiary, dark = dark.tertiary)
            buttonShape = shape(PARTNER_BUTTON_RADIUS)
        }
    }
}

/** §7.3's entry gate: the SDK's non-throwing pre-flight plus its per-payload validators. */
fun preflight(snapshot: FlowLaunchSnapshot): FlowPreflight {
    // Ahead of the payloads, because no form fixes a session that has run out (TOK-A5).
    if (snapshot.sessionExpired) return FlowPreflight.NeedsSession
    val builder = UseSmileIDFlowBuilder().apply { applying(snapshot) }
    // A form can fix what the user typed but not how the host built the flow, and §7.3 redirects only the first.
    val payloadChecks = buildList {
        // The SDK relaxes token-bound user details inside build(), but its host-facing
        // validateUserDetails takes no token payload — so checking it under a binding would redirect
        // to a form the SDK does not need.
        if (snapshot.liveSession?.bindings?.bindsRequiredUserDetails != true) {
            builder.userDetails?.let { add(builder.validateUserDetails(it)) }
        }
        builder.biometricKYCParams?.let { add(builder.validateBiometricKYCParams(it)) }
        builder.enhancedKYCParams?.let { add(builder.validateEnhancedKYCParams(it)) }
        builder.documentVerificationParams?.let { add(builder.validateDocumentVerificationParams(it)) }
        builder.enhancedDocumentVerificationParams?.let { add(builder.validateEnhancedDocumentVerificationParams(it)) }
    }
    val payloadIssues = payloadChecks.filterIsInstance<ValidationState.Invalid>().flatMap { it.issues }
    if (payloadIssues.isNotEmpty()) return FlowPreflight.NeedsDetails(payloadIssues)
    return when (val builderState = builder.validate()) {
        is ValidationState.Valid -> FlowPreflight.Ready
        is ValidationState.Invalid -> FlowPreflight.Misconfigured(builderState.issues)
    }
}

/** What the gate decided, and so where the journey goes instead of the SDK. */
sealed interface FlowPreflight {
    data object Ready : FlowPreflight

    /** The forms can resolve it. */
    data class NeedsDetails(val issues: List<UseSmileIDValidationException>) : FlowPreflight

    /** Only a new token resolves it, so the journey goes back to the scanner rather than to a form. */
    data object NeedsSession : FlowPreflight

    /** No form can resolve it, and it must still never reach the SDK. */
    data class Misconfigured(val issues: List<UseSmileIDValidationException>) : FlowPreflight
}

private fun UseSmileIDFlowBuilder.applyIdParams(snapshot: FlowLaunchSnapshot) {
    val details = snapshot.idDetails
    when (snapshot.product) {
        UseSmileIDSampleProduct.BiometricKyc -> biometricKYCParams = BiometricKYCParams(
            idType = details.idType?.id.orEmpty(),
            idNumber = details.idNumber,
            country = details.country?.code.orEmpty(),
        )
        UseSmileIDSampleProduct.EnhancedKyc -> enhancedKYCParams = EnhancedKYCParams(
            idType = details.idType?.id.orEmpty(),
            idNumber = details.idNumber,
            country = details.country?.code.orEmpty(),
        )
        UseSmileIDSampleProduct.DocumentVerification -> documentVerificationParams = DocumentVerificationParams(
            country = details.country?.code.orEmpty(),
            idType = details.idType?.id,
        )
        UseSmileIDSampleProduct.EnhancedDocumentVerification -> enhancedDocumentVerificationParams =
            EnhancedDocumentVerificationParams(
                country = details.country?.code.orEmpty(),
                idType = details.idType?.id.orEmpty(),
            )
        else -> Unit
    }
}

private fun ScreensBuilder.journeyFor(snapshot: FlowLaunchSnapshot) {
    consent {
        partnerName = snapshot.partnerName
        // Omitting it fails build() while validate() still reports Valid.
        partnerIcon = SampleUiR.drawable.sample_ic_product_mark
        partnerPrivacyPolicyUrl = PRIVACY_POLICY_URL
    }
    // Enhanced KYC is the one journey without capture: consent and processing only, per its validator.
    if (!snapshot.product.capture) {
        processing { }
        return
    }
    instructions { }
    when (snapshot.product) {
        UseSmileIDSampleProduct.DocumentVerification -> {
            documentCapture(snapshot.idDetails.idType)
            selfieCapture()
        }
        UseSmileIDSampleProduct.EnhancedDocumentVerification -> {
            selfieCapture()
            documentCapture(snapshot.idDetails.idType)
        }
        UseSmileIDSampleProduct.SmartSelfieEnrollment -> selfieCapture(enhancedLiveness = true)
        else -> selfieCapture()
    }
    processing { }
}

private fun ScreensBuilder.selfieCapture(enhancedLiveness: Boolean = false) {
    capture {
        captureType = CaptureType.SELFIE
        selfie { enableEnhancedLiveness = enhancedLiveness }
    }
    preview { }
}

private fun ScreensBuilder.documentCapture(idType: UseSmileIDSampleIdType?) {
    capture {
        captureType = CaptureType.DOCUMENT
        document {
            documentType = idType.toDocumentType()
            captureBothSides = true
            allowSkipBack = true
        }
    }
    preview { }
}

private fun UseSmileIDSampleIdType?.toDocumentType(): DocumentType = when (this) {
    UseSmileIDSampleIdType.Passport -> DocumentType.Passport
    null -> DocumentType.GenericDocument()
    else -> DocumentType.GenericDocument(displayName = label)
}

private val UseSmileIDSampleProduct.jobType: JobType
    get() = when (this) {
        UseSmileIDSampleProduct.SmartSelfieEnrollment -> JobType.SmartSelfieEnrollment
        UseSmileIDSampleProduct.SmartSelfieAuth -> JobType.SmartSelfieAuthentication
        UseSmileIDSampleProduct.DocumentVerification -> JobType.DocumentVerification
        UseSmileIDSampleProduct.EnhancedDocumentVerification -> JobType.EnhancedDocumentVerification
        UseSmileIDSampleProduct.BiometricKyc -> JobType.BiometricKyc
        UseSmileIDSampleProduct.EnhancedKyc -> JobType.EnhancedKyc
    }

private val UseSmileIDSampleProduct.needsDocumentCapture: Boolean
    get() = this == UseSmileIDSampleProduct.DocumentVerification ||
        this == UseSmileIDSampleProduct.EnhancedDocumentVerification

/**
 * The session a run actually submits under. Absent for the two scenarios that are *about* refresh:
 * a scanned token has no refresh journey, and the fixtures are what keep those scenarios meaningful.
 */
private val FlowLaunchSnapshot.liveSession: UseSmileIDSampleTokenSession?
    get() = session?.takeUnless { scenario.startsExpired }

/**
 * Whether the token this run will submit under binds the user details the SDK requires — both names
 * plus one contact field. When it does the SDK asks nothing more of `userDetails`, so the host's own
 * form has nothing left to collect and the journey may start past it. Read through the same
 * live-session rule the gate uses, so a skipped form can never be followed by a redirect back to it.
 */
val UseSmileIDSampleAppState.tokenBindsUserDetails: Boolean
    get() = session
        ?.takeIf { sessionActive && !flowResult.scenario.startsExpired }
        ?.bindings
        ?.bindsRequiredUserDetails == true

internal val UseSmileIDSampleScenario.startsExpired: Boolean
    get() = this == UseSmileIDSampleScenario.ExpiredToken || this == UseSmileIDSampleScenario.BadRefresh

private val PRIVACY_POLICY_URL = URL("https://usesmileid.com/privacy-policy")
private const val CALLBACK_URL = "https://your-callback-url.com"
private val PARTNER_BUTTON_RADIUS = 4.dp
