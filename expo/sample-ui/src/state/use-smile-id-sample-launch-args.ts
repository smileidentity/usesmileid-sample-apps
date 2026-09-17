import {
  smileIDSampleFlowRoutes,
  smileIDSampleScenarios,
  smileIDSampleThemeScenarios,
  type UseSmileIDSampleFlowRoute,
} from '../model/use-smile-id-sample-scenario';
import { smileIDSampleProductFrom } from '../model/use-smile-id-sample-product';

const HOLD_CAMERA_KEEP = 'keep';

/// How long the host holds the camera before handing off, so the SDK meets a contended device.
export type UseSmileIDSampleHoldCamera = { kind: 'keep' } | { kind: 'millis'; value: number };

/// The canonical arguments from `spec/launch-args.json`; reading the cold-start URL is the shell's job.
export type UseSmileIDSampleLaunchArgs = {
  readonly scenario: string;
  readonly theme: string;
  readonly route: UseSmileIDSampleFlowRoute;
  readonly autostart: string | null;
  /// Automation precondition only — see `spec/launch-args.json`.
  readonly seedJobs: boolean;
  /// The design's three profiles instead of the one empty starter; in memory, so per launch.
  readonly seedProfiles: boolean;
  /// Reveals the result card on a release build. Always on in debug, so only a release run needs it.
  readonly probes: boolean;
  readonly appLocale: string | null;
  readonly holdCamera: UseSmileIDSampleHoldCamera | null;
  /// Seconds a transient notice stays — see `spec/launch-args.json`. Automation only.
  readonly noticeWindow: number | null;
};

/// The ten argument names, which the spec test compares against `spec/launch-args.json`.
export const UseSmileIDSampleLaunchArgNames = [
  'scenario',
  'theme',
  'route',
  'autostart',
  'seedJobs',
  'seedProfiles',
  'probes',
  'appLocale',
  'holdCamera',
  'noticeWindow',
] as const;

export const smileIDSampleLaunchArgDefaults: UseSmileIDSampleLaunchArgs = {
  scenario: 'normal',
  theme: 'brandDefault',
  route: 'fullscreen',
  autostart: null,
  seedJobs: false,
  seedProfiles: false,
  probes: false,
  appLocale: null,
  holdCamera: null,
  noticeWindow: null,
};

type RawArgs = Readonly<Record<string, string | boolean | null | undefined>>;

const text = (raw: RawArgs, name: string): string | null => {
  const value = raw[name];
  if (value === null || value === undefined) return null;
  const trimmed = String(value).trim();
  return trimmed.length > 0 ? trimmed : null;
};

const flag = (raw: RawArgs, name: string): boolean | null => {
  const value = raw[name];
  if (typeof value === 'boolean') return value;
  const trimmed = text(raw, name)?.toLowerCase();
  if (trimmed === 'true') return true;
  if (trimmed === 'false') return false;
  return null;
};

/// Positive seconds; anything else falls back to the product's own window.
const noticeWindow = (raw: RawArgs): number | null => {
  const value = Number.parseInt(text(raw, 'noticeWindow') ?? '', 10);
  return Number.isInteger(value) && value > 0 ? value : null;
};

const holdCamera = (raw: RawArgs): UseSmileIDSampleHoldCamera | null => {
  const value = text(raw, 'holdCamera');
  if (value === null) return null;
  if (value.toLowerCase() === HOLD_CAMERA_KEEP) return { kind: 'keep' };
  const millis = Number.parseInt(value, 10);
  return Number.isInteger(millis) && millis > 0 ? { kind: 'millis', value: millis } : null;
};

/// An unrecognised value falls back to its default, which is safe only because the result card reports it.
export const smileIDSampleLaunchArgsFrom = (raw: RawArgs): UseSmileIDSampleLaunchArgs => {
  const defaults = smileIDSampleLaunchArgDefaults;
  const scenario = smileIDSampleScenarios.find((s) => s.id === text(raw, 'scenario'));
  const theme = smileIDSampleThemeScenarios.find((s) => s.id === text(raw, 'theme'));
  const route = smileIDSampleFlowRoutes.find((r) => r === text(raw, 'route'));

  return {
    scenario: scenario?.id ?? defaults.scenario,
    theme: theme?.id ?? defaults.theme,
    route: route ?? defaults.route,
    autostart: smileIDSampleProductFrom(text(raw, 'autostart'))?.id ?? null,
    seedJobs: flag(raw, 'seedJobs') ?? defaults.seedJobs,
    seedProfiles: flag(raw, 'seedProfiles') ?? defaults.seedProfiles,
    probes: flag(raw, 'probes') ?? defaults.probes,
    appLocale: text(raw, 'appLocale'),
    holdCamera: holdCamera(raw),
    noticeWindow: noticeWindow(raw),
  };
};

/// Reads the arguments out of a cold-start URL, which is this platform's mechanism per `spec/launch-args.json`.
export const smileIDSampleLaunchArgsFromUrl = (url: string | null): UseSmileIDSampleLaunchArgs => {
  if (!url) return smileIDSampleLaunchArgDefaults;
  // The fragment has to go before the split, or it lands inside the last value and that argument
  // parses as garbage and silently falls back to its default.
  const beforeFragment = url.split('#')[0] ?? '';
  const query = beforeFragment.includes('?')
    ? beforeFragment.slice(beforeFragment.indexOf('?') + 1)
    : '';
  const params = new URLSearchParams(query);
  const raw: Record<string, string> = {};
  for (const name of UseSmileIDSampleLaunchArgNames) {
    const value = params.get(name);
    if (value !== null) raw[name] = value;
  }
  return smileIDSampleLaunchArgsFrom(raw);
};
