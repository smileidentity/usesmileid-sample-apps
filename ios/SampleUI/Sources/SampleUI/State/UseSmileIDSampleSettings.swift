/// Which settings row a toggle belongs to, so the screen reports changes without six callbacks.
public enum UseSmileIDSampleSetting: String, CaseIterable, Sendable {
  case enhancedSmartSelfie, agentMode, darkMode, consentStep, instructionsStep, previewStep
}

/// The Settings state. Three of these decide whether a step is composed into the flow at all.
public struct UseSmileIDSampleSettings: Equatable, Sendable {
  /// ON is the head-turn challenge, which is the default the design draws.
  public var enhancedSmartSelfie: Bool
  public var agentMode: Bool
  public var darkMode: Bool
  public var consentStep: Bool
  public var instructionsStep: Bool
  public var previewStep: Bool

  public init(
    enhancedSmartSelfie: Bool = true,
    agentMode: Bool = false,
    darkMode: Bool = false,
    consentStep: Bool = true,
    instructionsStep: Bool = true,
    previewStep: Bool = true
  ) {
    self.enhancedSmartSelfie = enhancedSmartSelfie
    self.agentMode = agentMode
    self.darkMode = darkMode
    self.consentStep = consentStep
    self.instructionsStep = instructionsStep
    self.previewStep = previewStep
  }

  public subscript(setting: UseSmileIDSampleSetting) -> Bool {
    switch setting {
    case .enhancedSmartSelfie: enhancedSmartSelfie
    case .agentMode: agentMode
    case .darkMode: darkMode
    case .consentStep: consentStep
    case .instructionsStep: instructionsStep
    case .previewStep: previewStep
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
    }
    return copy
  }
}
