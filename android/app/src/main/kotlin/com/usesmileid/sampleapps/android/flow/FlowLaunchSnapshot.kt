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
)

fun buildSnapshot(
    args: SdkFlowScreenDestinationNavArgs,
    app: UseSmileIDSampleAppState,
    userId: String,
): FlowLaunchSnapshot? {
    val product = UseSmileIDSampleProduct.entries.firstOrNull { it.id == args.productId } ?: return null
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
            token = UseSmileIDSampleFlowTokens.token(
                expired = snapshot.scenario.startsExpired,
                nowMillis = System.currentTimeMillis(),
            )
            onTokenExpired = { _ ->
                onTokenRefreshed()
                when (snapshot.scenario) {
                    UseSmileIDSampleScenario.BadRefresh -> UseSmileIDSampleFlowTokens.malformed()
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
    val builder = UseSmileIDFlowBuilder().apply { applying(snapshot) }
    // A form can fix what the user typed but not how the host built the flow, and §7.3 redirects only the first.
    val payloadChecks = buildList {
        builder.userDetails?.let { add(builder.validateUserDetails(it)) }
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

private val UseSmileIDSampleScenario.startsExpired: Boolean
    get() = this == UseSmileIDSampleScenario.ExpiredToken || this == UseSmileIDSampleScenario.BadRefresh

private val PRIVACY_POLICY_URL = URL("https://usesmileid.com/privacy-policy")
private const val CALLBACK_URL = "https://your-callback-url.com"
private val PARTNER_BUTTON_RADIUS = 4.dp
