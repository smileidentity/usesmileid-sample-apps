import { useSmileIDSampleTheme } from "@smileid/sample-ui";
import { useContext, type ReactNode } from "react";
import { Platform, View, useWindowDimensions } from "react-native";
import {
  SafeAreaInsetsContext,
  type EdgeInsets,
} from "react-native-safe-area-context";

/// A width and a height, in points or dp.
export type UseSmileIDSampleSize = {
  readonly width: number;
  readonly height: number;
};

/// The largest phone's frame the app's own screens draw in on a large screen, from `spec/large-screen-frame.json`.
export const smileIDSampleLargeScreen = {
  /// The shorter side a large screen starts at.
  minSide: 600,
  /// The iPhone 18 Pro Max's screen, the SDK's own large-screen frame on iOS.
  iosFrame: { width: 440, height: 956 },
  /// The Galaxy S26 Ultra's screen at its default display size, the SDK's own large-screen frame on Android.
  androidFrame: { width: 384, height: 832 },
} as const;

/// The frame on `platform`: the iPhone's on iOS, the Galaxy's elsewhere.
export function smileIDSampleFrameOn(platform: string): UseSmileIDSampleSize {
  return platform === "ios"
    ? smileIDSampleLargeScreen.iosFrame
    : smileIDSampleLargeScreen.androidFrame;
}

/// The app's size in a `window` whose safe area is `safeArea`: the frame, each side the safe area's where shorter, on a large screen; null on a phone.
export function smileIDSampleLargeScreenFrameSize(
  window: UseSmileIDSampleSize,
  safeArea: UseSmileIDSampleSize,
  platform: string,
): UseSmileIDSampleSize | null {
  if (Math.min(window.width, window.height) < smileIDSampleLargeScreen.minSide)
    return null;
  const frame = smileIDSampleFrameOn(platform);
  return {
    width: Math.min(Math.max(safeArea.width, 0), frame.width),
    height: Math.min(Math.max(safeArea.height, 0), frame.height),
  };
}

const noInsets: EdgeInsets = { top: 0, right: 0, bottom: 0, left: 0 };

/// Draws `children` on a large screen as the largest phone shows it, centred on the screen background; a phone, or `framed` false, fills the window.
export function UseSmileIDSampleLargeScreenFrame({
  framed,
  children,
}: {
  readonly framed: boolean;
  readonly children: ReactNode;
}) {
  const theme = useSmileIDSampleTheme();
  const window = useWindowDimensions();
  const hostInsets = useContext(SafeAreaInsetsContext);
  const insets = hostInsets ?? noInsets;
  const frame = framed
    ? smileIDSampleLargeScreenFrameSize(
        window,
        {
          width: window.width - insets.left - insets.right,
          height: window.height - insets.top - insets.bottom,
        },
        Platform.OS,
      )
    : null;
  const large = frame !== null;
  return (
    <View
      style={{
        flex: 1,
        alignItems: "center",
        justifyContent: "center",
        backgroundColor: large ? theme.colors.background : undefined,
        paddingTop: large ? insets.top : 0,
        paddingRight: large ? insets.right : 0,
        paddingBottom: large ? insets.bottom : 0,
        paddingLeft: large ? insets.left : 0,
      }}
    >
      <View
        style={
          frame === null
            ? { flex: 1, alignSelf: "stretch" }
            : {
                width: frame.width,
                height: frame.height,
                maxWidth: "100%",
                maxHeight: "100%",
                overflow: "hidden",
              }
        }
      >
        {/* The frame keeps the safe area outside it, so the screens inside pad for none. */}
        <SafeAreaInsetsContext.Provider value={large ? noInsets : hostInsets}>
          {children}
        </SafeAreaInsetsContext.Provider>
      </View>
    </View>
  );
}
