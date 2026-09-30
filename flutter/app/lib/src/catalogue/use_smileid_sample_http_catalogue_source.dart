import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sample_ui/sample_ui.dart';

/// The two unauthenticated catalogue endpoints over `dart:io`, and the partner's own configuration under its token.
class UseSmileIDSampleHttpCatalogueSource
    implements UseSmileIDSampleCatalogueSource {
  /// [client] is injectable for tests; [timeout] matches the store's, so a request it gives up on is torn down.
  UseSmileIDSampleHttpCatalogueSource({
    HttpClient? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = (client ?? HttpClient())..connectionTimeout = timeout;

  /// How long one request may take before it is aborted.
  final Duration timeout;

  final HttpClient _client;

  @override
  Future<String> supportedIdTypes(UseSmileIDSampleEnvironment environment) =>
      _get(Uri.parse('${environment.baseUrl}v3/services/supported_id_types'));

  @override
  Future<String> supportedDocuments(
    UseSmileIDSampleEnvironment environment,
    String locale,
  ) => _get(
    Uri.parse(
      '${environment.baseUrl}v3/services/supported_documents',
    ).replace(queryParameters: <String, String>{'locale': locale}),
  );

  @override
  Future<String> servicesConfig(
    UseSmileIDSampleEnvironment environment,
    String token,
    String locale,
  ) => _get(
    Uri.parse('${environment.baseUrl}v3/services/config').replace(
      queryParameters: <String, String>{
        'product': UseSmileIDSampleCatalogueJson.enhancedDocumentVerification,
        'locale': locale,
      },
    ),
    token: token,
  );

  Future<String> _get(Uri uri, {String? token}) async {
    final HttpClientRequest request = await _client.getUrl(uri);
    if (token != null) {
      request.headers.set('SmileID-Token', token);
    }
    try {
      return await _read(uri, request).timeout(timeout);
    } on TimeoutException {
      request.abort();
      rethrow;
    }
  }

  Future<String> _read(Uri uri, HttpClientRequest request) async {
    final HttpClientResponse response = await request.close();
    final String body = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw UseSmileIDSampleCatalogueHttpException(response.statusCode);
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

  @override
  Future<String> servicesConfig(
    UseSmileIDSampleEnvironment environment,
    String token,
    String locale,
  ) => _source.then(
    (UseSmileIDSampleFixtureCatalogueSource it) =>
        it.servicesConfig(environment, token, locale),
  );
}

/// The source the `catalogue` launch argument names.
UseSmileIDSampleCatalogueSource useSmileIDSampleCatalogueSource(
  UseSmileIDSampleCatalogueMode mode,
) => switch (mode) {
  UseSmileIDSampleCatalogueMode.live =>
    UseSmileIDSampleSessionAwareCatalogueSource(
      UseSmileIDSampleHttpCatalogueSource(),
      UseSmileIDSampleAssetCatalogueSource(),
    ),
  UseSmileIDSampleCatalogueMode.fixture =>
    UseSmileIDSampleAssetCatalogueSource(),
  UseSmileIDSampleCatalogueMode.unreachable =>
    const UseSmileIDSampleUnreachableCatalogueSource(),
};
