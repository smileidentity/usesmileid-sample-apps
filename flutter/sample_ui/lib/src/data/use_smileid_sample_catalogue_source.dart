import 'dart:convert';

import '../model/use_smileid_sample_environment.dart';

/// The ID form's two lists as raw bodies, so the network stays in the shell and one decoder reads live and fixture.
abstract interface class UseSmileIDSampleCatalogueSource {
  /// `GET /v3/services/supported_id_types`, every country.
  Future<String> supportedIdTypes(UseSmileIDSampleEnvironment environment);

  /// `GET /v3/services/supported_documents?locale=…`.
  Future<String> supportedDocuments(
    UseSmileIDSampleEnvironment environment,
    String locale,
  );
}

/// `catalogue=fixture`: the two bodies from `spec/catalogue-fixture.json`, with no network.
class UseSmileIDSampleFixtureCatalogueSource
    implements UseSmileIDSampleCatalogueSource {
  /// [fixture] is the file's text; each response is re-encoded so the store decodes it as a body.
  UseSmileIDSampleFixtureCatalogueSource(String fixture)
    : _root = jsonDecode(fixture) as Map<String, Object?>;

  final Map<String, Object?> _root;

  @override
  Future<String> supportedIdTypes(UseSmileIDSampleEnvironment environment) =>
      Future<String>.value(jsonEncode(_root['supported_id_types']));

  @override
  Future<String> supportedDocuments(
    UseSmileIDSampleEnvironment environment,
    String locale,
  ) => Future<String>.value(jsonEncode(_root['supported_documents']));
}

/// `catalogue=unreachable`: every call fails at once, which is how a flow reaches the error state.
class UseSmileIDSampleUnreachableCatalogueSource
    implements UseSmileIDSampleCatalogueSource {
  /// Stateless.
  const UseSmileIDSampleUnreachableCatalogueSource();

  @override
  Future<String> supportedIdTypes(UseSmileIDSampleEnvironment environment) =>
      Future<String>.error(StateError('catalogue=unreachable'));

  @override
  Future<String> supportedDocuments(
    UseSmileIDSampleEnvironment environment,
    String locale,
  ) => Future<String>.error(StateError('catalogue=unreachable'));
}
