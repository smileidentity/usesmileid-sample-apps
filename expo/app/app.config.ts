import type { ExpoConfig } from 'expo/config';

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
const cameraUsage = 'Smile ID uses the camera to capture your selfie and your ID document.';

const config: ExpoConfig = {
  name: displayName,
  slug: 'usesmileid-sample-expo',
  version: '0.0.0',
  scheme: urlScheme,
  orientation: 'portrait',
  userInterfaceStyle: 'automatic',
  newArchEnabled: true,
  android: {
    package: applicationId,
    permissions: ['android.permission.CAMERA'],
    edgeToEdgeEnabled: true,
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

export default config;
