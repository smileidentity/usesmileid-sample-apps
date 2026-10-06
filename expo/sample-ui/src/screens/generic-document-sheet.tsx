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
import { useSmileIDSampleStrings } from '../use-smile-id-sample-strings-context';

type Props = {
  initial: UseSmileIDSampleGenericDocument;
  onDone: (genericDocument: UseSmileIDSampleGenericDocument) => void;
  onDismiss: () => void;
};

/// Builds the generic document "Capture as: Generic document" hands the SDK. Nothing is kept until Done.
export const GenericDocumentSheet = ({ initial, onDone, onDismiss }: Props) => {
  const strings = useSmileIDSampleStrings();
  const theme = useSmileIDSampleTheme();
  const [draft, setDraft] = useState(initial);
  const chips = {
    columnGap: theme.dimens.spacing.xs,
    rowGap: theme.dimens.spacing.xs,
  };

  return (
    <UseSmileIDSampleBottomSheet
      visible
      title={strings.genericDocumentTitle}
      onDismiss={onDismiss}
      testID={UseSmileIDSampleTestIds.GENERIC_DOCUMENT_SHEET}
    >
      <View style={{ rowGap: theme.dimens.spacing.sm }}>
        <UseSmileIDSampleSectionLabel text={strings.genericDocumentDisplayName} />
        <UseSmileIDSampleTextInput
          value={draft.displayName}
          onValueChange={(displayName) => setDraft({ ...draft, displayName })}
          placeholder={strings.genericDocumentDefaultName}
          testID={UseSmileIDSampleTestIds.GENERIC_DOCUMENT_NAME}
        />
        <UseSmileIDSampleSettingRow
          title={strings.genericDocumentBackSide}
          supportingText={strings.genericDocumentBackSideHint}
          trailing={
            <UseSmileIDSampleSwitch
              checked={draft.hasBackSide}
              onCheckedChange={(hasBackSide) => setDraft({ ...draft, hasBackSide })}
              testID={UseSmileIDSampleTestIds.GENERIC_DOCUMENT_BACK_SIDE}
            />
          }
        />
        <UseSmileIDSampleSectionLabel text={strings.genericDocumentOrientation} />
        <View style={[styles.chips, chips]}>
          {smileIDSampleOrientations.map((orientation) => (
            <UseSmileIDSampleFilterChip
              key={orientation.id}
              label={orientation.label(strings)}
              count={null}
              selected={orientation.id === draft.orientation}
              onPress={() => setDraft({ ...draft, orientation: orientation.id })}
              testID={UseSmileIDSampleSuffixedTestIds.genericDocumentOrientation(orientation.id)}
            />
          ))}
        </View>
        <UseSmileIDSampleSectionLabel text={strings.genericDocumentAspectRatio} />
        <View style={[styles.chips, chips]}>
          {smileIDSampleAspectRatios.map((ratio) => (
            <UseSmileIDSampleFilterChip
              key={ratio.id}
              label={ratio.label(strings)}
              count={null}
              selected={ratio.id === draft.aspectRatio}
              onPress={() => setDraft({ ...draft, aspectRatio: ratio.id })}
              testID={UseSmileIDSampleSuffixedTestIds.genericDocumentAspectRatio(ratio.id)}
            />
          ))}
        </View>
        <UseSmileIDSampleButton
          text={strings.commonDone}
          onPress={() =>
            onDone({
              ...draft,
              displayName: draft.displayName.trim() || strings.genericDocumentDefaultName,
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
