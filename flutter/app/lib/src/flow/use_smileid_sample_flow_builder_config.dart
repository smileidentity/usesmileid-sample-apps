import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid/usesmileid.dart';
import 'package:usesmileid_mlkit_face/usesmileid_mlkit_face.dart';
import 'package:usesmileid_vision_face/usesmileid_vision_face.dart';

import 'use_smileid_sample_flow_launch_snapshot.dart';
import 'use_smileid_sample_flow_plan.dart';
import 'use_smileid_sample_flow_tokens.dart';
import 'use_smileid_sample_token_binding_rules.dart';

/// The one place that decides what the SDK is handed.
void useSmileIDSampleApplying(
  UseSmileIDFlowBuilder builder,
  UseSmileIDSampleFlowLaunchSnapshot snapshot, {
  VoidCallback? onTokenRefreshed,
}) {
  final UseSmileIDSampleFlowPlan plan = useSmileIDSampleFlowPlan(
    snapshot.liveSession?.bindings,
    snapshot.product,
  );
  builder.userDetails = plan.passUserDetails
      ? UserDetails(
          givenNames: snapshot.userDetails.firstName,
          lastName: snapshot.userDetails.lastName,
          email: snapshot.userDetails.email.isEmpty
              ? null
              : snapshot.userDetails.email,
          phoneNumber: snapshot.userDetails.phone.isEmpty
              ? null
              : snapshot.userDetails.phone,
        )
      : null;
  if (snapshot.product == UseSmileIDSampleProduct.smartSelfieAuth) {
    builder.userId = snapshot.userId;
  }
  _applyIdParams(builder, snapshot);
  builder.screens((ScreensBuilder screens) => _journeyFor(screens, snapshot));
  if (snapshot.product.capture) {
    builder.ml(
      (UseSmileIDMLBuilder ml) => ml.analyzers((AnalyzerConfigBuilder a) {
        a.forCaptureType(CaptureType.selfie, (CaptureTypeAnalyzerBuilder c) {
          c.add(_selfieAnalyzerFactory());
          c.detectorMode = FaceDetectorMode.standard;
        });
        if (snapshot.product.needsDocumentCapture) {
          // No factory: this SDK's `add` takes a face one and no-ops for documents.
          a.forCaptureType(CaptureType.document);
        }
      }),
    );
  }
  builder.network(
    (UseSmileIDNetworkBuilder network) => network.config((
      ConfigBuilder config,
    ) {
      config.jobType = snapshot.product.jobType;
      final UseSmileIDSampleTokenSession? scanned = snapshot.liveSession;
      config.token =
          scanned?.token ??
          UseSmileIDSampleFlowTokens.token(
            expired: useSmileIDSampleStartsExpired(snapshot.scenario),
            nowMillis: DateTime.now().millisecondsSinceEpoch,
          );
      config.onTokenExpired = (String previous) async {
        onTokenRefreshed?.call();
        // No refresh endpoint exists for a scanned token, so its auth failure must surface.
        if (scanned != null) {
          return previous;
        }
        return snapshot.scenario == UseSmileIDSampleScenario.badRefresh
            ? UseSmileIDSampleFlowTokens.malformed()
            : UseSmileIDSampleFlowTokens.token(
                expired: false,
                nowMillis: DateTime.now().millisecondsSinceEpoch,
              );
      };
      // Debug only: a release build must never log traffic.
      config.logging((LoggingConfigBuilder logging) {
        logging.enabled = !kReleaseMode;
        // HEADERS, not BODY: a logged body carries the user details this repo forbids in logs.
        logging.level = LogLevel.headers;
      });
      config.partnerConfig((PartnerConfigBuilder partner) {
        // A signed token under a different partner id is a 401.
        partner.partnerId = scanned?.partnerId ?? snapshot.partnerId;
        partner.callbackUrl = scanned == null ? snapshot.callbackUrl : '';
        partner.useSandbox = snapshot.sandbox;
      });
    }),
  );
  final UseSmileIDSampleThemeOverride? palette = snapshot.theme.override;
  if (palette != null) {
    builder.theme((ThemeConfigBuilder theme) {
      theme.primaryColor = palette.primaryColor;
      theme.primaryForeground = palette.primaryForeground;
      theme.secondaryColor = palette.secondaryColor;
      theme.accentColor = palette.accentColor;
      theme.buttonShape = palette.buttonShape;
      if (palette.fontFamily case final String family) {
        theme.fontFamily = family;
      }
    });
  }
}

/// The platform's own face backend, as the SDK's sample picks it.
FaceAnalyzerFactory _selfieAnalyzerFactory() => Platform.isAndroid
    ? const MlKitFaceAnalyzerFactory()
    : const VisionFaceAnalyzerFactory();

void _applyIdParams(
  UseSmileIDFlowBuilder builder,
  UseSmileIDSampleFlowLaunchSnapshot snapshot,
) {
  final UseSmileIDSampleIdDetails details = snapshot.idDetails;
  // The server overwrites these from the token's claims regardless.
  final UseSmileIDSampleTokenBindings? bound = snapshot.liveSession?.bindings;
  final String country = bound?.country ?? details.country?.code ?? '';
  // The API's type, or the document's code: the server never hears which capture shape was chosen.
  final String? chosen = details.idType?.type ?? details.document?.code;
  final String idType = bound?.idType ?? chosen ?? '';
  final String idNumber = bound?.idNumberReference ?? details.idNumber;
  switch (snapshot.product) {
    case UseSmileIDSampleProduct.biometricKyc:
      builder.biometricKYCParams = BiometricKYCParams(
        idType: idType,
        idNumber: idNumber,
        country: country,
      );
    case UseSmileIDSampleProduct.enhancedKyc:
      builder.enhancedKYCParams = EnhancedKYCParams(
        idType: idType,
        idNumber: idNumber,
        country: country,
      );
    // Nullable here: an unselected type stays absent rather than becoming a rejected "".
    case UseSmileIDSampleProduct.documentVerification:
      builder.documentVerificationParams = DocumentVerificationParams(
        country: country,
        idType: bound?.idType ?? chosen,
      );
    case UseSmileIDSampleProduct.enhancedDocumentVerification:
      builder.enhancedDocumentVerificationParams =
          EnhancedDocumentVerificationParams(country: country, idType: idType);
    case UseSmileIDSampleProduct.smartSelfieEnrollment:
    case UseSmileIDSampleProduct.smartSelfieAuth:
      break;
  }
}

void _journeyFor(
  ScreensBuilder screens,
  UseSmileIDSampleFlowLaunchSnapshot snapshot,
) {
  for (final UseSmileIDSampleFlowJourneyStep step
      in useSmileIDSampleJourneyStepsFor(snapshot)) {
    switch (step) {
      case UseSmileIDSampleFlowJourneyStep.consent:
        screens.consent((ConsentConfigBuilder consent) {
          consent.partnerName = snapshot.partnerName;
          // Omitting it fails build() while validate() still reports Valid, so no gate catches it.
          consent.partnerIcon = const _UseSmileIDSamplePartnerMark();
          consent.partnerPrivacyPolicyUrl = _privacyPolicyUrl;
        });
      case UseSmileIDSampleFlowJourneyStep.instructions:
        screens.instructions();
      case UseSmileIDSampleFlowJourneyStep.selfieCapture:
        screens.capture((CaptureConfigBuilder capture) {
          capture.captureType = CaptureType.selfie;
          capture.selfie((SelfieCaptureConfigBuilder selfie) {
            selfie.allowAgentMode = snapshot.allowAgentMode;
            selfie.enableEnhancedLiveness = snapshot.enableEnhancedLiveness;
          });
        });
      case UseSmileIDSampleFlowJourneyStep.documentCapture:
        screens.capture((CaptureConfigBuilder capture) {
          capture.captureType = CaptureType.document;
          capture.document((DocumentCaptureConfigBuilder document) {
            final UseSmileIDSampleDocumentCapture shape =
                useSmileIDSampleDocumentCaptureFor(snapshot.idDetails);
            document.documentType = shape.documentType;
            document.captureBothSides = shape.captureBothSides;
            document.allowSkipBack = true;
            document.captureMode = snapshot.captureMode.sdk;
            document.allowGalleryUpload = snapshot.galleryUpload;
          });
        });
      case UseSmileIDSampleFlowJourneyStep.preview:
        screens.preview();
      case UseSmileIDSampleFlowJourneyStep.processing:
        screens.processing();
    }
  }
}

/// One SDK screen the host composes. Named so the journey can be asserted: the builder's list is private.
enum UseSmileIDSampleFlowJourneyStep {
  /// The SDK's consent step.
  consent,

  /// The instructions step.
  instructions,

  /// A selfie capture.
  selfieCapture,

  /// A document capture.
  documentCapture,

  /// A preview of what was just captured.
  preview,

  /// The submission step.
  processing,
}

/// The journey, as the three step switches and the token's consent binding decide it.
List<UseSmileIDSampleFlowJourneyStep> useSmileIDSampleJourneyStepsFor(
  UseSmileIDSampleFlowLaunchSnapshot snapshot,
) {
  final List<UseSmileIDSampleFlowJourneyStep> steps =
      <UseSmileIDSampleFlowJourneyStep>[];
  final bool declareConsent = useSmileIDSampleFlowPlan(
    snapshot.liveSession?.bindings,
    snapshot.product,
  ).declareConsentScreen;
  if (declareConsent && snapshot.consentStep) {
    steps.add(UseSmileIDSampleFlowJourneyStep.consent);
  }
  // Enhanced KYC is the one journey without capture: consent and processing only, per its validator.
  if (!snapshot.product.capture) {
    return steps..add(UseSmileIDSampleFlowJourneyStep.processing);
  }
  if (snapshot.instructionsStep) {
    steps.add(UseSmileIDSampleFlowJourneyStep.instructions);
  }
  switch (snapshot.product) {
    case UseSmileIDSampleProduct.documentVerification:
      _documentCapture(steps, snapshot.previewStep);
      _selfieCapture(steps, snapshot.previewStep);
    case UseSmileIDSampleProduct.enhancedDocumentVerification:
      _selfieCapture(steps, snapshot.previewStep);
      _documentCapture(steps, snapshot.previewStep);
    case UseSmileIDSampleProduct.smartSelfieEnrollment:
    case UseSmileIDSampleProduct.smartSelfieAuth:
    case UseSmileIDSampleProduct.biometricKyc:
    case UseSmileIDSampleProduct.enhancedKyc:
      _selfieCapture(steps, snapshot.previewStep);
  }
  return steps..add(UseSmileIDSampleFlowJourneyStep.processing);
}

/// A preview follows its capture, and the document products' two previews go together or not at all.
void _selfieCapture(List<UseSmileIDSampleFlowJourneyStep> steps, bool preview) {
  steps.add(UseSmileIDSampleFlowJourneyStep.selfieCapture);
  if (preview) {
    steps.add(UseSmileIDSampleFlowJourneyStep.preview);
  }
}

void _documentCapture(
  List<UseSmileIDSampleFlowJourneyStep> steps,
  bool preview,
) {
  steps.add(UseSmileIDSampleFlowJourneyStep.documentCapture);
  if (preview) {
    steps.add(UseSmileIDSampleFlowJourneyStep.preview);
  }
}

/// What the SDK is told to photograph; the server is told the document's code either way.
typedef UseSmileIDSampleDocumentCapture = ({
  DocumentType documentType,
  bool captureBothSides,
});

/// The "Capture as" mapping from `spec/catalogue-rules.json`; pure, so its table is unit-tested.
@visibleForTesting
UseSmileIDSampleDocumentCapture useSmileIDSampleDocumentCaptureFor(
  UseSmileIDSampleIdDetails details,
) {
  final UseSmileIDSampleDocument? document = details.document;
  return switch (details.captureAs) {
    UseSmileIDSampleCaptureAs.greenBook => _preset(
      DocumentType.southAfricaGreenBook,
    ),
    UseSmileIDSampleCaptureAs.passport => _preset(DocumentType.passport),
    UseSmileIDSampleCaptureAs.custom => _preset(
      GenericDocument(
        displayName: details.custom.displayName,
        hasBackSide: details.custom.hasBackSide,
        orientation: switch (details.custom.orientation) {
          UseSmileIDSampleDocumentOrientation.landscape =>
            DocumentOrientation.landscape,
          UseSmileIDSampleDocumentOrientation.portrait =>
            DocumentOrientation.portrait,
        },
        knownAspectRatio: details.custom.aspectRatio.ratio,
      ),
    ),
    // The API's has_back, not a preset's: the API is the source that says what the document is.
    UseSmileIDSampleCaptureAs.automatic => (
      documentType: switch (document?.format) {
        _formatGreenBook => DocumentType.southAfricaGreenBook,
        _formatBooklet => DocumentType.passport,
        _ => GenericDocument(
          displayName: document?.name ?? 'Document',
          hasBackSide: document?.hasBack ?? true,
        ),
      },
      captureBothSides: document?.hasBack ?? true,
    ),
  };
}

UseSmileIDSampleDocumentCapture _preset(DocumentType type) =>
    (documentType: type, captureBothSides: type.hasBackSide);

// The API's undocumented `format`: 3 is a passport or seaman's booklet, 7 the Green Book; the rest are cards.
const int _formatBooklet = 3;
const int _formatGreenBook = 7;

extension on UseSmileIDSampleCaptureMode {
  DocumentCaptureMode get sdk => switch (this) {
    UseSmileIDSampleCaptureMode.auto => const AutoCapture(),
    UseSmileIDSampleCaptureMode.manual => const ManualCapture(),
    UseSmileIDSampleCaptureMode.autoWithFallback =>
      const AutoCaptureWithManualFallback(),
  };
}

/// The SDK's own job type for each product.
extension on UseSmileIDSampleProduct {
  JobType get jobType => switch (this) {
    UseSmileIDSampleProduct.smartSelfieEnrollment =>
      JobType.smartSelfieEnrollment,
    UseSmileIDSampleProduct.smartSelfieAuth =>
      JobType.smartSelfieAuthentication,
    UseSmileIDSampleProduct.documentVerification =>
      JobType.documentVerification,
    UseSmileIDSampleProduct.enhancedDocumentVerification =>
      JobType.enhancedDocumentVerification,
    UseSmileIDSampleProduct.biometricKyc => JobType.biometricKyc,
    UseSmileIDSampleProduct.enhancedKyc => JobType.enhancedKyc,
  };

  bool get needsDocumentCapture =>
      this == UseSmileIDSampleProduct.documentVerification ||
      this == UseSmileIDSampleProduct.enhancedDocumentVerification;
}

/// The partner mark the consent screen draws, resolving its colour where the SDK mounts it.
class _UseSmileIDSamplePartnerMark extends StatelessWidget {
  const _UseSmileIDSamplePartnerMark();

  @override
  Widget build(BuildContext context) => UseSmileIDSampleGlyphs.productMark(
    UseSmileIDSampleTheme.colorsOf(context).textTitle,
  );
}

// The same host the Settings privacy row opens.
const String _privacyPolicyUrl = 'https://smile.id/privacy-policy';
