import { BottomSheet } from '@expo/ui/community/bottom-sheet';
import type { ReactNode } from 'react';
import { Platform, ScrollView, StyleSheet, Text, View } from 'react-native';

import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import { UseSmileIDSampleTopAppBarButton } from './use-smile-id-sample-top-app-bar';
import { atSize } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

/// The design's sheet margin is 20, which no spacing token carries.
const SHEET_PADDING_X = 20;
/// The gap between a full-height sheet's back control and its title, which no spacing token carries.
const SHEET_HEADER_GAP = 10;
/// Android draws the Compose app's 28-tall pill here, since Material's own handle is 48 tall.
const DRAWS_OWN_HANDLE = Platform.OS === 'android';
/// The Compose app's 44×4 grab handle, which no size token names.
const GRAB_HANDLE = { width: 44, height: 4 } as const;
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
        : { enableDynamicSizing: true, ...(DRAWS_OWN_HANDLE ? { handleComponent: null } : {}) })}
      backgroundStyle={{ backgroundColor: theme.colors.surface }}
      style={{ borderTopLeftRadius: theme.shapes.sheet, borderTopRightRadius: theme.shapes.sheet }}
    >
      <View testID={testID} style={[styles.sheet, { paddingHorizontal: SHEET_PADDING_X }]}>
        {!fullHeight && DRAWS_OWN_HANDLE ? <GrabHandle /> : null}
        {fullHeight && title !== undefined ? (
          <View style={[styles.header, { columnGap: SHEET_HEADER_GAP, paddingVertical: theme.dimens.spacing.xs }]}>
            <UseSmileIDSampleTopAppBarButton
              accessibilityLabel="Back"
              onPress={onDismiss}
              emphasis="Filled"
              glyph={(tint) => <UseSmileIDSampleIcon name="arrowBack" tint={tint} />}
            />
            <Text
              style={[atSize(theme.type.textStyleTitle, FULL_TITLE_SIZE), { color: theme.colors.textTitle }]}
            >
              {title}
            </Text>
          </View>
        ) : null}
        {!fullHeight && title !== undefined ? (
          <Text
            style={[
              atSize(theme.type.textStyleTitle, PARTIAL_TITLE_SIZE),
              // iOS's own grabber leaves 16 above the content; this brings the title to the Compose pill's 28.
              { color: theme.colors.textTitle, paddingTop: DRAWS_OWN_HANDLE ? 0 : theme.dimens.spacing.sm },
            ]}
          >
            {title}
          </Text>
        ) : null}
        {/* Scrolls rather than clips, so enlarged type cannot strand a call to action below the fold. */}
        <ScrollView
          style={!fullHeight && title !== undefined ? { marginTop: theme.dimens.spacing.sm } : undefined}
          contentContainerStyle={{ paddingBottom: theme.dimens.spacing.lg, rowGap: theme.dimens.spacing.sm }}
        >
          {children}
        </ScrollView>
      </View>
    </BottomSheet>
  );
};

/// The pill the design puts on partial sheets, drawn where the platform's own handle is not that pill.
const GrabHandle = () => {
  const theme = useSmileIDSampleTheme();
  return (
    <View style={[styles.handle, { paddingVertical: theme.dimens.spacing.sm }]}>
      <View
        style={{
          width: GRAB_HANDLE.width,
          height: GRAB_HANDLE.height,
          borderRadius: theme.dimens.radius.chip,
          backgroundColor: theme.colors.border,
        }}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  handle: { alignItems: 'center' },
  sheet: { width: '100%' },
  header: { alignItems: 'center', flexDirection: 'row' },
});
