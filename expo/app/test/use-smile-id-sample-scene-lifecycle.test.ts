import type { ExpoConfig } from 'expo/config';

import config from '../app.config';

/// The lines of Expo 57's prebuild AppDelegate, which starts React Native in a window of its own.
const legacyAppDelegate = `@main
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

/// The scene manifest Expo 58's prebuild writes.
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

/// The AppDelegate Expo 58.0.23's prebuild writes, verbatim.
const templateAppDelegate = `internal import Expo
import React
import ReactAppDependencyProvider

@main
class AppDelegate: ExpoAppDelegate, ExpoReactNativeFactoryProvider {
  var window: UIWindow?

  var reactNativeDelegate: ExpoReactNativeFactoryDelegate?
  var reactNativeFactory: RCTReactNativeFactory?

  public override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    let delegate = ReactNativeDelegate()
    let factory = ExpoReactNativeFactory(delegate: delegate)
    delegate.dependencyProvider = RCTAppDependencyProvider()

    reactNativeDelegate = delegate
    reactNativeFactory = factory

    // The window is created and React Native is started by \`SceneDelegate\` under the
    // scene-based life cycle (required by the iOS 27 SDK).
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

class ReactNativeDelegate: ExpoReactNativeFactoryDelegate {
  // Extension point for config-plugins

  override func sourceURL(for bridge: RCTBridge) -> URL? {
    // needed to return the correct URL for expo-dev-client.
    bridge.bundleURL ?? bundleURL()
  }

  override func bundleURL() -> URL? {
#if DEBUG
    return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: ".expo/.virtual-metro-entry")
#else
    return Bundle.main.url(forResource: "main", withExtension: "jsbundle")
#endif
  }
}
`;

type Mod = (input: { modResults: unknown; modRequest: object }) => Promise<{ modResults: unknown }>;

const iosMod = (name: string): Mod => {
  const mod = (config as ExpoConfig & { mods?: { ios?: Record<string, Mod> } }).mods?.ios?.[name];
  if (!mod) throw new Error(`app.config registers no ios.${name} mod`);
  return mod;
};

const appDelegate = (contents: string) => iosMod('appDelegate')({ modResults: { contents, language: 'swift' }, modRequest: {} });

describe('scene lifecycle check', () => {
  it("accepts the scene manifest Expo 58's template declares", async () => {
    const { modResults } = await iosMod('infoPlist')({
      modResults: { UIApplicationSceneManifest: templateSceneManifest },
      modRequest: {},
    });

    expect(modResults).toEqual({ UIApplicationSceneManifest: templateSceneManifest });
  });

  it('fails the prebuild when the Info.plist declares no scene delegate', async () => {
    await expect(iosMod('infoPlist')({ modResults: {}, modRequest: {} })).rejects.toThrow('declares no scene delegate');
  });

  it("accepts Expo 58's AppDelegate unchanged", async () => {
    const { modResults } = await appDelegate(templateAppDelegate);

    expect((modResults as { contents: string }).contents).toBe(templateAppDelegate);
  });

  it('fails the prebuild when the AppDelegate starts React Native in a window of its own', async () => {
    await expect(appDelegate(legacyAppDelegate)).rejects.toThrow('starts React Native itself');
  });

  it('fails the prebuild when an AppDelegate provides the factory but still starts React Native', async () => {
    const halfAdopted = legacyAppDelegate.replace(
      'class AppDelegate: ExpoAppDelegate {',
      'class AppDelegate: ExpoAppDelegate, ExpoReactNativeFactoryProvider {',
    );

    await expect(appDelegate(halfAdopted)).rejects.toThrow('starts React Native itself');
  });
});
