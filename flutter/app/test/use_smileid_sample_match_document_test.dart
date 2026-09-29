import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid/usesmileid.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_builder_config.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_launch_snapshot.dart';

/// Match document on every fixture row of both document products, through the SDK's `build()` and its job-type rules.
void main() {
  final List<UseSmileIDSampleApiCountryDocuments> documents =
      UseSmileIDSampleCatalogueJson.documents(
        jsonEncode(
          (jsonDecode(File('assets/catalogue-fixture.json').readAsStringSync())
              as Map<String, Object?>)['supported_documents'],
        ),
      )!;

  test('Match never builds a pair the SDK refuses', () {
    int checked = 0;
    for (final UseSmileIDSampleProduct product in <UseSmileIDSampleProduct>[
      UseSmileIDSampleProduct.documentVerification,
      UseSmileIDSampleProduct.enhancedDocumentVerification,
    ]) {
      for (final UseSmileIDSampleApiCountryDocuments listed in documents) {
        for (final UseSmileIDSampleDocument document
            in UseSmileIDSampleCatalogueRules.documents(
              documents,
              listed.country.code,
              product: product,
            )) {
          final String outcome = _build(
            product,
            UseSmileIDSampleIdDetails(
              country: listed.country,
              document: document,
            ),
          );
          expect(outcome, 'built', reason: '${document.id} on ${product.id}');
          checked++;
        }
      }
    }
    expect(checked, greaterThan(0));
  });

  test('the rules refuse the Green Book preset on Enhanced Document '
      'Verification, so the check above can fail', () {
    final String outcome = _build(
      UseSmileIDSampleProduct.enhancedDocumentVerification,
      const UseSmileIDSampleIdDetails(
        country: UseSmileIDSampleCountry('ZA', 'South Africa'),
        document: UseSmileIDSampleDocument(
          code: 'IDENTITY_CARD',
          name: 'Identity Card',
          hasBack: true,
          format: 1,
        ),
        captureAsOverride: UseSmileIDSampleCaptureAs.greenBook,
      ),
    );
    expect(outcome, contains('Green Book'));
  });
}

/// "built", or the refusal's reasons.
String _build(
  UseSmileIDSampleProduct product,
  UseSmileIDSampleIdDetails details,
) {
  final UseSmileIDFlowBuilder builder = UseSmileIDFlowBuilder();
  useSmileIDSampleApplying(
    builder,
    UseSmileIDSampleFlowLaunchSnapshot(
      product: product,
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
      userId: 'user_1',
      partnerId: 'profile-1',
      partnerName: 'Kobo Bank',
      callbackUrl: '',
    ),
  );
  // The SDK says to inspect this, then marks it internal.
  // ignore: invalid_use_of_internal_member
  final Object result = builder.build();
  // The result's types are unexported, hence the dynamic read.
  // ignore: avoid_dynamic_calls
  return result.runtimeType.toString() == 'FlowBuildResultSuccess'
      ? 'built'
      // ignore: avoid_dynamic_calls
      : '${(result as dynamic).validation.issues}';
}
