/// Which settings row a toggle belongs to, so the screen can report changes through one callback.
export const UseSmileIDSampleSetting = {
  EnhancedSmartSelfie: 'enhancedSmartSelfie',
  AgentMode: 'agentMode',
  ConsentStep: 'consentStep',
  InstructionsStep: 'instructionsStep',
  PreviewStep: 'previewStep',
  GalleryUpload: 'galleryUpload',
  AllowSkipBack: 'allowSkipBack',
  SelfieFirst: 'selfieFirst',
} as const;

export type UseSmileIDSampleSetting =
  (typeof UseSmileIDSampleSetting)[keyof typeof UseSmileIDSampleSetting];

/// The switch rows in the order Settings draws them, which the spec test compares against test-ids.json.
export const smileIDSampleSettings: readonly UseSmileIDSampleSetting[] = [
  UseSmileIDSampleSetting.EnhancedSmartSelfie,
  UseSmileIDSampleSetting.AgentMode,
  UseSmileIDSampleSetting.ConsentStep,
  UseSmileIDSampleSetting.InstructionsStep,
  UseSmileIDSampleSetting.PreviewStep,
  UseSmileIDSampleSetting.GalleryUpload,
  UseSmileIDSampleSetting.AllowSkipBack,
  UseSmileIDSampleSetting.SelfieFirst,
];
