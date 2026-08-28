/// The environment a job is submitted under. The token decides it; this is display only.
public enum UseSmileIDSampleEnvironment: String, CaseIterable, Sendable {
  case sandbox = "Sandbox"
  case production = "Production"

  public var label: String {
    rawValue
  }
}
