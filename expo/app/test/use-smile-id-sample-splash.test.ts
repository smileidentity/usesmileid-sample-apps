import type { ExpoConfig } from 'expo/config';
import { smileDarkColors, smileLightColors } from '@smileid/sample-ui';

import config, { splashBackground } from '../app.config';

/// The splash colours are copies the config loader forces; this holds them to the generated tokens.
describe('the splash', () => {
  it('paints the page background of each scheme', () => {
    expect(splashBackground).toEqual({ light: smileLightColors.background, dark: smileDarkColors.background });
  });

  it('shows only the background, through the splash plugin', () => {
    const plugin = (config as ExpoConfig).plugins?.find(
      (entry) => Array.isArray(entry) && entry[0] === 'expo-splash-screen',
    );
    expect(plugin).toEqual([
      'expo-splash-screen',
      {
        image: './assets/splash-transparent.png',
        backgroundColor: splashBackground.light,
        dark: { backgroundColor: splashBackground.dark },
      },
    ]);
  });
});
