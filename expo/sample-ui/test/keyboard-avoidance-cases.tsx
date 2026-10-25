import { act, fireEvent } from '@testing-library/react-native';
import type { ReactElement } from 'react';
import { Keyboard, Platform, View, type KeyboardEvent } from 'react-native';

import { smileIDSampleIdDetailsDefaults } from '../src/state/use-smile-id-sample-id-details';
import { smileIDSampleUserDetailsDefaults } from '../src/state/use-smile-id-sample-profiles';
import { AuthUserIdScreen } from '../src/screens/auth-user-id-screen';
import { KycIdFormScreen } from '../src/screens/kyc-id-form-screen';
import { ProfileConfigScreen } from '../src/screens/profile-config-screen';
import { ScanTokenScreen } from '../src/screens/scan-token-screen';
import { UserDetailsScreen } from '../src/screens/user-details-screen';
import { UseSmileIDSampleTestIds } from '../src/use-smile-id-sample-test-ids';
import { layoutTree, loadLayoutEngine, type LaidOutNode, type RenderedNode } from './layout/layout-tree';
import { PINNED_FRAME, renderInTheme, withoutHarness } from './render-in-theme';

const noop = () => {};

/// A phone keyboard with its suggestion bar.
const KEYBOARD_HEIGHT = 336;

/// Each screen with a field, the id its root carries and the action that must stay above the keyboard.
const screens: { name: string; root: string; action: string; element: () => ReactElement }[] = [
  {
    name: 'the details form',
    root: UseSmileIDSampleTestIds.USER_DETAILS_SCREEN,
    action: UseSmileIDSampleTestIds.USER_DETAILS_CONTINUE,
    element: () => (
      <UserDetailsScreen
        state={{ productLabel: 'Enhanced KYC', details: smileIDSampleUserDetailsDefaults, profile: null, saveToProfile: true }}
        onFieldChange={noop}
        onSaveToProfileChange={noop}
        onProfilePress={noop}
        onBack={noop}
        onContinue={noop}
      />
    ),
  },
  {
    name: 'the ID form',
    root: UseSmileIDSampleTestIds.KYC_FORM_SCREEN,
    action: UseSmileIDSampleTestIds.KYC_CONTINUE,
    element: () => (
      <KycIdFormScreen
        state={{ productLabel: 'Enhanced KYC', family: 'kyc', details: smileIDSampleIdDetailsDefaults, countryListLoading: false }}
        onCountryPress={noop}
        onIdTypePress={noop}
        onDocumentPress={noop}
        onCaptureAsPress={noop}
        onIdNumberChange={noop}
        onBack={noop}
        onContinue={noop}
        onTokenPress={noop}
      />
    ),
  },
  {
    name: 'a profile',
    root: UseSmileIDSampleTestIds.PROFILE_CONFIG_SCREEN,
    action: UseSmileIDSampleTestIds.PROFILE_CONFIG_SAVE,
    element: () => (
      <ProfileConfigScreen
        state={{
          title: 'Kobo',
          organisation: 'Kobo',
          defaults: smileIDSampleUserDetailsDefaults,
          isActive: true,
          callbackUrl: '',
          callbackOverride: null,
        }}
        onFieldChange={noop}
        onCallbackUrlChange={noop}
        onBack={noop}
        onSave={noop}
      />
    ),
  },
  {
    name: 'the user id form',
    root: UseSmileIDSampleTestIds.AUTH_USER_ID_SCREEN,
    action: UseSmileIDSampleTestIds.AUTH_USER_ID_CONTINUE,
    element: () => (
      <AuthUserIdScreen
        state={{ userId: '', previousUsers: [] }}
        onUserIdChange={noop}
        onRegister={noop}
        onBack={noop}
        onContinue={noop}
      />
    ),
  },
  {
    name: 'the scan sheet',
    root: UseSmileIDSampleTestIds.SCAN_TOKEN_SCREEN,
    action: UseSmileIDSampleTestIds.TOKEN_SIMULATE,
    element: () => <ScanTokenScreen onBack={noop} onLink={noop} onSimulate={noop} onPaste={async () => null} />,
  },
];

/// The laid-out box carrying [testID], with its top and bottom in the frame's coordinates.
const placed = (
  node: LaidOutNode,
  testID: string,
  originTop = 0,
): { top: number; bottom: number } | undefined => {
  const top = originTop + node.top;
  if (node.props.testID === testID) return { top, bottom: top + node.height };
  for (const child of node.children) {
    const found = placed(child, testID, top);
    if (found) return found;
  }
  return undefined;
};

/// The tree with React Native's own vertical ScrollView flex restored, which the jest mock leaves out: on a device it is what gives a list's room up to the keyboard.
const withScrollViewFlex = (node: RenderedNode): RenderedNode => {
  if (node === null || typeof node === 'string') return node;
  const props =
    node.type === 'RCTScrollView' && node.props.horizontal !== true
      ? { ...node.props, style: [{ flexGrow: 1, flexShrink: 1 }, node.props.style] }
      : node.props;
  return { ...node, props, children: (node.children ?? []).map(withScrollViewFlex) };
};

/// Renders [element] in the pinned frame, raises a keyboard as this platform announces one, and lays the result out.
const withKeyboard = async (element: ReactElement, root: string): Promise<LaidOutNode> => {
  // iOS announces the keyboard as it starts to rise, Android once it is up.
  const shown = Platform.OS === 'ios' ? 'keyboardWillShow' : 'keyboardDidShow';
  const listeners: { event: string; listener: (event: KeyboardEvent) => void }[] = [];
  jest.spyOn(Keyboard, 'addListener').mockImplementation((event, listener) => {
    listeners.push({ event, listener: listener as (event: KeyboardEvent) => void });
    return { remove: noop } as ReturnType<typeof Keyboard.addListener>;
  });
  const rendered = await renderInTheme(<View style={{ height: PINNED_FRAME.height }}>{element}</View>, false);
  await act(async () => {
    fireEvent(rendered.getByTestId(root), 'layout', {
      persist: noop,
      nativeEvent: { layout: { x: 0, y: 0, width: PINNED_FRAME.width, height: PINNED_FRAME.height } },
    });
  });
  const rising: KeyboardEvent = {
    duration: 0,
    easing: 'keyboard',
    isEventFromThisApp: true,
    startCoordinates: { screenX: 0, screenY: PINNED_FRAME.height, width: PINNED_FRAME.width, height: KEYBOARD_HEIGHT },
    endCoordinates: {
      screenX: 0,
      screenY: PINNED_FRAME.height - KEYBOARD_HEIGHT,
      width: PINNED_FRAME.width,
      height: KEYBOARD_HEIGHT,
    },
  };
  await act(async () => {
    for (const { event, listener } of listeners) if (event === shown) listener(rising);
  });
  return layoutTree(withScrollViewFlex(withoutHarness(rendered.toJSON()) as RenderedNode), { width: PINNED_FRAME.width });
};

/// Every screen with a field keeps its action above a keyboard raised the way the platform under test raises one.
export const describeKeyboardAvoidance = () => {
  beforeAll(loadLayoutEngine);

  describe.each(screens)('$name', ({ root, action, element }) => {
    it('keeps its action above the keyboard', async () => {
      const box = placed(await withKeyboard(element(), root), action);

      expect(box).toBeDefined();
      expect(box!.bottom).toBeLessThanOrEqual(PINNED_FRAME.height - KEYBOARD_HEIGHT);
    });
  });
};
