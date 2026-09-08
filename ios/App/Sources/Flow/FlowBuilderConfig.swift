import Foundation
import SampleUI
import SwiftUI
import UseSmileID
import UseSmileIDBridge
import UseSmileIDVisionDocument
import UseSmileIDVisionFace

/// The one place that decides what the SDK is handed (§8).
///
/// The journey is built as `[FlowStep]` first and replayed into the builder's own `screens` block,
/// so the gate in `FlowPreflight` validates the very screens the run composes. Two constructions of
/// the same journey would be free to drift, and the SDK gives no way to read a builder's list back.
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
    // Two call sites rather than one with a condition inside: `AnalyzersBuilder` declares only
    // `buildBlock`, so a result-builder `if` does not compile against it.
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
        // The Portal mints by hand and there is no endpoint this sample may call, so the auth failure
        // has to surface rather than be papered over with an invented token.
        if scanned != nil {
          return previous
        }
        if snapshot.scenario == .badRefresh {
          return UseSmileIDSampleFlowTokens.malformed()
        }
        return UseSmileIDSampleFlowTokens.token(expired: false, now: Date())
      }
      // Debug builds only: a sample that shows a partner what the SDK put on the wire is a real probe
      // affordance, but release must never log traffic.
      config.logging { logging in
        logging.enabled = UseSmileIDSampleAppState.isDebugBuild
        // HEADERS, not BODY: a logged body carries the user details this repo forbids in logs.
        logging.level = .headers
      }
      config.partnerConfig { partner in
        // The token wins over the local profile: it was minted for one partner, and a signed token
        // submitted under a different id comes back 401.
        partner.partnerId = scanned?.partnerId ?? snapshot.partnerId
        partner.callbackUrl = callbackUrl
        partner.useSandbox = snapshot.sandbox
      }
    }
  }
  if snapshot.theme == .partnerOverride {
    // A plausible partner palette through the SDK's public override. `clashingHost` has no iOS
    // counterpart yet: the Compose twin swaps the *host's* MaterialTheme, and SwiftUI hands the SDK
    // no host palette to collide with — see `ios-port-hardening.md` §16.
    builder.theme { theme in
      theme.primaryColor = theme.color(light: .indigo, dark: .indigo)
      theme.primaryForeground = theme.color(light: .white, dark: .white)
      theme.secondaryColor = theme.color(light: .teal, dark: .teal)
      theme.accentColor = theme.color(light: .orange, dark: .orange)
      theme.buttonShape = theme.shape(partnerButtonRadius)
    }
  }
}

/// Omitted when the token binds what the SDK requires: the forms were skipped, so these would be blanks.
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

/// The four ID payloads, of which a product carries at most one. One value, so the gate validates the
/// object the run passes rather than a second construction of it.
struct FlowIdParams {
  var biometricKyc: BiometricKYCParams?
  var enhancedKyc: EnhancedKYCParams?
  var documentVerification: DocumentVerificationParams?
  var enhancedDocumentVerification: EnhancedDocumentVerificationParams?
}

@MainActor
func useSmileIDSampleIdParams(_ snapshot: FlowLaunchSnapshot) -> FlowIdParams {
  let details = snapshot.idDetails
  // Per field, the token beats the form — the server overwrites these from its claims regardless.
  let bound = snapshot.liveSession?.bindings
  let country = bound?.country ?? details.country?.code ?? ""
  let idType = bound?.idType ?? details.idType?.id ?? ""
  // The SDK asks only that this be non-blank, and the server substitutes the same claim anyway.
  let idNumber = bound?.idNumberReference ?? details.idNumber
  var params = FlowIdParams()
  switch snapshot.product {
  case .biometricKyc:
    params.biometricKyc = BiometricKYCParams(idType: idType, idNumber: idNumber, country: country)
  case .enhancedKyc:
    params.enhancedKyc = EnhancedKYCParams(idType: idType, idNumber: idNumber, country: country)
  // Nullable here: an unbound, unselected type stays absent rather than becoming a rejected "".
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

/// The journey as the SDK's own screen list, from the steps the settings and the token decide.
@MainActor
func useSmileIDSampleFlowSteps(_ snapshot: FlowLaunchSnapshot) -> [FlowStep] {
  useSmileIDSampleJourneySteps(snapshot).map { step in
    switch step {
    case .consent:
      .consent(ConsentScreenConfiguration(
        partnerName: snapshot.partnerName,
        // Both required and non-optional here, unlike the builder's block, where omitting either
        // fails build() while validate() still reports Valid.
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

/// The same screens back through the builder's block, which is the only way to hand them to the SDK:
/// `UseSmileIDBuilder` takes no `FlowConfiguration`, and `ScreensBuilder` exposes no list to read.
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
    // A screen type this build does not know cannot be replayed, and dropping it silently would run
    // a journey the gate validated and the host cannot see.
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

/// One SDK screen the host composes. Named so the journey can be asserted: neither the builder nor
/// its screens block reads its list back.
enum FlowJourneyStep: Equatable {
  case consent
  case instructions
  case selfieCapture
  case documentCapture
  case preview
  case processing
}

/// The journey, as the three step switches and the token's bindings decide it. A consent binding
/// lifts the SDK's requirement, and declaring the screen anyway ends the run before it starts.
func useSmileIDSampleJourneySteps(_ snapshot: FlowLaunchSnapshot) -> [FlowJourneyStep] {
  var steps: [FlowJourneyStep] = []
  if snapshot.liveSession?.bindings.consent == nil, snapshot.consentStep {
    steps.append(.consent)
  }
  // Enhanced KYC is the one journey without capture: consent and processing only, per its validator.
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

/// A preview follows its capture, and the document products' two previews go together or not at all.
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
