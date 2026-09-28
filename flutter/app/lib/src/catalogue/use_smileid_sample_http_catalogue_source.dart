import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sample_ui/sample_ui.dart';

/// The two unauthenticated catalogue endpoints over `dart:io`; no token is sent, both are the same for every partner.
class UseSmileIDSampleHttpCatalogueSource
    implements UseSmileIDSampleCatalogueSource {
  /// [client] is injectable for tests; the store owns the timeout.
  UseSmileIDSampleHttpCatalogueSource({HttpClient? client})
    : _client = client ?? HttpClient();

  final HttpClient _client;

  // The picker lists African countries only; the API's continent filter is how it asks for them.
  static const String _continent = 'AFRICA';

  @override
  Future<String> supportedIdTypes(UseSmileIDSampleEnvironment environment) =>
      _get(Uri.parse('${environment.baseUrl}v3/services/supported_id_types'));

  @override
  Future<String> supportedDocuments(
    UseSmileIDSampleEnvironment environment,
    String locale,
  ) => _get(
    Uri.parse('${environment.baseUrl}v3/services/supported_documents').replace(
      queryParameters: <String, String>{
        'continent': _continent,
        'locale': locale,
      },
    ),
  );

  Future<String> _get(Uri uri) async {
    final HttpClientRequest request = await _client.getUrl(uri);
    final HttpClientResponse response = await request.close();
    final String body = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw HttpException('HTTP ${response.statusCode}', uri: uri);
    }
    return body;
  }
}

/// `catalogue=fixture` from the app's copy of spec/catalogue-fixture.json, read once on first use.
class UseSmileIDSampleAssetCatalogueSource
    implements UseSmileIDSampleCatalogueSource {
  /// [bundle] is injectable for tests.
  UseSmileIDSampleAssetCatalogueSource({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  Future<UseSmileIDSampleFixtureCatalogueSource>? _fixture;

  /// The asset key pubspec.yaml declares.
  static const String asset = 'assets/catalogue-fixture.json';

  /// Forgotten on failure, so Retry reads the asset again rather than replaying the error.
  Future<UseSmileIDSampleFixtureCatalogueSource> get _source =>
      _fixture ??= _bundle
          .loadString(asset)
          .then(UseSmileIDSampleFixtureCatalogueSource.new)
          .catchError((Object error) {
            _fixture = null;
            throw error;
          });

  @override
  Future<String> supportedIdTypes(UseSmileIDSampleEnvironment environment) =>
      _source.then(
        (UseSmileIDSampleFixtureCatalogueSource it) =>
            it.supportedIdTypes(environment),
      );

  @override
  Future<String> supportedDocuments(
    UseSmileIDSampleEnvironment environment,
    String locale,
  ) => _source.then(
    (UseSmileIDSampleFixtureCatalogueSource it) =>
        it.supportedDocuments(environment, locale),
  );
}

/// The source the `catalogue` launch argument names.
UseSmileIDSampleCatalogueSource useSmileIDSampleCatalogueSource(
  UseSmileIDSampleCatalogueMode mode,
) => switch (mode) {
  UseSmileIDSampleCatalogueMode.live => UseSmileIDSampleHttpCatalogueSource(),
  UseSmileIDSampleCatalogueMode.fixture =>
    UseSmileIDSampleAssetCatalogueSource(),
  UseSmileIDSampleCatalogueMode.unreachable =>
    const UseSmileIDSampleUnreachableCatalogueSource(),
};
