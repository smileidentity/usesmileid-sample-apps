import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usesmileid/usesmileid.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_builder_config.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_launch_snapshot.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_preflight.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_routes.dart';

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
    userId: 'user_1',
    partnerId: 'profile-1',
    partnerName: 'Kobo Bank',
    callbackUrl: '',
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

    // The two document products differ only in which capture leads, which is the design's order.
    test('the document products put their captures in opposite orders', () {
      expect(
        useSmileIDSampleJourneyStepsFor(
          snapshotFor(
            UseSmileIDSampleProduct.documentVerification,
            previewStep: false,
            instructionsStep: false,
            consentStep: false,
          ),
        ),
        <UseSmileIDSampleFlowJourneyStep>[
          UseSmileIDSampleFlowJourneyStep.documentCapture,
          UseSmileIDSampleFlowJourneyStep.selfieCapture,
          UseSmileIDSampleFlowJourneyStep.processing,
        ],
      );
      expect(
        useSmileIDSampleJourneyStepsFor(
          snapshotFor(
            UseSmileIDSampleProduct.enhancedDocumentVerification,
            previewStep: false,
            instructionsStep: false,
            consentStep: false,
          ),
        ),
        <UseSmileIDSampleFlowJourneyStep>[
          UseSmileIDSampleFlowJourneyStep.selfieCapture,
          UseSmileIDSampleFlowJourneyStep.documentCapture,
          UseSmileIDSampleFlowJourneyStep.processing,
        ],
      );
    });
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

    // The SDK requires a contact field even though the form labels both optional.
    test('sends an empty form back to the form rather than to the SDK', () {
      expect(
        useSmileIDSamplePreflight(
          snapshotFor(
            UseSmileIDSampleProduct.smartSelfieEnrollment,
            userDetails: const UseSmileIDSampleUserDetails(),
          ),
        ),
        isA<UseSmileIDSampleFlowNeedsDetails>(),
      );
    });

    // Held to naming the field, because the issues are what a future surface reports.
    test('names the fields an empty form left for the form to fix', () {
      final UseSmileIDSampleFlowPreflight outcome = useSmileIDSamplePreflight(
        snapshotFor(
          UseSmileIDSampleProduct.smartSelfieEnrollment,
          userDetails: const UseSmileIDSampleUserDetails(),
        ),
      );

      final String reported = (outcome as UseSmileIDSampleFlowNeedsDetails)
          .issues
          .map((UseSmileIDValidationException issue) => issue.message)
          .join('; ');
      expect(reported, contains('givenNames'));
      expect(reported, contains('lastName'));
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
              country: UseSmileIDSampleCountry.ke,
              idType: UseSmileIDSampleIdType.nationalId,
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

    // `validate()` is weaker than `build()`, whose result type is unexported — hence the name read.
    test('every product builds a configuration the SDK accepts', () {
      for (final UseSmileIDSampleProduct product
          in UseSmileIDSampleProduct.values) {
        final dynamic result =
            builderFor(
                  snapshotFor(
                    product,
                    idDetails: const UseSmileIDSampleIdDetails(
                      country: UseSmileIDSampleCountry.ke,
                      idType: UseSmileIDSampleIdType.nationalId,
                      idNumber: '11111111',
                    ),
                  ),
                )
                // The SDK says to inspect this, then marks it internal — a finding for the SDK.
                // ignore: invalid_use_of_internal_member
                .build();

        expect(
          result.runtimeType.toString(),
          contains('Success'),
          reason: '${product.id}: ${_issuesOf(result)}',
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
    Future<GoRouter> pump(WidgetTester tester) async {
      final GoRouter router = useSmileIDSampleRouter();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: UseSmileIDSampleTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('a product tap stacks its form over the shell', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pump(tester);

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
      // An imperative push leaves `currentConfiguration.uri` on the base match, so assert the stack.
      expect(router.routerDelegate.canPop(), isTrue);
    });

    // `go` left one page in the root stack, which made every back a hard-coded location.
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

    testWidgets('the run route exists and the gate turns an empty form back', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pump(tester);

      router.go(
        UseSmileIDSampleRoutes.sdkFlow(
          UseSmileIDSampleProduct.smartSelfieEnrollment.id,
        ),
      );
      await tester.pumpAndSettle();

      // Never mounted: an empty form cannot reach the SDK, so the gate redirects before it does.
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        UseSmileIDSampleRoutes.consentDetailsForm(
          UseSmileIDSampleProduct.smartSelfieEnrollment.id,
        ),
      );
    });

    testWidgets('a product id this build does not know leaves for the grid', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pump(tester);

      router.go(UseSmileIDSampleRoutes.sdkFlow('nosuchproduct'));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        UseSmileIDSampleRoutes.products,
      );
    });
  });
}

/// The rejected build's own words, so a red names the rule rather than only the product.
String _issuesOf(dynamic result) {
  try {
    return (result.validation.issues as List<dynamic>)
        .map((dynamic issue) => '${issue.runtimeType}: ${issue.message}')
        .join('; ');
  } on Object {
    return 'no issues reported';
  }
}
