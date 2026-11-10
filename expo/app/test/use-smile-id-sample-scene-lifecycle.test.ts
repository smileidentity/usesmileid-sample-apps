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

/// The scene manifest Expo 58's prebuild already writes.
const templateSceneManifest = {
  UIApplicationSupportsMultipleScenes: false,
  UISceneConfigurations: {
    UIWindowSceneSessionRoleApplication: [
      {
        UISceneConfigurationName: 'Default Configuration',
        UISceneDelegateClassName: '$(PRODUCT_MODULE_NAME).SceneDelegate',
      },
    ],
  },
};

/// Expo 58's prebuild AppDelegate, which already hands the factory to its scene delegate.
const sceneAppDelegate = `@main
class AppDelegate: ExpoAppDelegate, ExpoReactNativeFactoryProvider {
  var window: UIWindow?
  var reactNativeFactory: RCTReactNativeFactory?

  public override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    reactNativeFactory = factory
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

  it('keeps the scene delegate the template already declares', async () => {
    const { modResults } = await iosMod('infoPlist')({
      modResults: { UIApplicationSceneManifest: templateSceneManifest },
      modRequest: {},
    });

    expect(modResults).toEqual({ UIApplicationSceneManifest: templateSceneManifest });
  });

  it('leaves an AppDelegate that already provides the factory unchanged', async () => {
    const { modResults } = await iosMod('appDelegate')({
      modResults: { contents: sceneAppDelegate, language: 'swift' },
      modRequest: {},
    });

    expect((modResults as { contents: string }).contents).toBe(sceneAppDelegate);
  });

  it('fails the prebuild when the template no longer matches', async () => {
    const drifted = { contents: '@main\nclass AppDelegate {}\n', language: 'swift' };

    await expect(iosMod('appDelegate')({ modResults: drifted, modRequest: {} })).rejects.toThrow(
      'The AppDelegate template changed',
    );
  });
});
