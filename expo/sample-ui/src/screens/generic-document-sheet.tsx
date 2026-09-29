import { useState } from 'react';
import { StyleSheet, View } from 'react-native';

import { UseSmileIDSampleBottomSheet } from '../components/use-smile-id-sample-bottom-sheet';
import { UseSmileIDSampleButton } from '../components/use-smile-id-sample-button';
import { UseSmileIDSampleFilterChip } from '../components/use-smile-id-sample-filter-chip';
import { UseSmileIDSampleSectionLabel } from '../components/use-smile-id-sample-section-label';
import { UseSmileIDSampleSettingRow } from '../components/use-smile-id-sample-setting-row';
import { UseSmileIDSampleSwitch } from '../components/use-smile-id-sample-switch';
import { UseSmileIDSampleTextInput } from '../components/use-smile-id-sample-text-input';
import {
  smileIDSampleAspectRatios,
  smileIDSampleOrientations,
  type UseSmileIDSampleGenericDocument,
} from '../state/use-smile-id-sample-id-details';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import { UseSmileIDSampleSuffixedTestIds, UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';

type Props = {
  initial: UseSmileIDSampleGenericDocument;
  onDone: (genericDocument: UseSmileIDSampleGenericDocument) => void;
  onDismiss: () => void;
};

/// Builds the generic document "Capture as: Generic document" hands the SDK. Nothing is kept until Done.
export const GenericDocumentSheet = ({ initial, onDone, onDismiss }: Props) => {
  const theme = useSmileIDSampleTheme();
  const [draft, setDraft] = useState(initial);
  const chips = {
    columnGap: theme.dimens.spacing.xs,
    rowGap: theme.dimens.spacing.xs,
  };

  return (
    <UseSmileIDSampleBottomSheet
      visible
      title="Generic document"
      onDismiss={onDismiss}
      testID={UseSmileIDSampleTestIds.GENERIC_DOCUMENT_SHEET}
    >
      <View style={{ rowGap: theme.dimens.spacing.sm }}>
        <UseSmileIDSampleSectionLabel text="DISPLAY NAME" />
        <UseSmileIDSampleTextInput
          value={draft.displayName}
          onValueChange={(displayName) => setDraft({ ...draft, displayName })}
          placeholder="Document"
          testID={UseSmileIDSampleTestIds.GENERIC_DOCUMENT_NAME}
        />
        <UseSmileIDSampleSettingRow
          title="Back side"
          supportingText="Capture the back after the front"
          trailing={
            <UseSmileIDSampleSwitch
              checked={draft.hasBackSide}
              onCheckedChange={(hasBackSide) => setDraft({ ...draft, hasBackSide })}
              testID={UseSmileIDSampleTestIds.GENERIC_DOCUMENT_BACK_SIDE}
            />
          }
        />
        <UseSmileIDSampleSectionLabel text="ORIENTATION" />
        <View style={[styles.chips, chips]}>
          {smileIDSampleOrientations.map((orientation) => (
            <UseSmileIDSampleFilterChip
              key={orientation.id}
              label={orientation.label}
              count={null}
              selected={orientation.id === draft.orientation}
              onPress={() => setDraft({ ...draft, orientation: orientation.id })}
              testID={UseSmileIDSampleSuffixedTestIds.genericDocumentOrientation(orientation.id)}
            />
          ))}
        </View>
        <UseSmileIDSampleSectionLabel text="ASPECT RATIO" />
        <View style={[styles.chips, chips]}>
          {smileIDSampleAspectRatios.map((ratio) => (
            <UseSmileIDSampleFilterChip
              key={ratio.id}
              label={ratio.label}
              count={null}
              selected={ratio.id === draft.aspectRatio}
              onPress={() => setDraft({ ...draft, aspectRatio: ratio.id })}
              testID={UseSmileIDSampleSuffixedTestIds.genericDocumentAspectRatio(ratio.id)}
            />
          ))}
        </View>
        <UseSmileIDSampleButton
          text="Done"
          onPress={() =>
            onDone({
              ...draft,
              displayName: draft.displayName.trim() || 'Document',
            })
          }
          testID={UseSmileIDSampleTestIds.GENERIC_DOCUMENT_DONE}
        />
      </View>
    </UseSmileIDSampleBottomSheet>
  );
};

const styles = StyleSheet.create({
  chips: { flexDirection: 'row', flexWrap: 'wrap' },
});
