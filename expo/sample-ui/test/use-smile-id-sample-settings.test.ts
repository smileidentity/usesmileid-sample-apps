import { UseSmileIDSampleSetting, smileIDSampleSettings } from '../src/model/use-smile-id-sample-setting';
import {
  smileIDSampleSettingsDefaults,
  smileIDSampleSettingsNormalised,
  smileIDSampleSettingsWith,
} from '../src/state/use-smile-id-sample-settings';
import { UseSmileIDSampleTestIds } from '../src/use-smile-id-sample-test-ids';
import { smileIDSampleNavRows } from '../src/model/use-smile-id-sample-nav-row';
import { spec } from './spec-file';

describe('the settings defaults', () => {
  it('turns the head-turn challenge on, which is what the design draws', () => {
    expect(smileIDSampleSettingsDefaults.enhancedSmartSelfie).toBe(true);
    expect(smileIDSampleSettingsDefaults.agentMode).toBe(false);
  });

  it('shows all three SDK steps, so a plain run composes the whole flow', () => {
    expect([
      smileIDSampleSettingsDefaults.consentStep,
      smileIDSampleSettingsDefaults.instructionsStep,
      smileIDSampleSettingsDefaults.previewStep,
    ]).toEqual([true, true, true]);
  });

  it('never carries the pair the SDK refuses', () => {
    const { agentMode, enhancedSmartSelfie } = smileIDSampleSettingsDefaults;
    expect(agentMode && enhancedSmartSelfie).toBe(false);
  });
});

describe('the capture mutex', () => {
  it('turns agent mode off when enhanced liveness goes on', () => {
    const from = { ...smileIDSampleSettingsDefaults, enhancedSmartSelfie: false, agentMode: true };
    const to = smileIDSampleSettingsWith(from, UseSmileIDSampleSetting.EnhancedSmartSelfie, true);
    expect([to.enhancedSmartSelfie, to.agentMode]).toEqual([true, false]);
  });

  it('turns enhanced liveness off when agent mode goes on', () => {
    const to = smileIDSampleSettingsWith(
      smileIDSampleSettingsDefaults,
      UseSmileIDSampleSetting.AgentMode,
      true,
    );
    expect([to.agentMode, to.enhancedSmartSelfie]).toEqual([true, false]);
  });

  it('leaves the other row alone when either is turned off', () => {
    const to = smileIDSampleSettingsWith(
      smileIDSampleSettingsDefaults,
      UseSmileIDSampleSetting.EnhancedSmartSelfie,
      false,
    );
    expect([to.enhancedSmartSelfie, to.agentMode]).toEqual([false, false]);
  });

  it('touches nothing else for the four rows that are plain booleans', () => {
    for (const setting of [
      UseSmileIDSampleSetting.DarkMode,
      UseSmileIDSampleSetting.ConsentStep,
      UseSmileIDSampleSetting.InstructionsStep,
      UseSmileIDSampleSetting.PreviewStep,
    ]) {
      // Flipped away from its own default and put back, which is not the same as forcing it true:
      // dark mode defaults to false and the other three to true.
      const flipped = !smileIDSampleSettingsDefaults[setting];
      const to = smileIDSampleSettingsWith(smileIDSampleSettingsDefaults, setting, flipped);
      expect({ ...to, [setting]: smileIDSampleSettingsDefaults[setting] }).toEqual(
        smileIDSampleSettingsDefaults,
      );
    }
  });

  it('drops enhanced liveness from a stored state that predates the rule', () => {
    // Rejecting the pair on read would crash a device that already holds both.
    const stored = { ...smileIDSampleSettingsDefaults, enhancedSmartSelfie: true, agentMode: true };
    expect(smileIDSampleSettingsNormalised(stored).enhancedSmartSelfie).toBe(false);
  });

  it('leaves a legal stored state untouched', () => {
    expect(smileIDSampleSettingsNormalised(smileIDSampleSettingsDefaults)).toEqual(
      smileIDSampleSettingsDefaults,
    );
  });
});

describe('the settings rows match spec/test-ids.json', () => {
  type TestIds = { ids: Record<string, { id: string }[]> };
  const specIds = Object.values(spec<TestIds>('test-ids.json').ids).flatMap((group) =>
    group.map((entry) => entry.id),
  );

  it('carries a declared id for every one of the six switches', () => {
    const switchIds = [
      UseSmileIDSampleTestIds.SETTING_ENHANCED_SMART_SELFIE,
      UseSmileIDSampleTestIds.SETTING_AGENT_MODE,
      UseSmileIDSampleTestIds.SETTING_DARK_MODE,
      UseSmileIDSampleTestIds.SETTING_CONSENT_STEP,
      UseSmileIDSampleTestIds.SETTING_INSTRUCTIONS_STEP,
      UseSmileIDSampleTestIds.SETTING_PREVIEW_STEP,
    ];
    expect(switchIds.length).toBe(smileIDSampleSettings.length);
    expect(switchIds.filter((id) => !specIds.includes(id))).toEqual([]);
  });

  it('drives the renamed row rather than the one that no longer exists', () => {
    // sample_setting_smile_to_capture was superseded; a port still driving it drives nothing.
    expect(specIds).toContain('sample_setting_enhanced_smart_selfie');
    expect(specIds).not.toContain('sample_setting_smile_to_capture');
  });
});

describe('the ABOUT and LEGAL rows match spec/screens.json', () => {
  type Screens = { screens: { id: string; links?: Record<string, string> }[] };
  const settings = spec<Screens>('screens.json').screens.find((s) => s.id === 'settings');

  it('uses the URL the spec records for every row that has one', () => {
    const links = settings?.links ?? {};
    for (const row of smileIDSampleNavRows) {
      if (row.url === undefined) continue;
      expect({ id: row.id, url: row.url }).toEqual({ id: row.id, url: links[row.id] });
    }
  });

  it('gives the licences row no URL, because the notice ships with the bundle', () => {
    expect(smileIDSampleNavRows.find((row) => row.id === 'licenses')?.url).toBeUndefined();
  });

  it('ejects exactly the two legal pages, which serve their document as an embedded PDF', () => {
    expect(smileIDSampleNavRows.filter((row) => !row.opensInApp).map((row) => row.id)).toEqual([
      'terms',
      'privacy',
    ]);
  });

  it('declares the five rows the design draws, in order', () => {
    expect(smileIDSampleNavRows.map((row) => row.id)).toEqual([
      'documentation',
      'support',
      'terms',
      'privacy',
      'licenses',
    ]);
  });
});
