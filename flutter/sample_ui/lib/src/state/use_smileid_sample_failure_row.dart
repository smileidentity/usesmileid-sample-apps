import 'package:usesmileid/usesmileid.dart';

import '../model/use_smileid_sample_error_resolution.dart';
import 'use_smileid_sample_error_handling.dart';

/// How a failure the SDK hands `onResult` picks its row of `spec/error-handling.json`. On
/// `Exception`, the type `UseSmileIDFailure` carries, so it reaches nothing else.
extension UseSmileIDSampleFailureRow on Exception {
  /// The row this failure resolves to; null when no submission returned it, such as a camera that could not start.
  UseSmileIDSampleErrorResolution? get errorResolution => switch (this) {
    NetworkServerException(:final int statusCode, :final String message) =>
      UseSmileIDSampleErrorHandling.forStatus(
        statusCode,
        serverMessage: message,
      ),
    NetworkTimeoutException() => UseSmileIDSampleErrorHandling.forTransport(
      UseSmileIDSampleTransportFailure.timeout,
    ),
    // The code, not its type: the SDK's library exports the exceptions and not their error-code classes.
    NetworkTransportException(:final errorCode)
        when errorCode?.code == 'NETWORK_CONNECTION_FAILED' =>
      UseSmileIDSampleErrorHandling.forTransport(
        UseSmileIDSampleTransportFailure.noConnection,
      ),
    _ => null,
  };
}
