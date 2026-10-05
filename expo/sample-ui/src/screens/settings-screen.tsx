import type { ReactNode } from 'react';
import { smileIDSampleConfirm } from '../components/use-smile-id-sample-confirmation';
import { ScrollView, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { UseSmileIDSampleIcon } from '../components/use-smile-id-sample-icon';
import { UseSmileIDSampleProfileRow } from '../components/use-smile-id-sample-profile-row';
import {
  UseSmileIDSampleRowDivider,
  UseSmileIDSampleSectionSurface,
} from '../components/use-smile-id-sample-section-surface';
import {
  UseSmileIDSampleDestructiveRow,
  UseSmileIDSampleSettingRow,
  UseSmileIDSampleSettingRowChevron,
} from '../components/use-smile-id-sample-setting-row';
import { UseSmileIDSampleSwitch } from '../components/use-smile-id-sample-switch';
import {
  smileIDSampleAboutRows,
  smileIDSampleLegalRows,
  type UseSmileIDSampleNavRow,
} from '../model/use-smile-id-sample-nav-row';
import { smileIDSampleAppearanceLabel } from '../model/use-smile-id-sample-appearance';
import { smileIDSampleLanguageLabel } from '../model/use-smile-id-sample-language';
import { smileIDSampleCaptureModeLabel } from '../model/use-smile-id-sample-capture-mode';
import { UseSmileIDSampleSetting } from '../model/use-smile-id-sample-setting';
import type { SmileIconName } from '../smile-icons';
import { smileProfileHues } from '../smile-product-hues';
import type { UseSmileIDSampleSettings } from '../state/use-smile-id-sample-settings';
import {
  UseSmileIDSampleSuffixedTestIds,
  UseSmileIDSampleTestIds,
} from '../use-smile-id-sample-test-ids';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import { useSmileIDSampleDeviceLanguages, useSmileIDSampleStrings } from '../use-smile-id-sample-strings-context';

/// Everything the settings list renders; callbacks stay parameters, like every screen.
export type UseSmileIDSampleSettingsState = {
  readonly settings: UseSmileIDSampleSettings;
  readonly organisation: string;
  readonly initials: string;
  /// Passed in because it names the host, and this package runs under eight identities.
  readonly versionLabel: string;
  /// The token has taken the consent decision away, so the switch stops claiming to own it.
  readonly consentBoundByToken?: boolean;
  readonly avatarColor?: string;
  /// False while there is no profile, when the card invites creating one.
  readonly hasProfile?: boolean;
  /// The device's own theme, which the System label names; the shell reads it where the app's choice cannot mask it.
  readonly deviceDark: boolean;
};

/// A labelled group of rows on one surface, which is how the design draws every settings section.
const Section = ({ label, children }: { label: string; children: ReactNode }) => {
  const theme = useSmileIDSampleTheme();
  return (
    <UseSmileIDSampleSectionSurface label={label} style={{ paddingHorizontal: theme.dimens.spacing.md }}>
      {children}
    </UseSmileIDSampleSectionSurface>
  );
};

type SwitchRowProps = {
  title: string;
  supportingText: string;
  icon: SmileIconName;
  setting: UseSmileIDSampleSetting;
  checked: boolean;
  testID: string;
  onSettingChange: (setting: UseSmileIDSampleSetting, enabled: boolean) => void;
};

const SwitchRow = ({
  title,
  supportingText,
  icon,
  setting,
  checked,
  testID,
  onSettingChange,
}: SwitchRowProps) => (
  <UseSmileIDSampleSettingRow
    title={title}
    supportingText={supportingText}
    leading={(tint) => <UseSmileIDSampleIcon name={icon} tint={tint} />}
    trailing={
      <UseSmileIDSampleSwitch
        checked={checked}
        onCheckedChange={(enabled) => onSettingChange(setting, enabled)}
        testID={testID}
      />
    }
  />
);

const NavRow = ({
  row,
  onPress,
}: {
  row: UseSmileIDSampleNavRow;
  onPress: (row: UseSmileIDSampleNavRow) => void;
}) => {
  const strings = useSmileIDSampleStrings();
  return (
    <UseSmileIDSampleSettingRow
      title={row.title(strings)}
      supportingText={row.supportingText?.(strings)}
      onPress={() => onPress(row)}
      leading={(tint) => <UseSmileIDSampleIcon name={row.icon} tint={tint} />}
      trailing={<UseSmileIDSampleSettingRowChevron />}
      testID={UseSmileIDSampleSuffixedTestIds.settingNav(row.id)}
    />
  );
};

const NavSection = ({
  label,
  rows,
  onPress,
}: {
  label: string;
  rows: readonly UseSmileIDSampleNavRow[];
  onPress: (row: UseSmileIDSampleNavRow) => void;
}) => (
  <Section label={label}>
    {rows.map((row, index) => (
      <View key={row.id}>
        {index > 0 ? <UseSmileIDSampleRowDivider /> : null}
        <NavRow row={row} onPress={onPress} />
      </View>
    ))}
  </Section>
);

type Props = {
  state: UseSmileIDSampleSettingsState;
  onSettingChange: (setting: UseSmileIDSampleSetting, enabled: boolean) => void;
  onProfilePress: () => void;
  onNavRowPress: (row: UseSmileIDSampleNavRow) => void;
  /// Opens the capture-mode sheet.
  onCaptureModePress: () => void;
  /// Opens the appearance sheet.
  onAppearancePress: () => void;
  onLanguagePress: () => void;
  /// Absent hides the DEBUG section: this package may not read a host's build type.
  onOpenScenarioDrawer?: (() => void) | undefined;
  onSignOut: () => void;
  /// Whatever draws over the list, which the floating nav bar does.
  bottomInset?: number;
  style?: StyleProp<ViewStyle>;
};

/// Settings, which every other screen's configuration comes from.
export const SettingsScreen = ({
  state,
  onSettingChange,
  onProfilePress,
  onNavRowPress,
  onCaptureModePress,
  onAppearancePress,
  onLanguagePress,
  onOpenScenarioDrawer,
  onSignOut,
  bottomInset = 0,
  style,
}: Props) => {
  const strings = useSmileIDSampleStrings();
  const deviceLanguages = useSmileIDSampleDeviceLanguages();
  const theme = useSmileIDSampleTheme();
  const insets = useSafeAreaInsets();
  const { settings } = state;

  return (
    <ScrollView
      testID={UseSmileIDSampleTestIds.SETTINGS_SCREEN}
      style={[styles.screen, { backgroundColor: theme.colors.background }, style]}
      contentContainerStyle={{
        paddingTop: insets.top,
        paddingBottom: bottomInset,
        rowGap: theme.dimens.spacing.xs,
      }}
    >
      <Text
        style={[
          theme.type.textStyleHeadingPage,
          {
            color: theme.colors.textTitle,
            paddingHorizontal: theme.dimens.spacing.md,
            paddingVertical: theme.dimens.spacing.xs,
          },
        ]}
      >
        {strings.settingsTitle}
      </Text>

      <Section label={strings.settingsSectionProfile}>
        <UseSmileIDSampleProfileRow
          organisation={state.organisation}
          supportingText={state.hasProfile === false ? strings.settingsProfileCreate : strings.settingsProfileConfigure}
          initials={state.initials}
          selected={false}
          onPress={onProfilePress}
          avatarColor={state.avatarColor ?? smileProfileHues[0]}
          trailing={<UseSmileIDSampleSettingRowChevron />}
          testID={UseSmileIDSampleTestIds.PROFILE_SUMMARY}
        />
      </Section>

      {/* Mutually exclusive, so each row says what turning it on does to the other. */}
      <Section label={strings.settingsSectionCapture}>
        <SwitchRow
          title={strings.settingsEnhancedSmartSelfie}
          supportingText={settings.agentMode ? strings.settingsEnhancedSmartSelfieMutex : strings.settingsEnhancedSmartSelfieBody}
          icon="smile"
          setting={UseSmileIDSampleSetting.EnhancedSmartSelfie}
          checked={settings.enhancedSmartSelfie}
          testID={UseSmileIDSampleTestIds.SETTING_ENHANCED_SMART_SELFIE}
          onSettingChange={onSettingChange}
        />
        <UseSmileIDSampleRowDivider />
        <SwitchRow
          title={strings.settingsAgentMode}
          supportingText={
            settings.enhancedSmartSelfie
              ? strings.settingsAgentModeMutex({ setting: strings.settingsEnhancedSmartSelfie })
              : strings.settingsAgentModeBody
          }
          icon="agent"
          setting={UseSmileIDSampleSetting.AgentMode}
          checked={settings.agentMode}
          testID={UseSmileIDSampleTestIds.SETTING_AGENT_MODE}
          onSettingChange={onSettingChange}
        />
      </Section>

      <Section label={strings.settingsSectionAppearance}>
        <UseSmileIDSampleSettingRow
          title={strings.settingsTheme}
          supportingText={smileIDSampleAppearanceLabel(settings.appearance, state.deviceDark, strings)}
          onPress={onAppearancePress}
          leading={(tint) => <UseSmileIDSampleIcon name="darkMode" tint={tint} />}
          trailing={<UseSmileIDSampleSettingRowChevron />}
          testID={UseSmileIDSampleTestIds.SETTING_APPEARANCE}
        />
      </Section>

      <Section label={strings.settingsSectionLanguage}>
        <UseSmileIDSampleSettingRow
          title={strings.settingsLanguage}
          supportingText={smileIDSampleLanguageLabel(settings.language, strings, deviceLanguages)}
          onPress={onLanguagePress}
          leading={(tint) => <UseSmileIDSampleIcon name="settingLanguage" tint={tint} />}
          trailing={<UseSmileIDSampleSettingRowChevron />}
          testID={UseSmileIDSampleTestIds.SETTING_LANGUAGE}
        />
      </Section>

      <Section label={strings.settingsSectionSdkScreens}>
        <SwitchRow
          title={strings.settingsConsent}
          // A switch reading ON while the token has taken the decision away is a lie the screen tells.
          supportingText={
            state.consentBoundByToken === true
              ? strings.settingsConsentBound
              : strings.settingsConsentBody
          }
          icon="consent"
          setting={UseSmileIDSampleSetting.ConsentStep}
          checked={settings.consentStep}
          testID={UseSmileIDSampleTestIds.SETTING_CONSENT_STEP}
          onSettingChange={onSettingChange}
        />
        <UseSmileIDSampleRowDivider />
        <SwitchRow
          title={strings.settingsInstructions}
          supportingText={strings.settingsInstructionsBody}
          icon="instructions"
          setting={UseSmileIDSampleSetting.InstructionsStep}
          checked={settings.instructionsStep}
          testID={UseSmileIDSampleTestIds.SETTING_INSTRUCTIONS_STEP}
          onSettingChange={onSettingChange}
        />
        <UseSmileIDSampleRowDivider />
        <SwitchRow
          title={strings.settingsPreview}
          supportingText={strings.settingsPreviewBody}
          icon="preview"
          setting={UseSmileIDSampleSetting.PreviewStep}
          checked={settings.previewStep}
          testID={UseSmileIDSampleTestIds.SETTING_PREVIEW_STEP}
          onSettingChange={onSettingChange}
        />
      </Section>

      {/* The design draws no such section either; it sits with the other capture choices. */}
      <Section label={strings.settingsSectionDocumentCapture}>
        <UseSmileIDSampleSettingRow
          title={strings.settingsCaptureMode}
          supportingText={smileIDSampleCaptureModeLabel(settings.captureMode, strings)}
          onPress={onCaptureModePress}
          leading={(tint) => <UseSmileIDSampleIcon name="documentVerification" tint={tint} />}
          trailing={<UseSmileIDSampleSettingRowChevron />}
          testID={UseSmileIDSampleTestIds.SETTING_CAPTURE_MODE}
        />
        <UseSmileIDSampleRowDivider />
        <SwitchRow
          title={strings.settingsGalleryUpload}
          supportingText={strings.settingsGalleryUploadBody}
          icon="preview"
          setting={UseSmileIDSampleSetting.GalleryUpload}
          checked={settings.galleryUpload}
          testID={UseSmileIDSampleTestIds.SETTING_GALLERY_UPLOAD}
          onSettingChange={onSettingChange}
        />
        <UseSmileIDSampleRowDivider />
        <SwitchRow
          title={strings.settingsSkipBack}
          supportingText={strings.settingsSkipBackBody}
          icon="instructions"
          setting={UseSmileIDSampleSetting.AllowSkipBack}
          checked={settings.allowSkipBack}
          testID={UseSmileIDSampleTestIds.SETTING_ALLOW_SKIP_BACK}
          onSettingChange={onSettingChange}
        />
        <UseSmileIDSampleRowDivider />
        <SwitchRow
          title={strings.settingsSelfieFirst}
          supportingText={strings.settingsSelfieFirstBody}
          icon="smile"
          setting={UseSmileIDSampleSetting.SelfieFirst}
          checked={settings.selfieFirst}
          testID={UseSmileIDSampleTestIds.SETTING_SELFIE_FIRST}
          onSettingChange={onSettingChange}
        />
      </Section>

      {/* The design draws no control for the drawer, so this placement is ours, and debug-only. */}
      {onOpenScenarioDrawer ? (
        <Section label="DEBUG">
          <UseSmileIDSampleSettingRow
            title="Scenarios"
            supportingText="Choose how the environment misbehaves"
            onPress={onOpenScenarioDrawer}
            leading={(tint) => <UseSmileIDSampleIcon name="settingScenarios" tint={tint} />}
            trailing={<UseSmileIDSampleSettingRowChevron />}
            testID={UseSmileIDSampleTestIds.SCENARIO_DRAWER_BUTTON}
          />
        </Section>
      ) : null}

      <NavSection label={strings.settingsSectionAbout} rows={smileIDSampleAboutRows} onPress={onNavRowPress} />
      <NavSection label={strings.settingsSectionLegal} rows={smileIDSampleLegalRows} onPress={onNavRowPress} />

      <UseSmileIDSampleDestructiveRow
        text={strings.settingsSignOut}
        onPress={() =>
          smileIDSampleConfirm({
            cancelLabel: strings.commonCancel,
            title: strings.settingsSignOutTitle,
            message: strings.settingsSignOutBody,
            confirmLabel: strings.settingsSignOut,
            onConfirm: onSignOut,
          })
        }
        testID={UseSmileIDSampleTestIds.SIGN_OUT}
        style={{ marginHorizontal: theme.dimens.spacing.md }}
      />

      <Text
        testID={UseSmileIDSampleTestIds.VERSION_LABEL}
        style={[
          theme.type.textStyleCaption,
          styles.version,
          { color: theme.colors.textMuted, padding: theme.dimens.spacing.md },
        ]}
      >
        {state.versionLabel}
      </Text>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  screen: { flex: 1 },
  version: { textAlign: 'center', width: '100%' },
});
