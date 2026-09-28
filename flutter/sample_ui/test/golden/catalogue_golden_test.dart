import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import '../support/catalogue_fixtures.dart';
import 'golden_harness.dart';

/// The pickers while their lists arrive, fail or come back empty, and the capture sheets, light and dark.
void main() {
  setUpAll(loadSampleFonts);

  testWidgets('country picker loading', (WidgetTester tester) async {
    await goldens(
      tester,
      'sheet_country_picker_loading',
      () => _country(
        const UseSmileIDSampleCatalogueLoading<UseSmileIDSampleCountry>(),
      ),
      afterPump: _pastSkeletonDelay,
    );
  });

  testWidgets('country picker error', (WidgetTester tester) async {
    await goldens(
      tester,
      'sheet_country_picker_error',
      () => _country(
        const UseSmileIDSampleCatalogueFailed<UseSmileIDSampleCountry>(
          'offline',
        ),
      ),
    );
  });

  testWidgets('country picker error survives max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(
      tester,
      _country(
        const UseSmileIDSampleCatalogueFailed<UseSmileIDSampleCountry>(
          'offline',
        ),
      ),
    );
  });

  testWidgets('country picker empty', (WidgetTester tester) async {
    await goldens(
      tester,
      'sheet_country_picker_empty',
      () => _country(
        const UseSmileIDSampleCatalogueEmpty<UseSmileIDSampleCountry>(),
      ),
    );
  });

  testWidgets('id type picker loading', (WidgetTester tester) async {
    await goldens(
      tester,
      'sheet_idtype_picker_loading',
      () => _idType(
        const UseSmileIDSampleCatalogueLoading<UseSmileIDSampleKycIdType>(),
      ),
      afterPump: _pastSkeletonDelay,
    );
  });

  testWidgets('id type picker error', (WidgetTester tester) async {
    await goldens(
      tester,
      'sheet_idtype_picker_error',
      () => _idType(
        const UseSmileIDSampleCatalogueFailed<UseSmileIDSampleKycIdType>(
          'offline',
        ),
      ),
    );
  });

  testWidgets('id type picker empty', (WidgetTester tester) async {
    await goldens(
      tester,
      'sheet_idtype_picker_empty',
      () => _idType(
        const UseSmileIDSampleCatalogueEmpty<UseSmileIDSampleKycIdType>(),
        country: const UseSmileIDSampleCountry('RW', 'Rwanda'),
      ),
    );
  });

  testWidgets('document picker', (WidgetTester tester) async {
    await goldens(
      tester,
      'sheet_document_picker',
      () => _document(
        UseSmileIDSampleCatalogueReady<UseSmileIDSampleDocument>(
          CatalogueFixtures.documents('ZA'),
        ),
      ),
    );
  });

  /// Only names are translated under ar-EG, and the app does not flip its own layout, so the rows stay left-to-right.
  testWidgets('document picker with Arabic names', (WidgetTester tester) async {
    await goldens(
      tester,
      'sheet_document_picker_ar',
      () => UseSmileIDSampleDocumentPickerSheet(
        country: const UseSmileIDSampleCountry('KE', 'كينيا'),
        catalogue:
            const UseSmileIDSampleCatalogueReady<UseSmileIDSampleDocument>(
              _arabicDocuments,
            ),
        selected: null,
        onSelect: (UseSmileIDSampleDocument _) {},
        onRetry: () {},
      ),
    );
  });

  testWidgets('document picker loading', (WidgetTester tester) async {
    await goldens(
      tester,
      'sheet_document_picker_loading',
      () => _document(
        const UseSmileIDSampleCatalogueLoading<UseSmileIDSampleDocument>(),
      ),
      afterPump: _pastSkeletonDelay,
    );
  });

  testWidgets('document picker error', (WidgetTester tester) async {
    await goldens(
      tester,
      'sheet_document_picker_error',
      () => _document(
        const UseSmileIDSampleCatalogueFailed<UseSmileIDSampleDocument>(
          'offline',
        ),
      ),
    );
  });

  testWidgets('document picker empty', (WidgetTester tester) async {
    await goldens(
      tester,
      'sheet_document_picker_empty',
      () => _document(
        const UseSmileIDSampleCatalogueEmpty<UseSmileIDSampleDocument>(),
      ),
    );
  });

  testWidgets('capture as', (WidgetTester tester) async {
    await goldens(
      tester,
      'sheet_capture_as',
      () => UseSmileIDSampleCaptureAsSheet(
        selected: UseSmileIDSampleCaptureAs.genericDocument,
        onSelect: (UseSmileIDSampleCaptureAs _) {},
      ),
    );
  });

  testWidgets('generic document', (WidgetTester tester) async {
    await goldens(
      tester,
      'sheet_generic_document',
      () => UseSmileIDSampleGenericDocumentSheet(
        initial: const UseSmileIDSampleGenericDocument(),
        onDone: (UseSmileIDSampleGenericDocument _) {},
      ),
    );
  });

  testWidgets('generic document survives max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(
      tester,
      UseSmileIDSampleGenericDocumentSheet(
        initial: const UseSmileIDSampleGenericDocument(),
        onDone: (UseSmileIDSampleGenericDocument _) {},
      ),
    );
  });

  testWidgets('capture mode', (WidgetTester tester) async {
    await goldens(
      tester,
      'sheet_capture_mode',
      () => UseSmileIDSampleCaptureModeSheet(
        selected: UseSmileIDSampleCaptureMode.autoWithFallback,
        onSelect: (UseSmileIDSampleCaptureMode _) {},
      ),
    );
  });
}

/// Past the 300 ms before rows appear; the pulse is then at its first frame, so the capture is stable.
Future<void> _pastSkeletonDelay(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 350));

Widget _country(UseSmileIDSampleCatalogue<UseSmileIDSampleCountry> catalogue) =>
    UseSmileIDSampleCountryPickerSheet(
      catalogue: catalogue,
      selected: null,
      onSelect: (UseSmileIDSampleCountry _) {},
      onRetry: () {},
    );

Widget _idType(
  UseSmileIDSampleCatalogue<UseSmileIDSampleKycIdType> catalogue, {
  UseSmileIDSampleCountry country = CatalogueFixtures.kenya,
}) => UseSmileIDSampleIdTypePickerSheet(
  country: country,
  catalogue: catalogue,
  selected: null,
  onSelect: (UseSmileIDSampleKycIdType _) {},
  onRetry: () {},
);

Widget _document(
  UseSmileIDSampleCatalogue<UseSmileIDSampleDocument> catalogue,
) => UseSmileIDSampleDocumentPickerSheet(
  country: CatalogueFixtures.southAfrica,
  catalogue: catalogue,
  selected: null,
  onSelect: (UseSmileIDSampleDocument _) {},
  onRetry: () {},
);

const List<UseSmileIDSampleDocument> _arabicDocuments =
    <UseSmileIDSampleDocument>[
      UseSmileIDSampleDocument(
        code: 'ALIEN_CARD',
        name: 'بطاقة الأجانب',
        hasBack: false,
        format: 1,
      ),
      UseSmileIDSampleDocument(
        code: 'IDENTITY_CARD',
        name: 'بطاقة الهوية',
        hasBack: true,
        format: 1,
      ),
      UseSmileIDSampleDocument(
        code: 'PASSPORT',
        name: 'جواز السفر',
        hasBack: false,
        format: 3,
      ),
    ];
