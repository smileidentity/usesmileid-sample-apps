import { LicensesScreen, type UseSmileIDSampleLicence } from '../src/screens/licenses-screen';
import { ProductsScreen } from '../src/screens/products-screen';
import { SettingsScreen } from '../src/screens/settings-screen';
import { smileIDSampleSettingsDefaults } from '../src/state/use-smile-id-sample-settings';
import { UseSmileIDSampleTestIds } from '../src/use-smile-id-sample-test-ids';
import { renderInTheme, schemes } from './render-in-theme';
import { expectGoldens } from './paint/pixel-golden';

const noop = () => {};

/// One fixture set across every platform, so a pair of goldens can be read against each other.
const settingsState = {
  settings: smileIDSampleSettingsDefaults,
  organisation: 'UpTech Finance',
  initials: 'KA',
  versionLabel: 'Smile ID · 1.0.0',
};

const licences: readonly UseSmileIDSampleLicence[] = [
  { component: 'react-native-svg', version: '15.15.4', declared: 'MIT', text: 'MIT License\n\nCopyright (c) …' },
  { component: 'zustand', version: '5.0.15', declared: 'MIT', text: 'MIT License\n\nCopyright (c) …' },
];

const settings = (
  overrides: Partial<Parameters<typeof SettingsScreen>[0]> = {},
): React.ReactElement => (
  <SettingsScreen
    state={settingsState}
    onSettingChange={noop}
    onProfilePress={noop}
    onNavRowPress={noop}
    onSignOut={noop}
    {...overrides}
  />
);

type Case = { element: () => React.ReactElement };

const cases: { screen: string; states: Record<string, Case> }[] = [
  {
    screen: 'settings',
    states: {
      default: { element: () => settings() },
      // The DEBUG section is a nullable slot the host fills, because this package runs under eight identities.
      withDebugSection: { element: () => settings({ onOpenScenarioDrawer: noop }) },
      agentModeOn: {
        element: () =>
          settings({
            state: {
              ...settingsState,
              settings: {
                ...smileIDSampleSettingsDefaults,
                agentMode: true,
                enhancedSmartSelfie: false,
              },
            },
          }),
      },
      // A switch reading ON while the token has taken the decision away is a lie the screen tells.
      consentBoundByToken: {
        element: () => settings({ state: { ...settingsState, consentBoundByToken: true } }),
      },
    },
  },
  {
    screen: 'products',
    states: {
      default: {
        element: () => (
          <ProductsScreen
            state={{ initials: 'KA' }}
            onProductPress={noop}
            onProfilePress={noop}
            onScanPress={noop}
          />
        ),
      },
      tokenLinked: {
        element: () => (
          <ProductsScreen
            state={{ initials: 'KA', sessionId: 'a41f', sessionRemaining: '5:00' }}
            onProductPress={noop}
            onProfilePress={noop}
            onScanPress={noop}
          />
        ),
      },
      tokenLinkedLate: {
        element: () => (
          <ProductsScreen
            state={{ initials: 'KA', sessionId: 'a41f', sessionRemaining: '1:40' }}
            onProductPress={noop}
            onProfilePress={noop}
            onScanPress={noop}
          />
        ),
      },
      tokenExpired: {
        element: () => (
          <ProductsScreen
            state={{ initials: 'KA', sessionEnded: true }}
            onProductPress={noop}
            onProfilePress={noop}
            onScanPress={noop}
          />
        ),
      },
    },
  },
  {
    screen: 'licenses',
    states: {
      default: { element: () => <LicensesScreen licences={licences} onBack={noop} /> },
      // An empty list means the generated asset did not ship, and the screen says so.
      empty: { element: () => <LicensesScreen licences={[]} onBack={noop} /> },
    },
  },
];

describe.each(cases)('$screen', ({ states }) => {
  describe.each(schemes)('$name', ({ dark }) => {
    it.each(Object.keys(states))('%s', async (state) => {
      await expectGoldens(states[state]!.element(), dark);
    });
  });
});

describe('screen coverage', () => {
  it('records both schemes for every state spec/screens.json lists for these three', () => {
    const total = cases.reduce((sum, entry) => sum + Object.keys(entry.states).length, 0);
    expect(total * schemes.length).toBe(20);
  });
});

describe('settings', () => {
  it('attaches the id every one of the six switches is driven by', async () => {
    const rendered = await renderInTheme(settings(), false);
    for (const id of [
      UseSmileIDSampleTestIds.SETTING_ENHANCED_SMART_SELFIE,
      UseSmileIDSampleTestIds.SETTING_AGENT_MODE,
      UseSmileIDSampleTestIds.SETTING_DARK_MODE,
      UseSmileIDSampleTestIds.SETTING_CONSENT_STEP,
      UseSmileIDSampleTestIds.SETTING_INSTRUCTIONS_STEP,
      UseSmileIDSampleTestIds.SETTING_PREVIEW_STEP,
    ]) {
      expect(rendered.queryByTestId(id)).not.toBeNull();
    }
  });

  it('hides the DEBUG row unless the host supplies the callback', async () => {
    const without = await renderInTheme(settings(), false);
    expect(without.queryByTestId(UseSmileIDSampleTestIds.SCENARIO_DRAWER_BUTTON)).toBeNull();
    const with_ = await renderInTheme(settings({ onOpenScenarioDrawer: noop }), false);
    expect(with_.queryByTestId(UseSmileIDSampleTestIds.SCENARIO_DRAWER_BUTTON)).not.toBeNull();
  });

  it('says each capture row turns the other off while the other is on', async () => {
    const rendered = await renderInTheme(settings(), false);
    expect(rendered.queryByText('Turns Enhanced SmartSelfie™ off')).not.toBeNull();
    expect(rendered.queryByText('Face capture uses head-turns')).not.toBeNull();
  });

  it('tells the reader the token took the consent decision away', async () => {
    const rendered = await renderInTheme(
      settings({ state: { ...settingsState, consentBoundByToken: true } }),
      false,
    );
    expect(rendered.queryByText('The token grants consent, so the screen is skipped')).not.toBeNull();
  });

  it('names the product and the host version in the footer', async () => {
    const rendered = await renderInTheme(settings(), false);
    expect(rendered.getByTestId(UseSmileIDSampleTestIds.VERSION_LABEL)).toHaveTextContent(
      'Smile ID · 1.0.0',
    );
  });
});

describe('products', () => {
  it('draws a card for every one of the six products, each with its own id', async () => {
    const rendered = await renderInTheme(
      <ProductsScreen
        state={{ initials: 'KA' }}
        onProductPress={noop}
        onProfilePress={noop}
        onScanPress={noop}
      />,
      false,
    );
    for (const id of [
      'smartSelfieEnrollment',
      'smartSelfieAuth',
      'documentVerification',
      'enhancedDocumentVerification',
      'biometricKyc',
      'enhancedKyc',
    ]) {
      expect(rendered.queryByTestId(`sample_product_card_${id}`)).not.toBeNull();
    }
  });

  it('keeps the header avatar, which neither frame draws and the app needs for the profile switch', async () => {
    const rendered = await renderInTheme(
      <ProductsScreen
        state={{ initials: 'KA' }}
        onProductPress={noop}
        onProfilePress={noop}
        onScanPress={noop}
      />,
      false,
    );
    expect(rendered.queryByTestId(UseSmileIDSampleTestIds.PROFILE_AVATAR_BUTTON)).not.toBeNull();
  });

  it('renders no environment chip, which the 2026-08-24 ruling hid', async () => {
    const rendered = await renderInTheme(
      <ProductsScreen
        state={{ initials: 'KA' }}
        onProductPress={noop}
        onProfilePress={noop}
        onScanPress={noop}
      />,
      false,
    );
    expect(rendered.queryByTestId(UseSmileIDSampleTestIds.ENV_CHIP)).toBeNull();
  });

  it('swaps the session card for the ended banner rather than showing both', async () => {
    const live = await renderInTheme(
      <ProductsScreen
        state={{ initials: 'KA', sessionId: 'a41f', sessionRemaining: '5:00' }}
        onProductPress={noop}
        onProfilePress={noop}
        onScanPress={noop}
      />,
      false,
    );
    expect(live.queryByTestId(UseSmileIDSampleTestIds.SESSION_CARD)).not.toBeNull();
    expect(live.queryByTestId(UseSmileIDSampleTestIds.SESSION_ENDED_BANNER)).toBeNull();

    const ended = await renderInTheme(
      <ProductsScreen
        state={{ initials: 'KA', sessionEnded: true }}
        onProductPress={noop}
        onProfilePress={noop}
        onScanPress={noop}
      />,
      false,
    );
    expect(ended.queryByTestId(UseSmileIDSampleTestIds.SESSION_ENDED_BANNER)).not.toBeNull();
    expect(ended.queryByTestId(UseSmileIDSampleTestIds.SESSION_CARD)).toBeNull();
  });
});

describe('licenses', () => {
  it('says the asset did not ship rather than showing nothing', async () => {
    const rendered = await renderInTheme(<LicensesScreen licences={[]} onBack={noop} />, false);
    expect(rendered.queryByTestId(UseSmileIDSampleTestIds.LICENSES_EMPTY)).not.toBeNull();
  });

  it('gives each component a row keyed by an id a flow can reach', async () => {
    const rendered = await renderInTheme(<LicensesScreen licences={licences} onBack={noop} />, false);
    expect(rendered.queryByTestId('sample_license_row_react_native_svg')).not.toBeNull();
    expect(rendered.queryByTestId('sample_license_row_zustand')).not.toBeNull();
  });

  it('shows a licence text only once its row is opened', async () => {
    const rendered = await renderInTheme(<LicensesScreen licences={licences} onBack={noop} />, false);
    expect(rendered.queryByTestId('sample_license_text_zustand')).toBeNull();
  });
});
