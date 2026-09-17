import { Stack } from 'expo-router';

/// The list owns the new-profile sheet and the created confirmation, so a link to the sheet lands on it too.
export const unstable_settings = { initialRouteName: 'index' };

/// The profiles list, one profile's configuration, and the sheet that layers over the list.
export default function ProfilesLayout() {
  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="index" />
      <Stack.Screen name="[profileId]" />
      {/* Transparent, so the list and its confirmation stay behind the sheet rather than being replaced. */}
      <Stack.Screen
        name="new"
        options={{
          presentation: 'transparentModal',
          animation: 'none',
          contentStyle: { backgroundColor: 'transparent' },
        }}
      />
    </Stack>
  );
}
