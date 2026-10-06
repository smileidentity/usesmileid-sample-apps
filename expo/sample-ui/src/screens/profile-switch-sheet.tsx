import { UseSmileIDSampleBottomSheet } from '../components/use-smile-id-sample-bottom-sheet';
import { UseSmileIDSampleProfileRow } from '../components/use-smile-id-sample-profile-row';
import {
  smileIDSampleProfileCaption,
  smileIDSampleProfileInitials,
  smileIDSampleProfileTitle,
  type UseSmileIDSampleProfile,
} from '../state/use-smile-id-sample-profiles';
import { smileProfileHues } from '../smile-product-hues';
import { UseSmileIDSampleSuffixedTestIds, UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { useSmileIDSampleStrings } from '../use-smile-id-sample-strings-context';

type Props = {
  profiles: readonly UseSmileIDSampleProfile[];
  activeId: string | null;
  onSelect: (profile: UseSmileIDSampleProfile) => void;
  onDismiss: () => void;
  /// Absent hides the "New profile" row, for a host that offers no way to create one.
  onCreate?: () => void;
};

/// The profile-switch sheet. Selecting one switches immediately, which is why it needs no save action.
export const ProfileSwitchSheet = ({ profiles, activeId, onSelect, onDismiss, onCreate }: Props) => {
  const strings = useSmileIDSampleStrings();
  return (
    <UseSmileIDSampleBottomSheet
      visible
      title={strings.profileSwitchTitle}
      onDismiss={onDismiss}
      testID={UseSmileIDSampleTestIds.PROFILE_SWITCH_SHEET}
    >
      {profiles.map((profile, index) => (
        <UseSmileIDSampleProfileRow
          key={profile.id}
          // Position in the list, cycled, which is what picks a profile's avatar hue.
          avatarColor={smileProfileHues[index % smileProfileHues.length]}
          organisation={smileIDSampleProfileTitle(profile, strings)}
          supportingText={smileIDSampleProfileCaption(profile, strings)}
          initials={smileIDSampleProfileInitials(profile)}
          selected={profile.id === activeId}
          onPress={() => onSelect(profile)}
          testID={UseSmileIDSampleSuffixedTestIds.profileRow(profile.id)}
        />
      ))}
      {onCreate === undefined ? null : (
        <UseSmileIDSampleProfileRow
          organisation="New profile"
          supportingText={strings.profileSwitchNewHint}
          initials=""
          selected={false}
          onPress={onCreate}
          testID={UseSmileIDSampleTestIds.PROFILE_SWITCH_NEW}
        />
      )}
    </UseSmileIDSampleBottomSheet>
  );
};
