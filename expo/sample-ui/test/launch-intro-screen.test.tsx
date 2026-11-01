import { LaunchIntroFrame, LaunchIntroTimeline } from '../src/screens/launch-intro-screen';
import { PINNED_FRAME, schemes } from './render-in-theme';
import { expectGoldens } from './paint/pixel-golden';

/// The intro stopped on its two named frames; it draws on the dark scheme whatever the app's, so both baselines match.
const states: Record<string, number> = {
  locked: LaunchIntroTimeline.LOCKED,
  logo: 1,
};

describe('launchIntro', () => {
  describe.each(schemes)('$name', ({ dark }) => {
    it.each(Object.keys(states))('%s', async (state) => {
      await expectGoldens(<LaunchIntroFrame progress={states[state]!} size={PINNED_FRAME} />, dark);
    });
  });
});
