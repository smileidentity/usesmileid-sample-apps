import { useEffect } from 'react';
import {
  AppearanceSheet,
  CaptureModeSheet,
  LanguageSheet,
  ScenarioDrawerSheet,
  useSmileIDSampleDeviceLanguages,
  useSmileIDSampleSettingsStore,
} from '@smileid/sample-ui';

import { useSmileIDSampleShellExtension } from '../extension';
import type { UseSmileIDSampleStepScope } from '../navigation/use-smile-id-sample-navigation';
import { smileIDSampleDebugSheetOpens } from '../use-smile-id-sample-shell-extension';
import { useSmileIDSampleDeviceScheme } from '../use-smile-id-sample-device-scheme';
import { smileIDSamplePickScenario, smileIDSamplePickTheme, useLaunchArgs } from '../use-smile-id-sample-launch';

/// The capture-mode sheet over settings; a link opens it with settings beneath.
export const UseSmileIDSampleCaptureModeStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const selected = useSmileIDSampleSettingsStore((state) => state.settings.captureMode);
  const setCaptureMode = useSmileIDSampleSettingsStore((state) => state.setCaptureMode);
  return (
    <CaptureModeSheet
      selected={selected}
      onSelect={(mode) => {
        void setCaptureMode(mode);
        scope.navigator.back();
      }}
      onDismiss={() => scope.navigator.back()}
    />
  );
};

/// The appearance sheet over settings.
export const UseSmileIDSampleAppearanceStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const selected = useSmileIDSampleSettingsStore((state) => state.settings.appearance);
  const setAppearance = useSmileIDSampleSettingsStore((state) => state.setAppearance);
  const deviceDark = useSmileIDSampleDeviceScheme((state) => state.deviceDark);
  return (
    <AppearanceSheet
      selected={selected}
      deviceDark={deviceDark}
      onSelect={(appearance) => {
        void setAppearance(appearance);
        scope.navigator.back();
      }}
      onDismiss={() => scope.navigator.back()}
    />
  );
};

/// The language sheet over settings.
export const UseSmileIDSampleLanguageStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const selected = useSmileIDSampleSettingsStore((state) => state.settings.language);
  const setLanguage = useSmileIDSampleSettingsStore((state) => state.setLanguage);
  const deviceLanguages = useSmileIDSampleDeviceLanguages();
  return (
    <LanguageSheet
      selected={selected}
      deviceLanguages={deviceLanguages}
      onSelect={(language) => {
        void setLanguage(language);
        scope.navigator.back();
      }}
      onDismiss={() => scope.navigator.back()}
    />
  );
};

/// The scenario drawer over settings: its row is debug-only, but `debug/scenarios` reaches it on every build, as device flows do.
export const UseSmileIDSampleScenarioDrawerStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const { scenario, theme } = useLaunchArgs();
  return (
    <ScenarioDrawerSheet
      scenario={scenario}
      theme={theme}
      onScenarioSelect={smileIDSamplePickScenario}
      onThemeSelect={smileIDSamplePickTheme}
      onDismiss={() => scope.navigator.back()}
    />
  );
};

/// A sheet the extension draws for one of its DEBUG rows; a release build, or one with no extension, closes it at once.
export const UseSmileIDSampleDebugSheetStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const extension = useSmileIDSampleShellExtension;
  const opens = extension?.debugSheet !== undefined && smileIDSampleDebugSheetOpens(__DEV__, true);
  useEffect(() => {
    if (!opens) scope.navigator.back();
  }, [opens, scope.navigator]);
  return opens ? extension?.debugSheet?.(scope.entry.arg ?? '', () => scope.navigator.back()) : null;
};
