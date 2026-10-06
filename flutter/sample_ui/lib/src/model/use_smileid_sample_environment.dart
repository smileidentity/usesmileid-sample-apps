import '../use_smileid_sample_strings.dart';

/// Sandbox or production; there is no third case, and the SDK resolves to the same two hosts.
enum UseSmileIDSampleEnvironment {
  /// The sandbox, which every automated run reads.
  sandbox('sandbox', 'testapi.smileidentity.com'),

  /// Production.
  production('production', 'api.smileidentity.com');

  const UseSmileIDSampleEnvironment(this.id, this.host);

  /// The id the result card publishes.
  final String id;

  /// The human-readable name.
  String label(UseSmileIDSampleStrings strings) => switch (this) {
    UseSmileIDSampleEnvironment.sandbox => strings.scanEnvironmentSandbox,
    UseSmileIDSampleEnvironment.production => strings.scanEnvironmentProduction,
  };

  /// The API host the token's `api_url` claim names.
  final String host;

  /// Trailing slash, which is the form the SDK's own constants take.
  String get baseUrl => 'https://$host/';
}

/// A token's `api_url` onto an environment, matched on the parsed host: a real claim carries a
/// `/v3` path and no trailing slash, so a whole-string compare misses, and misses silently.
UseSmileIDSampleEnvironment? environmentFor(String? apiUrl) {
  final String? host = apiUrlHost(apiUrl);
  if (host == null) {
    return null;
  }
  return UseSmileIDSampleEnvironment.values
      .where((UseSmileIDSampleEnvironment it) => it.host == host)
      .firstOrNull;
}

/// The host an `api_url` names, so a rejection can say which one it saw.
String? apiUrlHost(String? apiUrl) {
  final String trimmed = apiUrl?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }
  final String? host = Uri.tryParse(trimmed)?.host;
  return host == null || host.isEmpty ? null : host.toLowerCase();
}
