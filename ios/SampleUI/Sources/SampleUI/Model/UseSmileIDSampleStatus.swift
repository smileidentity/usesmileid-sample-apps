/// The five job statuses; the raw value is stored, so it never changes with the language.
public enum UseSmileIDSampleStatus: String, CaseIterable, Sendable {
  case clear = "Clear"
  case attention = "Attention"
  case blocked = "Blocked"
  case error = "Error"
  case processing = "Processing"

  /// The status in the app's language.
  public var label: String {
    switch self {
    case .clear: UseSmileIDSampleStrings.statusClear
    case .attention: UseSmileIDSampleStrings.statusAttention
    case .blocked: UseSmileIDSampleStrings.statusBlocked
    case .error: UseSmileIDSampleStrings.statusError
    case .processing: UseSmileIDSampleStrings.statusProcessing
    }
  }
}
