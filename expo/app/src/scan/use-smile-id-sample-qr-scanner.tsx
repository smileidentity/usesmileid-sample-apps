import type { UseSmileIDSampleViewfinderProps } from '@smileid/sample-ui';
import { CameraView, useCameraPermissions, type BarcodeScanningResult } from 'expo-camera';
import { useIsFocused } from 'expo-router';
import { useEffect, useRef } from 'react';
import { StyleSheet } from 'react-native';

type Props = UseSmileIDSampleViewfinderProps & { readonly torchOn: boolean };

/// The token QR reader, owned by the shell.
export const UseSmileIDSampleQrScanner = ({ enabled, onCandidate, torchOn }: Props) => {
  const [permission, requestPermission] = useCameraPermissions();
  // Unmounted off focus, so the SDK never inherits the camera.
  const focused = useIsFocused();
  // Once per distinct code; a one-shot latch would kill the scanner.
  const lastReported = useRef<string | null>(null);

  // Once per visit: a denial that can still ask arrives as a new object.
  const asked = useRef(false);

  useEffect(() => {
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
      onBarcodeScanned={enabled ? onScanned : undefined}
    />
  );
};
