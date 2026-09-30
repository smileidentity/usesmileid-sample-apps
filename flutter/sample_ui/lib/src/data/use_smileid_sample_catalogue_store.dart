import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/use_smileid_sample_environment.dart';
import '../model/use_smileid_sample_product.dart';
import '../state/use_smileid_sample_catalogue.dart';
import '../state/use_smileid_sample_id_details.dart';
import '../state/use_smileid_sample_token_session.dart';
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
  (String?, UseSmileIDSampleEnvironment, String)? _enabledKey;
  String _enabledToken = '';
  int _enabledGeneration = 0;
  bool _enabledInFlight = false;
  UseSmileIDSampleCatalogue<UseSmileIDSampleApiEnabledCountry> _enabled =
      const UseSmileIDSampleCatalogueLoading<
        UseSmileIDSampleApiEnabledCountry
      >();

  /// The partner's Enhanced Document Verification list, kept per session: only a relink or a locale change asks again.
  UseSmileIDSampleCatalogue<UseSmileIDSampleApiEnabledCountry> get enabled =>
      _enabled;

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

  /// Enhanced Document Verification: fetches [session]'s list unless it is already here or on its way.
  void ensureEnabled(
    UseSmileIDSampleEnvironment environment,
    String locale,
    UseSmileIDSampleTokenSession? session,
  ) {
    final (String?, UseSmileIDSampleEnvironment, String) key = (
      session?.id,
      environment,
      locale,
    );
    if (key == _enabledKey &&
        (_enabled is UseSmileIDSampleCatalogueReady || _enabledInFlight)) {
      return;
    }
    _enabledKey = key;
    _enabledToken = session?.token ?? '';
    _fetchEnabled();
  }

  /// Asks again for whichever list failed, under the same timing as the first attempt.
  void retry() {
    if (_enabled is UseSmileIDSampleCatalogueFailed) {
      _fetchEnabled();
    }
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

  /// Leaving the form: anything in flight is dropped and the next run starts clean, bar a session's arrived list.
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
    if (_enabled is! UseSmileIDSampleCatalogueReady) {
      _enabledGeneration++;
      _enabledInFlight = false;
      _enabledKey = null;
      _enabledToken = '';
      _enabled =
          const UseSmileIDSampleCatalogueLoading<
            UseSmileIDSampleApiEnabledCountry
          >();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _enabledGeneration++;
    super.dispose();
  }

  /// The countries [family] offers; Enhanced Document Verification only those its partner enabled.
  UseSmileIDSampleCatalogue<UseSmileIDSampleCountry> countries(
    UseSmileIDSampleCatalogueFamily family, {
    UseSmileIDSampleProduct? product,
  }) {
    if (product == UseSmileIDSampleProduct.enhancedDocumentVerification) {
      return _withEnabled(UseSmileIDSampleCatalogueRules.enabledCountries);
    }
    final UseSmileIDSampleCatalogue<UseSmileIDSampleApiIdType> types =
        family == UseSmileIDSampleCatalogueFamily.kyc
        ? _idTypes
        : const UseSmileIDSampleCatalogueReady<UseSmileIDSampleApiIdType>(
            <UseSmileIDSampleApiIdType>[],
          );
    return switch ((_documents, types)) {
      (
        UseSmileIDSampleCatalogueFailed(
          :final String reason,
          :final String advice,
        ),
        _,
      ) ||
      (
        _,
        UseSmileIDSampleCatalogueFailed(
          :final String reason,
          :final String advice,
        ),
      ) => UseSmileIDSampleCatalogueFailed<UseSmileIDSampleCountry>(
        reason,
        advice: advice,
      ),
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
    UseSmileIDSampleCatalogueFailed(
      :final String reason,
      :final String advice,
    ) =>
      UseSmileIDSampleCatalogueFailed<UseSmileIDSampleKycIdType>(
        reason,
        advice: advice,
      ),
    UseSmileIDSampleCatalogueEmpty() =>
      const UseSmileIDSampleCatalogueEmpty<UseSmileIDSampleKycIdType>(),
    UseSmileIDSampleCatalogueLoading() =>
      const UseSmileIDSampleCatalogueLoading<UseSmileIDSampleKycIdType>(),
  };

  /// The documents [country] offers on [product].
  UseSmileIDSampleCatalogue<UseSmileIDSampleDocument> documents(
    String country, {
    UseSmileIDSampleProduct product =
        UseSmileIDSampleProduct.documentVerification,
  }) => product == UseSmileIDSampleProduct.enhancedDocumentVerification
      ? _withEnabled(
          (
            List<UseSmileIDSampleApiCountryDocuments> all,
            List<UseSmileIDSampleApiEnabledCountry> enabled,
          ) => UseSmileIDSampleCatalogueRules.enabledDocuments(
            all,
            enabled,
            country,
          ),
        )
      : switch (_documents) {
          UseSmileIDSampleCatalogueReady(
            items: final List<UseSmileIDSampleApiCountryDocuments> items,
          ) =>
            _ready(
              UseSmileIDSampleCatalogueRules.documents(
                items,
                country,
                product: product,
              ),
            ),
          UseSmileIDSampleCatalogueFailed(
            :final String reason,
            :final String advice,
          ) =>
            UseSmileIDSampleCatalogueFailed<UseSmileIDSampleDocument>(
              reason,
              advice: advice,
            ),
          UseSmileIDSampleCatalogueEmpty() =>
            const UseSmileIDSampleCatalogueEmpty<UseSmileIDSampleDocument>(),
          UseSmileIDSampleCatalogueLoading() =>
            const UseSmileIDSampleCatalogueLoading<UseSmileIDSampleDocument>(),
        };

  UseSmileIDSampleCatalogue<T> _withEnabled<T>(
    List<T> Function(
      List<UseSmileIDSampleApiCountryDocuments>,
      List<UseSmileIDSampleApiEnabledCountry>,
    )
    rows,
  ) => switch ((_enabled, _documents)) {
    (
      UseSmileIDSampleCatalogueFailed(
        :final String reason,
        :final String advice,
      ),
      _,
    ) ||
    (
      _,
      UseSmileIDSampleCatalogueFailed(
        :final String reason,
        :final String advice,
      ),
    ) => UseSmileIDSampleCatalogueFailed<T>(reason, advice: advice),
    (
      UseSmileIDSampleCatalogueReady(
        items: final List<UseSmileIDSampleApiEnabledCountry> allowed,
      ),
      UseSmileIDSampleCatalogueReady(
        items: final List<UseSmileIDSampleApiCountryDocuments> docs,
      ),
    ) =>
      _ready(rows(docs, allowed)),
    _ => UseSmileIDSampleCatalogueLoading<T>(),
  };

  void _fetchEnabled() {
    final (String?, UseSmileIDSampleEnvironment, String)? key = _enabledKey;
    if (key == null) {
      return;
    }
    final String token = _enabledToken;
    _enabled =
        const UseSmileIDSampleCatalogueLoading<
          UseSmileIDSampleApiEnabledCountry
        >();
    _enabledInFlight = true;
    notifyListeners();
    final int generation = ++_enabledGeneration;
    _load(
      () => _source.servicesConfig(key.$2, token, key.$3),
      UseSmileIDSampleCatalogueJson.enabledCountries,
    ).then((
      UseSmileIDSampleCatalogue<UseSmileIDSampleApiEnabledCountry> result,
    ) {
      if (generation == _enabledGeneration) {
        _enabled = result;
        _enabledInFlight = false;
        notifyListeners();
      }
    });
  }

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
    } on UseSmileIDSampleCatalogueHttpException catch (refused) {
      return UseSmileIDSampleCatalogueFailed<T>(
        '$refused',
        advice: UseSmileIDSampleCatalogueRules.advice(refused.status),
      );
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
