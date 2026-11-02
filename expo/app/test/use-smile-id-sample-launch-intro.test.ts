import { smileIDSamplePlaysLaunchIntro } from '../src/use-smile-id-sample-launch-intro';

describe('when a launch plays the intro', () => {
  it('plays on a launch from the icon', () => {
    expect(smileIDSamplePlaysLaunchIntro({ launchUrl: null, reduceMotion: false })).toBe(true);
  });

  it('lands a link on its destination without it', () => {
    expect(
      smileIDSamplePlaysLaunchIntro({ launchUrl: 'usesmileid-sample-expo://settings', reduceMotion: false }),
    ).toBe(false);
  });

  it('skips it for a launch argument, which rides a link', () => {
    expect(
      smileIDSamplePlaysLaunchIntro({ launchUrl: 'usesmileid-sample-expo://run?probes=true', reduceMotion: false }),
    ).toBe(false);
  });

  it('skips it when Reduce Motion is on', () => {
    expect(smileIDSamplePlaysLaunchIntro({ launchUrl: null, reduceMotion: true })).toBe(false);
  });
});
