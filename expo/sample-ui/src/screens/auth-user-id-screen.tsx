import { PixelRatio, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { UseSmileIDSampleButton } from '../components/use-smile-id-sample-button';
import { UseSmileIDSampleProductTile } from '../components/use-smile-id-sample-job-row';
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
import { useSmileIDSampleStrings } from '../use-smile-id-sample-strings-context';

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
  const times = smileIDSampleTimeLabels(state.previousUsers);
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
            <Card onPress={onRegister} testID={UseSmileIDSampleTestIds.AUTH_USER_ID_REGISTER} role="button">
              <UseSmileIDSampleProductTile product={ENROLLMENT} />
              <Text style={[theme.type.textStyleBodyStrong, styles.grow, { color: theme.colors.card.title }]}>
                {smileIDSampleProductTitle(ENROLLMENT, strings)}
              </Text>
              <UseSmileIDSampleSettingRowChevron />
            </Card>
          </>
        ) : (
          <>
            <ListSection label={strings.authUserIdPrevious} hint={strings.authUserIdPreviousHint} />
            <View style={{ rowGap: theme.dimens.spacing.xs }}>
              {state.previousUsers.map((job, index) => (
                <PreviousUserCard
                  key={job.userId}
                  job={job}
                  time={times[job.id] ?? ''}
                  latest={index === 0}
                  selected={job.userId === chosen}
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

/// An earlier user, laid out like a verifications row.
const PreviousUserCard = ({
  job,
  time,
  latest,
  selected,
  onPress,
  testID,
}: {
  job: UseSmileIDSampleJob;
  time: string;
  latest: boolean;
  selected: boolean;
  onPress: () => void;
  testID: string;
}) => {
  const theme = useSmileIDSampleTheme();
  const strings = useSmileIDSampleStrings();
  const stacks = PixelRatio.getFontScale() > 1;
  const lines = stacks ? undefined : 1;
  const pill = (
    <UseSmileIDSamplePill
      label={strings.authUserIdLatest}
      background={theme.colors.badge.infoBackground}
      foreground={theme.colors.badge.infoText}
      style={stacks ? styles.start : null}
    />
  );
  return (
    <Card onPress={onPress} testID={testID} role="radio" selected={selected}>
      <UseSmileIDSampleProductTile product={job.product} />
      <View style={[styles.grow, { rowGap: theme.dimens.spacing.xxs }]}>
        <Text numberOfLines={lines} style={[theme.type.textStyleBodyStrong, { color: theme.colors.card.title }]}>
          {smileIDSampleProductTitle(job.product, strings)}
        </Text>
        <Text numberOfLines={lines} style={[theme.type.textStyleCaption, { color: theme.colors.textMuted }]}>
          {`${smileIDSampleJobMiddleUserId(job)} · ${time}`}
        </Text>
        {latest && stacks ? pill : null}
      </View>
      {latest && !stacks ? pill : null}
    </Card>
  );
};

/// The verifications row's card; padding absorbs the thicker selected border.
const Card = ({
  onPress,
  testID,
  role,
  selected = false,
  children,
}: {
  onPress: () => void;
  testID: string;
  role: 'button' | 'radio';
  selected?: boolean;
  children: React.ReactNode;
}) => {
  const theme = useSmileIDSampleTheme();
  const border = selected ? theme.dimens.borderWidth.thin : smileCardStrokeWidth;
  return (
    <Pressable
      accessibilityRole={role}
      accessibilityState={role === 'radio' ? { selected } : undefined}
      onPress={onPress}
      testID={testID}
      style={[
        styles.card,
        {
          borderRadius: theme.shapes.card,
          backgroundColor: theme.colors.card.background,
          borderWidth: border,
          borderColor: selected ? theme.colors.primary : theme.colors.cardStroke,
          minHeight: theme.dimens.space[64],
          padding: theme.dimens.spacing.sm - (border - smileCardStrokeWidth),
          columnGap: theme.dimens.spacing.sm,
        },
      ]}
    >
      {children}
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
  start: { alignSelf: 'flex-start' },
});
