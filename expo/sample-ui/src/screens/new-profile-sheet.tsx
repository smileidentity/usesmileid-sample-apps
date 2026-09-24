import { UseSmileIDSampleBottomSheet } from '../components/use-smile-id-sample-bottom-sheet';
import { UseSmileIDSampleButton } from '../components/use-smile-id-sample-button';
import { UseSmileIDSampleIcon } from '../components/use-smile-id-sample-icon';
import { UseSmileIDSampleSectionLabel } from '../components/use-smile-id-sample-section-label';
import { UseSmileIDSampleTextInput } from '../components/use-smile-id-sample-text-input';
import { smileIDSampleUserFieldSpec, UseSmileIDSampleUserField } from '../model/use-smile-id-sample-user-fields';
import type { SmileIconName } from '../smile-icons';
import { UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';

/// What the sheet has collected. Its own state, because a dismissed sheet must start empty next time.
export type UseSmileIDSampleNewProfileDraft = {
  readonly name: string;
  readonly firstName: string;
  readonly lastName: string;
  readonly email: string;
  readonly phone: string;
};

export const smileIDSampleNewProfileDraftEmpty: UseSmileIDSampleNewProfileDraft = {
  name: '',
  firstName: '',
  lastName: '',
  email: '',
  phone: '',
};

/// Name, first name and last name: the three the CTA waits for.
export const smileIDSampleNewProfileComplete = (draft: UseSmileIDSampleNewProfileDraft): boolean =>
  draft.name.trim().length > 0 &&
  draft.firstName.trim().length > 0 &&
  draft.lastName.trim().length > 0;

type Field = {
  readonly key: keyof UseSmileIDSampleNewProfileDraft;
  readonly placeholder: string;
  readonly icon: SmileIconName;
  readonly testID: string;
};

/// The name, then the four user details that will live under it, each carrying its leading glyph.
const NAME_FIELD: Field = {
  key: 'name',
  placeholder: 'Profile name',
  icon: 'fieldPerson',
  testID: UseSmileIDSampleTestIds.NEW_PROFILE_NAME,
};

const DETAIL_FIELDS: readonly Field[] = [
  {
    key: 'firstName',
    placeholder: smileIDSampleUserFieldSpec(UseSmileIDSampleUserField.FirstName).label,
    icon: 'fieldPerson',
    testID: UseSmileIDSampleTestIds.NEW_PROFILE_FIRST_NAME,
  },
  {
    key: 'lastName',
    placeholder: smileIDSampleUserFieldSpec(UseSmileIDSampleUserField.LastName).label,
    icon: 'fieldPerson',
    testID: UseSmileIDSampleTestIds.NEW_PROFILE_LAST_NAME,
  },
  {
    key: 'email',
    placeholder: smileIDSampleUserFieldSpec(UseSmileIDSampleUserField.Email).label,
    icon: 'fieldEmail',
    testID: UseSmileIDSampleTestIds.NEW_PROFILE_EMAIL,
  },
  {
    key: 'phone',
    placeholder: smileIDSampleUserFieldSpec(UseSmileIDSampleUserField.Phone).label,
    icon: 'fieldPhone',
    testID: UseSmileIDSampleTestIds.NEW_PROFILE_PHONE,
  },
];

type Props = {
  draft: UseSmileIDSampleNewProfileDraft;
  onDraftChange: (draft: UseSmileIDSampleNewProfileDraft) => void;
  onSave: () => void;
  onDismiss: () => void;
};

/// A profile name, then the four user details that will live under it.
export const NewProfileSheet = ({ draft, onDraftChange, onSave, onDismiss }: Props) => {
  const field = (spec: Field) => (
    <UseSmileIDSampleTextInput
      key={spec.key}
      value={draft[spec.key]}
      onValueChange={(value) => onDraftChange({ ...draft, [spec.key]: value })}
      placeholder={spec.placeholder}
      testID={spec.testID}
      leading={(tint) => <UseSmileIDSampleIcon name={spec.icon} tint={tint} />}
    />
  );

  return (
    <UseSmileIDSampleBottomSheet
      visible
      title="New profile"
      onDismiss={onDismiss}
      testID={UseSmileIDSampleTestIds.NEW_PROFILE_SHEET}
    >
      {field(NAME_FIELD)}
      <UseSmileIDSampleSectionLabel text="USER DETAILS" />
      {DETAIL_FIELDS.map(field)}
      <UseSmileIDSampleButton
        text="Create profile"
        onPress={onSave}
        enabled={smileIDSampleNewProfileComplete(draft)}
        testID={UseSmileIDSampleTestIds.NEW_PROFILE_SAVE}
      />
    </UseSmileIDSampleBottomSheet>
  );
};
