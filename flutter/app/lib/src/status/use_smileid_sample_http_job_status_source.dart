import 'dart:convert';
import 'dart:io';

import 'package:sample_ui/sample_ui.dart';

/// `GET /v3/status/{jobId}` over `dart:io`.
class UseSmileIDSampleHttpJobStatusSource
    implements UseSmileIDSampleJobStatusSource {
  /// [client] and [timeout] are injectable for tests.
  UseSmileIDSampleHttpJobStatusSource({
    HttpClient? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? (HttpClient()..connectionTimeout = timeout);

  final HttpClient _client;

  /// How long each step may take.
  final Duration timeout;

  @override
  Future<UseSmileIDSampleStatusRefresh> check({
    required String jobId,
    required String token,
    required bool sandbox,
  }) async {
    final UseSmileIDSampleEnvironment environment = sandbox
        ? UseSmileIDSampleEnvironment.sandbox
        : UseSmileIDSampleEnvironment.production;
    final HttpClientRequest request = await _client
        .getUrl(
          Uri.parse(
            '${environment.baseUrl}v3/status/${Uri.encodeComponent(jobId)}',
          ),
        )
        .timeout(timeout);
    // Never logged.
    request.headers.set('SmileID-Token', token);
    final HttpClientResponse response = await request.close().timeout(timeout);
    final String body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(timeout);
    return useSmileIDSampleStatusOutcome(response.statusCode, body);
  }
}

/// The HTTP code and body onto an outcome.
UseSmileIDSampleStatusRefresh useSmileIDSampleStatusOutcome(
  int code,
  String body,
) {
  final Object? json;
  try {
    json = jsonDecode(body);
  } on FormatException {
    return UseSmileIDSampleStatusFailed('HTTP $code');
  }
  if (code < 200 ||
      code > 299 ||
      json is! Map<String, Object?> ||
      json['status'] is! String ||
      json['message'] is! String) {
    return UseSmileIDSampleStatusFailed('HTTP $code');
  }
  final String status = json['status']! as String;
  if (status == 'processing') {
    return const UseSmileIDSampleStatusStillProcessing();
  }
  final UseSmileIDSampleStatus? badge = switch (status) {
    'clear' => UseSmileIDSampleStatus.clear,
    'attention' => UseSmileIDSampleStatus.attention,
    // `error` lands on Blocked, as on Android.
    'block' || 'error' => UseSmileIDSampleStatus.blocked,
    _ => null,
  };
  return badge == null
      ? UseSmileIDSampleStatusFailed("Unrecognised status '$status'")
      : UseSmileIDSampleStatusUpdated(
          status: badge,
          message: json['message']! as String,
          httpCode: code,
        );
}
