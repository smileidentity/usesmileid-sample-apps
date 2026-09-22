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
import type { UseSmileIDSampleUserDetails } from '../state/use-smile-id-sample-profiles';
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
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import { atSize, atWeight } from '../theme/smile-type';
import {
  UseSmileIDSampleSuffixedTestIds,
  UseSmileIDSampleTestIds,
} from '../use-smile-id-sample-test-ids';

/// The switch line sits between the type scale's steps — spec/screens.json → userDetails.
const REMEMBER_TEXT_SIZE = 13.5;

/// Shown when a token supplied the row, which is why it is not asked for again.
const PROVIDED_BY_TOKEN = 'Provided by token';

/// Everything the Consent Details Form renders; callbacks stay parameters, like every screen.
export type UseSmileIDSampleUserDetailsState = {
  readonly productLabel: string;
  readonly details: UseSmileIDSampleUserDetails;
  readonly rememberDetails: boolean;
  /// What is still outstanding once the token's own bindings are taken off the SDK's rule.
  readonly requirement?: UseSmileIDSampleUserDetailsRequirement;
};

type Props = {
  state: UseSmileIDSampleUserDetailsState;
  onFieldChange: (field: UseSmileIDSampleUserField, value: string) => void;
  onRememberChange: (enabled: boolean) => void;
  onBack: () => void;
  onContinue: () => void;
};

/// The Consent Details Form, shown for every product ahead of the SDK flow.
export const UserDetailsScreen = ({
  state,
  onFieldChange,
  onRememberChange,
  onBack,
  onContinue,
}: Props) => {
  const theme = useSmileIDSampleTheme();
  const insets = useSafeAreaInsets();
  const requirement = state.requirement ?? smileIDSampleRequirementDefaults;
  const satisfied = smileIDSampleDetailsSatisfy(state.details, requirement);

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
        <UseSmileIDSampleSectionSurface
          label="YOUR DETAILS"
          style={{ marginHorizontal: theme.dimens.spacing.md }}
        >
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
        {/* Only once the details are worth remembering, which is how the design shows it. */}
        {satisfied ? (
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
                // Compose draws the stroke over the padding; here it sits inside the box, so it comes off the padding.
                paddingBottom: theme.dimens.spacing.sm - smileCardStrokeWidth,
                paddingLeft: theme.dimens.spacing.md - smileCardStrokeWidth,
                paddingRight: theme.dimens.spacing.sm - smileCardStrokeWidth,
                paddingTop: theme.dimens.spacing.sm - smileCardStrokeWidth,
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
              Remember these details for next time
            </Text>
            <UseSmileIDSampleSwitch
              checked={state.rememberDetails}
              onCheckedChange={onRememberChange}
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
