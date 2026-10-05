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
  smileIDSampleCaptureAsTriggerText,
  smileIDSampleFlag,
  smileIDSampleIdDetailsCaptureAs,
  smileIDSampleIdDetailsComplete,
  type UseSmileIDSampleCatalogueFamily,
  type UseSmileIDSampleIdDetails,
} from '../state/use-smile-id-sample-id-details';
import {
  smileIDSampleIdNumberError,
  smileIDSampleIdNumberPlaceholder,
} from '../state/use-smile-id-sample-id-number-hint';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import { UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { type UseSmileIDSampleStrings } from '../use-smile-id-sample-strings';
import { useSmileIDSampleStrings } from '../use-smile-id-sample-strings-context';

/// The picker's leading mark before a country is chosen.
const GLOBE_EMOJI = '🌍';

/// Everything the ID-details form renders; callbacks stay parameters, like every screen.
export type UseSmileIDSampleKycIdFormState = {
  readonly productLabel: string;
  readonly family: UseSmileIDSampleCatalogueFamily;
  readonly details: UseSmileIDSampleIdDetails;
  /// Whether the chosen country's list is still arriving, which the second trigger says.
  readonly countryListLoading: boolean;
};

type Props = {
  state: UseSmileIDSampleKycIdFormState;
  onCountryPress: () => void;
  onIdTypePress: () => void;
  onDocumentPress: () => void;
  onCaptureAsPress: () => void;
  onIdNumberChange: (value: string) => void;
  onBack: () => void;
  onContinue: () => void;
  onTokenPress: () => void;
};

/// Enabled while loading, with "Loading…" in place of the prompt, so the form never looks stuck.
const secondPlaceholder = (
  state: UseSmileIDSampleKycIdFormState,
  strings: UseSmileIDSampleStrings,
  loading: string,
  ready: string,
): string => {
  if (state.details.country === null) return strings.kycChooseCountryFirst;
  return state.countryListLoading ? loading : ready;
};

/// The ID-details form: an ID type and number for KYC, a document and how to capture it otherwise.
export const KycIdFormScreen = ({
  state,
  onCountryPress,
  onIdTypePress,
  onDocumentPress,
  onCaptureAsPress,
  onIdNumberChange,
  onBack,
  onContinue,
  onTokenPress,
}: Props) => {
  const strings = useSmileIDSampleStrings();
  const theme = useSmileIDSampleTheme();
  const insets = useSafeAreaInsets();
  const { country, idType, document, idNumber } = state.details;
  const numberError = smileIDSampleIdNumberError(idType, idNumber, strings);
  const captureAsLabel =
    document === null
      ? null
      : smileIDSampleCaptureAsTriggerText(smileIDSampleIdDetailsCaptureAs(state.details), strings);

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
          <UseSmileIDSampleSectionLabel text={strings.kycCountry} />
          <UseSmileIDSampleSelectTrigger
            value={country?.name ?? null}
            placeholder={strings.kycSelectCountry}
            onPress={onCountryPress}
            testID={UseSmileIDSampleTestIds.COUNTRY_TRIGGER}
            // The design leads with the chosen country's flag, falling back to a globe.
            leading={() => (
              <UseSmileIDSampleTriggerEmoji emoji={country ? smileIDSampleFlag(country.code) : GLOBE_EMOJI} />
            )}
          />
          {state.family === 'kyc' ? (
            <>
              <UseSmileIDSampleSectionLabel text={strings.kycIdType} />
              <UseSmileIDSampleSelectTrigger
                value={idType?.label ?? null}
                placeholder={secondPlaceholder(state, strings, strings.kycLoadingIdTypes, strings.kycSelectIdType)}
                onPress={onIdTypePress}
                enabled={country !== null}
                testID={UseSmileIDSampleTestIds.ID_TYPE_TRIGGER}
                leading={(tint) => <UseSmileIDSampleIcon name="biometricKyc" tint={tint} />}
              />
              <UseSmileIDSampleSectionLabel text={strings.kycIdNumber} />
              <UseSmileIDSampleTextInput
                value={idNumber}
                onValueChange={onIdNumberChange}
                placeholder={smileIDSampleIdNumberPlaceholder(idType, strings)}
                enabled={idType !== null}
                isError={numberError !== null}
                errorMessage={numberError}
                autoCapitalize="characters"
                testID={UseSmileIDSampleTestIds.ID_NUMBER_INPUT}
                errorTestID={UseSmileIDSampleTestIds.ID_NUMBER_ERROR}
              />
            </>
          ) : state.family === 'document' ? (
            <>
              <UseSmileIDSampleSectionLabel text={strings.kycDocument} />
              <UseSmileIDSampleSelectTrigger
                value={document?.name ?? null}
                placeholder={secondPlaceholder(state, strings, strings.kycLoadingDocuments, strings.kycSelectDocument)}
                onPress={onDocumentPress}
                enabled={country !== null}
                testID={UseSmileIDSampleTestIds.DOCUMENT_TRIGGER}
                leading={(tint) => <UseSmileIDSampleIcon name="documentVerification" tint={tint} />}
              />
              <UseSmileIDSampleSectionLabel text={strings.kycCaptureAs} />
              <UseSmileIDSampleSelectTrigger
                value={captureAsLabel}
                placeholder={strings.captureAsMatchDocument}
                onPress={onCaptureAsPress}
                enabled={document !== null}
                testID={UseSmileIDSampleTestIds.CAPTURE_AS_TRIGGER}
                leading={(tint) => <UseSmileIDSampleIcon name="preview" tint={tint} />}
              />
            </>
          ) : null}
        </ScrollView>
        <UseSmileIDSampleFloatingTokenButton
          onPress={onTokenPress}
          style={[styles.token, { bottom: theme.dimens.spacing.md, right: theme.dimens.spacing.md }]}
        />
      </View>
      <UseSmileIDSampleButton
        text={strings.commonContinue}
        onPress={onContinue}
        enabled={smileIDSampleIdDetailsComplete(state.details, state.family)}
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
