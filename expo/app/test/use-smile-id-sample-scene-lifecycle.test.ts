import type { ExpoConfig } from 'expo/config';

import config from '../app.config';

/// The lines of Expo 57's prebuild AppDelegate the plugin rewrites.
const templateAppDelegate = `@main
class AppDelegate: ExpoAppDelegate {
  var window: UIWindow?
  var reactNativeFactory: RCTReactNativeFactory?

  public override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    reactNativeFactory = factory

#if os(iOS) || os(tvOS)
    window = UIWindow(frame: UIScreen.main.bounds)
    factory.startReactNative(
      withModuleName: "main",
      in: window,
      launchOptions: launchOptions)
#endif

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
`;

type Mod = (input: { modResults: unknown; modRequest: object }) => Promise<{ modResults: unknown }>;

const iosMod = (name: string): Mod => {
  const mod = (config as ExpoConfig & { mods?: { ios?: Record<string, Mod> } }).mods?.ios?.[name];
  if (!mod) throw new Error(`app.config registers no ios.${name} mod`);
  return mod;
};

describe('scene lifecycle plugin', () => {
  it('declares Expo scene delegate as the only window scene', async () => {
    const { modResults } = await iosMod('infoPlist')({ modResults: {}, modRequest: {} });

    expect(modResults).toMatchObject({
      UIApplicationSceneManifest: {
        UIApplicationSupportsMultipleScenes: false,
        UISceneConfigurations: {
          UIWindowSceneSessionRoleApplication: [
            { UISceneDelegateClassName: 'EXExpoAppSceneDelegate' },
          ],
        },
      },
    });
  });

  it('hands the factory to the scene delegate instead of starting its own window', async () => {
    const { modResults } = await iosMod('appDelegate')({
      modResults: { contents: templateAppDelegate, language: 'swift' },
      modRequest: {},
    });
    const contents = (modResults as { contents: string }).contents;

    expect(contents).toContain(
      'class AppDelegate: ExpoAppDelegate, ExpoReactNativeFactoryProvider {',
    );
    expect(contents).not.toContain('UIWindow(frame:');
    expect(contents).not.toContain('startReactNative');
  });

  it('fails the prebuild when the template no longer matches', async () => {
    const drifted = { contents: '@main\nclass AppDelegate {}\n', language: 'swift' };

    await expect(iosMod('appDelegate')({ modResults: drifted, modRequest: {} })).rejects.toThrow(
      'The AppDelegate template changed',
    );
  });
});
