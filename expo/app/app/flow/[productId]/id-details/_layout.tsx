import { Stack } from 'expo-router';

/// The form owns both pickers, so a link to one resolves to the form with the sheet over it (routes.json R12).
export const unstable_settings = { initialRouteName: 'index' };

/// The ID-details form and the two pickers that layer over it.
export default function IdDetailsLayout() {
  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="index" />
      {/* Transparent, so the form stays visible behind the sheet's own scrim rather than being replaced. */}
      <Stack.Screen name="country" options={SHEET_OPTIONS} />
      <Stack.Screen name="id-type" options={SHEET_OPTIONS} />
    </Stack>
  );
}

/// A sheet is a layer, so its route adds no presentation of its own.
const SHEET_OPTIONS = {
  presentation: 'transparentModal',
  animation: 'none',
  contentStyle: { backgroundColor: 'transparent' },
} as const;
