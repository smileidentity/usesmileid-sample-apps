import {
  UseSmileIDSampleLaunchArgNames,
  smileIDSampleLaunchArgDefaults,
  smileIDSampleLaunchArgsFrom,
  smileIDSampleLaunchArgsFromUrl,
} from '../src/state/use-smile-id-sample-launch-args';
import { spec } from './spec-file';

type LaunchArgs = { args: { name: string; default: unknown }[] };

const launchArgsSpec = spec<LaunchArgs>('launch-args.json');

describe('launch arguments match spec/launch-args.json', () => {
  it('declares every argument name the spec lists, in spec order', () => {
    expect([...UseSmileIDSampleLaunchArgNames]).toEqual(launchArgsSpec.args.map((arg) => arg.name));
  });

  it('defaults each argument to what the spec records', () => {
    const declared = smileIDSampleLaunchArgDefaults as unknown as Record<string, unknown>;
    for (const arg of launchArgsSpec.args) {
      const expected = arg.default === undefined ? null : arg.default;
      expect({ [arg.name]: declared[arg.name] }).toEqual({ [arg.name]: expected });
    }
  });
});

describe('a launch with no arguments', () => {
  it('shows no fixture data', () => {
    const args = smileIDSampleLaunchArgsFrom({});
    expect(args.seedProfiles).toBe(false);
    expect(args.seedJobs).toBe(false);
  });

  it('hides the probe affordances until a release run asks for them', () => {
    expect(smileIDSampleLaunchArgsFrom({}).probes).toBe(false);
  });

  it('reads the defaults from a cold start with no link at all', () => {
    expect(smileIDSampleLaunchArgsFromUrl(null)).toEqual(smileIDSampleLaunchArgDefaults);
  });
});

describe('an unrecognised value', () => {
  it('falls back to the argument default rather than failing the launch', () => {
    const args = smileIDSampleLaunchArgsFrom({ scenario: 'nope', theme: 'nope', route: 'nope' });
    expect([args.scenario, args.theme, args.route]).toEqual(['normal', 'brandDefault', 'fullscreen']);
  });

  it('leaves autostart on the home screen rather than guessing a product', () => {
    expect(smileIDSampleLaunchArgsFrom({ autostart: 'bvn' }).autostart).toBeNull();
  });
});

describe('the cold-start URL', () => {
  const url = 'usesmileid-sample-expo://flow/biometricKyc/run?scenario=expiredToken&route=shell&seedProfiles=true';

  it('parses the arguments the link carries', () => {
    const args = smileIDSampleLaunchArgsFromUrl(url);
    expect([args.scenario, args.route, args.seedProfiles]).toEqual(['expiredToken', 'shell', true]);
  });

  it('reads a boolean written as a string, which is the only form a link can carry', () => {
    expect(smileIDSampleLaunchArgsFromUrl('app://x?probes=true').probes).toBe(true);
    expect(smileIDSampleLaunchArgsFromUrl('app://x?probes=false').probes).toBe(false);
  });

  it('takes holdCamera as milliseconds or as keep, and rejects anything else', () => {
    expect(smileIDSampleLaunchArgsFromUrl('app://x?holdCamera=keep').holdCamera).toEqual({ kind: 'keep' });
    expect(smileIDSampleLaunchArgsFromUrl('app://x?holdCamera=250').holdCamera).toEqual({
      kind: 'millis',
      value: 250,
    });
    expect(smileIDSampleLaunchArgsFromUrl('app://x?holdCamera=0').holdCamera).toBeNull();
  });

  it('takes noticeWindow only as positive seconds', () => {
    expect(smileIDSampleLaunchArgsFromUrl('app://x?noticeWindow=60').noticeWindow).toBe(60);
    expect(smileIDSampleLaunchArgsFromUrl('app://x?noticeWindow=-1').noticeWindow).toBeNull();
  });

  it('ignores a link that names no arguments', () => {
    expect(smileIDSampleLaunchArgsFromUrl('usesmileid-sample-expo://products')).toEqual(
      smileIDSampleLaunchArgDefaults,
    );
  });
});
