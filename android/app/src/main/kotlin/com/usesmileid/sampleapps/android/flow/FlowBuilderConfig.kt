package com.usesmileid.sampleapps.android.flow

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
import com.usesmileid.presentation.flow.config.ResidencyDocumentVerificationParams
import com.usesmileid.presentation.flow.dsl.DocumentCaptureConfigBuilder
import com.usesmileid.presentation.flow.dsl.ScreensBuilder
import com.usesmileid.presentation.flow.dsl.UseSmileIDFlowBuilder
import com.usesmileid.sampleapps.android.BuildConfig
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.presentation.flow.config.DocumentCaptureMode
import com.usesmileid.presentation.flow.config.DocumentOrientation
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureAs
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueFamily
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueRules
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureMode
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleDocumentOrientation
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleGenericDocument
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdDetails
import com.usesmileid.sampleapps.ui.state.bindsRequiredUserDetails
import com.usesmileid.sampleapps.ui.state.catalogueFamily
import com.usesmileid.sampleapps.ui.theme.override
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
            email = snapshot.userDetails.submittedEmail,
            phoneNumber = snapshot.userDetails.submittedPhone,
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
        // Debug builds only: logs the three document-capture keys of the submission metadata, nothing else.
        wireProbe()?.let { probe -> interceptors { +probe } }
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
                callbackUrl = resolveCallbackUrl(snapshot)
                useSandbox = snapshot.sandbox
            }
        }
    }
    // Both theme scenarios go through the SDK's public override, as spec/scenarios.json asks; only
    // the values differ. sample-ui states them in the SDK's own types, so this is a straight assignment.
    snapshot.theme.override?.let { palette ->
        theme {
            primaryColor = palette.primaryColor
            primaryForeground = palette.primaryForeground
            secondaryColor = palette.secondaryColor
            accentColor = palette.accentColor
            buttonShape = palette.buttonShape
            palette.fontFamily?.let { fontFamily = it }
        }
    }
}

private fun UseSmileIDFlowBuilder.applyIdParams(snapshot: FlowLaunchSnapshot) {
    val details = snapshot.idDetails
    // Per field, the token beats the form — the server overwrites these from its claims regardless.
    val bound = snapshot.liveSession?.bindings
    val country = bound?.country ?: details.country?.code.orEmpty()
    // By family, so a field left over from another product's form is never sent.
    val chosen = when (snapshot.product.catalogueFamily) {
        UseSmileIDSampleCatalogueFamily.Kyc -> details.idType?.type
        UseSmileIDSampleCatalogueFamily.Document -> details.document?.code
        UseSmileIDSampleCatalogueFamily.Passport -> UseSmileIDSampleCatalogueRules.PASSPORT
        null -> null
    }
    val idType = bound?.idType ?: chosen.orEmpty()
    // Trimmed, as the form checked it.
    val idNumber = bound?.idNumberReference ?: details.idNumber.trim()
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
            idType = bound?.idType ?: chosen,
        )
        UseSmileIDSampleProduct.EnhancedDocumentVerification -> enhancedDocumentVerificationParams =
            EnhancedDocumentVerificationParams(
                country = country,
                idType = idType,
            )
        // The SDK accepts no other type, and the server reads a token's own claim over this one.
        UseSmileIDSampleProduct.ResidencyDocumentVerification -> residencyDocumentVerificationParams =
            ResidencyDocumentVerificationParams(
                country = country,
                idType = UseSmileIDSampleCatalogueRules.PASSPORT,
            )
        else -> Unit
    }
}

private fun ScreensBuilder.journeyFor(snapshot: FlowLaunchSnapshot) {
    journeyStepsFor(snapshot).forEach { step ->
        when (step) {
            FlowJourneyStep.Consent -> consent {
                partnerName = snapshot.partnerName
                partnerIcon = SampleUiR.drawable.sample_ic_product_mark
                partnerPrivacyPolicyUrl = PRIVACY_POLICY_URL
            }
            FlowJourneyStep.Instructions -> instructions { }
            FlowJourneyStep.SelfieCapture -> capture {
                captureType = CaptureType.SELFIE
                selfie {
                    allowAgentMode = snapshot.allowAgentMode
                    enableEnhancedLiveness = snapshot.enableEnhancedLiveness
                }
            }
            FlowJourneyStep.DocumentCapture -> capture {
                captureType = CaptureType.DOCUMENT
                document { applyDocumentOptions(documentOptionsFor(snapshot)) }
            }
            FlowJourneyStep.Preview -> preview { }
            FlowJourneyStep.Processing -> processing { }
        }
    }
}

/** One SDK screen the host composes. Named so the journey can be asserted: the builder's own list is private. */
internal enum class FlowJourneyStep { Consent, Instructions, SelfieCapture, DocumentCapture, Preview, Processing }

/**
 * The journey, as the three step switches and the token's bindings decide it. A consent binding lifts
 * the SDK's requirement, and declaring the screen anyway ends the run before it starts.
 */
internal fun journeyStepsFor(snapshot: FlowLaunchSnapshot): List<FlowJourneyStep> = buildList {
    if (snapshot.liveSession?.bindings?.consent == null && snapshot.consentStep) add(FlowJourneyStep.Consent)
    // Enhanced KYC is the one journey without capture: consent and processing only, per its validator.
    if (!snapshot.product.capture) {
        add(FlowJourneyStep.Processing)
        return@buildList
    }
    if (snapshot.instructionsStep) add(FlowJourneyStep.Instructions)
    when (snapshot.product) {
        UseSmileIDSampleProduct.DocumentVerification,
        UseSmileIDSampleProduct.EnhancedDocumentVerification,
        UseSmileIDSampleProduct.ResidencyDocumentVerification,
        ->
            if (snapshot.selfieFirst) {
                selfieCapture(snapshot.previewStep)
                documentCapture(snapshot.previewStep)
            } else {
                documentCapture(snapshot.previewStep)
                selfieCapture(snapshot.previewStep)
            }
        else -> selfieCapture(snapshot.previewStep)
    }
    add(FlowJourneyStep.Processing)
}

/** A preview follows its capture, and the document products' two previews go together or not at all. */
private fun MutableList<FlowJourneyStep>.selfieCapture(preview: Boolean) {
    add(FlowJourneyStep.SelfieCapture)
    if (preview) add(FlowJourneyStep.Preview)
}

private fun MutableList<FlowJourneyStep>.documentCapture(preview: Boolean) {
    add(FlowJourneyStep.DocumentCapture)
    if (preview) add(FlowJourneyStep.Preview)
}

/** Everything the document capture step is handed, read from the snapshot so it can be tested without the SDK's builder. */
internal data class DocumentOptions(
    val documentType: DocumentType,
    val allowSkipBack: Boolean,
    val captureMode: DocumentCaptureMode,
    val allowGalleryUpload: Boolean,
)

/** Hands the options to the SDK's builder, leaving captureBothSides to the SDK's per-type default. */
internal fun DocumentCaptureConfigBuilder.applyDocumentOptions(options: DocumentOptions) {
    documentType = options.documentType
    allowSkipBack = options.allowSkipBack
    captureMode = options.captureMode
    allowGalleryUpload = options.allowGalleryUpload
}

internal fun documentOptionsFor(snapshot: FlowLaunchSnapshot): DocumentOptions {
    // The SDK refuses a skip on residency's visa page.
    val residency = snapshot.product == UseSmileIDSampleProduct.ResidencyDocumentVerification
    return DocumentOptions(
        documentType = if (residency) DocumentType.Passport else documentTypeFor(snapshot.idDetails),
        allowSkipBack = snapshot.allowSkipBack && !residency,
        captureMode = snapshot.captureMode.toSdk(),
        allowGalleryUpload = snapshot.galleryUpload,
    )
}

/** The SDK type for what "Capture as" resolves to (`spec/catalogue-rules.json` captureAs). */
internal fun documentTypeFor(details: UseSmileIDSampleIdDetails): DocumentType = with(details.resolvedCaptureAs) {
    when (captureAs) {
        UseSmileIDSampleCaptureAs.GreenBook -> DocumentType.SouthAfricaGreenBook
        UseSmileIDSampleCaptureAs.Passport -> DocumentType.Passport
        UseSmileIDSampleCaptureAs.GenericDocument -> genericDocument.toSdk()
    }
}

private fun UseSmileIDSampleGenericDocument.toSdk(): DocumentType = DocumentType.GenericDocument(
    displayName = displayName,
    hasBackSide = hasBackSide,
    orientation = when (orientation) {
        UseSmileIDSampleDocumentOrientation.Landscape -> DocumentOrientation.Landscape
        UseSmileIDSampleDocumentOrientation.Portrait -> DocumentOrientation.Portrait
    },
    knownAspectRatio = aspectRatio.ratio,
)

internal fun UseSmileIDSampleCaptureMode.toSdk(): DocumentCaptureMode = when (this) {
    UseSmileIDSampleCaptureMode.Auto -> DocumentCaptureMode.AutoCapture
    UseSmileIDSampleCaptureMode.Manual -> DocumentCaptureMode.ManualCapture
    UseSmileIDSampleCaptureMode.AutoWithFallback -> DocumentCaptureMode.AutoCaptureWithManualFallback()
}

private val UseSmileIDSampleProduct.jobType: JobType
    get() = when (this) {
        UseSmileIDSampleProduct.SmartSelfieEnrollment -> JobType.SmartSelfieEnrollment
        UseSmileIDSampleProduct.SmartSelfieAuth -> JobType.SmartSelfieAuthentication
        UseSmileIDSampleProduct.DocumentVerification -> JobType.DocumentVerification
        UseSmileIDSampleProduct.EnhancedDocumentVerification -> JobType.EnhancedDocumentVerification
        UseSmileIDSampleProduct.ResidencyDocumentVerification -> JobType.ResidencyDocumentVerification
        UseSmileIDSampleProduct.BiometricKyc -> JobType.BiometricKyc
        UseSmileIDSampleProduct.EnhancedKyc -> JobType.EnhancedKyc
    }

private val UseSmileIDSampleProduct.needsDocumentCapture: Boolean
    get() = this == UseSmileIDSampleProduct.DocumentVerification ||
        this == UseSmileIDSampleProduct.EnhancedDocumentVerification ||
        this == UseSmileIDSampleProduct.ResidencyDocumentVerification

// The same host the Settings privacy row opens.
private val PRIVACY_POLICY_URL = URL("https://smile.id/privacy-policy")
