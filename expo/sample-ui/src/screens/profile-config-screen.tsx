import { ScrollView, StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { UseSmileIDSampleButton } from '../components/use-smile-id-sample-button';
import { UseSmileIDSampleKeyValueEditRow } from '../components/use-smile-id-sample-key-value-edit-row';
import { UseSmileIDSampleSectionLabel } from '../components/use-smile-id-sample-section-label';
import {
  UseSmileIDSampleRowDivider,
  UseSmileIDSampleSectionSurface,
} from '../components/use-smile-id-sample-section-surface';
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
  /// The app bar title is the profile's name, which is why the screen takes it rather than an id.
  readonly organisation: string;
  readonly defaults: UseSmileIDSampleUserDetails;
  readonly isActive: boolean;
};

type Props = {
  state: UseSmileIDSampleProfileConfigState;
  onFieldChange: (field: UseSmileIDSampleUserField, value: string) => void;
  onBack: () => void;
  onSave: () => void;
};

/// A profile's user-details defaults, which is what seeds the Consent Details Form for its jobs.
export const ProfileConfigScreen = ({ state, onFieldChange, onBack, onSave }: Props) => {
  const theme = useSmileIDSampleTheme();
  const insets = useSafeAreaInsets();

  return (
    <View
      testID={UseSmileIDSampleTestIds.PROFILE_CONFIG_SCREEN}
      style={[styles.screen, { backgroundColor: theme.colors.background }]}
    >
      <UseSmileIDSampleTopAppBar title={state.organisation} onBack={onBack} />
      <ScrollView
        contentContainerStyle={{
          paddingBottom: theme.dimens.spacing.lg,
          paddingHorizontal: theme.dimens.spacing.md,
          rowGap: SECTION_GAP,
        }}
      >
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
      </ScrollView>
      <UseSmileIDSampleButton
        // The design disables it on the profile that is already active, and says so.
        text={state.isActive ? 'Active profile' : 'Make this profile active'}
        onPress={onSave}
        enabled={!state.isActive}
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
