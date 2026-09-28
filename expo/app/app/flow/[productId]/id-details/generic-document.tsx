import { GenericDocumentSheet, useSmileIDSampleFormsStore } from '@smileid/sample-ui';
import { useLocalSearchParams } from 'expo-router';

import { useSmileIDSampleBack } from '../../../../src/use-smile-id-sample-back';

export default function GenericDocument() {
  const { productId } = useLocalSearchParams<{ productId: string }>();
  const back = useSmileIDSampleBack(`/flow/${productId}/id-details`);
  const initial = useSmileIDSampleFormsStore((state) => state.idDetails.genericDocument);
  const setGenericDocument = useSmileIDSampleFormsStore((state) => state.setGenericDocument);

  return (
    <GenericDocumentSheet
      initial={initial}
      onDone={(genericDocument) => {
        setGenericDocument(genericDocument);
        back();
      }}
      onDismiss={() => back()}
    />
  );
}
