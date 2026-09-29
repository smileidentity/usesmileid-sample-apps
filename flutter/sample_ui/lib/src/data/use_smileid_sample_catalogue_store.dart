import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/use_smileid_sample_environment.dart';
import '../state/use_smileid_sample_catalogue.dart';
import '../state/use_smileid_sample_id_details.dart';
import 'use_smileid_sample_catalogue_source.dart';

/// The ID form's lists for one run: fetched ahead, held in memory only, cancelled on leaving.
class UseSmileIDSampleCatalogueStore extends ChangeNotifier {
  /// [timeout] and [decode] are injectable for tests, whose fake clock never finishes an isolate.
  UseSmileIDSampleCatalogueStore(
    this._source, {
    this.timeout = const Duration(seconds: 10),
    UseSmileIDSampleDecodeRunner decode = compute,
  }) : _decode = decode;

  final UseSmileIDSampleCatalogueSource _source;
  final UseSmileIDSampleDecodeRunner _decode;

  /// How long a list may take before it is a failure.
  final Duration timeout;

  (UseSmileIDSampleEnvironment, String)? _run;
  int _generation = 0;
  bool _disposed = false;

  UseSmileIDSampleCatalogue<UseSmileIDSampleApiIdType> _idTypes =
      const UseSmileIDSampleCatalogueLoading<UseSmileIDSampleApiIdType>();
  UseSmileIDSampleCatalogue<UseSmileIDSampleApiCountryDocuments> _documents =
      const UseSmileIDSampleCatalogueLoading<
        UseSmileIDSampleApiCountryDocuments
      >();

  /// The `supported_id_types` response for this run.
  UseSmileIDSampleCatalogue<UseSmileIDSampleApiIdType> get idTypeList =>
      _idTypes;

  /// A product tap: a new run always asks the server again, so a list changed on the server shows up.
  void begin(UseSmileIDSampleEnvironment environment, String locale) {
    stop();
    _run = (environment, locale);
    _fetchIdTypes();
    _fetchDocuments();
  }

  /// The form itself: a deep link can land here without the product tap, so start only if nothing has.
  void ensure(UseSmileIDSampleEnvironment environment, String locale) {
    if (_run != (environment, locale)) {
      begin(environment, locale);
    }
  }

  /// Asks again for whichever list failed, under the same timing as the first attempt.
  void retry() {
    if (_run == null) {
      return;
    }
    if (_idTypes is UseSmileIDSampleCatalogueFailed) {
      _fetchIdTypes();
    }
    if (_documents is UseSmileIDSampleCatalogueFailed) {
      _fetchDocuments();
    }
  }

  /// Leaving the form: anything in flight is dropped and the next run starts clean.
  void stop() {
    // The form stops it after its own teardown, which can follow the owner's dispose.
    if (_disposed) {
      return;
    }
    _generation++;
    _run = null;
    _idTypes =
        const UseSmileIDSampleCatalogueLoading<UseSmileIDSampleApiIdType>();
    _documents =
        const UseSmileIDSampleCatalogueLoading<
          UseSmileIDSampleApiCountryDocuments
        >();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }

  /// The countries [family] offers.
  UseSmileIDSampleCatalogue<UseSmileIDSampleCountry> countries(
    UseSmileIDSampleCatalogueFamily family,
  ) {
    final UseSmileIDSampleCatalogue<UseSmileIDSampleApiIdType> types =
        family == UseSmileIDSampleCatalogueFamily.kyc
        ? _idTypes
        : const UseSmileIDSampleCatalogueReady<UseSmileIDSampleApiIdType>(
            <UseSmileIDSampleApiIdType>[],
          );
    return switch ((_documents, types)) {
      (UseSmileIDSampleCatalogueFailed(:final String reason), _) ||
      (
        _,
        UseSmileIDSampleCatalogueFailed(:final String reason),
      ) => UseSmileIDSampleCatalogueFailed<UseSmileIDSampleCountry>(reason),
      (
        UseSmileIDSampleCatalogueReady(
          items: final List<UseSmileIDSampleApiCountryDocuments> docs,
        ),
        UseSmileIDSampleCatalogueReady(
          items: final List<UseSmileIDSampleApiIdType> ids,
        ),
      ) =>
        _ready(
          UseSmileIDSampleCatalogueRules.countries(
            UseSmileIDSampleCatalogueData(ids, docs),
            family,
          ),
        ),
      _ => const UseSmileIDSampleCatalogueLoading<UseSmileIDSampleCountry>(),
    };
  }

  /// The ID types [country] offers.
  UseSmileIDSampleCatalogue<UseSmileIDSampleKycIdType> idTypes(
    String country,
  ) => switch (_idTypes) {
    UseSmileIDSampleCatalogueReady(
      items: final List<UseSmileIDSampleApiIdType> items,
    ) =>
      _ready(UseSmileIDSampleCatalogueRules.idTypes(items, country)),
    UseSmileIDSampleCatalogueFailed(:final String reason) =>
      UseSmileIDSampleCatalogueFailed<UseSmileIDSampleKycIdType>(reason),
    UseSmileIDSampleCatalogueEmpty() =>
      const UseSmileIDSampleCatalogueEmpty<UseSmileIDSampleKycIdType>(),
    UseSmileIDSampleCatalogueLoading() =>
      const UseSmileIDSampleCatalogueLoading<UseSmileIDSampleKycIdType>(),
  };

  /// The documents [country] offers.
  UseSmileIDSampleCatalogue<UseSmileIDSampleDocument> documents(
    String country,
  ) => switch (_documents) {
    UseSmileIDSampleCatalogueReady(
      items: final List<UseSmileIDSampleApiCountryDocuments> items,
    ) =>
      _ready(UseSmileIDSampleCatalogueRules.documents(items, country)),
    UseSmileIDSampleCatalogueFailed(:final String reason) =>
      UseSmileIDSampleCatalogueFailed<UseSmileIDSampleDocument>(reason),
    UseSmileIDSampleCatalogueEmpty() =>
      const UseSmileIDSampleCatalogueEmpty<UseSmileIDSampleDocument>(),
    UseSmileIDSampleCatalogueLoading() =>
      const UseSmileIDSampleCatalogueLoading<UseSmileIDSampleDocument>(),
  };

  void _fetchIdTypes() {
    final (UseSmileIDSampleEnvironment, String)? run = _run;
    if (run == null) {
      return;
    }
    _idTypes =
        const UseSmileIDSampleCatalogueLoading<UseSmileIDSampleApiIdType>();
    notifyListeners();
    final int generation = _generation;
    _load(
      () => _source.supportedIdTypes(run.$1),
      UseSmileIDSampleCatalogueJson.idTypes,
    ).then((UseSmileIDSampleCatalogue<UseSmileIDSampleApiIdType> result) {
      if (generation == _generation) {
        _idTypes = result;
        notifyListeners();
      }
    });
  }

  void _fetchDocuments() {
    final (UseSmileIDSampleEnvironment, String)? run = _run;
    if (run == null) {
      return;
    }
    _documents =
        const UseSmileIDSampleCatalogueLoading<
          UseSmileIDSampleApiCountryDocuments
        >();
    notifyListeners();
    final int generation = _generation;
    _load(
      () => _source.supportedDocuments(run.$1, run.$2),
      UseSmileIDSampleCatalogueJson.documents,
    ).then((
      UseSmileIDSampleCatalogue<UseSmileIDSampleApiCountryDocuments> result,
    ) {
      if (generation == _generation) {
        _documents = result;
        notifyListeners();
      }
    });
  }

  Future<UseSmileIDSampleCatalogue<T>> _load<T>(
    Future<String> Function() fetch,
    List<T>? Function(String) decode,
  ) async {
    try {
      // Decoded off the UI isolate: the whole catalogue is about 200 KB, which a sheet would feel.
      final String body = await fetch().timeout(timeout);
      final List<T>? items = await _decode(decode, body);
      return items == null
          ? UseSmileIDSampleCatalogueFailed<T>('Unreadable response')
          : UseSmileIDSampleCatalogueReady<T>(items);
    } on TimeoutException {
      return UseSmileIDSampleCatalogueFailed<T>('Timed out after $timeout');
    } on Object catch (error) {
      return UseSmileIDSampleCatalogueFailed<T>('$error');
    }
  }

  static UseSmileIDSampleCatalogue<T> _ready<T>(List<T> items) => items.isEmpty
      ? UseSmileIDSampleCatalogueEmpty<T>()
      : UseSmileIDSampleCatalogueReady<T>(items);
}

/// Runs a decode, off the UI isolate in the app and inline in a test.
typedef UseSmileIDSampleDecodeRunner =
    Future<R> Function<M, R>(ComputeCallback<M, R> callback, M message);

/// Runs [callback] on this isolate, for tests.
Future<R> useSmileIDSampleDecodeInline<M, R>(
  ComputeCallback<M, R> callback,
  M message,
) async => callback(message);
