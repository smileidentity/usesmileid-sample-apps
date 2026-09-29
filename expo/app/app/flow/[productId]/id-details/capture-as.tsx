import { CaptureAsSheet, UseSmileIDSampleCaptureAs, useSmileIDSampleFormsStore } from '@smileid/sample-ui';
import { Redirect, useLocalSearchParams, useRouter } from 'expo-router';

import { useSmileIDSampleBack } from '../../../../src/use-smile-id-sample-back';

export default function CaptureAs() {
  const router = useRouter();
  const { productId } = useLocalSearchParams<{ productId: string }>();
  const back = useSmileIDSampleBack(`/flow/${productId}/id-details`);
  const document = useSmileIDSampleFormsStore((state) => state.idDetails.document);
  const selected = useSmileIDSampleFormsStore((state) => state.idDetails.captureAs);
  const setCaptureAs = useSmileIDSampleFormsStore((state) => state.setCaptureAs);

  // Its trigger could not open it yet, so neither may a link.
  if (document === null) return <Redirect href={`/flow/${productId}/id-details`} />;

  return (
    <CaptureAsSheet
      selected={selected}
      onSelect={(captureAs) => {
        // Generic document hands over to its own sheet, which is what keeps it; the others are kept at once.
        if (captureAs === UseSmileIDSampleCaptureAs.GenericDocument) {
          router.replace(`/flow/${productId}/id-details/generic-document`);
          return;
        }
        setCaptureAs(captureAs);
        back();
      }}
      onDismiss={() => back()}
    />
  );
}
