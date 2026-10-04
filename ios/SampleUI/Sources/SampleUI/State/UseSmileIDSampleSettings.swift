/// Which settings row a toggle belongs to, so the screen reports changes without a callback per row.
public enum UseSmileIDSampleSetting: String, CaseIterable, Sendable {
  case enhancedSmartSelfie, agentMode, consentStep, instructionsStep, previewStep
  case galleryUpload, allowSkipBack, selfieFirst
}

/// DocumentCaptureConfig.captureMode, in `spec/test-ids.json`'s vocabulary.
public enum UseSmileIDSampleCaptureMode: String, CaseIterable, Sendable {
  case auto, manual, autoWithFallback

  public var label: String {
    switch self {
    case .auto: UseSmileIDSampleStrings.captureModeAuto
    case .manual: UseSmileIDSampleStrings.captureModeManual
    case .autoWithFallback: UseSmileIDSampleStrings.captureModeAutoWithFallback
    }
  }
}

/// The app's theme choice; System follows the device's own theme.
public enum UseSmileIDSampleAppearance: String, CaseIterable, Sendable {
  case system, light, dark

  /// Whether the app renders dark, given the device's own theme.
  public func isDark(deviceDark: Bool) -> Bool {
    switch self {
    case .system: deviceDark
    case .light: false
    case .dark: true
    }
  }

  /// System names the device's theme, not the one the app renders.
  public func label(deviceDark: Bool) -> String {
    switch self {
    case .system: deviceDark ? UseSmileIDSampleStrings.appearanceSystemDark : UseSmileIDSampleStrings.appearanceSystemLight
    case .light: UseSmileIDSampleStrings.appearanceLight
    case .dark: UseSmileIDSampleStrings.appearanceDark
    }
  }
}

/// The app's language: System follows the device; the rest are in `spec/l10n/languages.json`.
public enum UseSmileIDSampleLanguage: String, CaseIterable, Sendable {
  case system, en, fr, ar, he

  /// The language's name in itself, which no other language translates.
  public var endonym: String {
    switch self {
    case .system: ""
    case .en: "English"
    case .fr: "Français"
    case .ar: "العربية"
    case .he: "עברית"
    }
  }

  /// System resolves to the first device language the app ships, else English.
  public func resolved(deviceLanguages: [String]) -> UseSmileIDSampleLanguage {
    guard self == .system else { return self }
    return deviceLanguages.lazy.compactMap(Self.shipped).first ?? .en
  }

  /// System names the language the device resolves to; a named language is its own endonym.
  public func label(deviceLanguages: [String]) -> String {
    self == .system
      ? UseSmileIDSampleStrings.languageSystem(language: resolved(deviceLanguages: deviceLanguages).endonym)
      : endonym
  }

  /// The shipped language a BCP 47 tag names, by its language subtag.
  public static func shipped(_ tag: String) -> UseSmileIDSampleLanguage? {
    let language = tag.split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map { $0.lowercased() } ?? ""
    return allCases.first { $0 != .system && $0.rawValue == language }
  }
}

/// The Settings state. Three of these decide whether a step is composed into the flow at all.
public struct UseSmileIDSampleSettings: Equatable, Sendable {
  /// ON is the head-turn challenge, which is the default the design draws.
  public var enhancedSmartSelfie: Bool
  public var agentMode: Bool
  public var consentStep: Bool
  public var instructionsStep: Bool
  public var previewStep: Bool
  /// DocumentCaptureConfig.allowGalleryUpload; off, as the SDK defaults it.
  public var galleryUpload: Bool
  /// DocumentCaptureConfig.allowSkipBack; off, as the SDK defaults it.
  public var allowSkipBack: Bool
  /// The document products capture the selfie before the document.
  public var selfieFirst: Bool
  /// A typed field rather than one of the switches: three values, not two.
  public var captureMode: UseSmileIDSampleCaptureMode
  /// This app's own appearance; the `theme` launch argument seeds a run's SDK theme scenario, which is a different axis.
  public var appearance: UseSmileIDSampleAppearance
  /// Typed like `appearance`; System follows the device's own language.
  public var language: UseSmileIDSampleLanguage

  public init(
    enhancedSmartSelfie: Bool = true,
    agentMode: Bool = false,
    consentStep: Bool = true,
    instructionsStep: Bool = true,
    previewStep: Bool = true,
    galleryUpload: Bool = false,
    allowSkipBack: Bool = false,
    selfieFirst: Bool = false,
    captureMode: UseSmileIDSampleCaptureMode = .autoWithFallback,
    appearance: UseSmileIDSampleAppearance = .system,
    language: UseSmileIDSampleLanguage = .system
  ) {
    self.enhancedSmartSelfie = enhancedSmartSelfie
    self.agentMode = agentMode
    self.consentStep = consentStep
    self.instructionsStep = instructionsStep
    self.previewStep = previewStep
    self.galleryUpload = galleryUpload
    self.allowSkipBack = allowSkipBack
    self.selfieFirst = selfieFirst
    self.captureMode = captureMode
    self.appearance = appearance
    self.language = language
  }

  public subscript(setting: UseSmileIDSampleSetting) -> Bool {
    switch setting {
    case .enhancedSmartSelfie: enhancedSmartSelfie
    case .agentMode: agentMode
    case .consentStep: consentStep
    case .instructionsStep: instructionsStep
    case .previewStep: previewStep
    case .galleryUpload: galleryUpload
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
    case .consentStep: copy.consentStep = enabled
    case .instructionsStep: copy.instructionsStep = enabled
    case .previewStep: copy.previewStep = enabled
    case .galleryUpload: copy.galleryUpload = enabled
    case .allowSkipBack: copy.allowSkipBack = enabled
    case .selfieFirst: copy.selfieFirst = enabled
    }
    return copy
  }
}
