import { ScrollView, StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { UseSmileIDSampleButton } from '../components/use-smile-id-sample-button';
import { smileIDSampleConfirm } from '../components/use-smile-id-sample-confirmation';
import { UseSmileIDSampleKeyValueEditRow } from '../components/use-smile-id-sample-key-value-edit-row';
import { UseSmileIDSampleSectionLabel } from '../components/use-smile-id-sample-section-label';
import {
  UseSmileIDSampleRowDivider,
  UseSmileIDSampleSectionSurface,
} from '../components/use-smile-id-sample-section-surface';
import { UseSmileIDSampleDestructiveRow } from '../components/use-smile-id-sample-setting-row';
import { UseSmileIDSampleTopAppBar } from '../components/use-smile-id-sample-top-app-bar';
import type { UseSmileIDSampleUserDetails } from '../state/use-smile-id-sample-profiles';
import {
  smileIDSampleUserFieldRead,
  smileIDSampleUserFields,
  type UseSmileIDSampleUserField,
} from '../model/use-smile-id-sample-user-fields';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import {
  UseSmileIDSampleSuffixedTestIds,
  UseSmileIDSampleTestIds,
} from '../use-smile-id-sample-test-ids';

/// The design's gap between the header, the label, the card and the CTA — not the 8 used inside a card.
const SECTION_GAP = 14;

/// Everything the profile configuration renders; callbacks stay parameters, like every screen.
export type UseSmileIDSampleProfileConfigState = {
  /// The app bar title: the saved profile's, so it does not change as the name is typed.
  readonly title?: string;
  /// The organisation as edited so far, which the SDK's consent screen names as the partner.
  readonly organisation: string;
  readonly defaults: UseSmileIDSampleUserDetails;
  readonly isActive: boolean;
  /// Whether anything differs from what is stored, which is all the active profile's Save can act on.
  readonly changed?: boolean;
  /// The webhook URL as edited so far; empty means the partner's portal default.
  readonly callbackUrl: string;
  /// Non-null while a token session is live: its text replaces the value, and the row stops editing.
  readonly callbackOverride: string | null;
};

type Props = {
  state: UseSmileIDSampleProfileConfigState;
  onFieldChange: (field: UseSmileIDSampleUserField, value: string) => void;
  onCallbackUrlChange: (value: string) => void;
  onOrganisationChange?: (value: string) => void;
  onBack: () => void;
  onSave: () => void;
  /// Deletes the profile once confirmed; absent hides the row.
  onDelete?: () => void;
};

/// A profile's name and user-details defaults, which is what seeds the Consent Details Form for its jobs.
export const ProfileConfigScreen = ({
  state,
  onFieldChange,
  onCallbackUrlChange,
  onOrganisationChange,
  onBack,
  onSave,
  onDelete,
}: Props) => {
  const theme = useSmileIDSampleTheme();
  const insets = useSafeAreaInsets();

  return (
    <View
      testID={UseSmileIDSampleTestIds.PROFILE_CONFIG_SCREEN}
      style={[styles.screen, { backgroundColor: theme.colors.background }]}
    >
      <UseSmileIDSampleTopAppBar title={state.title ?? state.organisation} onBack={onBack} />
      <ScrollView
        contentContainerStyle={{
          paddingBottom: theme.dimens.spacing.lg,
          paddingHorizontal: theme.dimens.spacing.md,
          rowGap: SECTION_GAP,
        }}
      >
        <UseSmileIDSampleSectionLabel text="PROFILE" />
        <UseSmileIDSampleSectionSurface>
          <UseSmileIDSampleKeyValueEditRow
            label="Organisation"
            value={state.organisation}
            onValueChange={(value) => onOrganisationChange?.(value)}
            placeholder="Shown on the consent screen"
            testID={UseSmileIDSampleTestIds.PROFILE_CONFIG_NAME}
          />
        </UseSmileIDSampleSectionSurface>
        {/* The label stays here: SECTION_GAP, not the surface's own spacing, separates it from the card. */}
        <UseSmileIDSampleSectionLabel text="USER DETAILS — ATTACHED TO EVERY JOB" />
        <UseSmileIDSampleSectionSurface>
          {smileIDSampleUserFields.map((field, index) => (
            <View key={field.id}>
              {index > 0 ? <UseSmileIDSampleRowDivider /> : null}
              <UseSmileIDSampleKeyValueEditRow
                label={field.label}
                value={smileIDSampleUserFieldRead(field.id, state.defaults)}
                onValueChange={(value) => onFieldChange(field.id, value)}
                placeholder={field.placeholder}
                required={field.required}
                testID={UseSmileIDSampleSuffixedTestIds.profileConfigField(field.id)}
              />
            </View>
          ))}
        </UseSmileIDSampleSectionSurface>
        {/* Its own section, not a row in the card above: a webhook URL is not a user detail. */}
        <UseSmileIDSampleSectionLabel text="CALLBACK URL" />
        <UseSmileIDSampleSectionSurface>
          <UseSmileIDSampleKeyValueEditRow
            label="Webhook URL"
            value={state.callbackOverride === null ? state.callbackUrl : ''}
            onValueChange={onCallbackUrlChange}
            placeholder={state.callbackOverride ?? 'Uses your portal default'}
            enabled={state.callbackOverride === null}
            keyboardType="url"
            testID={UseSmileIDSampleTestIds.PROFILE_CONFIG_CALLBACK_URL}
          />
        </UseSmileIDSampleSectionSurface>
        {onDelete === undefined ? null : (
          <UseSmileIDSampleDestructiveRow
            text="Delete profile"
            onPress={() =>
              smileIDSampleConfirm({
                title: `Delete ${state.title ?? state.organisation}?`,
                message: 'Its details and callback URL are removed from this device.',
                confirmLabel: 'Delete',
                onConfirm: onDelete,
              })
            }
            testID={UseSmileIDSampleTestIds.PROFILE_CONFIG_DELETE}
          />
        )}
      </ScrollView>
      <UseSmileIDSampleButton
        // One slot, as the design has it: the active profile saves its edits, any other also becomes active.
        text={state.isActive ? 'Save changes' : 'Use this profile'}
        onPress={onSave}
        enabled={(state.changed ?? false) || !state.isActive}
        testID={UseSmileIDSampleTestIds.PROFILE_CONFIG_SAVE}
        style={{
          marginBottom: insets.bottom + theme.dimens.spacing.md,
          marginHorizontal: theme.dimens.spacing.md,
          marginTop: theme.dimens.spacing.md,
        }}
      />
    </View>
  );
};

const styles = StyleSheet.create({ screen: { flex: 1 } });
