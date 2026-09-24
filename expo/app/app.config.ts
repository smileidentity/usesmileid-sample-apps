import type { ExpoConfig } from 'expo/config';
import { withAppDelegate, withInfoPlist, type ConfigPlugin } from 'expo/config-plugins';

import identity from '../../spec/app-identity.json';

/// The expo entry of spec/app-identity.json, which owns every id and scheme this shell may claim.
const expoIdentity = identity.apps.find((app) => app.platform === 'expo');

if (!expoIdentity) {
  throw new Error('spec/app-identity.json carries no expo app entry to build an identity from.');
}

const { applicationId, bundleIdentifier, displayName, urlScheme } = expoIdentity;

if (!applicationId || !bundleIdentifier || !displayName || !urlScheme) {
  throw new Error(`spec/app-identity.json expo entry is missing an id, a display name or a scheme.`);
}

/// Capture is the SDK's, but no @smileid package ships a purpose string, so the host declares it.
const cameraUsage = 'Smile ID uses the camera to scan a session QR code and to capture your selfie and your ID document.';

const templateWindow = /\n#if os\(iOS\) \|\| os\(tvOS\)\n\s*window = UIWindow\(frame: UIScreen\.main\.bounds\)\n\s*factory\.startReactNative\([^)]*\)\n#endif\n/;

const templateClass = 'class AppDelegate: ExpoAppDelegate {';

/// iOS 27 stops an app built on its SDK at launch unless it adopts scenes, so Expo's delegate starts React Native.
const withSceneLifecycle: ConfigPlugin = (base) =>
  withAppDelegate(
    withInfoPlist(base, (plist) => {
      plist.modResults.UIApplicationSceneManifest = {
        UIApplicationSupportsMultipleScenes: false,
        UISceneConfigurations: {
          UIWindowSceneSessionRoleApplication: [
            {
              UISceneConfigurationName: 'Default Configuration',
              UISceneDelegateClassName: 'EXExpoAppSceneDelegate',
            },
          ],
        },
      };
      return plist;
    }),
    (delegate) => {
      const source = delegate.modResults.contents;
      if (!templateWindow.test(source) || !source.includes(templateClass)) {
        throw new Error('The AppDelegate template changed; update withSceneLifecycle.');
      }
      delegate.modResults.contents = source
        .replace(templateWindow, '\n')
        .replace(templateClass, 'class AppDelegate: ExpoAppDelegate, ExpoReactNativeFactoryProvider {');
      return delegate;
    },
  );

const config: ExpoConfig = {
  name: displayName,
  slug: 'usesmileid-sample-expo',
  version: '1.0.0',
  scheme: urlScheme,
  orientation: 'portrait',
  userInterfaceStyle: 'automatic',
  android: {
    package: applicationId,
    permissions: ['android.permission.CAMERA'],
  },
  ios: {
    bundleIdentifier,
    supportsTablet: false,
    infoPlist: {
      NSCameraUsageDescription: cameraUsage,
      NSPhotoLibraryUsageDescription: 'Smile ID uses your photo library when you upload an ID document.',
      ITSAppUsesNonExemptEncryption: false,
    },
  },
  plugins: [
    'expo-router',
    'expo-status-bar',
    'expo-font',
    'react-native-quick-crypto',
    // QR only, so neither platform asks for the microphone.
    ['expo-camera', { cameraPermission: cameraUsage, microphonePermission: false, recordAudioAndroid: false }],
    // kspVersion is deliberately not passed: the plugin rejects it without kotlinVersion, and its
    // own Kotlin default is what the published AARs were compiled against.
    '@smileid/usesmileid_mlkit_face',
    '@smileid/usesmileid_mlkit_document',
    '@smileid/usesmileid_vision_face',
    '@smileid/usesmileid_vision_document',
  ],
  experiments: {
    typedRoutes: true,
  },
};

export default withSceneLifecycle(config);
