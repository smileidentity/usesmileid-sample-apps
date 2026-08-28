/// The four job statuses, Title case as the design sets them.
public enum UseSmileIDSampleStatus: String, CaseIterable, Sendable {
  case clear = "Clear"
  case attention = "Attention"
  case blocked = "Blocked"
  case processing = "Processing"

  public var label: String {
    rawValue
  }
}
