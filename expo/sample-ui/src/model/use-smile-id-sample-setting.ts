/// Which settings row a toggle belongs to, so the screen can report changes without six callbacks.
export const UseSmileIDSampleSetting = {
  EnhancedSmartSelfie: 'enhancedSmartSelfie',
  AgentMode: 'agentMode',
  DarkMode: 'darkMode',
  ConsentStep: 'consentStep',
  InstructionsStep: 'instructionsStep',
  PreviewStep: 'previewStep',
} as const;

export type UseSmileIDSampleSetting =
  (typeof UseSmileIDSampleSetting)[keyof typeof UseSmileIDSampleSetting];

/// The six rows in the order Settings draws them, which the spec test compares against test-ids.json.
export const smileIDSampleSettings: readonly UseSmileIDSampleSetting[] = [
  UseSmileIDSampleSetting.EnhancedSmartSelfie,
  UseSmileIDSampleSetting.AgentMode,
  UseSmileIDSampleSetting.DarkMode,
  UseSmileIDSampleSetting.ConsentStep,
  UseSmileIDSampleSetting.InstructionsStep,
  UseSmileIDSampleSetting.PreviewStep,
];
