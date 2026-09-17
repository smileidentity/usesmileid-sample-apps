import { RefreshControl, ScrollView, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import { UseSmileIDSampleDataFieldRow } from '../components/use-smile-id-sample-data-field-row';
import { UseSmileIDSampleEmptyState } from '../components/use-smile-id-sample-empty-state';
import { UseSmileIDSampleIcon } from '../components/use-smile-id-sample-icon';
import {
  UseSmileIDSampleRowDivider,
  UseSmileIDSampleSectionSurface,
} from '../components/use-smile-id-sample-section-surface';
import { UseSmileIDSampleStatusBadge } from '../components/use-smile-id-sample-status-badge';
import {
  UseSmileIDSampleTopAppBar,
  UseSmileIDSampleTopAppBarButton,
} from '../components/use-smile-id-sample-top-app-bar';
import {
  smileIDSampleCreatedAtLabel,
} from '../model/use-smile-id-sample-job-dates';
import {
  smileIDSampleHttpLabel,
  smileIDSampleJobShortId,
  smileIDSampleJobShortUserId,
  type UseSmileIDSampleJob,
} from '../model/use-smile-id-sample-job';
import {
  UseSmileIDSampleSuffixedTestIds,
  UseSmileIDSampleTestIds,
} from '../use-smile-id-sample-test-ids';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

/// Everything the details screen renders. `job` is null for a deep link naming a row this build has no copy of.
export type UseSmileIDSampleVerificationDetailsState = {
  readonly job: UseSmileIDSampleJob | null;
  /// The id the route asked for, which is the whole diagnostic when there is no row.
  readonly jobId: string;
  readonly refreshing: boolean;
  /// What the last refresh said, shown as the transient notice rather than stored on the row.
  readonly refreshNotice?: string | null;
};

type Props = {
  state: UseSmileIDSampleVerificationDetailsState;
  onBack: () => void;
  onDelete: () => void;
  onRefresh: () => void;
  onCopy: (field: string, value: string) => void;
  style?: StyleProp<ViewStyle>;
};

/// Verification details, which doubles as the result screen — which is why the result card belongs here.
export const VerificationDetailsScreen = ({
  state,
  onBack,
  onDelete,
  onRefresh,
  onCopy,
  style,
}: Props) => {
  const theme = useSmileIDSampleTheme();
  const { job } = state;

  return (
    <View style={[styles.screen, { backgroundColor: theme.colors.background }, style]}>
      <UseSmileIDSampleTopAppBar
        title="Verification details"
        onBack={onBack}
        action={
          job === null ? undefined : (
            <UseSmileIDSampleTopAppBarButton
              accessibilityLabel="Delete"
              onPress={onDelete}
              emphasis="Destructive"
              testID={UseSmileIDSampleTestIds.DETAILS_DELETE}
              glyph={(tint) => <UseSmileIDSampleIcon name="trash" tint={tint} />}
            />
          )
        }
      />
      <ScrollView
        testID={UseSmileIDSampleTestIds.VERIFICATION_DETAILS_SCREEN}
        contentContainerStyle={{
          padding: theme.dimens.spacing.md,
          rowGap: theme.dimens.spacing.sm,
        }}
        // Present in every state, not only processing: an outcome that cannot succeed says why.
        refreshControl={
          <RefreshControl
            testID={UseSmileIDSampleTestIds.DETAILS_REFRESH}
            refreshing={state.refreshing}
            onRefresh={onRefresh}
            tintColor={theme.colors.primary}
          />
        }
      >
        {job === null ? (
          <UseSmileIDSampleEmptyState
            text="No verification stored for this id"
            // The id asked for is the whole diagnostic, which a deep link is how you reach.
            supportingText={state.jobId}
            testID={UseSmileIDSampleTestIds.DETAILS_EMPTY}
          />
        ) : (
          <>
            <View style={[styles.status, { columnGap: theme.dimens.spacing.sm }]}>
              <UseSmileIDSampleStatusBadge
                status={job.status}
                testID={UseSmileIDSampleTestIds.STATUS_BADGE}
              />
              <Text style={[theme.type.textStyleBodySm, styles.message, { color: theme.colors.textBody }]}>
                {job.message}
              </Text>
            </View>

            {state.refreshNotice != null ? (
              <Text style={[theme.type.textStyleCaption, { color: theme.colors.textMuted }]}>
                {state.refreshNotice}
              </Text>
            ) : null}

            <UseSmileIDSampleSectionSurface label="DETAILS">
              <UseSmileIDSampleDataFieldRow
                label="Job_id"
                value={smileIDSampleJobShortId(job)}
                onCopy={() => onCopy('jobId', job.id)}
                testID={UseSmileIDSampleSuffixedTestIds.detailField('jobId')}
                copyTestID={UseSmileIDSampleSuffixedTestIds.detailCopy('jobId')}
              />
              <UseSmileIDSampleRowDivider />
              <UseSmileIDSampleDataFieldRow
                label="User_id"
                value={smileIDSampleJobShortUserId(job)}
                onCopy={() => onCopy('userId', job.userId)}
                testID={UseSmileIDSampleSuffixedTestIds.detailField('userId')}
                copyTestID={UseSmileIDSampleSuffixedTestIds.detailCopy('userId')}
              />
              <UseSmileIDSampleRowDivider />
              <UseSmileIDSampleDataFieldRow
                label="Product"
                value={job.product.label}
                testID={UseSmileIDSampleSuffixedTestIds.detailField('product')}
              />
              <UseSmileIDSampleRowDivider />
              <UseSmileIDSampleDataFieldRow
                label="Status"
                // The code is stored; the reason phrase is composed here, where the row is drawn.
                value={smileIDSampleHttpLabel(job.httpStatus) ?? '—'}
                testID={UseSmileIDSampleSuffixedTestIds.detailField('httpStatus')}
              />
              <UseSmileIDSampleRowDivider />
              <UseSmileIDSampleDataFieldRow
                label="Submitted"
                value={smileIDSampleCreatedAtLabel(job)}
                testID={UseSmileIDSampleSuffixedTestIds.detailField('createdAt')}
              />
              <UseSmileIDSampleRowDivider />
              <UseSmileIDSampleDataFieldRow
                label="Environment"
                // The only surface besides the result card that says where a row went.
                value={job.sandbox ? 'sandbox' : 'production'}
                testID={UseSmileIDSampleSuffixedTestIds.detailField('environment')}
              />
            </UseSmileIDSampleSectionSurface>
          </>
        )}
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  screen: { flex: 1 },
  status: { alignItems: 'center', flexDirection: 'row', width: '100%' },
  message: { flex: 1 },
});
