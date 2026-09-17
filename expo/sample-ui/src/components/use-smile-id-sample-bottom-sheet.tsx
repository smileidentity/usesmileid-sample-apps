import { BottomSheet } from '@expo/ui/community/bottom-sheet';
import type { ReactNode } from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';

import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import { UseSmileIDSampleTopAppBarButton } from './use-smile-id-sample-top-app-bar';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

/// The design's sheet margin is 20, which no spacing token carries.
const SHEET_PADDING_X = 20;
const PARTIAL_TITLE_SIZE = 18;
const FULL_TITLE_SIZE = 16;

type Props = {
  visible: boolean;
  onDismiss: () => void;
  title?: string;
  /// A full-height sheet drops the grabber and takes a back header; a partial one keeps the grabber.
  fullHeight?: boolean;
  testID?: string;
  children: ReactNode;
};

/// The platform sheet, owned by the screen beneath as a boolean — never a route, which would leave nothing behind the scrim.
export const UseSmileIDSampleBottomSheet = ({
  visible,
  onDismiss,
  title,
  fullHeight = false,
  testID,
  children,
}: Props) => {
  const theme = useSmileIDSampleTheme();

  // Removed from the tree when hidden, which is the platform's own guidance for a modal sheet.
  if (!visible) return null;

  return (
    <BottomSheet
      onDismiss={onDismiss}
      onClose={onDismiss}
      enablePanDownToClose
      // Content height, not the platform's half-screen state: at half, the five-field new-profile
      // sheet clipped its last field and put its CTA below the fold.
      {...(fullHeight
        ? { snapPoints: ['100%'], handleComponent: null }
        : { enableDynamicSizing: true })}
      backgroundStyle={{ backgroundColor: theme.colors.surface }}
      style={{ borderTopLeftRadius: theme.shapes.sheet, borderTopRightRadius: theme.shapes.sheet }}
    >
      <View testID={testID} style={[styles.sheet, { paddingHorizontal: SHEET_PADDING_X }]}>
        {fullHeight && title !== undefined ? (
          <View style={[styles.header, { columnGap: theme.dimens.spacing.xs, paddingTop: theme.dimens.spacing.sm }]}>
            <UseSmileIDSampleTopAppBarButton
              accessibilityLabel="Back"
              onPress={onDismiss}
              emphasis="Filled"
              glyph={(tint) => <UseSmileIDSampleIcon name="arrowBack" tint={tint} />}
            />
            <Text
              style={[theme.type.textStyleTitle, { fontSize: FULL_TITLE_SIZE, color: theme.colors.textTitle }]}
            >
              {title}
            </Text>
          </View>
        ) : null}
        {!fullHeight && title !== undefined ? (
          <Text
            style={[
              theme.type.textStyleTitle,
              { fontSize: PARTIAL_TITLE_SIZE, color: theme.colors.textTitle, paddingTop: theme.dimens.spacing.sm },
            ]}
          >
            {title}
          </Text>
        ) : null}
        {/* Scrolls rather than clips, so enlarged type cannot strand a call to action below the fold. */}
        <ScrollView
          contentContainerStyle={{ paddingBottom: theme.dimens.spacing.lg, rowGap: theme.dimens.spacing.xs }}
        >
          {children}
        </ScrollView>
      </View>
    </BottomSheet>
  );
};

const styles = StyleSheet.create({
  sheet: { width: '100%' },
  header: { alignItems: 'center', flexDirection: 'row' },
});
