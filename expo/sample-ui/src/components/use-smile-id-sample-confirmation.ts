import { Alert } from 'react-native';

/// The platform's own alert, asking before an action that deletes something; the confirm action is destructive.
export const smileIDSampleConfirm = ({
  title,
  message,
  confirmLabel,
  onConfirm,
}: {
  readonly title: string;
  readonly message: string;
  readonly confirmLabel: string;
  readonly onConfirm: () => void;
}): void =>
  Alert.alert(title, message, [
    { text: 'Cancel', style: 'cancel' },
    { text: confirmLabel, style: 'destructive', onPress: onConfirm },
  ]);
