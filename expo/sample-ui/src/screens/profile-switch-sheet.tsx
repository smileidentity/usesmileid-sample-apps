import { UseSmileIDSampleBottomSheet } from '../components/use-smile-id-sample-bottom-sheet';
import { UseSmileIDSampleProfileRow } from '../components/use-smile-id-sample-profile-row';
import {
  smileIDSampleProfileCaption,
  smileIDSampleProfileInitials,
  type UseSmileIDSampleProfile,
} from '../state/use-smile-id-sample-profiles';
import { smileProfileHues } from '../smile-product-hues';
import { UseSmileIDSampleSuffixedTestIds, UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';

type Props = {
  profiles: readonly UseSmileIDSampleProfile[];
  activeId: string;
  onSelect: (profile: UseSmileIDSampleProfile) => void;
  onDismiss: () => void;
};

/// The profile-switch sheet. Selecting one switches immediately, which is why it needs no save action.
export const ProfileSwitchSheet = ({ profiles, activeId, onSelect, onDismiss }: Props) => (
  <UseSmileIDSampleBottomSheet
    visible
    title="Switch profile"
    onDismiss={onDismiss}
    testID={UseSmileIDSampleTestIds.PROFILE_SWITCH_SHEET}
  >
    {profiles.map((profile, index) => (
      <UseSmileIDSampleProfileRow
        key={profile.id}
        // Position in the list, cycled, which is what picks a profile's avatar hue.
        avatarColor={smileProfileHues[index % smileProfileHues.length]}
        organisation={profile.organisation}
        supportingText={smileIDSampleProfileCaption(profile)}
        initials={smileIDSampleProfileInitials(profile)}
        selected={profile.id === activeId}
        onPress={() => onSelect(profile)}
        testID={UseSmileIDSampleSuffixedTestIds.profileRow(profile.id)}
      />
    ))}
  </UseSmileIDSampleBottomSheet>
);
