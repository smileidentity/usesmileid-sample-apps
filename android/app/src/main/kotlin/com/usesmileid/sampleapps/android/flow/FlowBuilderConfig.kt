package com.usesmileid.sampleapps.android.flow

import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.unit.dp
import com.usesmileid.bridge.dsl.builder.FaceDetectorMode
import com.usesmileid.bridge.mlkit.document.DocumentDetectorAnalyzer
import com.usesmileid.bridge.mlkit.face.FaceDetectorAnalyzer
import com.usesmileid.bridge.model.CaptureType
import com.usesmileid.core.models.JobType
import com.usesmileid.data.dsl.config.NetworkConfiguration
import com.usesmileid.data.model.UserDetails
import com.usesmileid.presentation.flow.config.BiometricKYCParams
import com.usesmileid.presentation.flow.config.DocumentType
import com.usesmileid.presentation.flow.config.DocumentVerificationParams
import com.usesmileid.presentation.flow.config.EnhancedDocumentVerificationParams
import com.usesmileid.presentation.flow.config.EnhancedKYCParams
import com.usesmileid.presentation.flow.dsl.ScreensBuilder
import com.usesmileid.presentation.flow.dsl.UseSmileIDFlowBuilder
import com.usesmileid.sampleapps.android.BuildConfig
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdType
import com.usesmileid.sampleapps.ui.state.bindsRequiredUserDetails
import java.net.URL
import com.usesmileid.sampleapps.ui.R as SampleUiR

/** The one place that decides what the SDK is handed (§8.1). */
fun UseSmileIDFlowBuilder.applying(snapshot: FlowLaunchSnapshot, onTokenRefreshed: () -> Unit = {}) {
    // Omitted when the token binds what the SDK requires: the forms were skipped, so these would be blanks.
    userDetails = if (snapshot.liveSession?.bindings?.bindsRequiredUserDetails == true) {
        null
    } else {
        UserDetails(
            givenNames = snapshot.userDetails.firstName,
            lastName = snapshot.userDetails.lastName,
            email = snapshot.userDetails.email.takeIf { it.isNotBlank() },
            phoneNumber = snapshot.userDetails.phone.takeIf { it.isNotBlank() },
        )
    }
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
            // Debug builds only: a sample that shows a partner what the SDK put on the wire is a real
            // probe affordance, but release must never log traffic. The SDK redacts the credential
            // headers itself before any list we pass, which is why BODY level is safe here.
            logging {
                enabled = BuildConfig.DEBUG
                // HEADERS, not BODY: a logged body carries the user details this repo forbids in logs.
                // One word to raise it locally when a response body is what you need.
                level = NetworkConfiguration.LogLevel.HEADERS
            }
            partnerConfig {
                // The token wins over the local profile: it was minted for one partner, and a signed
                // token submitted under a different id comes back 401. Verified on device with a real
                // Portal token, where the sample's fixture profile id produced exactly that.
                partnerId = scanned?.partnerId ?: snapshot.partnerId
                callbackUrl = CALLBACK_URL
                useSandbox = snapshot.sandbox
            }
        }
    }
    if (snapshot.theme == UseSmileIDSampleThemeScenario.PartnerOverride) {
        // Baseline Material3: the partner-override scenario needs stable non-brand colours, and no raw hex exists here.
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

private fun UseSmileIDFlowBuilder.applyIdParams(snapshot: FlowLaunchSnapshot) {
    val details = snapshot.idDetails
    // Per field, the token beats the form — the server overwrites these from its claims regardless.
    val bound = snapshot.liveSession?.bindings
    val country = bound?.country ?: details.country?.code.orEmpty()
    val idType = bound?.idType ?: details.idType?.id.orEmpty()
    // The SDK asks only that this be non-blank, and the server substitutes the same claim anyway.
    val idNumber = bound?.idNumberReference ?: details.idNumber
    when (snapshot.product) {
        UseSmileIDSampleProduct.BiometricKyc -> biometricKYCParams = BiometricKYCParams(
            idType = idType,
            idNumber = idNumber,
            country = country,
        )
        UseSmileIDSampleProduct.EnhancedKyc -> enhancedKYCParams = EnhancedKYCParams(
            idType = idType,
            idNumber = idNumber,
            country = country,
        )
        // Nullable here: an unbound, unselected type stays absent rather than becoming a rejected "".
        UseSmileIDSampleProduct.DocumentVerification -> documentVerificationParams = DocumentVerificationParams(
            country = country,
            idType = bound?.idType ?: details.idType?.id,
        )
        UseSmileIDSampleProduct.EnhancedDocumentVerification -> enhancedDocumentVerificationParams =
            EnhancedDocumentVerificationParams(
                country = country,
                idType = idType,
            )
        else -> Unit
    }
}

private fun ScreensBuilder.journeyFor(snapshot: FlowLaunchSnapshot) {
    // A complete consent binding lifts the SDK's requirement, and declaring one anyway is filtered back
    // out and ends the run before it starts. The binding decides whether the screen exists at all.
    if (snapshot.liveSession?.bindings?.consent == null) {
        consent {
            partnerName = snapshot.partnerName
            // Omitting it fails build() while validate() still reports Valid.
            partnerIcon = SampleUiR.drawable.sample_ic_product_mark
            partnerPrivacyPolicyUrl = PRIVACY_POLICY_URL
        }
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
            selfieCapture(snapshot)
        }
        UseSmileIDSampleProduct.EnhancedDocumentVerification -> {
            selfieCapture(snapshot)
            documentCapture(snapshot.idDetails.idType)
        }
        else -> selfieCapture(snapshot)
    }
    processing { }
}

/**
 * Both fields come from Settings, enrollment included — it hard-coded the head-turn challenge before,
 * which made the setting a no-op there and could pair enhanced liveness with agent mode.
 */
private fun ScreensBuilder.selfieCapture(snapshot: FlowLaunchSnapshot) {
    capture {
        captureType = CaptureType.SELFIE
        selfie {
            allowAgentMode = snapshot.allowAgentMode
            enableEnhancedLiveness = snapshot.enableEnhancedLiveness
        }
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

private val PRIVACY_POLICY_URL = URL("https://usesmileid.com/privacy-policy")
private const val CALLBACK_URL = "https://your-callback-url.com"
private val PARTNER_BUTTON_RADIUS = 4.dp
