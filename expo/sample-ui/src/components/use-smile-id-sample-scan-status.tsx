import { Pressable, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import type { UseSmileIDSampleScanState } from '../model/use-smile-id-sample-scan-state';
import { touchTargetStyle } from '../theme/smile-compose-layout';
import { atSize, atWeight } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import { type UseSmileIDSampleStrings } from '../use-smile-id-sample-strings';
import { useSmileIDSampleStrings } from '../use-smile-id-sample-strings-context';

const DETAIL_SIZE = 12.5;

type Props = {
  state: UseSmileIDSampleScanState;
  onRetry: () => void;
  style?: StyleProp<ViewStyle>;
};

const headline = (state: UseSmileIDSampleScanState, strings: UseSmileIDSampleStrings): string => {
  switch (state.kind) {
    case 'searching':
      return strings.scanPoint;
    case 'found':
      return strings.scanFound;
    case 'linked':
      return strings.scanLinked;
    case 'rejected':
      return strings.scanNotAToken;
  }
};

const detail = (state: UseSmileIDSampleScanState, strings: UseSmileIDSampleStrings): string | null => {
  switch (state.kind) {
    case 'searching':
      return null;
    case 'found':
      return strings.scanReading;
    case 'linked':
      return `${state.handle} · ${state.remaining} left`;
    case 'rejected':
      return state.reason;
  }
};

/// The scanner's state over the viewfinder, in the feedback fills; only a rejection offers an action.
export const UseSmileIDSampleScanStatus = ({ state, onRetry, style }: Props) => {
  const strings = useSmileIDSampleStrings();
  const theme = useSmileIDSampleTheme();
  const { background, foreground } = {
    searching: { background: theme.colors.surface, foreground: theme.colors.textTitle },
    found: { background: theme.colors.infoFill, foreground: theme.colors.onInfo },
    linked: { background: theme.colors.successFill, foreground: theme.colors.onSuccess },
    rejected: { background: theme.colors.errorFill, foreground: theme.colors.onError },
  }[state.kind];
  const text = detail(state, strings);

  return (
    <View
      style={[
        styles.pill,
        {
          backgroundColor: background,
          borderRadius: theme.shapes.card,
          paddingHorizontal: theme.dimens.spacing.md,
          paddingVertical: theme.dimens.spacing.sm,
          rowGap: theme.dimens.spacing.xxs,
        },
        style,
      ]}
    >
      <View style={[styles.row, { columnGap: theme.dimens.spacing.xs }]}>
        {state.kind === 'linked' ? (
          <UseSmileIDSampleIcon name="check" size={theme.dimens.size['icon-md']} tint={foreground} />
        ) : null}
        <Text style={[theme.type.textStyleBodyStrong, styles.centred, { color: foreground }]}>
          {headline(state, strings)}
        </Text>
      </View>
      {text === null ? null : (
        <Text style={[atSize(theme.type.textStyleCaption, DETAIL_SIZE), styles.centred, { color: foreground }]}>
          {text}
        </Text>
      )}
      {state.kind === 'rejected' ? (
        <Pressable
          accessibilityRole="button"
          onPress={onRetry}
          style={[styles.action, touchTargetStyle(theme), { paddingHorizontal: theme.dimens.spacing.xs }]}
        >
          <Text style={[atWeight(theme.type.linkFont, 700), { color: foreground }]}>{strings.commonTryAgain}</Text>
        </Pressable>
      ) : null}
    </View>
  );
};

const styles = StyleSheet.create({
  pill: { alignItems: 'center' },
  row: { alignItems: 'center', flexDirection: 'row' },
  centred: { textAlign: 'center' },
  action: { alignItems: 'center', justifyContent: 'center' },
});
