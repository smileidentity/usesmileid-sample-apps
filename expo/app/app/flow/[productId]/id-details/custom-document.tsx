import { CustomDocumentSheet, UseSmileIDSampleCaptureAs, useSmileIDSampleFormsStore } from '@smileid/sample-ui';
import { useLocalSearchParams } from 'expo-router';
import { useEffect } from 'react';

import { useSmileIDSampleBack } from '../../../../src/use-smile-id-sample-back';

export default function CustomDocument() {
  const { productId } = useLocalSearchParams<{ productId: string }>();
  const back = useSmileIDSampleBack(`/flow/${productId}/id-details`);
  const initial = useSmileIDSampleFormsStore((state) => state.idDetails.custom);
  const setCustomDocument = useSmileIDSampleFormsStore((state) => state.setCustomDocument);
  const setCaptureAs = useSmileIDSampleFormsStore((state) => state.setCaptureAs);

  // A link straight here selects Custom too, so the form never shows a shape it did not choose.
  useEffect(() => setCaptureAs(UseSmileIDSampleCaptureAs.Custom), [setCaptureAs]);

  return (
    <CustomDocumentSheet
      initial={initial}
      onDone={(custom) => {
        setCustomDocument(custom);
        back();
      }}
      onDismiss={() => back()}
    />
  );
}
