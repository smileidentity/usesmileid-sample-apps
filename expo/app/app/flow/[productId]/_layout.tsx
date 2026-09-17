import { Stack } from 'expo-router';

/// The Consent Details Form is the wizard's first step, so a link deeper still lands on it (routes.json R12).
export const unstable_settings = { initialRouteName: 'details' };

/// The pre-flow wizard, whose steps run product → details → id-details → the SDK flow.
export default function FlowLayout() {
  return <Stack screenOptions={{ headerShown: false }} />;
}
