import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usesmileid/usesmileid.dart';
import 'package:usesmileid_njia/usesmileid_njia.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_builder_config.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_launch_snapshot.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_preflight.dart';
import 'package:usesmileid_sample_flutter/src/navigation/use_smileid_sample_navigation.dart';
import 'package:usesmileid_sample_flutter/src/navigation/use_smileid_sample_njia.dart';

import 'support/use_smileid_sample_catalogue_fixture.dart';
import 'support/use_smileid_sample_test_njia.dart';
import 'support/use_smileid_sample_test_session.dart';

/// The flow host: what it hands the SDK, what it refuses to hand over, and where the wizard stacks.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  UseSmileIDSampleFlowLaunchSnapshot snapshotFor(
    UseSmileIDSampleProduct product, {
    UseSmileIDSampleUserDetails userDetails = const UseSmileIDSampleUserDetails(
      firstName: 'Ada',
      lastName: 'Okafor',
      email: 'ada.okafor@example.com',
    ),
    UseSmileIDSampleIdDetails idDetails = const UseSmileIDSampleIdDetails(),
    bool consentStep = true,
    bool instructionsStep = true,
    bool previewStep = true,
    bool selfieFirst = false,
  }) => UseSmileIDSampleFlowLaunchSnapshot(
    product: product,
    route: UseSmileIDSampleFlowRoute.fullscreen,
    userDetails: userDetails,
    idDetails: idDetails,
    scenario: UseSmileIDSampleScenario.normal,
    theme: UseSmileIDSampleThemeScenario.brandDefault,
    sandbox: true,
    allowAgentMode: false,
    enableEnhancedLiveness: true,
    consentStep: consentStep,
    instructionsStep: instructionsStep,
    previewStep: previewStep,
    selfieFirst: selfieFirst,
    userId: 'user_1',
    partnerId: 'profile-1',
    partnerName: 'Kobo Bank',
    callbackUrl: '',
    session: useSmileIDSampleTestSession(),
  );

  group('the journey the switches compose', () {
    test(
      'a selfie enrollment is consent, instructions, capture, preview, processing',
      () {
        expect(
          useSmileIDSampleJourneyStepsFor(
            snapshotFor(UseSmileIDSampleProduct.smartSelfieEnrollment),
          ),
          <UseSmileIDSampleFlowJourneyStep>[
            UseSmileIDSampleFlowJourneyStep.consent,
            UseSmileIDSampleFlowJourneyStep.instructions,
            UseSmileIDSampleFlowJourneyStep.selfieCapture,
            UseSmileIDSampleFlowJourneyStep.preview,
            UseSmileIDSampleFlowJourneyStep.processing,
          ],
        );
      },
    );

    test('each switch takes its own step out', () {
      expect(
        useSmileIDSampleJourneyStepsFor(
          snapshotFor(
            UseSmileIDSampleProduct.smartSelfieEnrollment,
            consentStep: false,
            instructionsStep: false,
            previewStep: false,
          ),
        ),
        <UseSmileIDSampleFlowJourneyStep>[
          UseSmileIDSampleFlowJourneyStep.selfieCapture,
          UseSmileIDSampleFlowJourneyStep.processing,
        ],
      );
    });

    // The one journey without capture, per its own validator.
    test('enhanced KYC is consent and processing only', () {
      expect(
        useSmileIDSampleJourneyStepsFor(
          snapshotFor(UseSmileIDSampleProduct.enhancedKyc),
        ),
        <UseSmileIDSampleFlowJourneyStep>[
          UseSmileIDSampleFlowJourneyStep.consent,
          UseSmileIDSampleFlowJourneyStep.processing,
        ],
      );
    });

    test(
      'every document product captures the document first unless selfie first is on',
      () {
        for (final UseSmileIDSampleProduct product in <UseSmileIDSampleProduct>[
          UseSmileIDSampleProduct.documentVerification,
          UseSmileIDSampleProduct.enhancedDocumentVerification,
          UseSmileIDSampleProduct.residencyDocumentVerification,
        ]) {
          List<UseSmileIDSampleFlowJourneyStep> steps({
            required bool selfieFirst,
          }) => useSmileIDSampleJourneyStepsFor(
            snapshotFor(
              product,
              previewStep: false,
              instructionsStep: false,
              consentStep: false,
              selfieFirst: selfieFirst,
            ),
          );
          expect(steps(selfieFirst: false), <UseSmileIDSampleFlowJourneyStep>[
            UseSmileIDSampleFlowJourneyStep.documentCapture,
            UseSmileIDSampleFlowJourneyStep.selfieCapture,
            UseSmileIDSampleFlowJourneyStep.processing,
          ], reason: product.id);
          expect(steps(selfieFirst: true), <UseSmileIDSampleFlowJourneyStep>[
            UseSmileIDSampleFlowJourneyStep.selfieCapture,
            UseSmileIDSampleFlowJourneyStep.documentCapture,
            UseSmileIDSampleFlowJourneyStep.processing,
          ], reason: product.id);
        }
      },
    );
  });

  group('the gate', () {
    test('passes a complete selfie enrollment', () {
      expect(
        useSmileIDSamplePreflight(
          snapshotFor(UseSmileIDSampleProduct.smartSelfieEnrollment),
        ),
        isA<UseSmileIDSampleFlowReady>(),
      );
    });

    test('passes an empty form to the SDK, for the API to judge', () {
      expect(
        useSmileIDSamplePreflight(
          snapshotFor(
            UseSmileIDSampleProduct.smartSelfieEnrollment,
            userDetails: const UseSmileIDSampleUserDetails(),
          ),
        ),
        isA<UseSmileIDSampleFlowReady>(),
      );
    });

    test('sends a KYC product with no country back to the form', () {
      expect(
        useSmileIDSamplePreflight(
          snapshotFor(UseSmileIDSampleProduct.biometricKyc),
        ),
        isA<UseSmileIDSampleFlowNeedsDetails>(),
      );
    });

    test('passes a KYC product the ID form has filled', () {
      expect(
        useSmileIDSamplePreflight(
          snapshotFor(
            UseSmileIDSampleProduct.biometricKyc,
            idDetails: const UseSmileIDSampleIdDetails(
              country: kenya,
              idType: kenyaNationalId,
              idNumber: '11111111',
            ),
          ),
        ),
        isA<UseSmileIDSampleFlowReady>(),
      );
    });
  });

  group('what the SDK is handed', () {
    UseSmileIDFlowBuilder builderFor(UseSmileIDSampleFlowLaunchSnapshot s) {
      final UseSmileIDFlowBuilder builder = UseSmileIDFlowBuilder();
      useSmileIDSampleApplying(builder, s);
      return builder;
    }

    test(
      'a document job sends the document, even with an ID type left in the form',
      () {
        final UseSmileIDFlowBuilder builder = builderFor(
          snapshotFor(
            UseSmileIDSampleProduct.documentVerification,
            idDetails: const UseSmileIDSampleIdDetails(
              country: kenya,
              idType: kenyaNationalId,
              document: UseSmileIDSampleDocument(
                code: 'PASSPORT',
                name: 'Passport',
                hasBack: false,
                format: 3,
              ),
            ),
          ),
        );
        expect(builder.documentVerificationParams?.idType, 'PASSPORT');
      },
    );

    test('a KYC job sends the number trimmed, as the form checked it', () {
      final UseSmileIDFlowBuilder builder = builderFor(
        snapshotFor(
          UseSmileIDSampleProduct.biometricKyc,
          idDetails: const UseSmileIDSampleIdDetails(
            country: kenya,
            idType: kenyaNationalId,
            idNumber: ' 12345678 ',
          ),
        ),
      );
      expect(builder.biometricKYCParams?.idNumber, '12345678');
    });

    test(
      'the user details the form collected, with an absent field left absent',
      () {
        final UserDetails details = builderFor(
          snapshotFor(UseSmileIDSampleProduct.smartSelfieEnrollment),
        ).userDetails!;

        expect(details.givenNames, 'Ada');
        expect(details.lastName, 'Okafor');
        expect(details.email, 'ada.okafor@example.com');
        expect(details.phoneNumber, isNull);
      },
    );

    // Only authentication carries one: the server issues the id for every other job.
    test('a user id only where the job type requires one', () {
      expect(
        builderFor(snapshotFor(UseSmileIDSampleProduct.smartSelfieAuth)).userId,
        'user_1',
      );
      expect(
        builderFor(
          snapshotFor(UseSmileIDSampleProduct.smartSelfieEnrollment),
        ).userId,
        isNull,
      );
    });

    // `validate()` gives the verdict `build()` reaches, without building.
    test('every product builds a configuration the SDK accepts', () {
      for (final UseSmileIDSampleProduct product
          in UseSmileIDSampleProduct.values) {
        final ValidationState state = builderFor(
          snapshotFor(
            product,
            // Both families filled, so each product finds the field it submits.
            idDetails: const UseSmileIDSampleIdDetails(
              country: kenya,
              idType: kenyaNationalId,
              document: UseSmileIDSampleDocument(
                code: 'PASSPORT',
                name: 'Passport',
                hasBack: false,
                format: 3,
              ),
              idNumber: '11111111',
            ),
          ),
        ).validate();

        expect(
          state,
          isA<ValidationStateValid>(),
          reason: '${product.id}: ${_issuesOf(state)}',
        );
      }
    });

    test(
      'an unselected document type stays absent rather than becoming a rejected empty string',
      () {
        expect(
          builderFor(
            snapshotFor(UseSmileIDSampleProduct.documentVerification),
          ).documentVerificationParams!.idType,
          isNull,
        );
      },
    );
  });

  group('the wizard above the shell', () {
    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          // The form reads the session's configuration, so the catalogue decodes inline to settle.
          overrides: [
            ...useSmileIDSampleTestNjia(),
            ...useSmileIDSampleLinkedSessionOverrides(),
            useSmileIDSampleFixtureCatalogueOverride(),
          ],
          child: MaterialApp.router(
            theme: UseSmileIDSampleTheme.light(),
            routerConfig: useSmileIDSampleTestRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a product tap stacks its form over the shell', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tester.tap(
        find.bySemanticsIdentifier(
          UseSmileIDSampleTestIds.productCard(
            UseSmileIDSampleProduct.smartSelfieEnrollment.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsIdentifier(UseSmileIDSampleTestIds.userDetailsScreen),
        findsOne,
      );
      expect(
        useSmileIDSampleTestEngine(
          tester,
        ).state.entries.map((NjiaEntry entry) => entry.step),
        <String>[
          UseSmileIDSampleStep.products.name,
          UseSmileIDSampleStep.consentDetailsForm.name,
        ],
      );
    });

    testWidgets('system back from a stacked form pops to the shell', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await tester.tap(
        find.bySemanticsIdentifier(
          UseSmileIDSampleTestIds.productCard(
            UseSmileIDSampleProduct.smartSelfieEnrollment.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsIdentifier(UseSmileIDSampleTestIds.productsScreen),
        findsOne,
      );
    });

    testWidgets('the run route exists and the gate turns an empty ID form back', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await useSmileIDSampleTestDeliver(
        tester,
        UseSmileIDSampleRoutes.sdkFlow(UseSmileIDSampleProduct.biometricKyc.id),
      );

      // A KYC run with no ID details cannot reach the SDK, so the run hands over to the form.
      final UseSmileIDSampleEngine engine = useSmileIDSampleTestEngine(tester);
      expect(
        useSmileIDSampleTestTop(tester),
        UseSmileIDSampleStep.consentDetailsForm,
      );
      expect(
        engine.state.entries.last.arg,
        UseSmileIDSampleProduct.biometricKyc.id,
      );
    });

    testWidgets('a product id this build does not know leaves for the grid', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await useSmileIDSampleTestDeliver(
        tester,
        UseSmileIDSampleRoutes.sdkFlow('nosuchproduct'),
      );

      expect(useSmileIDSampleTestTop(tester), UseSmileIDSampleStep.products);
    });
  });
}

/// The rejected flow's own words, so a red names the rule rather than only the product.
String _issuesOf(ValidationState state) => switch (state) {
  ValidationStateValid() => 'no issues reported',
  final ValidationStateInvalid invalid =>
    invalid.issues
        .map(
          (UseSmileIDValidationException issue) =>
              '${issue.runtimeType}: ${issue.message}',
        )
        .join('; '),
};
