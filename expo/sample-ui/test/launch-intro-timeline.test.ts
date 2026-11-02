import { LaunchIntroTimeline, launchIntroRest } from '../src/screens/launch-intro-screen';

describe('the launch intro timeline', () => {
  it('starts on an empty screen', () => {
    const pose = LaunchIntroTimeline.pose(0);

    expect(pose.markAlpha).toBe(0);
    expect(pose.wordmarkReveal).toBe(0);
  });

  it('has the logo unlocked, at its own size, once it has appeared', () => {
    const pose = LaunchIntroTimeline.pose(LaunchIntroTimeline.APPEARED);

    expect(pose.markAlpha).toBe(1);
    expect(pose.markScale).toBe(1);
    expect(pose.shackleLock).toBe(0);
  });

  it('shuts the lock while the name is still unrolling', () => {
    const pose = LaunchIntroTimeline.pose(LaunchIntroTimeline.LOCKED);

    expect(pose.shackleLock).toBe(1);
    expect(pose.shackleLift).toBe(0);
    expect(pose.wordmarkReveal).toBeGreaterThan(0);
    expect(pose.wordmarkReveal).toBeLessThan(1);
  });

  it('ends on the logo at rest, unlocked again', () => {
    expect(LaunchIntroTimeline.pose(1)).toEqual(launchIntroRest);
  });

  it('only ever lifts the shackle, never sinks it into the body', () => {
    const lifts = Array.from({ length: 1001 }, (_, step) => LaunchIntroTimeline.pose(step / 1000).shackleLift);

    expect(lifts.every((lift) => lift >= 0)).toBe(true);
  });

  it('clamps progress outside the timeline', () => {
    expect(LaunchIntroTimeline.pose(-1)).toEqual(LaunchIntroTimeline.pose(0));
    expect(LaunchIntroTimeline.pose(2)).toEqual(LaunchIntroTimeline.pose(1));
  });

  it('runs for as long as the other three apps', () => {
    expect(LaunchIntroTimeline.DURATION_MILLIS).toBe(2800);
  });
});
