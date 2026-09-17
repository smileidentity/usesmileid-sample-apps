import type { ReactNode } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import Swipeable from 'react-native-gesture-handler/Swipeable';

import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import { lightColors } from '../tokens';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

type Props = {
  onAction: () => void;
  testID?: string;
  children: ReactNode;
};

/// The platform swipe gesture; the design only fixes the revealed action's treatment.
export const UseSmileIDSampleSwipeAction = ({ onAction, testID, children }: Props) => {
  const theme = useSmileIDSampleTheme();
  const revealWidth = theme.dimens.space[64] + theme.dimens.spacing.md;

  return (
    <Swipeable
      testID={testID}
      // Fires on the settled value, so a re-render mid-gesture cannot remove the row twice.
      onSwipeableOpen={(direction) => {
        if (direction === 'right') onAction();
      }}
      renderRightActions={() => (
        <View
          style={[
            styles.action,
            {
              width: revealWidth,
              backgroundColor: lightColors.color.feedback.error.fill,
              borderRadius: theme.shapes.card,
              rowGap: theme.dimens.spacing.xxs,
            },
          ]}
        >
          <UseSmileIDSampleIcon
            name="trash"
            tint={lightColors.color.text.inverse}
            size={theme.dimens.size['icon-sm']}
          />
          {/* Labelled Hide, matching the selection bar: nothing is deleted at the API. */}
          <Text style={[theme.type.textStyleOverline, { color: lightColors.color.text.inverse }]}>
            Hide
          </Text>
        </View>
      )}
    >
      {children}
    </Swipeable>
  );
};

const styles = StyleSheet.create({
  action: { alignItems: 'center', justifyContent: 'center' },
});
