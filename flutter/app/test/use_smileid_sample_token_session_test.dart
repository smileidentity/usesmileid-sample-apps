import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usesmileid/usesmileid.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_builder_config.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_launch_snapshot.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_plan.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_preflight.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_tokens.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_session_providers.dart';
import 'package:usesmileid_sample_flutter/src/status/use_smileid_sample_http_job_status_source.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_journey.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_routes.dart';

/// The token session end to end on the host side: minting, the plan, the gate, the builder and the journey.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('the flow plan, as a truth table', () {
    // Consent × user details × ID claims × product, each axis independent: enumerated, not sampled.
    const Map<String, UseSmileIDSampleTokenConsent?> consents =
        <String, UseSmileIDSampleTokenConsent?>{
          'absent': null,
          'complete': UseSmileIDSampleTokenConsent(
            granted: true,
            grantedAt: '2026-08-18T09:00:00Z',
            noticeLanguage: 'en',
            noticePrivacyPolicyUrl: 'https://smile.id/privacy-policy',
          ),
          'partial': UseSmileIDSampleTokenConsent(granted: true),
        };
    const Map<String, UseSmileIDSampleTokenBindings> details =
        <String, UseSmileIDSampleTokenBindings>{
          'none': UseSmileIDSampleTokenBindings(),
          'given name only': UseSmileIDSampleTokenBindings(givenNames: true),
          'names only': UseSmileIDSampleTokenBindings(
            givenNames: true,
            lastName: true,
          ),
          'email only': UseSmileIDSampleTokenBindings(email: true),
          'phone only': UseSmileIDSampleTokenBindings(phoneNumber: true),
          'names and email': UseSmileIDSampleTokenBindings(
            givenNames: true,
            lastName: true,
            email: true,
          ),
          'names and phone': UseSmileIDSampleTokenBindings(
            givenNames: true,
            lastName: true,
            phoneNumber: true,
          ),
        };
    const Map<String, List<String?>> ids = <String, List<String?>>{
      'no ID claims': <String?>[null, null, null],
      'country and type': <String?>['KE', 'NATIONAL_ID', null],
      'all three': <String?>['KE', 'NATIONAL_ID', 'vault_id_number'],
    };

    for (final MapEntry<String, UseSmileIDSampleTokenConsent?> consent
        in consents.entries) {
      for (final MapEntry<String, UseSmileIDSampleTokenBindings> detail
          in details.entries) {
        for (final MapEntry<String, List<String?>> id in ids.entries) {
          for (final UseSmileIDSampleProduct product
              in UseSmileIDSampleProduct.values) {
            test(
              'consent ${consent.key}, ${detail.key}, ${id.key}, ${product.id}',
              () {
                final UseSmileIDSampleTokenBindings d = detail.value;
                final UseSmileIDSampleTokenBindings bindings =
                    UseSmileIDSampleTokenBindings(
                      givenNames: d.givenNames,
                      lastName: d.lastName,
                      email: d.email,
                      phoneNumber: d.phoneNumber,
                      consent: consent.value,
                      country: id.value[0],
                      idType: id.value[1],
                      idNumberReference: id.value[2],
                    );
                final bool contact = d.email || d.phoneNumber;
                final bool bindsId = switch (product) {
                  UseSmileIDSampleProduct.biometricKyc ||
                  UseSmileIDSampleProduct.enhancedKyc => id.value[2] != null,
                  UseSmileIDSampleProduct.documentVerification ||
                  UseSmileIDSampleProduct.enhancedDocumentVerification =>
                    id.value[1] != null,
                  _ => true,
                };
                expect(
                  useSmileIDSampleFlowPlan(bindings, product),
                  UseSmileIDSampleFlowPlan(
                    userDetailsGap: UseSmileIDSampleUserDetailsRequirement(
                      firstName: !d.givenNames,
                      lastName: !d.lastName,
                      contact: !contact,
                    ),
                    showIdDetailsForm: product.needsIdDetails && !bindsId,
                    declareConsentScreen: consent.value == null,
                    passUserDetails: !(d.givenNames && d.lastName && contact),
                  ),
                );
              },
            );
          }
        }
      }
    }

    test('no token is the unbound baseline for every product', () {
      for (final UseSmileIDSampleProduct product
          in UseSmileIDSampleProduct.values) {
        expect(
          useSmileIDSampleFlowPlan(null, product),
          UseSmileIDSampleFlowPlan(
            userDetailsGap: const UseSmileIDSampleUserDetailsRequirement(),
            showIdDetailsForm: product.needsIdDetails,
            declareConsentScreen: true,
            passUserDetails: true,
          ),
        );
      }
    });
  });

  group('what Simulate mints', () {
    test('each span decodes over its own span, in the chosen environment', () {
      for (final UseSmileIDSampleSimulatedSpan span
          in UseSmileIDSampleSimulatedSpan.values) {
        for (final UseSmileIDSampleEnvironment environment
            in UseSmileIDSampleEnvironment.values) {
          final UseSmileIDSampleTokenSession session = _mint(
            span: span,
            environment: environment,
          );
          expect(
            session.expiresAtMillis - session.issuedAtMillis,
            span.span.inMilliseconds,
          );
          expect(session.environment, environment);
          expect(session.hasExpired(_now), span.inPast, reason: span.label);
        }
      }
    });

    test('a token minted with nothing bound binds nothing', () {
      expect(_mint().bindings, const UseSmileIDSampleTokenBindings());
    });

    test('bound details carry every field and both ID parameters', () {
      final UseSmileIDSampleTokenBindings bindings = _mint(
        bindings: const UseSmileIDSampleSimulatedBindings(userDetails: true),
      ).bindings;
      expect(bindings.bindsRequiredUserDetails, isTrue);
      for (final UseSmileIDSampleProduct product
          in UseSmileIDSampleProduct.values) {
        expect(bindings.bindsIdDetails(product), isTrue, reason: product.id);
      }
      expect(bindings.consent, isNull);
    });

    test('bound consent is complete, so the SDK drops its screen', () {
      expect(
        _mint(
          bindings: const UseSmileIDSampleSimulatedBindings(consent: true),
        ).bindings.consent?.isComplete,
        isTrue,
      );
    });
  });

  group('the gate and the builder under a session', () {
    test('an ended session goes to the scanner ahead of any form', () {
      expect(
        useSmileIDSamplePreflight(
          _snapshot(
            UseSmileIDSampleProduct.smartSelfieEnrollment,
            userDetails: const UseSmileIDSampleUserDetails(),
            sessionExpired: true,
          ),
        ),
        isA<UseSmileIDSampleFlowNeedsSession>(),
      );
    });

    test(
      'a fully bound token reaches the SDK with empty forms, and passes null details',
      () {
        for (final UseSmileIDSampleProduct product
            in UseSmileIDSampleProduct.values) {
          final UseSmileIDSampleFlowLaunchSnapshot snapshot = _snapshot(
            product,
            userDetails: const UseSmileIDSampleUserDetails(),
            session: _mint(
              bindings: const UseSmileIDSampleSimulatedBindings(
                consent: true,
                userDetails: true,
              ),
            ),
          );
          expect(
            useSmileIDSamplePreflight(snapshot),
            isA<UseSmileIDSampleFlowReady>(),
            reason: product.id,
          );
          final UseSmileIDFlowBuilder builder = UseSmileIDFlowBuilder();
          useSmileIDSampleApplying(builder, snapshot);
          expect(builder.userDetails, isNull, reason: product.id);
          // `validate()` is weaker than `build()`, whose result type is unexported — hence the name read.
          // ignore: invalid_use_of_internal_member
          final dynamic result = builder.build();
          expect(
            result.runtimeType.toString(),
            contains('Success'),
            reason: product.id,
          );
        }
      },
    );

    test(
      'the ID parameters come from the token, the number as its vault reference',
      () {
        final UseSmileIDFlowBuilder builder = UseSmileIDFlowBuilder();
        useSmileIDSampleApplying(
          builder,
          _snapshot(
            UseSmileIDSampleProduct.biometricKyc,
            session: _mint(
              bindings: const UseSmileIDSampleSimulatedBindings(
                userDetails: true,
              ),
            ),
          ),
        );
        expect(builder.biometricKYCParams?.country, 'KE');
        expect(builder.biometricKYCParams?.idType, 'NATIONAL_ID');
        expect(builder.biometricKYCParams?.idNumber, 'vault_id_number');
      },
    );

    test(
      'a bound consent takes the consent step out, even with the switch on',
      () {
        final List<UseSmileIDSampleFlowJourneyStep> steps =
            useSmileIDSampleJourneyStepsFor(
              _snapshot(
                UseSmileIDSampleProduct.enhancedKyc,
                session: _mint(
                  bindings: const UseSmileIDSampleSimulatedBindings(
                    consent: true,
                  ),
                ),
              ),
            );
        // The narrowest legal flow, and the one that broke on Android.
        expect(steps, <UseSmileIDSampleFlowJourneyStep>[
          UseSmileIDSampleFlowJourneyStep.processing,
        ]);
      },
    );

    test(
      'the refresh scenarios keep the fixture path, so they still mean something',
      () {
        final UseSmileIDSampleFlowLaunchSnapshot snapshot = _snapshot(
          UseSmileIDSampleProduct.smartSelfieEnrollment,
          scenario: UseSmileIDSampleScenario.expiredToken,
          session: _mint(
            bindings: const UseSmileIDSampleSimulatedBindings(consent: true),
          ),
        );
        expect(snapshot.liveSession, isNull);
        expect(
          useSmileIDSampleJourneyStepsFor(snapshot).first,
          UseSmileIDSampleFlowJourneyStep.consent,
        );
      },
    );

    test('the environment is the token\'s, and no session is sandbox', () {
      expect(useSmileIDSampleUseSandbox(null), isTrue);
      expect(useSmileIDSampleUseSandbox(_mint()), isTrue);
      expect(
        useSmileIDSampleUseSandbox(
          _mint(environment: UseSmileIDSampleEnvironment.production),
        ),
        isFalse,
      );
    });
  });

  group('where a product tap goes', () {
    test('no token starts at the details form', () {
      expect(
        UseSmileIDSampleJourney.firstStepFor(
          UseSmileIDSampleProduct.biometricKyc,
          null,
        ),
        UseSmileIDSampleRoutes.consentDetailsForm(
          UseSmileIDSampleProduct.biometricKyc.id,
        ),
      );
    });

    test('bound details skip both forms', () {
      expect(
        UseSmileIDSampleJourney.firstStepFor(
          UseSmileIDSampleProduct.biometricKyc,
          _mint(
            bindings: const UseSmileIDSampleSimulatedBindings(
              userDetails: true,
            ),
          ).bindings,
        ),
        UseSmileIDSampleRoutes.sdkFlow(UseSmileIDSampleProduct.biometricKyc.id),
      );
    });

    test('bound names alone still show the details form', () {
      expect(
        UseSmileIDSampleJourney.firstStepFor(
          UseSmileIDSampleProduct.smartSelfieEnrollment,
          const UseSmileIDSampleTokenBindings(givenNames: true, lastName: true),
        ),
        UseSmileIDSampleRoutes.consentDetailsForm(
          UseSmileIDSampleProduct.smartSelfieEnrollment.id,
        ),
      );
    });
  });

  group('a status refresh reads the server', () {
    test(
      'each API state lands on its badge, and processing stays processing',
      () {
        String body(String status) =>
            '{"status":"$status","message":"m","job_id":"j","user_id":"u","created_at":"t","extra":1}';
        expect(
          useSmileIDSampleStatusOutcome(200, body('processing')),
          isA<UseSmileIDSampleStatusStillProcessing>(),
        );
        for (final (String api, UseSmileIDSampleStatus badge)
            in <(String, UseSmileIDSampleStatus)>[
              ('clear', UseSmileIDSampleStatus.clear),
              ('attention', UseSmileIDSampleStatus.attention),
              ('block', UseSmileIDSampleStatus.blocked),
              ('error', UseSmileIDSampleStatus.blocked),
            ]) {
          final UseSmileIDSampleStatusRefresh outcome =
              useSmileIDSampleStatusOutcome(200, body(api));
          expect(
            (outcome as UseSmileIDSampleStatusUpdated).status,
            badge,
            reason: api,
          );
        }
      },
    );

    test(
      'a failed exchange or an unknown state says so rather than guessing',
      () {
        expect(
          (useSmileIDSampleStatusOutcome(401, '{}')
                  as UseSmileIDSampleStatusFailed)
              .reason,
          'HTTP 401',
        );
        expect(
          (useSmileIDSampleStatusOutcome(200, 'not json')
                  as UseSmileIDSampleStatusFailed)
              .reason,
          'HTTP 200',
        );
        expect(
          (useSmileIDSampleStatusOutcome(200, '{"status":"odd","message":"m"}')
                  as UseSmileIDSampleStatusFailed)
              .reason,
          "Unrecognised status 'odd'",
        );
      },
    );
  });

  group('the session on screen', () {
    Future<(GoRouter, ProviderContainer)> pump(
      WidgetTester tester, {
      UseSmileIDSampleSessionRecord stored =
          const UseSmileIDSampleSessionRecord(),
      String? at,
    }) async {
      final GoRouter router = useSmileIDSampleRouter(initialLocation: at);
      // Owned by the tree, so its timers go when the tree does.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            useSmileIDSampleSessionRepositoryProvider.overrideWithValue(
              UseSmileIDSampleMemorySessionRepository(stored),
            ),
            useSmileIDSampleStoredSessionProvider.overrideWithValue(stored),
          ],
          child: MaterialApp.router(
            theme: UseSmileIDSampleTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      return (
        router,
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp))),
      );
    }

    Finder byId(String id) => find.bySemanticsIdentifier(id);

    testWidgets(
      'the nav bar reaches the scanner, and Simulate links a live session',
      (WidgetTester tester) async {
        final (GoRouter _, ProviderContainer container) = await pump(tester);
        expect(byId(UseSmileIDSampleTestIds.sessionCard), findsNothing);

        await tester.tap(byId(UseSmileIDSampleTestIds.navToken));
        await tester.pumpAndSettle();
        expect(byId(UseSmileIDSampleTestIds.scanTokenScreen), findsOne);

        await tester.tap(byId(UseSmileIDSampleTestIds.tokenSimulate));
        await tester.pumpAndSettle();

        expect(byId(UseSmileIDSampleTestIds.productsScreen), findsOne);
        expect(byId(UseSmileIDSampleTestIds.sessionCard), findsOne);
        expect(container.read(useSmileIDSampleSessionProvider).live, isNotNull);
      },
    );

    testWidgets('Settings says so when a live token binds consent', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        stored: UseSmileIDSampleSessionRecord(
          live: _mint(
            bindings: const UseSmileIDSampleSimulatedBindings(consent: true),
          ),
        ),
        at: UseSmileIDSampleRoutes.settings,
      );
      await tester.pumpAndSettle();
      expect(
        find.text('The token grants consent, so the screen is skipped'),
        findsOne,
      );
    });

    testWidgets(
      'Settings keeps its own wording under a token that binds no consent',
      (WidgetTester tester) async {
        await pump(
          tester,
          stored: UseSmileIDSampleSessionRecord(live: _mint()),
          at: UseSmileIDSampleRoutes.settings,
        );
        await tester.pumpAndSettle();
        expect(find.text('Ask permission before KYC checks'), findsOne);
      },
    );

    testWidgets('a stored ended marker shows the ended banner, not a card', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        stored: const UseSmileIDSampleSessionRecord(
          ended: UseSmileIDSampleEndedSession(id: 'a1b2c3d4', endedAtMillis: 1),
        ),
      );
      expect(byId(UseSmileIDSampleTestIds.sessionEndedBanner), findsOne);
      expect(byId(UseSmileIDSampleTestIds.sessionCard), findsNothing);
    });

    testWidgets(
      'a cold start past the deadline retires the token and keeps only its marker',
      (WidgetTester tester) async {
        final UseSmileIDSampleTokenSession lapsed = _mint(
          span: UseSmileIDSampleSimulatedSpan.ended,
        );
        final (GoRouter _, ProviderContainer container) = await pump(
          tester,
          stored: UseSmileIDSampleSessionRecord(live: lapsed),
        );
        await tester.pumpAndSettle();

        final UseSmileIDSampleSessionRecord record = container.read(
          useSmileIDSampleSessionProvider,
        );
        expect(record.live, isNull);
        expect(record.ended?.id, lapsed.id);
        expect(byId(UseSmileIDSampleTestIds.sessionEndedBanner), findsOne);
      },
    );

    testWidgets('an ended session sends a run to the scanner, which says why', (
      WidgetTester tester,
    ) async {
      final (GoRouter router, ProviderContainer container) = await pump(
        tester,
        stored: const UseSmileIDSampleSessionRecord(
          ended: UseSmileIDSampleEndedSession(id: 'a1b2c3d4', endedAtMillis: 1),
        ),
        at: UseSmileIDSampleRoutes.sdkFlow(
          UseSmileIDSampleProduct.smartSelfieEnrollment.id,
        ),
      );
      await tester.pumpAndSettle();

      expect(byId(UseSmileIDSampleTestIds.scanTokenScreen), findsOne);
      expect(
        find.text(UseSmileIDSampleScanReason.sessionEnded.caption),
        findsOne,
      );
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        UseSmileIDSampleRoutes.scanToken,
      );
      // Claimed by the visit, so a later deliberate scan resumes nothing.
      expect(container.read(useSmileIDSampleInterruptedRunProvider), isNull);
    });

    testWidgets('leaving the scanner unlinked drops the run it was sent', (
      WidgetTester tester,
    ) async {
      final (GoRouter router, ProviderContainer _) = await pump(
        tester,
        stored: const UseSmileIDSampleSessionRecord(
          ended: UseSmileIDSampleEndedSession(id: 'a1b2c3d4', endedAtMillis: 1),
        ),
        at: UseSmileIDSampleRoutes.sdkFlow(
          UseSmileIDSampleProduct.smartSelfieEnrollment.id,
        ),
      );
      await tester.pumpAndSettle();
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();

      unawaited(router.push(UseSmileIDSampleRoutes.scanToken));
      await tester.pumpAndSettle();
      expect(
        find.text(UseSmileIDSampleScanReason.sessionEnded.caption),
        findsNothing,
      );
    });
  });
}

UseSmileIDSampleTokenSession _mint({
  UseSmileIDSampleSimulatedSpan span =
      UseSmileIDSampleSimulatedSpan.fifteenMinutes,
  UseSmileIDSampleSimulatedBindings bindings =
      const UseSmileIDSampleSimulatedBindings(),
  UseSmileIDSampleEnvironment environment = UseSmileIDSampleEnvironment.sandbox,
}) => UseSmileIDSampleTokenDecoder.session(
  UseSmileIDSampleFlowTokens.session(
    span: span,
    bindings: bindings,
    environment: environment,
    nowMillis: _now,
  ),
)!;

UseSmileIDSampleFlowLaunchSnapshot _snapshot(
  UseSmileIDSampleProduct product, {
  UseSmileIDSampleUserDetails userDetails = const UseSmileIDSampleUserDetails(
    firstName: 'Ada',
    lastName: 'Okafor',
    email: 'ada.okafor@example.com',
  ),
  UseSmileIDSampleScenario scenario = UseSmileIDSampleScenario.normal,
  UseSmileIDSampleTokenSession? session,
  bool sessionExpired = false,
}) => UseSmileIDSampleFlowLaunchSnapshot(
  product: product,
  route: UseSmileIDSampleFlowRoute.fullscreen,
  userDetails: userDetails,
  idDetails: const UseSmileIDSampleIdDetails(),
  scenario: scenario,
  theme: UseSmileIDSampleThemeScenario.brandDefault,
  sandbox: useSmileIDSampleUseSandbox(session),
  allowAgentMode: false,
  enableEnhancedLiveness: true,
  consentStep: true,
  instructionsStep: true,
  previewStep: true,
  userId: 'user_1',
  partnerId: 'profile-1',
  partnerName: 'Kobo Bank',
  callbackUrl: '',
  session: session,
  sessionExpired: sessionExpired,
);

/// The wall clock, since the gate and the ended span both measure against it.
final int _now = DateTime.now().millisecondsSinceEpoch;
