import type { UseSmileIDSampleViewfinderProps } from '@smileid/sample-ui';
import { CameraView, useCameraPermissions, type BarcodeScanningResult } from 'expo-camera';
import { useIsFocused } from 'expo-router';
import { useEffect, useRef } from 'react';
import { StyleSheet } from 'react-native';

type Props = UseSmileIDSampleViewfinderProps & { readonly torchOn: boolean };

/// The token QR reader, in the app's own screen so camera contention with the SDK is something this sample can show.
export const UseSmileIDSampleQrScanner = ({ enabled, onCandidate, torchOn }: Props) => {
  const [permission, requestPermission] = useCameraPermissions();
  // Unmounted off focus, so the SDK never inherits a camera the host still holds.
  const focused = useIsFocused();
  // A code is reported once, but a different one still gets through; a one-shot latch would kill the scanner.
  const lastReported = useRef<string | null>(null);

  // Asked once per visit: a denial that still allows asking arrives as a new permission object.
  const asked = useRef(false);

  useEffect(() => {
    // A denial is not a dead end: the sheet's manual entry still links a token.
    if (asked.current || permission === null || permission.granted || !permission.canAskAgain) return;
    asked.current = true;
    void requestPermission();
  }, [permission, requestPermission]);

  useEffect(() => {
    // Re-enabled after a rejection, so the same QR reads again.
    if (enabled) lastReported.current = null;
  }, [enabled]);

  if (!focused || permission?.granted !== true) return null;

  const onScanned = ({ data }: BarcodeScanningResult) => {
    if (data === lastReported.current) return;
    lastReported.current = data;
    onCandidate(data);
  };

  return (
    <CameraView
      style={StyleSheet.absoluteFill}
      facing="back"
      enableTorch={torchOn}
      barcodeScannerSettings={{ barcodeTypes: ['qr'] }}
      // Frames are read only while the screen is searching, never behind a result it is showing.
      onBarcodeScanned={enabled ? onScanned : undefined}
    />
  );
};
