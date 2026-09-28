import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid/usesmileid.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_builder_config.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_launch_snapshot.dart';

/// spec/catalogue-rules.json captureAs: what "Capture as" hands the SDK, and that the server always gets the code.
void main() {
  final Map<String, Object?> captureAs =
      (jsonDecode(File('../../spec/catalogue-rules.json').readAsStringSync())
              as Map<String, Object?>)['captureAs']!
          as Map<String, Object?>;

  test('every case maps as the spec says', () {
    final List<Object?> cases = captureAs['cases']! as List<Object?>;
    expect(cases.length, greaterThanOrEqualTo(8));
    for (final Object? raw in cases) {
      final Map<String, Object?> spec = raw! as Map<String, Object?>;
      final String name = spec['name']! as String;
      final Map<String, Object?> expected =
          spec['expected']! as Map<String, Object?>;
      final UseSmileIDSampleIdDetails details = _detailsOf(spec);
      final UseSmileIDSampleDocumentCapture capture =
          useSmileIDSampleDocumentCaptureFor(details);
      final DocumentType type = capture.documentType;
      switch (expected['documentType']) {
        case 'passport':
          expect(type, DocumentType.passport, reason: name);
        case 'greenBook':
          expect(type, DocumentType.southAfricaGreenBook, reason: name);
        default:
          final GenericDocument generic = type as GenericDocument;
          expect(generic.displayName, expected['displayName'], reason: name);
          expect(generic.hasBackSide, expected['hasBackSide'], reason: name);
          if (expected['orientation'] case final String orientation) {
            expect(generic.orientation.name, orientation, reason: name);
          }
          if (expected['knownAspectRatio'] case final num ratio) {
            expect(generic.knownAspectRatio, closeTo(ratio, 0.0001));
          }
      }
      final Object? both = expected['captureBothSides'];
      expect(
        capture.captureBothSides,
        both is bool ? both : type.hasBackSide,
        reason: name,
      );
      expect(_submittedIdType(details), expected['idType'], reason: name);
    }
  });

  test('the aspect ratios are the spec\'s', () {
    final Map<String, Object?> ratios =
        captureAs['aspectRatios']! as Map<String, Object?>;
    for (final UseSmileIDSampleAspectRatio ratio
        in UseSmileIDSampleAspectRatio.values) {
      expect(ratio.ratio, (ratios[ratio.id] as num?)?.toDouble());
    }
  });

  test('capture mode and gallery reach the SDK', () {
    for (final (UseSmileIDSampleCaptureMode mode, DocumentCaptureMode sdk)
        in <(UseSmileIDSampleCaptureMode, DocumentCaptureMode)>[
          (UseSmileIDSampleCaptureMode.auto, const AutoCapture()),
          (UseSmileIDSampleCaptureMode.manual, const ManualCapture()),
          (
            UseSmileIDSampleCaptureMode.autoWithFallback,
            const AutoCaptureWithManualFallback(),
          ),
        ]) {
      final UseSmileIDFlowBuilder builder = UseSmileIDFlowBuilder();
      useSmileIDSampleApplying(
        builder,
        _snapshot(
          const UseSmileIDSampleIdDetails(
            country: UseSmileIDSampleCountry('KE', 'Kenya'),
            document: UseSmileIDSampleDocument(
              code: 'PASSPORT',
              name: 'Passport',
              hasBack: false,
              format: 3,
            ),
          ),
          captureMode: mode,
          galleryUpload: true,
        ),
      );
      // The SDK says to inspect this, then marks it internal.
      // ignore: invalid_use_of_internal_member
      final dynamic result = builder.build();
      // The result's type is unexported, hence the dynamic read.
      final List<Object?> screens =
          // ignore: avoid_dynamic_calls
          result.configuration.screens as List<Object?>;
      final DocumentCaptureConfiguration document = screens
          .whereType<CaptureScreenConfiguration>()
          .firstWhere(
            (CaptureScreenConfiguration it) =>
                it.captureType == CaptureType.document,
          )
          .documentConfig!;
      expect(document.captureMode, sdk);
      expect(document.allowGalleryUpload, isTrue);
    }
  });
}

UseSmileIDSampleIdDetails _detailsOf(Map<String, Object?> spec) {
  final Map<String, Object?> document =
      spec['document']! as Map<String, Object?>;
  final Map<String, Object?>? genericDocument =
      spec['genericDocument'] as Map<String, Object?>?;
  return UseSmileIDSampleIdDetails(
    country: const UseSmileIDSampleCountry('ZA', 'South Africa'),
    document: UseSmileIDSampleDocument(
      code: document['code']! as String,
      subType: document['subType'] as String?,
      name: document['name']! as String,
      hasBack: document['hasBack']! as bool,
      format: document['format']! as int,
    ),
    captureAs: UseSmileIDSampleCaptureAs.values.firstWhere(
      (UseSmileIDSampleCaptureAs it) => it.id == spec['captureAs'],
    ),
    genericDocument: genericDocument == null
        ? const UseSmileIDSampleGenericDocument()
        : UseSmileIDSampleGenericDocument(
            displayName: genericDocument['displayName']! as String,
            hasBackSide: genericDocument['hasBackSide']! as bool,
            orientation: UseSmileIDSampleDocumentOrientation.values.firstWhere(
              (UseSmileIDSampleDocumentOrientation it) =>
                  it.id == genericDocument['orientation'],
            ),
            aspectRatio: UseSmileIDSampleAspectRatio.values.firstWhere(
              (UseSmileIDSampleAspectRatio it) =>
                  it.id == genericDocument['aspectRatio'],
            ),
          ),
  );
}

/// What the builder puts in DocumentVerificationParams, whatever "Capture as" chose.
String? _submittedIdType(UseSmileIDSampleIdDetails details) {
  final UseSmileIDFlowBuilder builder = UseSmileIDFlowBuilder();
  useSmileIDSampleApplying(builder, _snapshot(details));
  return builder.documentVerificationParams?.idType;
}

UseSmileIDSampleFlowLaunchSnapshot _snapshot(
  UseSmileIDSampleIdDetails details, {
  UseSmileIDSampleCaptureMode captureMode =
      UseSmileIDSampleCaptureMode.autoWithFallback,
  bool galleryUpload = false,
}) => UseSmileIDSampleFlowLaunchSnapshot(
  product: UseSmileIDSampleProduct.documentVerification,
  route: UseSmileIDSampleFlowRoute.fullscreen,
  userDetails: const UseSmileIDSampleUserDetails(
    firstName: 'Ada',
    lastName: 'Okafor',
    email: 'ada@example.com',
  ),
  idDetails: details,
  scenario: UseSmileIDSampleScenario.normal,
  theme: UseSmileIDSampleThemeScenario.brandDefault,
  sandbox: true,
  allowAgentMode: false,
  enableEnhancedLiveness: true,
  consentStep: true,
  instructionsStep: true,
  previewStep: true,
  captureMode: captureMode,
  galleryUpload: galleryUpload,
  userId: 'user_1',
  partnerId: 'profile-1',
  partnerName: 'Kobo Bank',
  callbackUrl: '',
);
