import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { UseSmileIDSampleButton } from '../components/use-smile-id-sample-button';
import { UseSmileIDSampleProductTile } from '../components/use-smile-id-sample-job-row';
import { UseSmileIDSampleOptionRow } from '../components/use-smile-id-sample-option-row';
import { UseSmileIDSampleTextInput } from '../components/use-smile-id-sample-text-input';
import { UseSmileIDSampleTopAppBar } from '../components/use-smile-id-sample-top-app-bar';
import { smileIDSampleProductFrom, smileIDSampleProductTitle } from '../model/use-smile-id-sample-product';
import { smileCardStrokeWidth } from '../smile-product-hues';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import { UseSmileIDSampleSuffixedTestIds, UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { useSmileIDSampleStrings } from '../use-smile-id-sample-strings-context';

/// What the authentication user ID screen renders; callbacks stay parameters, like every screen.
export type UseSmileIDSampleAuthUserIdState = {
  readonly userId: string;
  /// Newest first; empty shows the way to enrol one instead.
  readonly previousUserIds: readonly string[];
};

type Props = {
  state: UseSmileIDSampleAuthUserIdState;
  onUserIdChange: (value: string) => void;
  onRegister: () => void;
  onBack: () => void;
  onContinue: () => void;
};

const AUTH = smileIDSampleProductFrom('smartSelfieAuth')!;
const ENROLLMENT = smileIDSampleProductFrom('smartSelfieEnrollment')!;

/// SmartSelfie Authentication's user ID: typed, or picked from earlier runs that enrolled one. Never made up, because the SDK authenticates only an enrolled user.
export const AuthUserIdScreen = ({ state, onUserIdChange, onRegister, onBack, onContinue }: Props) => {
  const theme = useSmileIDSampleTheme();
  const strings = useSmileIDSampleStrings();
  const insets = useSafeAreaInsets();
  const chosen = state.userId.trim();
  const heading = (text: string) => (
    <Text accessibilityRole="header" style={[theme.type.textStyleTitle, { color: theme.colors.textTitle }]}>
      {text}
    </Text>
  );
  const note = (text: string) => (
    <Text style={[theme.type.textStyleCaption, { color: theme.colors.textMuted, marginTop: theme.dimens.spacing.xxs }]}>
      {text}
    </Text>
  );
  const or = (
    <Text style={[theme.type.textStyleCaption, styles.or, { color: theme.colors.textMuted }]}>{strings.authUserIdOr}</Text>
  );
  const field = (
    <View style={{ rowGap: theme.dimens.spacing.xs }}>
      {heading(strings.authUserIdEnter)}
      <UseSmileIDSampleTextInput
        value={state.userId}
        onValueChange={onUserIdChange}
        placeholder={strings.authUserIdPlaceholder}
        autoCapitalize="none"
        autoCorrect={false}
        testID={UseSmileIDSampleTestIds.AUTH_USER_ID_INPUT}
      />
    </View>
  );
  return (
    <View
      testID={UseSmileIDSampleTestIds.AUTH_USER_ID_SCREEN}
      style={[styles.screen, { backgroundColor: theme.colors.background }]}
    >
      <UseSmileIDSampleTopAppBar title={smileIDSampleProductTitle(AUTH, strings)} onBack={onBack} />
      <ScrollView
        style={styles.body}
        contentContainerStyle={{
          paddingHorizontal: theme.dimens.spacing.md,
          paddingVertical: theme.dimens.spacing.lg,
          rowGap: theme.dimens.spacing.sm,
        }}
      >
        <View style={styles.center}>
          <UseSmileIDSampleProductTile product={AUTH} side={theme.dimens.space[64]} />
        </View>
        {state.previousUserIds.length === 0 ? (
          <>
            <View>
              {heading(strings.authUserIdEmptyTitle)}
              {note(strings.authUserIdPreviousBody)}
            </View>
            {heading(strings.authUserIdRun)}
            <Pressable
              accessibilityRole="button"
              onPress={onRegister}
              testID={UseSmileIDSampleTestIds.AUTH_USER_ID_REGISTER}
              style={[
                styles.card,
                {
                  borderRadius: theme.shapes.card,
                  backgroundColor: theme.colors.card.background,
                  borderWidth: smileCardStrokeWidth,
                  borderColor: theme.colors.cardStroke,
                  padding: theme.dimens.spacing.sm,
                  columnGap: theme.dimens.spacing.sm,
                },
              ]}
            >
              <UseSmileIDSampleProductTile product={ENROLLMENT} />
              <Text style={[theme.type.textStyleBodyStrong, styles.cardTitle, { color: theme.colors.card.title }]}>
                {smileIDSampleProductTitle(ENROLLMENT, strings)}
              </Text>
            </Pressable>
            {or}
            {field}
          </>
        ) : (
          <>
            {field}
            {or}
            <View>
              {heading(strings.authUserIdPrevious)}
              {note(strings.authUserIdPreviousBody)}
            </View>
            {state.previousUserIds.map((previous, index) => (
              <UseSmileIDSampleOptionRow
                key={previous}
                label={previous}
                selected={previous === chosen}
                onPress={() => onUserIdChange(previous)}
                testID={UseSmileIDSampleSuffixedTestIds.authUserIdOption(index)}
              />
            ))}
          </>
        )}
      </ScrollView>
      <UseSmileIDSampleButton
        text={strings.commonContinue}
        onPress={onContinue}
        enabled={chosen.length > 0}
        testID={UseSmileIDSampleTestIds.AUTH_USER_ID_CONTINUE}
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
  center: { alignItems: 'center' },
  card: { alignItems: 'center', flexDirection: 'row' },
  cardTitle: { flex: 1 },
  or: { textAlign: 'center' },
});
