import { LaunchIntroScreen, SMILE_ID_SAMPLE_LAUNCH_INTRO_FADE_MS } from '@smileid/sample-ui';
import { StatusBar } from 'expo-status-bar';
import { useCallback, useEffect, useState } from 'react';
import { Animated, BackHandler, Linking, StyleSheet } from 'react-native';

/// Whether a launch plays the intro: one from the icon does; a link, which also carries every launch argument, or Reduce Motion goes straight in.
export const smileIDSamplePlaysLaunchIntro = ({
  launchUrl,
  reduceMotion,
}: {
  launchUrl: string | null;
  reduceMotion: boolean;
}): boolean => launchUrl === null && !reduceMotion;

/// Lays the intro over the app and fades it out; a link or back while it shows skips it, so the link lands at once. `plays` is read once, when it mounts.
export const UseSmileIDSampleLaunchIntroOverlay = ({ plays }: { plays: boolean }) => {
  const [showing, setShowing] = useState(plays);
  const [mounted, setMounted] = useState(plays);
  const [opacity] = useState(() => new Animated.Value(1));

  const dismiss = useCallback(() => setShowing(false), []);

  useEffect(() => {
    if (showing || !mounted) return undefined;
    const fade = Animated.timing(opacity, { toValue: 0, duration: SMILE_ID_SAMPLE_LAUNCH_INTRO_FADE_MS, useNativeDriver: true });
    fade.start(() => setMounted(false));
    return () => fade.stop();
  }, [showing, mounted, opacity]);

  useEffect(() => {
    if (!showing) return undefined;
    const link = Linking.addEventListener('url', dismiss);
    const back = BackHandler.addEventListener('hardwareBackPress', () => {
      dismiss();
      return true;
    });
    return () => {
      link.remove();
      back.remove();
    };
  }, [showing, dismiss]);

  if (!mounted) return null;
  return (
    <Animated.View
      style={[StyleSheet.absoluteFill, { opacity }]}
      pointerEvents={showing ? 'auto' : 'none'}
      accessibilityViewIsModal={showing}
    >
      {showing && <StatusBar style="light" />}
      <LaunchIntroScreen onFinished={dismiss} />
    </Animated.View>
  );
};
