import 'dart:convert';

import '../model/use_smileid_sample_environment.dart';
import '../state/use_smileid_sample_token_decoder.dart';

/// The ID form's lists as raw bodies, so the network stays in the shell and one decoder reads live and fixture.
abstract interface class UseSmileIDSampleCatalogueSource {
  /// `GET /v3/services/supported_id_types`, every country.
  Future<String> supportedIdTypes(UseSmileIDSampleEnvironment environment);

  /// `GET /v3/services/supported_documents?locale=…`.
  Future<String> supportedDocuments(
    UseSmileIDSampleEnvironment environment,
    String locale,
  );

  /// `GET /v3/services/config?product=enhanced_document_verification&locale=…`, under the session's [token].
  Future<String> servicesConfig(
    UseSmileIDSampleEnvironment environment,
    String token,
    String locale,
  );
}

/// A response that is not a 2xx, so the store can name a 401 or 403 in the error state.
class UseSmileIDSampleCatalogueHttpException implements Exception {
  /// [status] is the HTTP status code.
  const UseSmileIDSampleCatalogueHttpException(this.status);

  /// The HTTP status code.
  final int status;

  @override
  String toString() => 'HTTP $status';
}

/// A live source that answers a simulated session's configuration from the fixture: the server refuses an unsigned token.
class UseSmileIDSampleSessionAwareCatalogueSource
    implements UseSmileIDSampleCatalogueSource {
  /// [live] answers everything a signed token asks; [fixture] a simulated session's configuration.
  const UseSmileIDSampleSessionAwareCatalogueSource(this._live, this._fixture);

  final UseSmileIDSampleCatalogueSource _live;
  final UseSmileIDSampleCatalogueSource _fixture;

  @override
  Future<String> supportedIdTypes(UseSmileIDSampleEnvironment environment) =>
      _live.supportedIdTypes(environment);

  @override
  Future<String> supportedDocuments(
    UseSmileIDSampleEnvironment environment,
    String locale,
  ) => _live.supportedDocuments(environment, locale);

  @override
  Future<String> servicesConfig(
    UseSmileIDSampleEnvironment environment,
    String token,
    String locale,
  ) => (UseSmileIDSampleTokenDecoder.isUnsigned(token) ? _fixture : _live)
      .servicesConfig(environment, token, locale);
}

/// `catalogue=fixture`: the bodies from `spec/catalogue-fixture.json`, with no network.
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

  @override
  Future<String> servicesConfig(
    UseSmileIDSampleEnvironment environment,
    String token,
    String locale,
  ) => Future<String>.value(jsonEncode(_root['services_config']));
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

  @override
  Future<String> servicesConfig(
    UseSmileIDSampleEnvironment environment,
    String token,
    String locale,
  ) => Future<String>.error(StateError('catalogue=unreachable'));
}
