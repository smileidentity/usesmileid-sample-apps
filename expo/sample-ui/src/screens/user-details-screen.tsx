import { ScrollView, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { UseSmileIDSampleButton } from '../components/use-smile-id-sample-button';
import { UseSmileIDSampleKeyValueEditRow } from '../components/use-smile-id-sample-key-value-edit-row';
import {
  UseSmileIDSampleRowDivider,
  UseSmileIDSampleSectionSurface,
} from '../components/use-smile-id-sample-section-surface';
import { UseSmileIDSampleSwitch } from '../components/use-smile-id-sample-switch';
import { UseSmileIDSampleTopAppBar } from '../components/use-smile-id-sample-top-app-bar';
import { avatarColorForProfile } from '../components/use-smile-id-sample-avatar';
import { UseSmileIDSampleIcon } from '../components/use-smile-id-sample-icon';
import { UseSmileIDSampleProfileRow } from '../components/use-smile-id-sample-profile-row';
import {
  USE_SMILE_ID_SAMPLE_NO_PROFILE_LABEL,
  smileIDSampleProfileInitials,
  smileIDSampleProfileTitle,
  smileIDSampleUserDetailsEqual,
  type UseSmileIDSampleProfile,
  type UseSmileIDSampleUserDetails,
} from '../state/use-smile-id-sample-profiles';
import {
  smileIDSampleDetailsSatisfy,
  smileIDSampleRequirementDefaults,
  smileIDSampleRequirementLabel,
  smileIDSampleRequirementPrompt,
  smileIDSampleRequirementSupplies,
  type UseSmileIDSampleUserDetailsRequirement,
} from '../state/use-smile-id-sample-user-details-requirement';
import {
  smileIDSampleUserFieldRead,
  smileIDSampleUserFields,
  type UseSmileIDSampleUserField,
} from '../model/use-smile-id-sample-user-fields';
import { smileCardStrokeWidth } from '../smile-product-hues';
import { insetForBorder } from '../theme/smile-compose-layout';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import { atSize, atWeight } from '../theme/smile-type';
import {
  UseSmileIDSampleSuffixedTestIds,
  UseSmileIDSampleTestIds,
} from '../use-smile-id-sample-test-ids';

/// The switch line sits between the type scale's steps — spec/screens.json → userDetails.
const REMEMBER_TEXT_SIZE = 13.5;

/// The profile row's chevron, the select trigger's size.
const CHEVRON_SIZE = 12;

/// The organisation row's id suffix, beside the four user fields'.
export const ORGANISATION_FIELD_ID = 'organisation';

/// Shown when a token supplied the row, which is why it is not asked for again.
const PROVIDED_BY_TOKEN = 'Provided by token';

/// Everything the Consent Details Form renders; callbacks stay parameters, like every screen.
export type UseSmileIDSampleUserDetailsState = {
  readonly productLabel: string;
  readonly details: UseSmileIDSampleUserDetails;
  /// Who this run is for; null while there is no profile, when the form offers to create one.
  readonly profile: UseSmileIDSampleProfile | null;
  readonly profileIndex?: number;
  /// Whether Continue keeps what was typed: into the profile, or as a new one when there is none.
  readonly saveToProfile: boolean;
  /// The new profile's name, asked only while there is no profile.
  readonly organisation?: string;
  /// What is still outstanding once the token's own bindings are taken off the SDK's rule.
  readonly requirement?: UseSmileIDSampleUserDetailsRequirement;
};

type Props = {
  state: UseSmileIDSampleUserDetailsState;
  onFieldChange: (field: UseSmileIDSampleUserField, value: string) => void;
  onSaveToProfileChange: (enabled: boolean) => void;
  onOrganisationChange?: (value: string) => void;
  onProfilePress: () => void;
  onBack: () => void;
  onContinue: () => void;
};

/// The Consent Details Form, shown for every product ahead of the SDK flow.
export const UserDetailsScreen = ({
  state,
  onFieldChange,
  onSaveToProfileChange,
  onOrganisationChange,
  onProfilePress,
  onBack,
  onContinue,
}: Props) => {
  const theme = useSmileIDSampleTheme();
  const insets = useSafeAreaInsets();
  const requirement = state.requirement ?? smileIDSampleRequirementDefaults;
  const satisfied = smileIDSampleDetailsSatisfy(state.details, requirement);
  const { profile } = state;
  // Only once there is something to keep: valid details that no profile holds yet.
  const offersSave =
    satisfied &&
    (profile === null || !smileIDSampleUserDetailsEqual(state.details, profile.defaults));

  return (
    <View
      testID={UseSmileIDSampleTestIds.USER_DETAILS_SCREEN}
      style={[styles.screen, { backgroundColor: theme.colors.background }]}
    >
      <UseSmileIDSampleTopAppBar title={state.productLabel} onBack={onBack} />
      <ScrollView
        contentContainerStyle={{
          paddingBottom: theme.dimens.spacing.lg,
          rowGap: theme.dimens.spacing.xs,
        }}
      >
        {/* Says whose details these are, and switches in one tap: the whole reason profiles exist. */}
        <UseSmileIDSampleProfileRow
          organisation={profile === null ? USE_SMILE_ID_SAMPLE_NO_PROFILE_LABEL : smileIDSampleProfileTitle(profile)}
          supportingText={profile === null ? 'Your details below will create one' : 'Tap to switch profile'}
          initials={profile === null ? '' : smileIDSampleProfileInitials(profile)}
          selected={false}
          onPress={onProfilePress}
          avatarColor={avatarColorForProfile(state.profileIndex ?? 0)}
          testID={UseSmileIDSampleTestIds.USER_DETAILS_PROFILE}
          trailing={<UseSmileIDSampleIcon name="chevronDown" tint={theme.colors.textMuted} size={CHEVRON_SIZE} />}
          style={{ marginHorizontal: theme.dimens.spacing.md }}
        />
        <UseSmileIDSampleSectionSurface
          label="YOUR DETAILS"
          style={{ marginHorizontal: theme.dimens.spacing.md }}
        >
          {profile === null ? (
            <View>
              <UseSmileIDSampleKeyValueEditRow
                label="Organisation (optional)"
                value={state.organisation ?? ''}
                onValueChange={(value) => onOrganisationChange?.(value)}
                placeholder="Shown on the consent screen"
                required={false}
                testID={UseSmileIDSampleSuffixedTestIds.userDetailsField(ORGANISATION_FIELD_ID)}
              />
              <UseSmileIDSampleRowDivider />
            </View>
          ) : null}
          {smileIDSampleUserFields.map((field, index) => {
            // Shown as provided, not asked again — the value is vaulted, so it cannot be prefilled either.
            const supplied = smileIDSampleRequirementSupplies(requirement, field.id);
            return (
              <View key={field.id}>
                {index > 0 ? <UseSmileIDSampleRowDivider /> : null}
                <UseSmileIDSampleKeyValueEditRow
                  label={smileIDSampleRequirementLabel(requirement, field)}
                  value={supplied ? '' : smileIDSampleUserFieldRead(field.id, state.details)}
                  onValueChange={(value) => onFieldChange(field.id, value)}
                  placeholder={supplied ? PROVIDED_BY_TOKEN : field.placeholder}
                  required={false}
                  enabled={!supplied}
                  testID={UseSmileIDSampleSuffixedTestIds.userDetailsField(field.id)}
                />
              </View>
            );
          })}
        </UseSmileIDSampleSectionSurface>
        <Text
          testID={UseSmileIDSampleTestIds.USER_DETAILS_HINT}
          style={[
            theme.type.textStyleCaption,
            { color: theme.colors.textMuted, paddingHorizontal: theme.dimens.spacing.md },
          ]}
        >
          {satisfied ? 'Tap any field to edit.' : smileIDSampleRequirementPrompt(requirement)}
        </Text>
        {offersSave ? (
          <View
            style={[
              styles.rememberCard,
              {
                backgroundColor: theme.colors.surface,
                borderColor: theme.colors.cardStroke,
                borderRadius: theme.shapes.card,
                borderWidth: smileCardStrokeWidth,
                columnGap: theme.dimens.spacing.sm,
                marginHorizontal: theme.dimens.spacing.md,
                paddingBottom: insetForBorder(theme.dimens.spacing.sm, smileCardStrokeWidth),
                paddingLeft: insetForBorder(theme.dimens.spacing.md, smileCardStrokeWidth),
                paddingRight: insetForBorder(theme.dimens.spacing.sm, smileCardStrokeWidth),
                paddingTop: insetForBorder(theme.dimens.spacing.sm, smileCardStrokeWidth),
              },
            ]}
          >
            {/* One line of body text beside the switch: no icon and no supporting line, so not a SettingRow. */}
            <Text
              style={[
                atSize(atWeight(theme.type.textStyleSubtitle, 500), REMEMBER_TEXT_SIZE),
                styles.rememberText,
                { color: theme.colors.textBody },
              ]}
            >
              {profile === null ? 'Save as a new profile' : `Save to ${smileIDSampleProfileTitle(profile)}`}
            </Text>
            <UseSmileIDSampleSwitch
              checked={state.saveToProfile}
              onCheckedChange={onSaveToProfileChange}
              testID={UseSmileIDSampleTestIds.REMEMBER_DETAILS_SWITCH}
            />
          </View>
        ) : null}
      </ScrollView>
      <UseSmileIDSampleButton
        text="Continue"
        onPress={onContinue}
        enabled={satisfied}
        testID={UseSmileIDSampleTestIds.USER_DETAILS_CONTINUE}
        style={{
          marginBottom: insets.bottom + theme.dimens.spacing.md,
          marginHorizontal: theme.dimens.spacing.md,
          marginTop: theme.dimens.spacing.md,
        }}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  screen: { flex: 1 },
  rememberCard: { alignItems: 'center', flexDirection: 'row' },
  rememberText: { flexGrow: 1, flexShrink: 1 },
});
