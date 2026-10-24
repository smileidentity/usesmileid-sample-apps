import AsyncStorage from '@react-native-async-storage/async-storage';
import { NjiaDefaults, navigatorFor, stepOf, top } from '@smileid/njia';
import { njiaSheetScrim } from '@smileid/njia/host';
import { RecordingNjiaListener } from '@smileid/njia-testing';
import {
  UseSmileIDSampleSuffixedTestIds,
  UseSmileIDSampleTestIds,
  UseSmileIDSampleThemeProvider,
  smileIDSampleBase64UrlEncode,
  smileIDSampleFixtureProfiles,
  smileIDSampleLaunchArgDefaults,
  smileIDSampleLaunchArgsFromUrl,
  smileIDSampleTokenSession,
  useSmileIDSampleFormsStore,
  useSmileIDSampleJobStore,
  useSmileIDSampleProfileStore,
  useSmileIDSampleResultStore,
  useSmileIDSampleSessionStore,
  useSmileIDSampleSettingsStore,
  type UseSmileIDSampleLaunchArgs,
} from '@smileid/sample-ui';
import { act, fireEvent, render, waitFor, type RenderResult } from '@testing-library/react-native';
import * as Linking from 'expo-linking';
import { AccessibilityInfo, Alert, BackHandler, Platform } from 'react-native';

import {
  smileIDSampleCurrentLink,
  smileIDSampleOpenLink,
  smileIDSampleResetNavigation,
  smileIDSampleStartShell,
  UseSmileIDSampleShell,
} from '../src/navigation/use-smile-id-sample-shell';
import type { UseSmileIDSampleFact } from '../src/navigation/use-smile-id-sample-njia';
import { smileIDSampleLoadLaunchArgs, smileIDSampleResetLaunchArgs } from '../src/use-smile-id-sample-launch';
import {
  smileIDSampleReferenceNavigation,
  smileIDSampleStackKinds,
  smileIDSampleTopKind,
} from './support/use-smile-id-sample-test-njia';

jest.mock('@smileid/usesmileid_mlkit_face', () => ({ useSmileIDMlkitFace: { key: 'mlkit' } }));
jest.mock('@smileid/usesmileid_vision_face', () => ({ useSmileIDVisionFace: { key: 'vision' } }));
jest.mock('@smileid/usesmileid_mlkit_document', () => ({ useSmileIDMlkitDocument: { key: 'mlkit-document' } }));
jest.mock('@smileid/usesmileid_vision_document', () => ({ useSmileIDVisionDocument: { key: 'vision-document' } }));
/// The listener the shell added for links delivered while it runs.
let mockOnUrl: ((event: { url: string }) => void) | null = null;
jest.mock('expo-linking', () => ({
  getInitialURL: jest.fn(async () => null),
  addEventListener: (_type: string, listener: (event: { url: string }) => void) => {
    mockOnUrl = listener;
    return { remove: () => (mockOnUrl = null) };
  },
}));
jest.mock('expo-haptics', () => ({
  notificationAsync: jest.fn(async () => undefined),
  NotificationFeedbackType: { Success: 'success', Error: 'error' },
}));
jest.mock('expo-clipboard', () => ({ getStringAsync: jest.fn(async () => ''), setStringAsync: jest.fn(async () => true) }));
jest.mock('expo-camera', () => ({ CameraView: () => null, useCameraPermissions: () => [null, jest.fn()] }));
jest.mock('expo-web-browser', () => ({ openBrowserAsync: jest.fn(async () => undefined) }));
jest.mock('react-native-safe-area-context', () => ({
  SafeAreaProvider: ({ children }: { children?: unknown }) => children,
  useSafeAreaInsets: () => ({ top: 44, bottom: 34, left: 0, right: 0 }),
}));
/// The result callback the SDK flow was given, which a test calls as the SDK would.
let mockOnResult: ((result: unknown) => void) | null = null;
jest.mock('@smileid/usesmileid', () => {
  const actual = jest.requireActual('@smileid/usesmileid');
  return {
    ...actual,
    UseSmileIDBuilder: ({ builder }: { builder: (target: object) => void }) => {
      // Any method chains, and the one assignment that matters is kept.
      const target: object = new Proxy(
        {},
        {
          get: (_object, key) => (key === 'then' ? undefined : () => target),
          set: (_object, key, value) => {
            if (key === 'onResult') mockOnResult = value as typeof mockOnResult;
            return true;
          },
        },
      );
      builder(target);
      return null;
    },
  };
});

/// The scheme spec/app-identity.json gives this app.
const SCHEME = 'usesmileid-sample-expo://';

/// A live session; with `bound`, its token carries the user's and the ID's details.
const liveSession = (bound: boolean) => {
  const nowSeconds = Math.floor(Date.now() / 1000);
  const payload = bound
    ? '{"given_names":"Ada","last_name":"Obi","email":"a@b.co","phone_number":"+254700000000","country":"KE","id_type":"NATIONAL_ID","id_number":"v"}'
    : '{}';
  const claims = `{"iat":${nowSeconds - 1},"exp":${nowSeconds + 900},"api_url":"https://testapi.smileidentity.com/v3","payload":${payload}}`;
  return smileIDSampleTokenSession(['{"alg":"none"}', claims, 's'].map(smileIDSampleBase64UrlEncode).join('.'))!;
};

/// Lets a step's motion finish, which is when the scanner starts taking taps.
const settle = () => act(async () => await new Promise((resolve) => setTimeout(resolve, NjiaDefaults.motionDurationMs + 50)));

type Shell = { screen: RenderResult; engine: () => NonNullable<ReturnType<typeof smileIDSampleReferenceNavigation>['model']['engine']> };

/// The real app shell on njia's reference reducer, launched as the app launches: at `path` when given, else from the icon, with the launch arguments in `query`.
const launch = async (path?: string, args?: UseSmileIDSampleLaunchArgs, query = ''): Promise<Shell> => {
  const url = path === undefined && query === '' ? null : `${SCHEME}${path ?? ''}${query}`;
  (Linking.getInitialURL as jest.Mock).mockResolvedValue(url);
  smileIDSampleResetLaunchArgs();
  await act(async () => await smileIDSampleLoadLaunchArgs());
  const launched = args ?? smileIDSampleLaunchArgsFromUrl(url);
  const { model } = smileIDSampleReferenceNavigation();
  smileIDSampleStartShell(url, launched);
  const screen = await render(
    <UseSmileIDSampleThemeProvider dark={false}>
      <UseSmileIDSampleShell args={launched} />
    </UseSmileIDSampleThemeProvider>,
  );
  await settle();
  return { screen, engine: () => model.engine! };
};

/// Presses `testID` and lets the step it opens move in.
const tap = async (screen: RenderResult, testID: string) => {
  await fireEvent.press(screen.getByTestId(testID));
  await settle();
};

beforeEach(async () => {
  // At rest, as njia draws steps when the system asks for reduced motion, so a query never meets a half-faded step.
  jest.spyOn(AccessibilityInfo, 'isReduceMotionEnabled').mockResolvedValue(true);
  await AsyncStorage.clear();
  mockOnUrl = null;
  mockOnResult = null;
  useSmileIDSampleSessionStore.getState().reset();
  useSmileIDSampleJobStore.getState().reset();
  useSmileIDSampleSettingsStore.getState().reset();
  useSmileIDSampleFormsStore.getState().clear();
  useSmileIDSampleResultStore.getState().reset?.();
  useSmileIDSampleProfileStore.getState().reset(smileIDSampleFixtureProfiles());
});

afterEach(() => {
  smileIDSampleResetNavigation();
  jest.restoreAllMocks();
});

describe('the tabs', () => {
  it('opens on products, with a stack of its own for each tab', async () => {
    const { screen, engine } = await launch();
    expect(smileIDSampleStackKinds(engine())).toEqual(['products']);
    await tap(screen, UseSmileIDSampleTestIds.NAV_SETTINGS);
    expect(smileIDSampleTopKind(engine())).toBe('settings');
    await tap(screen, UseSmileIDSampleTestIds.NAV_VERIFICATIONS);
    expect(smileIDSampleTopKind(engine())).toBe('verifications');
    expect(screen.queryByTestId(UseSmileIDSampleTestIds.VERIFICATIONS_SCREEN)).not.toBeNull();
  });

  it("keeps a tab's pushed screen while another tab is showing", async () => {
    const { screen, engine } = await launch('settings/licenses');
    expect(smileIDSampleStackKinds(engine())).toEqual(['settings', 'licenses']);
    // A pushed screen draws no bar, so the next tab is reached by a link, as a notification would.
    await act(async () => smileIDSampleOpenLink(`${SCHEME}products`, smileIDSampleLaunchArgDefaults));
    await settle();
    expect(smileIDSampleTopKind(engine())).toBe('products');
    expect(engine().state.parked?.settings?.map((entry) => entry.step)).toEqual(['licenses']);
    await tap(screen, UseSmileIDSampleTestIds.NAV_SETTINGS);
    expect(smileIDSampleStackKinds(engine())).toEqual(['settings', 'licenses']);
  });

  it('opens the scanner from any tab on products, the tab the graph gives it', async () => {
    const { screen, engine } = await launch('settings');
    await tap(screen, UseSmileIDSampleTestIds.NAV_SETTINGS);
    expect(smileIDSampleStackKinds(engine())).toEqual(['settings']);
    await tap(screen, UseSmileIDSampleTestIds.NAV_TOKEN);
    expect(smileIDSampleStackKinds(engine())).toEqual(['products', 'scanToken']);
  });

  it('finishes the flow on back from the products root: Android goes to the background, and a fresh flow waits', async () => {
    const os = jest.replaceProperty(Platform, 'OS', 'android');
    const exit = jest.spyOn(BackHandler, 'exitApp').mockImplementation(() => undefined);
    try {
      const { engine } = await launch();
      const first = engine();
      await act(async () => navigatorFor(first, top(first.state)!).back());
      expect(exit).toHaveBeenCalledTimes(1);
      expect(engine()).not.toBe(first);
      expect(smileIDSampleStackKinds(engine())).toEqual(['products']);
    } finally {
      exit.mockRestore();
      os.restore();
    }
  });
});

describe('the settings sheets', () => {
  it.each([
    ['capture mode', UseSmileIDSampleTestIds.SETTING_CAPTURE_MODE, 'captureMode', UseSmileIDSampleTestIds.CAPTURE_MODE_SHEET],
    ['appearance', UseSmileIDSampleTestIds.SETTING_APPEARANCE, 'appearance', UseSmileIDSampleTestIds.APPEARANCE_SHEET],
    ['language', UseSmileIDSampleTestIds.SETTING_LANGUAGE, 'language', UseSmileIDSampleTestIds.LANGUAGE_SHEET],
  ] as const)('opens the %s sheet over settings, and its scrim closes it', async (_name, row, kind, sheet) => {
    const { screen, engine } = await launch('settings');
    await tap(screen, row);
    expect(smileIDSampleStackKinds(engine())).toEqual(['settings', kind]);
    expect(screen.queryByTestId(sheet)).not.toBeNull();
    // Settings stays drawn beneath the sheet, which is a layer, not a page of its own.
    expect(screen.queryByTestId(UseSmileIDSampleTestIds.SETTINGS_SCREEN, { includeHiddenElements: true })).not.toBeNull();
    await fireEvent.press(screen.getByTestId(njiaSheetScrim, { includeHiddenElements: true }));
    await settle();
    expect(smileIDSampleStackKinds(engine())).toEqual(['settings']);
  });

  it('keeps a pick and closes the sheet', async () => {
    const { screen, engine } = await launch('settings/appearance');
    expect(smileIDSampleStackKinds(engine())).toEqual(['settings', 'appearance']);
    await tap(screen, UseSmileIDSampleSuffixedTestIds.appearanceOption('dark'));
    expect(smileIDSampleStackKinds(engine())).toEqual(['settings']);
    expect(useSmileIDSampleSettingsStore.getState().settings.appearance).toBe('dark');
  });

  it('lands a link to the scenario drawer, which this app has not built, on settings', async () => {
    const { engine } = await launch('debug/scenarios');
    await waitFor(() => expect(smileIDSampleStackKinds(engine())).toEqual(['settings']));
  });

  it('pushes the notices inside settings, and back returns to it', async () => {
    const { screen, engine } = await launch('settings');
    await tap(screen, UseSmileIDSampleSuffixedTestIds.settingNav('licenses'));
    expect(smileIDSampleStackKinds(engine())).toEqual(['settings', 'licenses']);
    expect(smileIDSampleCurrentLink()).toBe('settings/licenses');
  });

  it('signs out to products', async () => {
    // The confirmation is the platform's alert, so its destructive button is pressed as a user would.
    jest.spyOn(Alert, 'alert').mockImplementation((_title, _message, buttons) =>
      buttons?.find((button) => button.style === 'destructive')?.onPress?.(),
    );
    const { screen, engine } = await launch('settings');
    await tap(screen, UseSmileIDSampleTestIds.SIGN_OUT);
    expect(smileIDSampleTopKind(engine())).toBe('products');
  });
});

describe('profiles', () => {
  it('goes from settings to the list, makes a profile in a sheet over it, and opens one', async () => {
    const { screen, engine } = await launch('settings');
    await tap(screen, UseSmileIDSampleTestIds.PROFILE_SUMMARY);
    expect(smileIDSampleStackKinds(engine())).toEqual(['settings', 'profiles']);
    await tap(screen, UseSmileIDSampleTestIds.CREATE_PROFILE);
    expect(smileIDSampleTopKind(engine())).toBe('newProfile');
    await fireEvent.changeText(screen.getByTestId(UseSmileIDSampleTestIds.NEW_PROFILE_NAME), 'Kazi Ltd');
    await fireEvent.changeText(screen.getByTestId(UseSmileIDSampleTestIds.NEW_PROFILE_FIRST_NAME), 'Wanjiku');
    await fireEvent.changeText(screen.getByTestId(UseSmileIDSampleTestIds.NEW_PROFILE_LAST_NAME), 'Kamau');
    await tap(screen, UseSmileIDSampleTestIds.NEW_PROFILE_SAVE);
    expect(smileIDSampleStackKinds(engine())).toEqual(['settings', 'profiles']);
    expect(useSmileIDSampleProfileStore.getState().items.some((item) => item.organisation === 'Kazi Ltd')).toBe(true);
    const first = useSmileIDSampleProfileStore.getState().items[0]!.id;
    await tap(screen, UseSmileIDSampleSuffixedTestIds.profileRow(first));
    expect(smileIDSampleTopKind(engine())).toBe('profileConfig');
    expect(engine().state.entries.at(-1)?.arg).toBe(first);
    expect(smileIDSampleCurrentLink()).toBe(`profiles/${first}`);
  });

  it('switches from products, and a profile made from the switch is active at once', async () => {
    const { screen, engine } = await launch();
    await tap(screen, UseSmileIDSampleTestIds.PROFILE_AVATAR_BUTTON);
    expect(smileIDSampleStackKinds(engine())).toEqual(['products', 'profileSwitch']);
    await tap(screen, UseSmileIDSampleTestIds.PROFILE_SWITCH_NEW);
    // The form takes the switch's place in the same sheet, so one back closes both.
    expect(smileIDSampleStackKinds(engine())).toEqual(['products', 'profileSwitch']);
    await fireEvent.changeText(screen.getByTestId(UseSmileIDSampleTestIds.NEW_PROFILE_NAME), 'Duka Co');
    await fireEvent.changeText(screen.getByTestId(UseSmileIDSampleTestIds.NEW_PROFILE_FIRST_NAME), 'Juma');
    await fireEvent.changeText(screen.getByTestId(UseSmileIDSampleTestIds.NEW_PROFILE_LAST_NAME), 'Ali');
    await tap(screen, UseSmileIDSampleTestIds.NEW_PROFILE_SAVE);
    expect(smileIDSampleStackKinds(engine())).toEqual(['products']);
    const { items, activeId } = useSmileIDSampleProfileStore.getState();
    expect(items.find((item) => item.id === activeId)?.organisation).toBe('Duka Co');
  });
});

describe('links', () => {
  it('rebuilds the stack a user could have built by tapping, with its argument', async () => {
    const { engine } = await launch('verifications/job_link');
    expect(smileIDSampleStackKinds(engine())).toEqual(['verifications', 'verificationDetails']);
    expect(engine().state.entries.at(-1)?.arg).toBe('job_link');
    expect(smileIDSampleCurrentLink()).toBe('verifications/job_link');
  });

  it('opens a link delivered while the app runs as a new flow, keeping the other tabs up to a run', async () => {
    const { engine } = await launch('settings/licenses');
    await act(async () => mockOnUrl!({ url: `${SCHEME}verifications/job_warm` }));
    await settle();
    expect(smileIDSampleStackKinds(engine())).toEqual(['verifications', 'verificationDetails']);
    expect(engine().state.parked?.settings?.map((entry) => entry.step)).toEqual(['licenses']);
  });

  it('leaves the flow alone for a link the graph refuses', async () => {
    const { engine } = await launch('settings');
    const before = engine();
    await act(async () => mockOnUrl!({ url: `${SCHEME}nowhere/at/all` }));
    expect(engine()).toBe(before);
  });

  it('drops the second delivery of the cold link, which iOS repeats after launch', async () => {
    const { engine } = await launch('settings/licenses');
    const opened = engine();
    await act(async () => mockOnUrl!({ url: `${SCHEME}settings/licenses` }));
    expect(engine()).toBe(opened);
  });

  it('names the screen under a sheet as where the app is, for a reload to return to', async () => {
    await launch('settings/language');
    expect(smileIDSampleCurrentLink()).toBe('settings');
  });

  it('holds a link that arrives before the flow starts, and opens it once it has', async () => {
    const { model } = smileIDSampleReferenceNavigation();
    smileIDSampleOpenLink(`${SCHEME}settings/licenses`, smileIDSampleLaunchArgDefaults);
    expect(smileIDSampleCurrentLink()).toBeNull();
    smileIDSampleStartShell(null, smileIDSampleLaunchArgDefaults);
    expect(smileIDSampleStackKinds(model.engine!)).toEqual(['settings', 'licenses']);
  });
});

describe('a run', () => {
  /// Records the shell engine's transitions from here on.
  const recording = (engine: Shell['engine']) => {
    const recorder = new RecordingNjiaListener<UseSmileIDSampleFact>();
    engine().addListener(recorder.listener);
    return recorder;
  };

  it('autostarts straight into the run, past every form, on the route the launch asked for', async () => {
    await act(async () => {
      await useSmileIDSampleSessionStore.getState().link(liveSession(false));
    });
    const { engine } = await launch(undefined, { ...smileIDSampleLaunchArgDefaults, autostart: 'smartSelfieEnrollment' });
    expect(smileIDSampleStackKinds(engine())).toEqual(['products', 'sdkFlowFullScreen']);
    expect(engine().state.entries.at(-1)?.arg).toBe('smartSelfieEnrollment');
  });

  it('walks a product with no bound details through its forms and pickers into the run, then lands on its result', async () => {
    await act(async () => {
      await useSmileIDSampleSessionStore.getState().link(liveSession(false));
    });
    const { screen, engine } = await launch();
    const recorder = recording(engine);
    await tap(screen, UseSmileIDSampleSuffixedTestIds.productCard('smartSelfieEnrollment'));
    // The run's facts go first, so the graph skips what this product doesn't ask, then the tap's go.
    expect([...recorder.consume().state.facts]).toEqual(['fullScreenRun']);
    expect(stepOf(engine().graph, top(recorder.consume().state)!).kind).toBe('consentDetailsForm');
    recorder.ensureAllTransitionsConsumed();
    expect(smileIDSampleStackKinds(engine())).toEqual(['products', 'consentDetailsForm']);

    for (const [field, value] of [
      ['firstName', 'Ada'],
      ['lastName', 'Obi'],
      ['email', 'ada@example.com'],
      ['phone', '+254700000000'],
    ] as const) {
      const input = screen.queryByTestId(UseSmileIDSampleSuffixedTestIds.userDetailsField(field));
      if (input !== null) await fireEvent.changeText(input, value);
    }
    await tap(screen, UseSmileIDSampleTestIds.USER_DETAILS_CONTINUE);
    expect(smileIDSampleStackKinds(engine())).toEqual(['products', 'consentDetailsForm', 'sdkFlowFullScreen']);

    await waitFor(() => expect(mockOnResult).not.toBeNull());
    await act(async () =>
      mockOnResult!({ status: 'success', value: { jobId: 'job_run', userId: 'user_run', message: 'ok' } }),
    );
    await settle();
    // The result replaces the run's forms, so back from it can't return into them.
    expect(smileIDSampleTopKind(engine())).toBe('verificationDetails');
    expect(engine().state.entries.at(-1)?.arg).toBe('job_run');
    expect(smileIDSampleStackKinds(engine())).not.toContain('consentDetailsForm');
  });

  it('opens the ID-details pickers as sheets over the form, and refuses one whose trigger could not open yet', async () => {
    await act(async () => {
      await useSmileIDSampleSessionStore.getState().link(liveSession(false));
    });
    const { screen, engine } = await launch('flow/biometricKyc/id-details');
    expect(smileIDSampleTopKind(engine())).toBe('idDetailsForm');
    await tap(screen, UseSmileIDSampleTestIds.COUNTRY_TRIGGER);
    expect(smileIDSampleTopKind(engine())).toBe('countryPicker');
    await fireEvent.press(screen.getByTestId(njiaSheetScrim, { includeHiddenElements: true }));
    await settle();
    expect(smileIDSampleTopKind(engine())).toBe('idDetailsForm');

    const { engine: linked } = await launch('flow/biometricKyc/id-details/id-type');
    // No country yet, so the ID type sheet leaves as it opens.
    await waitFor(() => expect(smileIDSampleTopKind(linked())).toBe('idDetailsForm'));
  });

  it('asks Auth for its user ID, and Register starts enrollment in its place', async () => {
    await act(async () => {
      await useSmileIDSampleSessionStore.getState().link(liveSession(true));
    });
    const { screen, engine } = await launch();
    await tap(screen, UseSmileIDSampleSuffixedTestIds.productCard('smartSelfieAuth'));
    expect(smileIDSampleStackKinds(engine())).toEqual(['products', 'authUserId']);
    await tap(screen, UseSmileIDSampleTestIds.AUTH_USER_ID_REGISTER);
    expect(smileIDSampleStackKinds(engine())).toEqual(['products', 'sdkFlowFullScreen']);
    expect(engine().state.entries.at(-1)?.arg).toBe('smartSelfieEnrollment');
  });

  it('sends a run whose form was skipped but whose details are missing back to that form', async () => {
    await act(async () => {
      await useSmileIDSampleSessionStore.getState().link(liveSession(false));
    });
    const { engine } = await launch('flow/biometricKyc/run?route=shell');
    await waitFor(() => expect(smileIDSampleTopKind(engine())).toBe('consentDetailsForm'));
    expect(engine().state.entries.at(-1)?.arg).toBe('biometricKyc');
  });
});

describe('the ID-details pickers', () => {
  /// Live, unbound, and reading the bundled catalogue, so the pickers list real countries and documents.
  const formFor = async (productId: string) => {
    await act(async () => {
      await useSmileIDSampleSessionStore.getState().link(liveSession(false));
    });
    return launch(`flow/${productId}/id-details`, undefined, '?catalogue=fixture');
  };

  it('picks a country and an ID type in sheets over the form, which keeps both', async () => {
    const { screen, engine } = await formFor('biometricKyc');
    await tap(screen, UseSmileIDSampleTestIds.COUNTRY_TRIGGER);
    await waitFor(() => expect(screen.queryAllByTestId(/^sample_country_option_/).length).toBeGreaterThan(0));
    await fireEvent.press(screen.getByTestId(UseSmileIDSampleSuffixedTestIds.countryOption('KE')));
    await settle();
    expect(smileIDSampleTopKind(engine())).toBe('idDetailsForm');
    await tap(screen, UseSmileIDSampleTestIds.ID_TYPE_TRIGGER);
    expect(smileIDSampleTopKind(engine())).toBe('idTypePicker');
    await waitFor(() => expect(screen.queryAllByTestId(/^sample_idtype_option_/).length).toBeGreaterThan(0));
    await fireEvent.press(screen.getAllByTestId(/^sample_idtype_option_/)[0]!);
    await settle();
    expect(smileIDSampleStackKinds(engine()).slice(-1)).toEqual(['idDetailsForm']);
  });

  it('picks a document, then hands generic document from the capture-as sheet to its own sheet in its place', async () => {
    const { screen, engine } = await formFor('enhancedDocumentVerification');
    await tap(screen, UseSmileIDSampleTestIds.COUNTRY_TRIGGER);
    await waitFor(() => expect(screen.queryAllByTestId(/^sample_country_option_/).length).toBeGreaterThan(0));
    await fireEvent.press(screen.getAllByTestId(/^sample_country_option_/)[0]!);
    await settle();
    await tap(screen, UseSmileIDSampleTestIds.DOCUMENT_TRIGGER);
    expect(smileIDSampleTopKind(engine())).toBe('documentPicker');
    await waitFor(() => expect(screen.queryAllByTestId(/^sample_document_option_/).length).toBeGreaterThan(0));
    await fireEvent.press(screen.getAllByTestId(/^sample_document_option_/)[0]!);
    await settle();
    expect(smileIDSampleTopKind(engine())).toBe('idDetailsForm');
    await tap(screen, UseSmileIDSampleTestIds.CAPTURE_AS_TRIGGER);
    expect(smileIDSampleTopKind(engine())).toBe('captureAs');
    await tap(screen, UseSmileIDSampleSuffixedTestIds.captureAsOption('genericDocument'));
    expect(smileIDSampleStackKinds(engine()).slice(-2)).toEqual(['idDetailsForm', 'genericDocument']);
    await fireEvent.changeText(screen.getByTestId(UseSmileIDSampleTestIds.GENERIC_DOCUMENT_NAME), 'Work permit');
    await tap(screen, UseSmileIDSampleTestIds.GENERIC_DOCUMENT_DONE);
    expect(smileIDSampleTopKind(engine())).toBe('idDetailsForm');
  });

  it('refuses the document and capture-as sheets a link opens before their triggers could', async () => {
    const { engine } = await formFor('enhancedDocumentVerification');
    await act(async () => mockOnUrl!({ url: `${SCHEME}flow/enhancedDocumentVerification/id-details/document` }));
    await waitFor(() => expect(smileIDSampleTopKind(engine())).toBe('idDetailsForm'));
    await act(async () => mockOnUrl!({ url: `${SCHEME}flow/enhancedDocumentVerification/id-details/capture-as` }));
    await waitFor(() => expect(smileIDSampleTopKind(engine())).toBe('idDetailsForm'));
  });
});

describe('the other sheets keep a pick', () => {
  it('keeps a capture mode and a language', async () => {
    const { screen, engine } = await launch('settings/capture-mode');
    await fireEvent.press(screen.getAllByTestId(/^sample_capture_mode_option_/).at(-1)!);
    await settle();
    expect(smileIDSampleStackKinds(engine())).toEqual(['settings']);
    await tap(screen, UseSmileIDSampleTestIds.SETTING_LANGUAGE);
    await tap(screen, UseSmileIDSampleSuffixedTestIds.languageOption('en'));
    expect(smileIDSampleStackKinds(engine())).toEqual(['settings']);
    expect(useSmileIDSampleSettingsStore.getState().settings.language).toBe('en');
  });

  it('switches to another profile and refills the form from it', async () => {
    const { screen, engine } = await launch('profiles/switch');
    const other = useSmileIDSampleProfileStore.getState().items.at(-1)!;
    await fireEvent.press(screen.getAllByText(other.organisation)[0]!);
    await settle();
    expect(smileIDSampleStackKinds(engine())).toEqual(['products']);
    expect(useSmileIDSampleProfileStore.getState().activeId).toBe(other.id);
  });
});

describe('leaving a page', () => {
  it('deletes a profile and leaves its page', async () => {
    jest.spyOn(Alert, 'alert').mockImplementation((_title, _message, buttons) =>
      buttons?.find((button) => button.style === 'destructive')?.onPress?.(),
    );
    const other = useSmileIDSampleProfileStore.getState().items.at(-1)!;
    const { screen, engine } = await launch(`profiles/${other.id}`);
    expect(smileIDSampleTopKind(engine())).toBe('profileConfig');
    await tap(screen, UseSmileIDSampleTestIds.PROFILE_CONFIG_DELETE);
    const confirm = screen.queryByTestId(UseSmileIDSampleTestIds.PROFILE_DELETE_CONFIRM);
    if (confirm !== null) await tap(screen, UseSmileIDSampleTestIds.PROFILE_DELETE_CONFIRM);
    await waitFor(() => expect(smileIDSampleTopKind(engine())).toBe('profiles'));
    expect(useSmileIDSampleProfileStore.getState().items.some((item) => item.id === other.id)).toBe(false);
  });

  it('deletes a verification from its page and returns to the list', async () => {
    jest.spyOn(Alert, 'alert').mockImplementation((_title, _message, buttons) =>
      buttons?.find((button) => button.style === 'destructive')?.onPress?.(),
    );
    await useSmileIDSampleJobStore.getState().seedFixtures(Date.now());
    const job = useSmileIDSampleJobStore.getState().jobs![0]!;
    const { screen, engine } = await launch(`verifications/${job.id}`);
    await tap(screen, UseSmileIDSampleTestIds.DETAILS_DELETE);
    await waitFor(() => expect(smileIDSampleStackKinds(engine())).toEqual(['verifications']));
  });
});

describe('how a run ends', () => {
  const liveRun = async (path: string, bound = false) => {
    await act(async () => {
      await useSmileIDSampleSessionStore.getState().link(liveSession(bound));
    });
    return launch(path);
  };

  it('goes back to products when the SDK fails or is cancelled', async () => {
    const { engine } = await liveRun('flow/smartSelfieEnrollment/run', true);
    expect(smileIDSampleTopKind(engine())).toBe('sdkFlowFullScreen');
    await waitFor(() => expect(mockOnResult).not.toBeNull());
    await act(async () => mockOnResult!({ status: 'cancelled' }));
    await settle();
    expect(smileIDSampleStackKinds(engine())).toEqual(['products']);
  });

  it("sends Auth's run back for the user ID it has no value for", async () => {
    const { engine } = await liveRun('flow/smartSelfieAuth/run', true);
    await waitFor(() => expect(smileIDSampleTopKind(engine())).toBe('authUserId'));
    expect(engine().state.entries.at(-1)?.arg).toBe('smartSelfieAuth');
  });

  it('continues from the user ID into the run', async () => {
    const { screen, engine } = await liveRun('flow/smartSelfieAuth/user-id', true);
    await fireEvent.changeText(screen.getByTestId(UseSmileIDSampleTestIds.AUTH_USER_ID_INPUT), 'user_known');
    await tap(screen, UseSmileIDSampleTestIds.AUTH_USER_ID_CONTINUE);
    expect(smileIDSampleTopKind(engine())).toBe('sdkFlowFullScreen');
  });

  it('records a run the builder refuses, and never hands it to the SDK', async () => {
    const { engine } = await liveRun('flow/notAProduct/run');
    await waitFor(() => expect(smileIDSampleStackKinds(engine())).toEqual(['products']));
    expect(mockOnResult).toBeNull();
  });
});
