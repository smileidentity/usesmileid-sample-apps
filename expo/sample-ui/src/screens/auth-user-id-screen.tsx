import { useMemo } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { UseSmileIDSampleButton } from '../components/use-smile-id-sample-button';
import { UseSmileIDSampleJobRow, UseSmileIDSampleProductTile } from '../components/use-smile-id-sample-job-row';
import { UseSmileIDSampleSectionLabel } from '../components/use-smile-id-sample-section-label';
import { UseSmileIDSampleSettingRowChevron } from '../components/use-smile-id-sample-setting-row';
import { UseSmileIDSamplePill } from '../components/use-smile-id-sample-status-badge';
import { UseSmileIDSampleTextInput } from '../components/use-smile-id-sample-text-input';
import { UseSmileIDSampleTopAppBar } from '../components/use-smile-id-sample-top-app-bar';
import { smileIDSampleJobMiddleUserId, type UseSmileIDSampleJob } from '../model/use-smile-id-sample-job';
import { smileIDSampleTimeLabels } from '../model/use-smile-id-sample-job-dates';
import { smileIDSampleProductFrom, smileIDSampleProductTitle } from '../model/use-smile-id-sample-product';
import { smileCardStrokeWidth, smileLabelSize, smileLabelTracking } from '../smile-product-hues';
import { atSize } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import { UseSmileIDSampleSuffixedTestIds, UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { useSmileIDSampleLanguageShown, useSmileIDSampleStrings } from '../use-smile-id-sample-strings-context';

/// What the authentication user ID screen renders; callbacks stay parameters, like every screen.
export type UseSmileIDSampleAuthUserIdState = {
  readonly userId: string;
  /// The newest run per enrolled user, newest first.
  readonly previousUsers: readonly UseSmileIDSampleJob[];
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
  const language = useSmileIDSampleLanguageShown();
  const times = useMemo(() => smileIDSampleTimeLabels(state.previousUsers, language), [state.previousUsers, language]);
  return (
    <View
      testID={UseSmileIDSampleTestIds.AUTH_USER_ID_SCREEN}
      style={[styles.screen, { backgroundColor: theme.colors.background }]}
    >
      <UseSmileIDSampleTopAppBar title={smileIDSampleProductTitle(AUTH, strings)} onBack={onBack} />
      <ScrollView
        style={styles.body}
        keyboardShouldPersistTaps="handled"
        contentContainerStyle={{
          paddingHorizontal: theme.dimens.spacing.md,
          paddingBottom: theme.dimens.spacing.sm,
          rowGap: theme.dimens.spacing.sm,
        }}
      >
        <UseSmileIDSampleSectionLabel text={strings.authUserIdSection} />
        <UseSmileIDSampleTextInput
          value={state.userId}
          onValueChange={onUserIdChange}
          placeholder={strings.authUserIdPlaceholder}
          autoCapitalize="none"
          autoCorrect={false}
          testID={UseSmileIDSampleTestIds.AUTH_USER_ID_INPUT}
        />
        <Caption text={strings.authUserIdHint} />
        <OrDivider />
        {state.previousUsers.length === 0 ? (
          <>
            <ListSection label={strings.authUserIdRun} hint={strings.authUserIdRunBody} />
            <EnrollmentCard onPress={onRegister} />
          </>
        ) : (
          <>
            <ListSection label={strings.authUserIdPrevious} hint={strings.authUserIdPreviousHint} />
            <View style={{ rowGap: theme.dimens.spacing.xs }}>
              {state.previousUsers.map((job, index) => (
                <UseSmileIDSampleJobRow
                  key={job.userId}
                  product={job.product}
                  jobId={smileIDSampleJobMiddleUserId(job)}
                  time={times[job.id] ?? ''}
                  status={null}
                  selected={job.userId === chosen}
                  trailing={index === 0 ? <LatestPill /> : null}
                  onPress={() => onUserIdChange(job.userId)}
                  testID={UseSmileIDSampleSuffixedTestIds.authUserIdOption(index)}
                />
              ))}
            </View>
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

/// The newest user's pill.
const LatestPill = () => {
  const theme = useSmileIDSampleTheme();
  const strings = useSmileIDSampleStrings();
  return (
    <UseSmileIDSamplePill
      label={strings.authUserIdLatest}
      background={theme.colors.badge.infoBackground}
      foreground={theme.colors.badge.infoText}
    />
  );
};

/// Starts SmartSelfie Enrollment, on the verifications row's card.
const EnrollmentCard = ({ onPress }: { onPress: () => void }) => {
  const theme = useSmileIDSampleTheme();
  const strings = useSmileIDSampleStrings();
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      testID={UseSmileIDSampleTestIds.AUTH_USER_ID_REGISTER}
      style={[
        styles.card,
        {
          borderRadius: theme.shapes.card,
          backgroundColor: theme.colors.card.background,
          borderWidth: smileCardStrokeWidth,
          borderColor: theme.colors.cardStroke,
          minHeight: theme.dimens.space[64],
          padding: theme.dimens.spacing.sm,
          columnGap: theme.dimens.spacing.sm,
        },
      ]}
    >
      <UseSmileIDSampleProductTile product={ENROLLMENT} />
      <Text style={[theme.type.textStyleBodyStrong, styles.grow, { color: theme.colors.card.title }]}>
        {smileIDSampleProductTitle(ENROLLMENT, strings)}
      </Text>
      <UseSmileIDSampleSettingRowChevron />
    </Pressable>
  );
};

/// A section label with its hint.
const ListSection = ({ label, hint }: { label: string; hint: string }) => {
  const theme = useSmileIDSampleTheme();
  return (
    <View style={{ rowGap: theme.dimens.spacing.xxs }}>
      <UseSmileIDSampleSectionLabel text={label} />
      <Caption text={hint} />
    </View>
  );
};

/// OR between two hairlines.
const OrDivider = () => {
  const theme = useSmileIDSampleTheme();
  const strings = useSmileIDSampleStrings();
  const hairline = <View style={[styles.grow, { height: smileCardStrokeWidth, backgroundColor: theme.colors.cardStroke }]} />;
  return (
    <View style={[styles.row, { columnGap: theme.dimens.spacing.sm, paddingVertical: theme.dimens.spacing.xs }]}>
      {hairline}
      <Text
        style={[
          atSize(theme.type.textStyleOverline, smileLabelSize),
          { letterSpacing: smileLabelTracking, color: theme.colors.textMuted },
        ]}
      >
        {strings.authUserIdOr}
      </Text>
      {hairline}
    </View>
  );
};

/// Muted supporting copy.
const Caption = ({ text }: { text: string }) => {
  const theme = useSmileIDSampleTheme();
  return <Text style={[theme.type.textStyleCaption, { color: theme.colors.textMuted }]}>{text}</Text>;
};

const styles = StyleSheet.create({
  screen: { flex: 1 },
  body: { flexGrow: 1, flexShrink: 1 },
  card: { alignItems: 'center', flexDirection: 'row', width: '100%' },
  row: { alignItems: 'center', flexDirection: 'row' },
  grow: { flex: 1 },
});
