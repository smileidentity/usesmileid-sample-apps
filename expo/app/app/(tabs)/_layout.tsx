import { smileIDSampleNavItems } from '@smileid/sample-ui';
import { Tabs } from 'expo-router/tabs';

import { UseSmileIDSampleNavBarHost } from '../../src/use-smile-id-sample-nav-bar-host';

/// The three tab destinations of spec/routes.json, drawn by the design's floating pill.
export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{ headerShown: false }}
      tabBar={(props) => <UseSmileIDSampleNavBarHost {...props} />}
    >
      {smileIDSampleNavItems.map((item) => (
        <Tabs.Screen key={item.id} name={item.id} options={{ title: item.label }} />
      ))}
      {/* Routable but not a tab: a pushed screen has no nav bar even inside a tab's own graph. */}
      <Tabs.Screen name="settings/licenses" options={{ href: null }} />
      <Tabs.Screen name="verifications/[jobId]" options={{ href: null }} />
    </Tabs>
  );
}
