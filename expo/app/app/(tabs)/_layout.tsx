import { UseSmileIDSampleTestIds, useSmileIDSampleTheme } from '@smileid/sample-ui';
import { Tabs } from 'expo-router';

/// The three tab destinations of spec/routes.json. The design's floating pill replaces this bar in U2.
export default function TabsLayout() {
  const theme = useSmileIDSampleTheme();

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: theme.colors.primary,
        tabBarInactiveTintColor: theme.colors.textMuted,
        tabBarStyle: {
          backgroundColor: theme.colors.navBar,
          borderTopColor: theme.colors.cardStroke,
        },
        tabBarLabelStyle: theme.type.tabFont,
      }}
    >
      <Tabs.Screen
        name="products"
        options={{ title: 'Products', tabBarButtonTestID: UseSmileIDSampleTestIds.NAV_PRODUCTS }}
      />
      <Tabs.Screen
        name="verifications"
        options={{
          title: 'Verifications',
          tabBarButtonTestID: UseSmileIDSampleTestIds.NAV_VERIFICATIONS,
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{ title: 'Settings', tabBarButtonTestID: UseSmileIDSampleTestIds.NAV_SETTINGS }}
      />
      {/* Routable but not a tab: a pushed screen has no nav bar even inside a tab's own graph. */}
      <Tabs.Screen name="settings/licenses" options={{ href: null }} />
      <Tabs.Screen name="verifications/[jobId]" options={{ href: null }} />
    </Tabs>
  );
}
