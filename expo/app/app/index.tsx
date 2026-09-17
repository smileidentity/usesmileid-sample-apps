import { Redirect } from 'expo-router';

/// Products is where every flow starts, so a cold launch with no path lands there.
export default function Index() {
  return <Redirect href="/products" />;
}
