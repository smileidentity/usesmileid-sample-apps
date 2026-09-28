import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import '../support/catalogue_fixtures.dart';

/// The store fetches ahead, fails whole lists, retries only what failed and drops a run it left.
void main() {
  const UseSmileIDSampleEnvironment sandbox =
      UseSmileIDSampleEnvironment.sandbox;

  UseSmileIDSampleCatalogueStore storeOver(
    UseSmileIDSampleCatalogueSource source,
  ) => UseSmileIDSampleCatalogueStore(
    source,
    decode: useSmileIDSampleDecodeInline,
  );

  testWidgets('a product tap fetches both lists, and the rules apply', (
    WidgetTester tester,
  ) async {
    final _CountingSource source = _CountingSource();
    final UseSmileIDSampleCatalogueStore store = storeOver(source)
      ..begin(sandbox, 'en-GB');
    addTearDown(store.dispose);
    expect(
      store.countries(UseSmileIDSampleCatalogueFamily.kyc).isLoading,
      isTrue,
    );

    await tester.pump();

    expect(source.idTypeCalls, 1);
    expect(source.documentCalls, 1);
    expect(source.locales, <String>['en-GB']);
    final UseSmileIDSampleCatalogue<UseSmileIDSampleKycIdType> kenya = store
        .idTypes('KE');
    expect(
      kenya,
      isA<UseSmileIDSampleCatalogueReady<UseSmileIDSampleKycIdType>>(),
    );
    expect(
      (kenya as UseSmileIDSampleCatalogueReady<UseSmileIDSampleKycIdType>).items
          .map((UseSmileIDSampleKycIdType it) => it.id),
      CatalogueFixtures.idTypes(
        'KE',
      ).map((UseSmileIDSampleKycIdType it) => it.id),
    );
  });

  testWidgets('the form entering the same run does not ask again', (
    WidgetTester tester,
  ) async {
    final _CountingSource source = _CountingSource();
    final UseSmileIDSampleCatalogueStore store = storeOver(source)
      ..begin(sandbox, 'en-GB');
    addTearDown(store.dispose);
    await tester.pump();

    store.ensure(sandbox, 'en-GB');
    await tester.pump();

    expect(source.idTypeCalls, 1);
  });

  testWidgets('a deep link with no product tap starts the fetch itself', (
    WidgetTester tester,
  ) async {
    final _CountingSource source = _CountingSource();
    final UseSmileIDSampleCatalogueStore store = storeOver(source)
      ..ensure(sandbox, 'en-GB');
    addTearDown(store.dispose);
    await tester.pump();

    expect(source.idTypeCalls, 1);
  });

  testWidgets('a failure fails the list, and Retry asks only for that one', (
    WidgetTester tester,
  ) async {
    final _CountingSource source = _CountingSource(failIdTypes: true);
    final UseSmileIDSampleCatalogueStore store = storeOver(source)
      ..begin(sandbox, 'en-GB');
    addTearDown(store.dispose);
    await tester.pump();

    expect(
      store.idTypes('KE'),
      isA<UseSmileIDSampleCatalogueFailed<UseSmileIDSampleKycIdType>>(),
    );
    expect(
      store.countries(UseSmileIDSampleCatalogueFamily.kyc),
      isA<UseSmileIDSampleCatalogueFailed<UseSmileIDSampleCountry>>(),
    );
    expect(
      store.countries(UseSmileIDSampleCatalogueFamily.document),
      isA<UseSmileIDSampleCatalogueReady<UseSmileIDSampleCountry>>(),
      reason: 'the document products never read supported_id_types',
    );

    source.failIdTypes = false;
    store.retry();
    await tester.pump();

    expect(source.idTypeCalls, 2);
    expect(source.documentCalls, 1);
    expect(
      store.idTypes('KE'),
      isA<UseSmileIDSampleCatalogueReady<UseSmileIDSampleKycIdType>>(),
    );
  });

  testWidgets('a list that never answers fails after the timeout', (
    WidgetTester tester,
  ) async {
    final _CountingSource source = _CountingSource(hang: true);
    final UseSmileIDSampleCatalogueStore store = storeOver(source)
      ..begin(sandbox, 'en-GB');
    addTearDown(store.dispose);

    await tester.pump(const Duration(seconds: 9));
    expect(store.documents('KE').isLoading, isTrue);

    await tester.pump(const Duration(seconds: 2));
    expect(
      store.documents('KE'),
      isA<UseSmileIDSampleCatalogueFailed<UseSmileIDSampleDocument>>(),
    );
  });

  testWidgets('an answer arriving after stop is dropped', (
    WidgetTester tester,
  ) async {
    final _CountingSource source = _CountingSource(hang: true);
    final UseSmileIDSampleCatalogueStore store = storeOver(source)
      ..begin(sandbox, 'en-GB');
    addTearDown(store.dispose);
    store.stop();

    source.release();
    await tester.pump(const Duration(seconds: 11));

    expect(store.documents('KE').isLoading, isTrue);
  });

  testWidgets('a new run always asks the server again', (
    WidgetTester tester,
  ) async {
    final _CountingSource source = _CountingSource();
    final UseSmileIDSampleCatalogueStore store = storeOver(source)
      ..begin(sandbox, 'en-GB');
    addTearDown(store.dispose);
    await tester.pump();

    store.begin(sandbox, 'en-GB');
    await tester.pump();

    expect(source.documentCalls, 2);
  });
}

/// The fixture, counting calls, with a switchable failure and a hang released by hand.
class _CountingSource implements UseSmileIDSampleCatalogueSource {
  _CountingSource({this.failIdTypes = false, this.hang = false});

  final UseSmileIDSampleFixtureCatalogueSource _fixture =
      UseSmileIDSampleFixtureCatalogueSource(CatalogueFixtures.json);
  final Completer<void> _released = Completer<void>();

  bool failIdTypes;
  final bool hang;
  int idTypeCalls = 0;
  int documentCalls = 0;
  final List<String> locales = <String>[];

  void release() => _released.complete();

  Future<String> _answer(Future<String> Function() body) async {
    if (hang) {
      await _released.future;
    }
    return body();
  }

  @override
  Future<String> supportedIdTypes(UseSmileIDSampleEnvironment environment) {
    idTypeCalls++;
    if (failIdTypes) {
      return Future<String>.error(StateError('offline'));
    }
    return _answer(() => _fixture.supportedIdTypes(environment));
  }

  @override
  Future<String> supportedDocuments(
    UseSmileIDSampleEnvironment environment,
    String locale,
  ) {
    documentCalls++;
    locales.add(locale);
    return _answer(() => _fixture.supportedDocuments(environment, locale));
  }
}
