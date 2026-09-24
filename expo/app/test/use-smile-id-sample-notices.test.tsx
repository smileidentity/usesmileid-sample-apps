import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  UseSmileIDSampleStatus,
  UseSmileIDSampleThemeProvider,
  smileIDSampleProducts,
  smileIDSampleRefreshLabel,
  useSmileIDSampleJobStore,
  useSmileIDSampleProfileStore,
  useSmileIDSampleResultStore,
} from '@smileid/sample-ui';
import { act, fireEvent, render, waitFor } from '@testing-library/react-native';
import * as Clipboard from 'expo-clipboard';
import type { ReactElement } from 'react';
import { StyleSheet } from 'react-native';

import VerificationDetails from '../app/(tabs)/verifications/[jobId]';
import Profiles from '../app/profiles/index';

/// A three-button nav bar's height.
const BOTTOM_INSET = 48;

jest.mock('react-native-safe-area-context', () => ({
  useSafeAreaInsets: () => ({ top: 24, bottom: 48, left: 0, right: 0 }),
}));
const mockRouter = { back: jest.fn(), replace: jest.fn(), push: jest.fn(), canGoBack: () => true };
jest.mock('expo-router', () => ({
  useRouter: () => mockRouter,
  useLocalSearchParams: () => ({ jobId: 'job_notice' }),
}));

jest.mock('expo-clipboard', () => ({ setStringAsync: jest.fn(async () => true) }));

const inTheme = async (element: ReactElement) =>
  await render(<UseSmileIDSampleThemeProvider dark={false}>{element}</UseSmileIDSampleThemeProvider>);

/// The notice host is the only absolutely positioned view.
const noticeBottom = (screen: Awaited<ReturnType<typeof inTheme>>, message: string): number | undefined => {
  let node = screen.getByText(message).parent;
  while (node !== null) {
    const style = StyleSheet.flatten(node.props.style) as { position?: string; bottom?: number } | undefined;
    if (style?.position === 'absolute') return style.bottom;
    node = node.parent;
  }
  return undefined;
};

beforeEach(async () => {
  await AsyncStorage.clear();
  useSmileIDSampleJobStore.getState().reset();
});

describe('a notice on a screen with no nav bar', () => {
  it('sits past the system bar the route is drawn under, plus one gap, on verification details', async () => {
    await useSmileIDSampleJobStore.getState().load();
    await useSmileIDSampleJobStore.getState().add({
      id: 'job_notice',
      userId: 'user_1',
      product: smileIDSampleProducts[0]!,
      status: UseSmileIDSampleStatus.Clear,
      createdAtMillis: Date.now(),
      message: 'Job completed',
      httpStatus: 200,
      sandbox: true,
      sessionId: null,
      partnerId: null,
    });
    const screen = await inTheme(<VerificationDetails />);
    const scroll = screen.getByTestId('sample_verification_details_screen');
    await act(async () => {
      scroll.props.refreshControl.props.onRefresh();
    });
    const message = 'Not submitted under a scanned token';
    await waitFor(() => expect(screen.queryByText(message)).not.toBeNull());
    expect(noticeBottom(screen, message)).toBe(BOTTOM_INSET + 16);
  });

  it('copies the full job id, not the shortened label, on verification details', async () => {
    await useSmileIDSampleJobStore.getState().load();
    await useSmileIDSampleJobStore.getState().add({
      id: 'job_notice',
      userId: 'user_1',
      product: smileIDSampleProducts[0]!,
      status: UseSmileIDSampleStatus.Clear,
      createdAtMillis: Date.now(),
      message: 'Job completed',
      httpStatus: 200,
      sandbox: true,
      sessionId: null,
      partnerId: null,
    });
    const screen = await inTheme(<VerificationDetails />);
    await act(async () => {
      fireEvent.press(screen.getByTestId('sample_detail_copy_jobId'));
    });
    expect(Clipboard.setStringAsync).toHaveBeenCalledWith('job_notice');
  });

  it('shows the last run on verification details, even for a job never stored', async () => {
    await useSmileIDSampleJobStore.getState().load();
    useSmileIDSampleResultStore.getState().reset();
    useSmileIDSampleResultStore.getState().record('cancelled');
    const screen = await inTheme(<VerificationDetails />);
    expect(screen.getByTestId('sample_details_empty')).toBeTruthy();
    expect(screen.getByTestId('sample_result_result_count').props.children).toBe('1');
  });

  it('loads the store itself on a cold link, so a stored job is found without the list', async () => {
    await useSmileIDSampleJobStore.getState().load();
    await useSmileIDSampleJobStore.getState().add({
      id: 'job_notice',
      userId: 'user_1',
      product: smileIDSampleProducts[0]!,
      status: UseSmileIDSampleStatus.Clear,
      createdAtMillis: Date.now(),
      message: 'Job completed',
      httpStatus: 200,
      sandbox: true,
      sessionId: null,
      partnerId: null,
    });
    useSmileIDSampleJobStore.getState().reset();
    const screen = await inTheme(<VerificationDetails />);
    await waitFor(() => expect(screen.queryByText('Job completed')).not.toBeNull());
  });

  it('sits past the system bar on the profiles list too', async () => {
    useSmileIDSampleProfileStore.getState().add('Kobo Bank', 'Ada Okafor');
    const screen = await inTheme(<Profiles />);
    await waitFor(() => expect(screen.queryByText('Kobo Bank created')).not.toBeNull());
    expect(noticeBottom(screen, 'Kobo Bank created')).toBe(BOTTOM_INSET + 16);
  });
});

describe('what a refresh says', () => {
  it('uses the words the other three apps use', () => {
    expect(
      smileIDSampleRefreshLabel({ kind: 'updated', status: UseSmileIDSampleStatus.Clear, message: 'Job completed', httpCode: 200 }),
    ).toBe('Clear — Job completed');
    expect(smileIDSampleRefreshLabel({ kind: 'stillProcessing' })).toBe('Still processing');
    expect(smileIDSampleRefreshLabel({ kind: 'noSession' })).toBe('Scan a token first');
    expect(smileIDSampleRefreshLabel({ kind: 'noServerJob' })).toBe('Not submitted under a scanned token');
    expect(smileIDSampleRefreshLabel({ kind: 'partnerMismatch' })).toBe('Submitted by a different partner');
    expect(smileIDSampleRefreshLabel({ kind: 'failed', reason: 'HTTP 401' })).toBe('Could not check status: HTTP 401');
  });
});
