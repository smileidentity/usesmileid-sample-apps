/// How long a simulated scan's token lasts; Ended reaches the expiry gate without waiting.
export type UseSmileIDSampleSimulatedSpan = {
  readonly id: 'fifteenMinutes' | 'oneHour' | 'eightHours' | 'ended';
  readonly label: string;
  readonly spanMillis: number;
  readonly ended: boolean;
};

const MINUTE = 60_000;

export const smileIDSampleSimulatedSpans: readonly UseSmileIDSampleSimulatedSpan[] = [
  { id: 'fifteenMinutes', label: '15m', spanMillis: 15 * MINUTE, ended: false },
  { id: 'oneHour', label: '1h', spanMillis: 60 * MINUTE, ended: false },
  { id: 'eightHours', label: '8h', spanMillis: 480 * MINUTE, ended: false },
  { id: 'ended', label: 'Expired', spanMillis: 15 * MINUTE, ended: true },
];

/// What a simulated scan's token binds; both off by default.
export type UseSmileIDSampleSimulatedBindings = {
  readonly consent: boolean;
  readonly userDetails: boolean;
};

export const smileIDSampleSimulatedBindingsDefaults: UseSmileIDSampleSimulatedBindings = {
  consent: false,
  userDetails: false,
};
