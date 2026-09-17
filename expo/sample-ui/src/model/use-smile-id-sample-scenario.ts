/// One scenario the drawer offers, with the copy the drawer and the result card both read.
export type UseSmileIDSampleScenarioEntry = {
  readonly id: string;
  readonly label: string;
  readonly description: string;
};

/// The flow scenarios the drawer offers, asserted against `spec/scenarios.json` by a unit test.
export const smileIDSampleScenarios: readonly UseSmileIDSampleScenarioEntry[] = [
  { id: 'normal', label: 'Normal', description: 'Happy path with valid sandbox credentials.' },
  {
    id: 'expiredToken',
    label: 'Expired token',
    description: 'Token is valid but expired, so the SDK must refresh before it can submit.',
  },
  {
    id: 'badRefresh',
    label: 'Refresh fails',
    description: 'Refresh returns an unusable token, so the failure path must surface.',
  },
  {
    id: 'noCallback',
    label: 'No result callback',
    description: 'Host provides no result callback; the SDK must not crash or hang.',
  },
  {
    id: 'throwingCallback',
    label: 'Throwing callback',
    description: 'Host callback throws; it must not corrupt SDK state.',
  },
  {
    id: 'offlineRetry',
    label: 'Offline then retry',
    description: 'Submission starts with no connectivity, then it returns.',
  },
] as const;

/// Theme scenarios apply on top of any flow scenario, through the SDK's public theme override.
export const smileIDSampleThemeScenarios: readonly UseSmileIDSampleScenarioEntry[] = [
  {
    id: 'brandDefault',
    label: 'Brand default',
    description: 'Ship state: Smile ID branding, light or dark per the Settings switch.',
  },
  {
    id: 'clashingHost',
    label: 'Clashing host',
    description: 'A deliberately distant host theme, to expose host-versus-SDK collisions.',
  },
  {
    id: 'partnerOverride',
    label: 'Partner override',
    description: 'A plausible partner palette through the same public override.',
  },
] as const;

/// The SDK flow is one route with two presentations; same destination, different container.
export const smileIDSampleFlowRoutes = ['fullscreen', 'shell'] as const;

export type UseSmileIDSampleFlowRoute = (typeof smileIDSampleFlowRoutes)[number];
