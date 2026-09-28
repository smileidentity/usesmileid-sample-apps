import { CustomDocumentSheet, useSmileIDSampleFormsStore } from '@smileid/sample-ui';
import { useLocalSearchParams } from 'expo-router';

import { useSmileIDSampleBack } from '../../../../src/use-smile-id-sample-back';

export default function CustomDocument() {
  const { productId } = useLocalSearchParams<{ productId: string }>();
  const back = useSmileIDSampleBack(`/flow/${productId}/id-details`);
  const initial = useSmileIDSampleFormsStore((state) => state.idDetails.custom);
  const setCustomDocument = useSmileIDSampleFormsStore((state) => state.setCustomDocument);

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
