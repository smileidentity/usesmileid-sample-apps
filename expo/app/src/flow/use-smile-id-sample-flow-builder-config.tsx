import {
  UseSmileIDSampleIcon,
  smileIDSampleThemeOverride,
  useSmileIDSampleTheme,
} from '@smileid/sample-ui';
import {
  CaptureType,
  DocumentType,
  JobType,
  LogLevel,
  type AnalyzerRegistryBuilder,
  type CaptureConfigBuilder,
  type ConfigBuilder,
  type ConsentConfigBuilder,
  type DocumentCaptureConfigBuilder,
  type ScreensBuilder,
  type SelfieCaptureConfigBuilder,
  type ThemeConfigBuilder,
  type UseSmileIDFlowBuilder,
  type UseSmileIDMLBuilder,
  type UseSmileIDNetworkBuilder,
} from '@smileid/usesmileid';
import type { FaceAnalyzer } from '@smileid/usesmileid_platform_interface';
import { Platform } from 'react-native';

import { smileIDSampleFlowToken, smileIDSampleMalformedToken } from './use-smile-id-sample-flow-tokens';
import {
  smileIDSampleSnapshotSession,
  type UseSmileIDSampleFlowLaunchSnapshot,
} from './use-smile-id-sample-flow-launch-snapshot';
import { smileIDSampleFlowPlan } from './use-smile-id-sample-flow-plan';
import { smileIDSampleStartsExpired } from './use-smile-id-sample-token-binding-rules';

/// One SDK screen the host composes. Named so the journey can be asserted: the builder's list is private.
export const smileIDSampleFlowJourneySteps = [
  'consent',
  'instructions',
  'selfieCapture',
  'documentCapture',
  'preview',
  'processing',
] as const;

export type UseSmileIDSampleFlowJourneyStep = (typeof smileIDSampleFlowJourneySteps)[number];

/// The one place that decides what the SDK is handed.
export const smileIDSampleApplying = (
  builder: UseSmileIDFlowBuilder,
  snapshot: UseSmileIDSampleFlowLaunchSnapshot,
): void => {
  const scanned = smileIDSampleSnapshotSession(snapshot);
  // Omitted, never blanked, when the token binds what the SDK requires: a blank silences its per-field errors.
  if (smileIDSampleFlowPlan(scanned?.bindings, snapshot.product).passUserDetails) {
    builder.userDetails = {
      givenNames: snapshot.userDetails.firstName,
      lastName: snapshot.userDetails.lastName,
      ...(snapshot.userDetails.email.length > 0 ? { email: snapshot.userDetails.email } : {}),
      ...(snapshot.userDetails.phone.length > 0 ? { phoneNumber: snapshot.userDetails.phone } : {}),
    };
  }
  if (snapshot.product.id === 'smartSelfieAuth') builder.userId = snapshot.userId;
  applyIdParams(builder, snapshot);
  builder.screens((screens: ScreensBuilder) => journeyFor(screens, snapshot));
  if (snapshot.product.capture) {
    builder.ml((ml: UseSmileIDMLBuilder) =>
      ml.analyzers((analyzers: AnalyzerRegistryBuilder) => {
        analyzers.forCaptureType(CaptureType.selfie, (face) => {
          face.add(selfieAnalyzer());
        });
      }),
    );
  }
  builder.network((network: UseSmileIDNetworkBuilder) =>
    network.config((config: ConfigBuilder) => {
      config.jobType = jobTypeFor(snapshot.product.id);
      config.token =
        scanned?.token ??
        smileIDSampleFlowToken({
          expired: smileIDSampleStartsExpired(snapshot.scenario),
          nowMillis: Date.now(),
        });
      // The Portal mints by hand and nothing here may call it, so a scanned token's auth failure surfaces.
      config.onTokenExpired = async () =>
        scanned !== null
          ? scanned.token
          : snapshot.scenario === 'badRefresh'
            ? smileIDSampleMalformedToken()
            : smileIDSampleFlowToken({ expired: false, nowMillis: Date.now() });
      // Debug only: a release build must never log traffic.
      config.logging((logging) => {
        logging.enabled = __DEV__;
        // Headers, not body: a logged body carries the user details this repo forbids in logs.
        logging.level = LogLevel.headers;
      });
      config.partnerConfig((partner) => {
        // The token wins over the profile: a signed token submitted under another partner id comes back 401.
        partner.partnerId = scanned?.partnerId ?? snapshot.partnerId;
        partner.callbackUrl = scanned === null ? snapshot.callbackUrl : '';
        partner.useSandbox = snapshot.sandbox;
      });
    }),
  );
  const palette = smileIDSampleThemeOverride(snapshot.theme);
  if (palette !== null) {
    builder.theme((theme: ThemeConfigBuilder) => {
      theme.primaryColor = palette.primaryColor;
      theme.primaryForeground = palette.primaryForeground;
      theme.secondaryColor = palette.secondaryColor;
      theme.accentColor = palette.accentColor;
      theme.buttonShape = palette.buttonShape;
      if (palette.fontFamily !== undefined) theme.fontFamily = palette.fontFamily;
    });
  }
};

/// The journey, as the three step switches and the token's bindings decide it.
export const smileIDSampleJourneyStepsFor = (
  snapshot: UseSmileIDSampleFlowLaunchSnapshot,
): UseSmileIDSampleFlowJourneyStep[] => {
  const steps: UseSmileIDSampleFlowJourneyStep[] = [];
  const plan = smileIDSampleFlowPlan(smileIDSampleSnapshotSession(snapshot)?.bindings, snapshot.product);
  // A consent binding lifts the SDK's requirement, and declaring the screen anyway ends the run before it starts.
  if (plan.declareConsentScreen && snapshot.consentStep) steps.push('consent');
  // Enhanced KYC is the one journey without capture: consent and processing only, per its validator.
  if (!snapshot.product.capture) return [...steps, 'processing'];
  if (snapshot.instructionsStep) steps.push('instructions');
  const selfie: UseSmileIDSampleFlowJourneyStep[] = snapshot.previewStep
    ? ['selfieCapture', 'preview']
    : ['selfieCapture'];
  const document: UseSmileIDSampleFlowJourneyStep[] = snapshot.previewStep
    ? ['documentCapture', 'preview']
    : ['documentCapture'];
  if (snapshot.product.id === 'documentVerification') steps.push(...document, ...selfie);
  else if (snapshot.product.id === 'enhancedDocumentVerification') steps.push(...selfie, ...document);
  else steps.push(...selfie);
  return [...steps, 'processing'];
};

const journeyFor = (screens: ScreensBuilder, snapshot: UseSmileIDSampleFlowLaunchSnapshot): void => {
  for (const step of smileIDSampleJourneyStepsFor(snapshot)) {
    switch (step) {
      case 'consent':
        screens.consent((consent: ConsentConfigBuilder) => {
          consent.partnerName = snapshot.partnerName;
          // Omitting it fails the build while validate() still reports valid, so no gate catches it.
          consent.partnerIcon = <PartnerMark />;
          consent.partnerPrivacyPolicyUrl = privacyPolicyUrl;
        });
        break;
      case 'instructions':
        screens.instructions();
        break;
      case 'selfieCapture':
        screens.capture((capture: CaptureConfigBuilder) => {
          capture.captureType = CaptureType.selfie;
          capture.selfie((selfie: SelfieCaptureConfigBuilder) => {
            selfie.allowAgentMode = snapshot.allowAgentMode;
            selfie.enableEnhancedLiveness = snapshot.enableEnhancedLiveness;
          });
        });
        break;
      case 'documentCapture':
        screens.capture((capture: CaptureConfigBuilder) => {
          capture.captureType = CaptureType.document;
          capture.document((document: DocumentCaptureConfigBuilder) => {
            document.documentType = documentTypeFor(snapshot.idDetails.idType?.id);
            document.captureBothSides = true;
            document.allowSkipBack = true;
          });
        });
        break;
      case 'preview':
        screens.preview();
        break;
      case 'processing':
        screens.processing();
        break;
    }
  }
};

const applyIdParams = (
  builder: UseSmileIDFlowBuilder,
  snapshot: UseSmileIDSampleFlowLaunchSnapshot,
): void => {
  // Per field the token beats the form, since the server overwrites these from its claims regardless.
  const bound = smileIDSampleSnapshotSession(snapshot)?.bindings;
  const country = bound?.country ?? snapshot.idDetails.country?.code ?? '';
  const idType = bound?.idType ?? snapshot.idDetails.idType?.id ?? '';
  // The SDK asks only that this be non-blank, and the server substitutes the same claim anyway.
  const idNumber = bound?.idNumberReference ?? snapshot.idDetails.idNumber;
  switch (snapshot.product.id) {
    case 'biometricKyc':
      // Capture still runs either way; false is the plain path a sample demonstrates.
      builder.biometricKYCParams = { idType, idNumber, country, useEnrolledImage: false };
      break;
    case 'enhancedKyc':
      builder.enhancedKYCParams = { idType, idNumber, country };
      break;
    // Left absent rather than sent as a rejected empty string when nothing was selected.
    case 'documentVerification':
      builder.documentVerificationParams = {
        country,
        ...(bound?.idType == null && snapshot.idDetails.idType === null ? {} : { idType }),
      };
      break;
    case 'enhancedDocumentVerification':
      builder.enhancedDocumentVerificationParams = { country, idType };
      break;
    default:
      break;
  }
};

/// Required, not imported: a provider resolves its native module on import and would take the bundle down.
const selfieAnalyzer = (): FaceAnalyzer =>
  Platform.OS === 'android'
    ? // eslint-disable-next-line @typescript-eslint/no-require-imports
      (require('@smileid/usesmileid_mlkit_face') as { useSmileIDMlkitFace: FaceAnalyzer })
        .useSmileIDMlkitFace
    : // eslint-disable-next-line @typescript-eslint/no-require-imports
      (require('@smileid/usesmileid_vision_face') as { useSmileIDVisionFace: FaceAnalyzer })
        .useSmileIDVisionFace;

/// The partner mark the consent screen draws, resolving its colour where the SDK mounts it.
const PartnerMark = () => {
  const theme = useSmileIDSampleTheme();
  return <UseSmileIDSampleIcon name="productMark" tint={theme.colors.textTitle} />;
};

const jobTypeFor = (productId: string): JobType => {
  switch (productId) {
    case 'smartSelfieEnrollment':
      return JobType.smartSelfieEnrollment;
    case 'smartSelfieAuth':
      return JobType.smartSelfieAuthentication;
    case 'documentVerification':
      return JobType.documentVerification;
    case 'enhancedDocumentVerification':
      return JobType.enhancedDocumentVerification;
    case 'biometricKyc':
      return JobType.biometricKyc;
    default:
      return JobType.enhancedKyc;
  }
};

const documentTypeFor = (idTypeId: string | undefined): DocumentType =>
  idTypeId === 'PASSPORT' ? DocumentType.Passport : DocumentType.GenericDocument();

// The same host the Settings privacy row opens.
const privacyPolicyUrl = 'https://smile.id/privacy-policy';
