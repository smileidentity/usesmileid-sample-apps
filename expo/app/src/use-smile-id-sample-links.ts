import type { UseSmileIDSampleNavRow } from '@smileid/sample-ui';
import * as WebBrowser from 'expo-web-browser';
import { Linking } from 'react-native';

/// Opens a settings row's destination the way that destination can actually be rendered.
export const openNavRow = async (row: UseSmileIDSampleNavRow, toolbarColor: string): Promise<void> => {
  if (row.url === undefined) return;
  try {
    if (!row.opensInApp) {
      // Both legal pages serve their document as an embedded PDF, which an in-app browser shows as a
      // stub with an Open button rather than the document — so they eject rather than look broken.
      await Linking.openURL(row.url);
      return;
    }
    // Never a WebView: the page would lose the reader's session, autofill and password manager, and
    // this is code partners copy.
    await WebBrowser.openBrowserAsync(row.url, { toolbarColor });
  } catch (error) {
    // A device with no browser, or a scheme nothing claims, rejects here. Swallowed rather than
    // rethrown into a discarded promise, which a release build turns into a crash the reader cannot act on.
    console.warn(`could not open ${row.url}`, error);
  }
};
