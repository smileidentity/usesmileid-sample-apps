import { Text, type StyleProp, type TextStyle } from 'react-native';

import {
  type UseSmileIDSampleStatus,
  smileIDSampleStatusLabel,
  smileIDSampleStatusRole,
} from '../model/use-smile-id-sample-status';
import { smileLabelSize, smileLabelTracking } from '../smile-product-hues';
import { atSize, untrimmed } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import type { BadgeTokens } from '../theme/smile-colors';
import { useSmileIDSampleStrings } from '../use-smile-id-sample-strings-context';

type Props = {
  status: UseSmileIDSampleStatus;
  testID?: string;
  style?: StyleProp<TextStyle>;
};

const pairFor = (badge: BadgeTokens, role: string): { background: string; foreground: string } => {
  switch (role) {
    case 'success':
      return { background: badge.successBackground, foreground: badge.successText };
    case 'warning':
      return { background: badge.warningBackground, foreground: badge.warningText };
    case 'error':
      return { background: badge.errorBackground, foreground: badge.errorText };
    case 'neutral':
      return { background: badge.neutralBackground, foreground: badge.neutralText };
    default:
      return { background: badge.infoBackground, foreground: badge.infoText };
  }
};

/// A status pill in the design's soft tinted fill, Title case and on `radius.control` rather than `radius.chip`.
export const UseSmileIDSampleStatusBadge = ({ status, testID, style }: Props) => {
  const theme = useSmileIDSampleTheme();
  const strings = useSmileIDSampleStrings();
  const { background, foreground } = pairFor(theme.colors.badge, smileIDSampleStatusRole(status));

  const label = atSize(theme.type.textStyleOverline, smileLabelSize);

  return (
    <Text
      testID={testID}
      style={[
        // The pill is this Text's own box, so its trim comes off the padding rather than the margins.
        untrimmed(label),
        {
          letterSpacing: smileLabelTracking,
          color: foreground,
          backgroundColor: background,
          borderRadius: theme.dimens.radius.control,
          overflow: 'hidden',
          paddingHorizontal: theme.dimens.spacing.xs,
          paddingVertical: theme.dimens.space[4] + label.marginTop,
        },
        style,
      ]}
    >
      {smileIDSampleStatusLabel(status, strings)}
    </Text>
  );
};
