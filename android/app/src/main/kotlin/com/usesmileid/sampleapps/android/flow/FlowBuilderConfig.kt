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
import com.usesmileid.presentation.flow.dsl.ScreensBuilder
import com.usesmileid.presentation.flow.dsl.UseSmileIDFlowBuilder
import com.usesmileid.sampleapps.android.BuildConfig
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.presentation.flow.config.DocumentCaptureMode
import com.usesmileid.presentation.flow.config.DocumentOrientation
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureAs
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueFamily
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureMode
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleDocumentOrientation
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
        else -> Unit
    }
}

private fun ScreensBuilder.journeyFor(snapshot: FlowLaunchSnapshot) {
    journeyStepsFor(snapshot).forEach { step ->
        when (step) {
            FlowJourneyStep.Consent -> consent {
                partnerName = snapshot.partnerName
                // Omitting it fails build() while validate() still reports Valid.
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
                document {
                    val options = documentOptionsFor(snapshot)
                    documentType = options.capture.documentType
                    captureBothSides = options.capture.captureBothSides
                    allowSkipBack = true
                    captureMode = options.captureMode
                    allowGalleryUpload = options.allowGalleryUpload
                }
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
        UseSmileIDSampleProduct.DocumentVerification -> {
            documentCapture(snapshot.previewStep)
            selfieCapture(snapshot.previewStep)
        }
        UseSmileIDSampleProduct.EnhancedDocumentVerification -> {
            selfieCapture(snapshot.previewStep)
            documentCapture(snapshot.previewStep)
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

/** What the SDK is told to photograph; the server is told the document's code either way. */
internal data class DocumentCapture(val documentType: DocumentType, val captureBothSides: Boolean)

/** Everything the document capture step is handed, read from the snapshot so it can be tested without the SDK's builder. */
internal data class DocumentOptions(
    val capture: DocumentCapture,
    val captureMode: DocumentCaptureMode,
    val allowGalleryUpload: Boolean,
)

internal fun documentOptionsFor(snapshot: FlowLaunchSnapshot): DocumentOptions = DocumentOptions(
    capture = documentCaptureFor(snapshot.idDetails),
    captureMode = snapshot.captureMode.toSdk(),
    allowGalleryUpload = snapshot.galleryUpload,
)

/** The "Capture as" mapping from `spec/catalogue-rules.json` captureAs. Pure, so its table is unit-tested. */
internal fun documentCaptureFor(details: UseSmileIDSampleIdDetails): DocumentCapture {
    val document = details.document
    return when (details.captureAs) {
        UseSmileIDSampleCaptureAs.GreenBook -> preset(DocumentType.SouthAfricaGreenBook)
        UseSmileIDSampleCaptureAs.Passport -> preset(DocumentType.Passport)
        UseSmileIDSampleCaptureAs.GenericDocument -> with(details.genericDocument) {
            preset(
                DocumentType.GenericDocument(
                    displayName = displayName,
                    hasBackSide = hasBackSide,
                    orientation = when (orientation) {
                        UseSmileIDSampleDocumentOrientation.Landscape -> DocumentOrientation.Landscape
                        UseSmileIDSampleDocumentOrientation.Portrait -> DocumentOrientation.Portrait
                    },
                    knownAspectRatio = aspectRatio.ratio,
                ),
            )
        }
        // The API's has_back, not a preset's: the API is the source that says what the document is.
        UseSmileIDSampleCaptureAs.Automatic -> DocumentCapture(
            documentType = when (document?.format) {
                FORMAT_GREEN_BOOK -> DocumentType.SouthAfricaGreenBook
                FORMAT_BOOKLET -> DocumentType.Passport
                else -> DocumentType.GenericDocument(
                    displayName = document?.name ?: "Document",
                    hasBackSide = document?.hasBack ?: true,
                )
            },
            captureBothSides = document?.hasBack ?: true,
        )
    }
}

private fun preset(type: DocumentType) = DocumentCapture(type, captureBothSides = type.hasBackSide)

internal fun UseSmileIDSampleCaptureMode.toSdk(): DocumentCaptureMode = when (this) {
    UseSmileIDSampleCaptureMode.Auto -> DocumentCaptureMode.AutoCapture
    UseSmileIDSampleCaptureMode.Manual -> DocumentCaptureMode.ManualCapture
    UseSmileIDSampleCaptureMode.AutoWithFallback -> DocumentCaptureMode.AutoCaptureWithManualFallback()
}

// The API's undocumented `format`: 3 is a passport or seaman's booklet, 7 the Green Book; the rest are cards.
private const val FORMAT_BOOKLET = 3
private const val FORMAT_GREEN_BOOK = 7

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

// The same host the Settings privacy row opens.
private val PRIVACY_POLICY_URL = URL("https://smile.id/privacy-policy")
