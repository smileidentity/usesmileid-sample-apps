import { ScrollView, StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { UseSmileIDSampleButton } from '../components/use-smile-id-sample-button';
import { UseSmileIDSampleFloatingTokenButton } from '../components/use-smile-id-sample-floating-token-button';
import { UseSmileIDSampleIcon } from '../components/use-smile-id-sample-icon';
import { UseSmileIDSampleSectionLabel } from '../components/use-smile-id-sample-section-label';
import {
  UseSmileIDSampleSelectTrigger,
  UseSmileIDSampleTriggerEmoji,
} from '../components/use-smile-id-sample-select-trigger';
import { UseSmileIDSampleTextInput } from '../components/use-smile-id-sample-text-input';
import { UseSmileIDSampleTopAppBar } from '../components/use-smile-id-sample-top-app-bar';
import {
  smileIDSampleIdDetailsComplete,
  type UseSmileIDSampleIdDetails,
} from '../state/use-smile-id-sample-id-details';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import { UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';

/// The picker's leading mark before a country is chosen.
const GLOBE_EMOJI = '🌍';

/// Everything the ID-details form renders; callbacks stay parameters, like every screen.
export type UseSmileIDSampleKycIdFormState = {
  readonly productLabel: string;
  readonly details: UseSmileIDSampleIdDetails;
};

type Props = {
  state: UseSmileIDSampleKycIdFormState;
  onCountryPress: () => void;
  onIdTypePress: () => void;
  onIdNumberChange: (value: string) => void;
  onBack: () => void;
  onContinue: () => void;
  onTokenPress: () => void;
};

/// The ID-details form. ID type is disabled until a country is chosen, because the types depend on it.
export const KycIdFormScreen = ({
  state,
  onCountryPress,
  onIdTypePress,
  onIdNumberChange,
  onBack,
  onContinue,
  onTokenPress,
}: Props) => {
  const theme = useSmileIDSampleTheme();
  const insets = useSafeAreaInsets();
  const { country, idType, idNumber } = state.details;

  return (
    <View
      testID={UseSmileIDSampleTestIds.KYC_FORM_SCREEN}
      style={[styles.screen, { backgroundColor: theme.colors.background }]}
    >
      <UseSmileIDSampleTopAppBar title={state.productLabel} onBack={onBack} />
      <View style={styles.body}>
        <ScrollView
          contentContainerStyle={{
            paddingBottom: theme.dimens.spacing.lg,
            paddingHorizontal: theme.dimens.spacing.md,
            rowGap: theme.dimens.spacing.sm,
          }}
        >
          <UseSmileIDSampleSectionLabel text="COUNTRY" />
          <UseSmileIDSampleSelectTrigger
            value={country?.label ?? null}
            placeholder="Select country"
            onPress={onCountryPress}
            testID={UseSmileIDSampleTestIds.COUNTRY_TRIGGER}
            // The design leads with the chosen country's flag, falling back to a globe.
            leading={() => <UseSmileIDSampleTriggerEmoji emoji={country?.flag ?? GLOBE_EMOJI} />}
          />
          <UseSmileIDSampleSectionLabel text="ID TYPE" />
          <UseSmileIDSampleSelectTrigger
            value={idType?.label ?? null}
            placeholder={country === null ? 'Choose a country first' : 'Select ID type'}
            onPress={onIdTypePress}
            enabled={country !== null}
            testID={UseSmileIDSampleTestIds.ID_TYPE_TRIGGER}
            leading={(tint) => <UseSmileIDSampleIcon name="biometricKyc" tint={tint} />}
          />
          <UseSmileIDSampleSectionLabel text="ID NUMBER" />
          <UseSmileIDSampleTextInput
            value={idNumber}
            onValueChange={onIdNumberChange}
            placeholder="Enter ID number"
            autoCapitalize="characters"
            testID={UseSmileIDSampleTestIds.ID_NUMBER_INPUT}
          />
        </ScrollView>
        <UseSmileIDSampleFloatingTokenButton
          onPress={onTokenPress}
          style={[styles.token, { bottom: theme.dimens.spacing.md, right: theme.dimens.spacing.md }]}
        />
      </View>
      <UseSmileIDSampleButton
        text="Continue"
        onPress={onContinue}
        enabled={smileIDSampleIdDetailsComplete(state.details)}
        testID={UseSmileIDSampleTestIds.KYC_CONTINUE}
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
  body: { flexGrow: 1, flexShrink: 1 },
  token: { position: 'absolute' },
});
