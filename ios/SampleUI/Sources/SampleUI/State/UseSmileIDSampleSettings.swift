/// Which settings row a toggle belongs to, so the screen reports changes without a callback per row.
public enum UseSmileIDSampleSetting: String, CaseIterable, Sendable {
  case enhancedSmartSelfie, agentMode, darkMode, consentStep, instructionsStep, previewStep
  case galleryUpload, captureBothSides, allowSkipBack, selfieFirst
}

/// DocumentCaptureConfig.captureMode, in `spec/test-ids.json`'s vocabulary.
public enum UseSmileIDSampleCaptureMode: String, CaseIterable, Sendable {
  case auto, manual, autoWithFallback

  public var label: String {
    switch self {
    case .auto: "Automatic"
    case .manual: "Manual"
    case .autoWithFallback: "Automatic with manual fallback"
    }
  }
}

/// The Settings state. Three of these decide whether a step is composed into the flow at all.
public struct UseSmileIDSampleSettings: Equatable, Sendable {
  /// ON is the head-turn challenge, which is the default the design draws.
  public var enhancedSmartSelfie: Bool
  public var agentMode: Bool
  /// This app's own appearance; the `theme` launch argument seeds a run's SDK theme scenario, which is a different axis.
  public var darkMode: Bool
  public var consentStep: Bool
  public var instructionsStep: Bool
  public var previewStep: Bool
  /// DocumentCaptureConfig.allowGalleryUpload; off, as the SDK defaults it.
  public var galleryUpload: Bool
  /// DocumentCaptureConfig.captureBothSides; on, as the SDK defaults it.
  public var captureBothSides: Bool
  /// DocumentCaptureConfig.allowSkipBack; off, as the SDK defaults it.
  public var allowSkipBack: Bool
  /// The document products capture the selfie before the document.
  public var selfieFirst: Bool
  /// A typed field rather than one of the switches: three values, not two.
  public var captureMode: UseSmileIDSampleCaptureMode

  public init(
    enhancedSmartSelfie: Bool = true,
    agentMode: Bool = false,
    darkMode: Bool = false,
    consentStep: Bool = true,
    instructionsStep: Bool = true,
    previewStep: Bool = true,
    galleryUpload: Bool = false,
    captureBothSides: Bool = true,
    allowSkipBack: Bool = false,
    selfieFirst: Bool = false,
    captureMode: UseSmileIDSampleCaptureMode = .autoWithFallback
  ) {
    self.enhancedSmartSelfie = enhancedSmartSelfie
    self.agentMode = agentMode
    self.darkMode = darkMode
    self.consentStep = consentStep
    self.instructionsStep = instructionsStep
    self.previewStep = previewStep
    self.galleryUpload = galleryUpload
    self.captureBothSides = captureBothSides
    self.allowSkipBack = allowSkipBack
    self.selfieFirst = selfieFirst
    self.captureMode = captureMode
  }

  public subscript(setting: UseSmileIDSampleSetting) -> Bool {
    switch setting {
    case .enhancedSmartSelfie: enhancedSmartSelfie
    case .agentMode: agentMode
    case .darkMode: darkMode
    case .consentStep: consentStep
    case .instructionsStep: instructionsStep
    case .previewStep: previewStep
    case .galleryUpload: galleryUpload
    case .captureBothSides: captureBothSides
    case .allowSkipBack: allowSkipBack
    case .selfieFirst: selfieFirst
    }
  }

  /// Drops enhanced liveness where a stored state carries both, since the SDK refuses the pair.
  public func normalised() -> Self {
    agentMode && enhancedSmartSelfie ? with(.enhancedSmartSelfie, false) : self
  }

  /// The capture mutex: the SDK refuses the pair, so turning either on turns the other off.
  public func with(_ setting: UseSmileIDSampleSetting, _ enabled: Bool) -> Self {
    var copy = self
    switch setting {
    case .enhancedSmartSelfie:
      copy.enhancedSmartSelfie = enabled
      copy.agentMode = agentMode && !enabled
    case .agentMode:
      copy.agentMode = enabled
      copy.enhancedSmartSelfie = enhancedSmartSelfie && !enabled
    case .darkMode: copy.darkMode = enabled
    case .consentStep: copy.consentStep = enabled
    case .instructionsStep: copy.instructionsStep = enabled
    case .previewStep: copy.previewStep = enabled
    case .galleryUpload: copy.galleryUpload = enabled
    case .captureBothSides: copy.captureBothSides = enabled
    case .allowSkipBack: copy.allowSkipBack = enabled
    case .selfieFirst: copy.selfieFirst = enabled
    }
    return copy
  }
}
