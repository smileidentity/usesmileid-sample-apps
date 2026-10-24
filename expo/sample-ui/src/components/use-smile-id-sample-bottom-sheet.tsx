import type { ReactNode } from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';

import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import { UseSmileIDSampleTopAppBarButton } from './use-smile-id-sample-top-app-bar';
import { atSize } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import { useSmileIDSampleStrings } from '../use-smile-id-sample-strings-context';

/// The design's sheet margin is 20, which no spacing token carries.
const SHEET_PADDING_X = 20;
/// The gap between a full-height sheet's back control and its title, which no spacing token carries.
const SHEET_HEADER_GAP = 10;
/// The Compose app's 44×4 grab handle, which no size token names.
const GRAB_HANDLE = { width: 44, height: 4 } as const;
const PARTIAL_TITLE_SIZE = 18;
const FULL_TITLE_SIZE = 16;

type Props = {
  onDismiss: () => void;
  title?: string;
  /// A full-height sheet drops the grabber and takes a back header; a partial one keeps the grabber.
  fullHeight?: boolean;
  testID?: string;
  children: ReactNode;
};

/// A sheet's panel, sized to its content; njia's sheet step draws the scrim and the dismiss gestures around it.
export const UseSmileIDSampleBottomSheet = ({ onDismiss, title, fullHeight = false, testID, children }: Props) => {
  const strings = useSmileIDSampleStrings();
  const theme = useSmileIDSampleTheme();

  return (
    <View style={[styles.panel, { backgroundColor: theme.colors.surface }]}>
      <View testID={testID} style={[styles.sheet, { paddingHorizontal: SHEET_PADDING_X }]}>
        {fullHeight ? null : <GrabHandle />}
        {fullHeight && title !== undefined ? (
          <View style={[styles.header, { columnGap: SHEET_HEADER_GAP, paddingVertical: theme.dimens.spacing.xs }]}>
            <UseSmileIDSampleTopAppBarButton
              accessibilityLabel={strings.commonBack}
              onPress={onDismiss}
              emphasis="Filled"
              glyph={(tint) => <UseSmileIDSampleIcon name="arrowBack" tint={tint} />}
            />
            <Text style={[atSize(theme.type.textStyleTitle, FULL_TITLE_SIZE), { color: theme.colors.textTitle }]}>
              {title}
            </Text>
          </View>
        ) : null}
        {!fullHeight && title !== undefined ? (
          <Text style={[atSize(theme.type.textStyleTitle, PARTIAL_TITLE_SIZE), { color: theme.colors.textTitle }]}>
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
    </View>
  );
};

/// The pill the design puts on partial sheets.
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
  // The host's panel takes the content's height, so the sheet shrinks to fit rather than filling it.
  panel: { flexShrink: 1, width: '100%' },
  sheet: { width: '100%' },
  header: { alignItems: 'center', flexDirection: 'row' },
});
