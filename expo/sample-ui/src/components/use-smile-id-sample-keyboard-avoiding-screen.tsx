import type { ReactNode } from 'react';
import { KeyboardAvoidingView, type StyleProp, type ViewStyle } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

type Props = {
  testID?: string;
  style?: StyleProp<ViewStyle>;
  children: ReactNode;
};

/// A screen root that lifts its bottom action above the keyboard, which neither platform does for an edge-to-edge app.
export const UseSmileIDSampleKeyboardAvoidingScreen = ({ testID, style, children }: Props) => {
  const insets = useSafeAreaInsets();
  return (
    <KeyboardAvoidingView
      testID={testID}
      behavior="padding"
      // The action already clears the bottom inset, which the keyboard covers, so the lift leaves it out.
      keyboardVerticalOffset={-insets.bottom}
      style={style}
    >
      {children}
    </KeyboardAvoidingView>
  );
};
