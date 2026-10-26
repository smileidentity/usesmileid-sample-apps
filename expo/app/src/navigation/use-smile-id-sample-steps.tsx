import { select } from '@smileid/njia';
import { njiaSteps, type NjiaSteps } from '@smileid/njia/host';
import type { ReactNode } from 'react';

import { UseSmileIDSampleAuthUserIdStep } from '../steps/use-smile-id-sample-auth-user-id-step';
import { UseSmileIDSampleConsentDetailsStep } from '../steps/use-smile-id-sample-consent-details-step';
import {
  UseSmileIDSampleCaptureAsStep,
  UseSmileIDSampleCountryPickerStep,
  UseSmileIDSampleDocumentPickerStep,
  UseSmileIDSampleGenericDocumentStep,
  UseSmileIDSampleIdTypePickerStep,
} from '../steps/use-smile-id-sample-id-details-sheets';
import { UseSmileIDSampleIdDetailsStep } from '../steps/use-smile-id-sample-id-details-step';
import { UseSmileIDSampleLicensesStep } from '../steps/use-smile-id-sample-licenses-step';
import { UseSmileIDSampleProductsStep } from '../steps/use-smile-id-sample-products-step';
import { UseSmileIDSampleProfileConfigStep } from '../steps/use-smile-id-sample-profile-config-step';
import { UseSmileIDSampleNewProfileStep, UseSmileIDSampleProfileSwitchStep } from '../steps/use-smile-id-sample-profile-sheets';
import { UseSmileIDSampleProfilesStep } from '../steps/use-smile-id-sample-profiles-step';
import { UseSmileIDSampleScanTokenStep } from '../steps/use-smile-id-sample-scan-token-step';
import { UseSmileIDSampleSdkFlowStep } from '../steps/use-smile-id-sample-sdk-flow-step';
import {
  UseSmileIDSampleAppearanceStep,
  UseSmileIDSampleCaptureModeStep,
  UseSmileIDSampleSubmissionStep,
  UseSmileIDSampleLanguageStep,
  UseSmileIDSampleScenarioDrawerStep,
} from '../steps/use-smile-id-sample-settings-sheets';
import { UseSmileIDSampleSettingsStep } from '../steps/use-smile-id-sample-settings-step';
import { UseSmileIDSampleVerificationDetailsStep } from '../steps/use-smile-id-sample-verification-details-step';
import { UseSmileIDSampleVerificationsStep } from '../steps/use-smile-id-sample-verifications-step';
import { UseSmileIDSampleNavBarHost } from '../use-smile-id-sample-nav-bar-host';
import { useSmileIDSampleEngine, type UseSmileIDSampleStepScope } from './use-smile-id-sample-navigation';
import type { UseSmileIDSampleFact, UseSmileIDSampleStep } from './use-smile-id-sample-njia';

/// The tab roots, which carry the nav bar.
const tabRoots: ReadonlySet<UseSmileIDSampleStep> = new Set(['products', 'verifications', 'settings']);

/// The steps the shell's own page drew before: the tab roots, with their bar, and the screens pushed inside a tab.
const shellPages: ReadonlySet<UseSmileIDSampleStep> = new Set([...tabRoots, 'licenses', 'verificationDetails']);

/// A tab's root with its bar, or a screen pushed inside a tab with none; each screen insets itself.
const UseSmileIDSampleShellPage = ({ scope, children }: { scope: UseSmileIDSampleStepScope; children: ReactNode }) => {
  const engine = useSmileIDSampleEngine();
  return (
    <UseSmileIDSampleNavBarHost
      tab={tabRoots.has(scope.step.kind) ? scope.step.id : null}
      onSelect={(tab) => select(engine, tab)}
      onTokenPress={() => scope.navigator.go('scanToken')}
    >
      {children}
    </UseSmileIDSampleNavBarHost>
  );
};

/// What draws each of the graph's step kinds; a kind with no renderer fails before the first frame.
export const smileIDSampleSteps: NjiaSteps<UseSmileIDSampleStep, UseSmileIDSampleFact> = njiaSteps((steps) => {
  steps.decorate((scope, content) =>
    shellPages.has(scope.step.kind) ? <UseSmileIDSampleShellPage scope={scope}>{content}</UseSmileIDSampleShellPage> : content,
  );
  steps.step('products', (scope) => <UseSmileIDSampleProductsStep scope={scope} />);
  steps.step('verifications', (scope) => <UseSmileIDSampleVerificationsStep scope={scope} />);
  steps.step('settings', (scope) => <UseSmileIDSampleSettingsStep scope={scope} />);
  steps.step('licenses', (scope) => <UseSmileIDSampleLicensesStep scope={scope} />);
  steps.step('captureMode', (scope) => <UseSmileIDSampleCaptureModeStep scope={scope} />);
  steps.step('submission', (scope) => <UseSmileIDSampleSubmissionStep scope={scope} />);
  steps.step('appearance', (scope) => <UseSmileIDSampleAppearanceStep scope={scope} />);
  steps.step('language', (scope) => <UseSmileIDSampleLanguageStep scope={scope} />);
  steps.step('scenarioDrawer', (scope) => <UseSmileIDSampleScenarioDrawerStep scope={scope} />);
  steps.step('verificationDetails', (scope) => <UseSmileIDSampleVerificationDetailsStep scope={scope} />);
  steps.step('profileSwitch', (scope) => <UseSmileIDSampleProfileSwitchStep scope={scope} />);
  steps.step('profiles', (scope) => <UseSmileIDSampleProfilesStep scope={scope} />);
  steps.step('newProfile', (scope) => <UseSmileIDSampleNewProfileStep scope={scope} />);
  steps.step('profileConfig', (scope) => <UseSmileIDSampleProfileConfigStep scope={scope} />);
  steps.step('scanToken', (scope) => <UseSmileIDSampleScanTokenStep scope={scope} />);
  steps.step('countryPicker', (scope) => <UseSmileIDSampleCountryPickerStep scope={scope} />);
  steps.step('idTypePicker', (scope) => <UseSmileIDSampleIdTypePickerStep scope={scope} />);
  steps.step('documentPicker', (scope) => <UseSmileIDSampleDocumentPickerStep scope={scope} />);
  steps.step('captureAs', (scope) => <UseSmileIDSampleCaptureAsStep scope={scope} />);
  steps.step('genericDocument', (scope) => <UseSmileIDSampleGenericDocumentStep scope={scope} />);
  steps.step('consentDetailsForm', (scope) => <UseSmileIDSampleConsentDetailsStep scope={scope} />);
  steps.step('authUserId', (scope) => <UseSmileIDSampleAuthUserIdStep scope={scope} />);
  steps.step('idDetailsForm', (scope) => <UseSmileIDSampleIdDetailsStep scope={scope} />);
  steps.step('sdkFlow', (scope) => <UseSmileIDSampleSdkFlowStep scope={scope} />);
  steps.step('sdkFlowFullScreen', (scope) => <UseSmileIDSampleSdkFlowStep scope={scope} />);
});
