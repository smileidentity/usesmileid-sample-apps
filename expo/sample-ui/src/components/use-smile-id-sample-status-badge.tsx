import { Text, type StyleProp, type TextStyle } from 'react-native';

import { UseSmileIDSampleStatus, useSmileIDSampleStatusRole } from '../model/use-smile-id-sample-status';
import { smileLabelSize, smileLabelTracking } from '../smile-product-hues';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import type { BadgeTokens } from '../theme/smile-colors';

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
    default:
      return { background: badge.infoBackground, foreground: badge.infoText };
  }
};

/// A status pill in the design's soft tinted fill, Title case and on `radius.control` rather than `radius.chip`.
export const UseSmileIDSampleStatusBadge = ({ status, testID, style }: Props) => {
  const theme = useSmileIDSampleTheme();
  const { background, foreground } = pairFor(theme.colors.badge, useSmileIDSampleStatusRole(status));

  return (
    <Text
      testID={testID}
      style={[
        theme.type.textStyleOverline,
        {
          fontSize: smileLabelSize,
          letterSpacing: smileLabelTracking,
          color: foreground,
          backgroundColor: background,
          borderRadius: theme.dimens.radius.control,
          overflow: 'hidden',
          paddingHorizontal: theme.dimens.spacing.xs,
          paddingVertical: theme.dimens.space[4],
        },
        style,
      ]}
    >
      {status}
    </Text>
  );
};
