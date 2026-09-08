import Foundation
import SampleUI
import SwiftUI
import UseSmileID
import UseSmileIDBridge
import UseSmileIDVisionDocument
import UseSmileIDVisionFace

/// The one place that decides what the SDK is handed.
///
/// The journey is built as `[FlowStep]` and replayed into the builder's `screens` block, so the gate
/// validates the screens the run composes; the SDK reads no list back for a second construction.
@MainActor
func useSmileIDSampleApply(
  _ builder: UseSmileIDFlowBuilder,
  _ snapshot: FlowLaunchSnapshot,
  onTokenRefreshed: @escaping @Sendable @MainActor () -> Void = {}
) {
  builder.userDetails = useSmileIDSampleUserDetails(snapshot)
  if snapshot.product == .smartSelfieAuth {
    builder.userId = snapshot.userId
  }
  let params = useSmileIDSampleIdParams(snapshot)
  builder.biometricKYCParams = params.biometricKyc
  builder.enhancedKYCParams = params.enhancedKyc
  builder.documentVerificationParams = params.documentVerification
  builder.enhancedDocumentVerificationParams = params.enhancedDocumentVerification
  builder.screens { screens in
    replay(useSmileIDSampleFlowSteps(snapshot), into: screens)
  }
  if snapshot.product.capture {
    // Two call sites: `AnalyzersBuilder` declares only `buildBlock`, so an `if` inside will not
    // compile.
    builder.ml { ml in
      if snapshot.product.needsDocumentCapture {
        ml.analyzers {
          selfieAnalyzer()
          documentAnalyzer()
        }
      } else {
        ml.analyzers {
          selfieAnalyzer()
        }
      }
    }
  }
  builder.network { network in
    network.config { config in
      config.jobType = snapshot.product.jobType
      let scanned = snapshot.liveSession
      config.token = scanned?.token ?? UseSmileIDSampleFlowTokens.token(
        expired: snapshot.scenario.startsExpired,
        now: Date()
      )
      config.onTokenExpired = { previous in
        await onTokenRefreshed()
        // No endpoint this sample may call, so the auth failure surfaces rather than being papered
        // over with an invented token.
        if scanned != nil {
          return previous
        }
        if snapshot.scenario == .badRefresh {
          return UseSmileIDSampleFlowTokens.malformed()
        }
        return UseSmileIDSampleFlowTokens.token(expired: false, now: Date())
      }
      // Debug only: release must never log traffic.
      config.logging { logging in
        logging.enabled = UseSmileIDSampleAppState.isDebugBuild
        // Not BODY: a logged body carries the user details this repo forbids in logs.
        logging.level = .headers
      }
      config.partnerConfig { partner in
        // The token wins over the local profile: a signed token under another id comes back 401.
        partner.partnerId = scanned?.partnerId ?? snapshot.partnerId
        partner.callbackUrl = callbackUrl
        partner.useSandbox = snapshot.sandbox
      }
    }
  }
  if snapshot.theme == .partnerOverride {
    // `clashingHost` has no counterpart: the Compose twin swaps the host's own MaterialTheme, and
    // SwiftUI hands the SDK no host palette to collide with.
    builder.theme { theme in
      theme.primaryColor = theme.color(light: .indigo, dark: .indigo)
      theme.primaryForeground = theme.color(light: .white, dark: .white)
      theme.secondaryColor = theme.color(light: .teal, dark: .teal)
      theme.accentColor = theme.color(light: .orange, dark: .orange)
      theme.buttonShape = theme.shape(partnerButtonRadius)
    }
  }
}

/// Omitted when the token binds them: the forms were skipped, so these would be blanks.
@MainActor
func useSmileIDSampleUserDetails(_ snapshot: FlowLaunchSnapshot) -> UserDetails? {
  guard snapshot.liveSession?.bindings.bindsRequiredUserDetails != true else { return nil }
  return UserDetails(
    givenNames: snapshot.userDetails.firstName,
    lastName: snapshot.userDetails.lastName,
    email: snapshot.userDetails.email.isEmpty ? nil : snapshot.userDetails.email,
    phoneNumber: snapshot.userDetails.phone.isEmpty ? nil : snapshot.userDetails.phone
  )
}

/// The four ID payloads, of which a product carries at most one, so the gate validates the object
/// the run passes.
struct FlowIdParams {
  var biometricKyc: BiometricKYCParams?
  var enhancedKyc: EnhancedKYCParams?
  var documentVerification: DocumentVerificationParams?
  var enhancedDocumentVerification: EnhancedDocumentVerificationParams?
}

@MainActor
func useSmileIDSampleIdParams(_ snapshot: FlowLaunchSnapshot) -> FlowIdParams {
  let details = snapshot.idDetails
  // Per field, the token beats the form; the server overwrites these from its claims anyway.
  let bound = snapshot.liveSession?.bindings
  let country = bound?.country ?? details.country?.code ?? ""
  let idType = bound?.idType ?? details.idType?.id ?? ""
  // The SDK asks only that this be non-blank.
  let idNumber = bound?.idNumberReference ?? details.idNumber
  var params = FlowIdParams()
  switch snapshot.product {
  case .biometricKyc:
    params.biometricKyc = BiometricKYCParams(idType: idType, idNumber: idNumber, country: country)
  case .enhancedKyc:
    params.enhancedKyc = EnhancedKYCParams(idType: idType, idNumber: idNumber, country: country)
  // Nullable: an unselected type stays absent rather than becoming a rejected "".
  case .documentVerification:
    params.documentVerification = DocumentVerificationParams(
      country: country,
      idType: bound?.idType ?? details.idType?.id
    )
  case .enhancedDocumentVerification:
    params.enhancedDocumentVerification = EnhancedDocumentVerificationParams(country: country, idType: idType)
  case .smartSelfieEnrollment, .smartSelfieAuth:
    break
  }
  return params
}

/// The SDK's own screen list, from the steps the settings and the token decide.
@MainActor
func useSmileIDSampleFlowSteps(_ snapshot: FlowLaunchSnapshot) -> [FlowStep] {
  useSmileIDSampleJourneySteps(snapshot).map { step in
    switch step {
    case .consent:
      .consent(ConsentScreenConfiguration(
        partnerName: snapshot.partnerName,
        // Non-optional here, unlike the builder's block, where omitting either fails build().
        partnerPrivacyPolicyUrl: privacyPolicyUrl,
        partnerIcon: UseSmileIDSampleFlowIcon.partnerMark
      ))
    case .instructions:
      .instructions(InstructionsScreenConfiguration())
    case .selfieCapture:
      .capture(CaptureScreenConfiguration(
        captureType: .selfie,
        selfie: SelfieCaptureConfig(
          allowAgentMode: snapshot.allowAgentMode,
          enableEnhancedLiveness: snapshot.enableEnhancedLiveness
        )
      ))
    case .documentCapture:
      .capture(CaptureScreenConfiguration(
        captureType: .document,
        document: DocumentCaptureConfig(
          documentType: snapshot.idDetails.idType.documentType,
          captureBothSides: true,
          allowSkipBack: true
        )
      ))
    case .preview:
      .preview(PreviewScreenConfiguration())
    case .processing:
      .processing(ProcessingScreenConfiguration())
    }
  }
}

/// The only way to hand the screens over: `UseSmileIDBuilder` takes no `FlowConfiguration`.
@MainActor
private func replay(_ steps: [FlowStep], into screens: ScreensBuilder) {
  for step in steps {
    switch step {
    case .consent(let config):
      screens.consent { consent in
        consent.partnerName = config.partnerName
        consent.partnerIcon = config.partnerIcon
        consent.partnerPrivacyPolicyUrl = config.partnerPrivacyPolicyUrl
      }
    case .instructions:
      screens.instructions { _ in }
    case .capture(let config):
      screens.capture { capture in
        capture.captureType = config.captureType
        if let selfie = config.selfie {
          capture.selfie { target in
            target.allowAgentMode = selfie.allowAgentMode
            target.enableEnhancedLiveness = selfie.enableEnhancedLiveness
          }
        }
        if let document = config.document {
          capture.document { target in
            target.documentType = document.documentType
            target.captureBothSides = document.captureBothSides
            target.allowSkipBack = document.allowSkipBack
          }
        }
      }
    case .preview:
      screens.preview { _ in }
    case .processing:
      screens.processing { _ in }
    // Dropping one silently would run a journey the host cannot see.
    @unknown default:
      assertionFailure("unhandled SDK screen type \(step.type)")
    }
  }
}

private func selfieAnalyzer() -> CaptureTypeConfiguration {
  forCaptureType(.selfie) { analyzers in
    analyzers.addAnalyzer(FaceDetectorAnalyzer.Factory())
    analyzers.detectorMode = .default
  }
}

private func documentAnalyzer() -> CaptureTypeConfiguration {
  forCaptureType(.document) { analyzers in
    analyzers.addAnalyzer(DocumentDetectorAnalyzer.Factory())
  }
}

/// Named so the journey can be asserted: the builder reads no list back.
enum FlowJourneyStep: Equatable {
  case consent
  case instructions
  case selfieCapture
  case documentCapture
  case preview
  case processing
}

/// A consent binding lifts the SDK's requirement, and declaring the screen anyway ends the run
/// before it starts.
func useSmileIDSampleJourneySteps(_ snapshot: FlowLaunchSnapshot) -> [FlowJourneyStep] {
  var steps: [FlowJourneyStep] = []
  if snapshot.liveSession?.bindings.consent == nil, snapshot.consentStep {
    steps.append(.consent)
  }
  // Enhanced KYC is the one journey without capture, per its own validator.
  guard snapshot.product.capture else {
    steps.append(.processing)
    return steps
  }
  if snapshot.instructionsStep {
    steps.append(.instructions)
  }
  switch snapshot.product {
  case .documentVerification:
    steps += capture(.documentCapture, snapshot.previewStep) + capture(.selfieCapture, snapshot.previewStep)
  case .enhancedDocumentVerification:
    steps += capture(.selfieCapture, snapshot.previewStep) + capture(.documentCapture, snapshot.previewStep)
  default:
    steps += capture(.selfieCapture, snapshot.previewStep)
  }
  steps.append(.processing)
  return steps
}

/// A preview follows its capture; the document products' two go together or not at all.
private func capture(_ step: FlowJourneyStep, _ preview: Bool) -> [FlowJourneyStep] {
  preview ? [step, .preview] : [step]
}

extension UseSmileIDSampleIdType? {
  var documentType: DocumentType {
    switch self {
    case .passport: .passport
    case .none: .genericDocument()
    case .some(let type): .genericDocument(displayName: type.label)
    }
  }
}

extension UseSmileIDSampleProduct {
  var jobType: JobType {
    switch self {
    case .smartSelfieEnrollment: .smartSelfieEnrollment
    case .smartSelfieAuth: .smartSelfieAuthentication
    case .documentVerification: .documentVerification
    case .enhancedDocumentVerification: .enhancedDocumentVerification
    case .biometricKyc: .biometricKyc
    case .enhancedKyc: .enhancedKyc
    }
  }

  var needsDocumentCapture: Bool {
    self == .documentVerification || self == .enhancedDocumentVerification
  }
}

// The same host the Settings privacy row opens.
private let privacyPolicyUrl = URL(string: "https://smile.id/privacy-policy")!
private let callbackUrl = "https://your-callback-url.com"
private let partnerButtonRadius: CGFloat = 4
