import UseSmileID

public extension Error {
  /// The row a failure the SDK hands `onResult` resolves to; nil when no submission returned it, such as a camera that could not start.
  var useSmileIDSampleErrorResolution: UseSmileIDSampleErrorResolution? {
    switch self {
    case let refused as NetworkServerException:
      UseSmileIDSampleErrorHandling.forStatus(refused.statusCode, serverMessage: refused.message)
    case is NetworkTimeoutException:
      UseSmileIDSampleErrorHandling.forTransport(.timeout)
    case let transport as NetworkTransportException where transport.errorCode == .network(.connectionFailed):
      UseSmileIDSampleErrorHandling.forTransport(.noConnection)
    default:
      nil
    }
  }
}
