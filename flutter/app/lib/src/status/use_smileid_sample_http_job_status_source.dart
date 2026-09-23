import 'dart:convert';
import 'dart:io';

import 'package:sample_ui/sample_ui.dart';

/// `GET /v3/status/{jobId}`, the partner's own call: the SDK stops at the 202 that creates the job.
///
/// `dart:io` rather than a client package, so the shell carries no HTTP dependency of its own.
class UseSmileIDSampleHttpJobStatusSource
    implements UseSmileIDSampleJobStatusSource {
  /// [client] is injectable so a test can answer without a network.
  UseSmileIDSampleHttpJobStatusSource({HttpClient? client})
    : _client = client ?? HttpClient();

  final HttpClient _client;

  @override
  Future<UseSmileIDSampleStatusRefresh> check({
    required String jobId,
    required String token,
    required bool sandbox,
  }) async {
    final UseSmileIDSampleEnvironment environment = sandbox
        ? UseSmileIDSampleEnvironment.sandbox
        : UseSmileIDSampleEnvironment.production;
    final HttpClientRequest request = await _client.getUrl(
      Uri.parse(
        '${environment.baseUrl}v3/status/${Uri.encodeComponent(jobId)}',
      ),
    );
    // The session's own JWT. Never logged.
    request.headers.set('SmileID-Token', token);
    final HttpClientResponse response = await request.close();
    final String body = await response.transform(utf8.decoder).join();
    return useSmileIDSampleStatusOutcome(response.statusCode, body);
  }
}

/// The HTTP code and body onto an outcome; pure, so the branch table is unit-testable.
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
  // Unknown keys ignored: a field added server-side must not turn a good response into a failure.
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
    // Five API states onto four badges: `error` lands on Blocked and leans on the server's message.
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
