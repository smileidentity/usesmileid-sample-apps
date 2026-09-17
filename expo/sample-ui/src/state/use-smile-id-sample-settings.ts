import { UseSmileIDSampleSetting } from '../model/use-smile-id-sample-setting';

/// The Settings state. Three of these decide whether a step is composed into the flow at all.
export type UseSmileIDSampleSettings = {
  /// ON is the head-turn challenge, which is the default the design draws.
  readonly enhancedSmartSelfie: boolean;
  readonly agentMode: boolean;
  readonly darkMode: boolean;
  readonly consentStep: boolean;
  readonly instructionsStep: boolean;
  readonly previewStep: boolean;
};

export const smileIDSampleSettingsDefaults: UseSmileIDSampleSettings = {
  enhancedSmartSelfie: true,
  agentMode: false,
  darkMode: false,
  consentStep: true,
  instructionsStep: true,
  previewStep: true,
};

/// Drops enhanced liveness where a stored state carries both, so the SDK is never handed the pair it refuses.
export const smileIDSampleSettingsNormalised = (
  settings: UseSmileIDSampleSettings,
): UseSmileIDSampleSettings =>
  settings.agentMode && settings.enhancedSmartSelfie
    ? { ...settings, enhancedSmartSelfie: false }
    : settings;

/// The capture mutex: the SDK refuses agent mode with enhanced liveness, so turning either on turns the other off.
export const smileIDSampleSettingsWith = (
  settings: UseSmileIDSampleSettings,
  setting: UseSmileIDSampleSetting,
  enabled: boolean,
): UseSmileIDSampleSettings => {
  switch (setting) {
    case UseSmileIDSampleSetting.EnhancedSmartSelfie:
      return { ...settings, enhancedSmartSelfie: enabled, agentMode: settings.agentMode && !enabled };
    case UseSmileIDSampleSetting.AgentMode:
      return {
        ...settings,
        agentMode: enabled,
        enhancedSmartSelfie: settings.enhancedSmartSelfie && !enabled,
      };
    default:
      return { ...settings, [setting]: enabled };
  }
};
