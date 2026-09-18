import { UseSmileIDSampleNavBar, smileIDSampleNavItems } from '@smileid/sample-ui';
import { useRouter } from 'expo-router';
import {
  BottomTabBarHeightCallbackContext,
  Tabs,
  type BottomTabBarProps,
} from 'expo-router/tabs';
import { use } from 'react';
import { StyleSheet, View } from 'react-native';

/// The three tab destinations of spec/routes.json, drawn by the design's floating pill.
export default function TabsLayout() {
  return (
    <Tabs screenOptions={{ headerShown: false }} tabBar={(props) => <FloatingNavBar {...props} />}>
      {smileIDSampleNavItems.map((item) => (
        <Tabs.Screen key={item.id} name={item.id} options={{ title: item.label }} />
      ))}
      {/* Routable but not a tab: a pushed screen has no nav bar even inside a tab's own graph. */}
      <Tabs.Screen name="settings/licenses" options={{ href: null }} />
      <Tabs.Screen name="verifications/[jobId]" options={{ href: null }} />
    </Tabs>
  );
}

/// The pill, floated over the screens and publishing its laid-out height the way the stock bar does.
const FloatingNavBar = ({ state, navigation }: BottomTabBarProps) => {
  const router = useRouter();
  const onHeightChange = use(BottomTabBarHeightCallbackContext);
  const selected = state.routes[state.index];
  // The design draws no bar on a pushed screen, even one inside a tab's graph; empty, it publishes 0.
  const onTabRoot = smileIDSampleNavItems.some((item) => item.id === selected?.name);

  return (
    <View
      // Absolute, or the bar is a column sibling that shortens the screens instead of floating over them.
      style={styles.bar}
      onLayout={(event) => onHeightChange?.(event.nativeEvent.layout.height)}
    >
      {onTabRoot ? (
        <UseSmileIDSampleNavBar
          selectedId={selected?.name ?? ''}
          onSelect={(item) => {
            const route = state.routes.find((candidate) => candidate.name === item.id);
            if (!route) return;
            // The stock bar's own sequence: a listener that prevents the default must still win.
            const event = navigation.emit({
              type: 'tabPress',
              target: route.key,
              canPreventDefault: true,
            });
            if (route.key !== selected?.key && !event.defaultPrevented) {
              navigation.navigate(route.name);
            }
          }}
          onTokenPress={() => router.push('/token/scan')}
        />
      ) : null}
    </View>
  );
};

const styles = StyleSheet.create({
  bar: { bottom: 0, left: 0, position: 'absolute', right: 0 },
});
