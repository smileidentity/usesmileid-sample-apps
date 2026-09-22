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
import type { UseSmileIDSampleFlowLaunchSnapshot } from './use-smile-id-sample-flow-launch-snapshot';

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
  builder.userDetails = {
    givenNames: snapshot.userDetails.firstName,
    lastName: snapshot.userDetails.lastName,
    ...(snapshot.userDetails.email.length > 0 ? { email: snapshot.userDetails.email } : {}),
    ...(snapshot.userDetails.phone.length > 0 ? { phoneNumber: snapshot.userDetails.phone } : {}),
  };
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
      config.token = smileIDSampleFlowToken({
        expired: snapshot.scenario === 'expiredToken',
        nowMillis: Date.now(),
      });
      config.onTokenExpired = async () =>
        snapshot.scenario === 'badRefresh'
          ? smileIDSampleMalformedToken()
          : smileIDSampleFlowToken({ expired: false, nowMillis: Date.now() });
      // Debug builds only: a sample that shows a partner what the SDK put on the wire is a real
      // probe affordance, but release must never log traffic.
      config.logging((logging) => {
        logging.enabled = __DEV__;
        // Headers, not body: a logged body carries the user details this repo forbids in logs.
        logging.level = LogLevel.headers;
      });
      config.partnerConfig((partner) => {
        partner.partnerId = snapshot.partnerId;
        partner.callbackUrl = snapshot.callbackUrl;
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

/// The journey, as the three step switches decide it.
export const smileIDSampleJourneyStepsFor = (
  snapshot: UseSmileIDSampleFlowLaunchSnapshot,
): UseSmileIDSampleFlowJourneyStep[] => {
  const steps: UseSmileIDSampleFlowJourneyStep[] = [];
  if (snapshot.consentStep) steps.push('consent');
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
  const country = snapshot.idDetails.country?.code ?? '';
  const idType = snapshot.idDetails.idType?.id ?? '';
  const idNumber = snapshot.idDetails.idNumber;
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
        ...(snapshot.idDetails.idType === null ? {} : { idType }),
      };
      break;
    case 'enhancedDocumentVerification':
      builder.enhancedDocumentVerificationParams = { country, idType };
      break;
    default:
      break;
  }
};

/// The platform's own face backend, required rather than imported: each provider resolves its native
/// module at import time, so naming the other platform's here takes the whole JS bundle down.
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
