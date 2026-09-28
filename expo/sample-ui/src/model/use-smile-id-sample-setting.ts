/// Which settings row a toggle belongs to, so the screen can report changes without eight callbacks.
export const UseSmileIDSampleSetting = {
  EnhancedSmartSelfie: 'enhancedSmartSelfie',
  AgentMode: 'agentMode',
  DarkMode: 'darkMode',
  ConsentStep: 'consentStep',
  InstructionsStep: 'instructionsStep',
  PreviewStep: 'previewStep',
  CustomContinue: 'customContinue',
  CustomCancel: 'customCancel',
} as const;

export type UseSmileIDSampleSetting =
  (typeof UseSmileIDSampleSetting)[keyof typeof UseSmileIDSampleSetting];

/// The eight rows in the order Settings draws them, which the spec test compares against test-ids.json.
export const smileIDSampleSettings: readonly UseSmileIDSampleSetting[] = [
  UseSmileIDSampleSetting.EnhancedSmartSelfie,
  UseSmileIDSampleSetting.AgentMode,
  UseSmileIDSampleSetting.DarkMode,
  UseSmileIDSampleSetting.ConsentStep,
  UseSmileIDSampleSetting.InstructionsStep,
  UseSmileIDSampleSetting.PreviewStep,
  UseSmileIDSampleSetting.CustomContinue,
  UseSmileIDSampleSetting.CustomCancel,
];
