/// Which settings row a toggle belongs to, so the screen reports changes without eight callbacks.
public enum UseSmileIDSampleSetting: String, CaseIterable, Sendable {
  case enhancedSmartSelfie, agentMode, darkMode, consentStep, instructionsStep, previewStep, customContinue, customCancel
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
  /// The SDK's continue buttons (consent allow, instructions, processing continue) become "Custom continue".
  public var customContinue: Bool
  /// The SDK's cancel buttons (consent deny, processing exit) become "Custom cancel".
  public var customCancel: Bool

  public init(
    enhancedSmartSelfie: Bool = true,
    agentMode: Bool = false,
    darkMode: Bool = false,
    consentStep: Bool = true,
    instructionsStep: Bool = true,
    previewStep: Bool = true,
    customContinue: Bool = false,
    customCancel: Bool = false
  ) {
    self.enhancedSmartSelfie = enhancedSmartSelfie
    self.agentMode = agentMode
    self.darkMode = darkMode
    self.consentStep = consentStep
    self.instructionsStep = instructionsStep
    self.previewStep = previewStep
    self.customContinue = customContinue
    self.customCancel = customCancel
  }

  public subscript(setting: UseSmileIDSampleSetting) -> Bool {
    switch setting {
    case .enhancedSmartSelfie: enhancedSmartSelfie
    case .agentMode: agentMode
    case .darkMode: darkMode
    case .consentStep: consentStep
    case .instructionsStep: instructionsStep
    case .previewStep: previewStep
    case .customContinue: customContinue
    case .customCancel: customCancel
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
    case .customContinue: copy.customContinue = enabled
    case .customCancel: copy.customCancel = enabled
    }
    return copy
  }
}
