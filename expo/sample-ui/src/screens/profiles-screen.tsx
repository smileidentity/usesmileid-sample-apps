import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { UseSmileIDSampleIcon } from '../components/use-smile-id-sample-icon';
import { UseSmileIDSampleProfileRow } from '../components/use-smile-id-sample-profile-row';
import { UseSmileIDSampleSettingRowChevron } from '../components/use-smile-id-sample-setting-row';
import { UseSmileIDSampleTopAppBar } from '../components/use-smile-id-sample-top-app-bar';
import {
  smileIDSampleProfileCaption,
  smileIDSampleProfileInitials,
  type UseSmileIDSampleProfile,
} from '../state/use-smile-id-sample-profiles';
import { smileProfileHues } from '../smile-product-hues';
import { atSize, atWeight } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import {
  UseSmileIDSampleSuffixedTestIds,
  UseSmileIDSampleTestIds,
} from '../use-smile-id-sample-test-ids';

/// Appended to the active profile's supporting line.
const ACTIVE_SUFFIX = ' · active';

/// The create row's own metrics, which land between the scale steps — spec/screens.json → profiles.
const CREATE_PADDING_X = 14;
const CREATE_TILE_RADIUS = 12;
const CREATE_TITLE_SIZE = 14.5;

/// The last row: no card and no border, a pale primary tile with a plus.
const CreateProfileRow = ({ onPress }: { onPress: () => void }) => {
  const theme = useSmileIDSampleTheme();

  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      testID={UseSmileIDSampleTestIds.CREATE_PROFILE}
      style={[
        styles.createRow,
        {
          columnGap: theme.dimens.spacing.sm,
          paddingHorizontal: CREATE_PADDING_X,
          paddingVertical: theme.dimens.spacing.sm,
        },
      ]}
    >
      <View
        style={[
          styles.createTile,
          {
            backgroundColor: theme.colors.badge.infoBackground,
            borderRadius: CREATE_TILE_RADIUS,
            height: theme.dimens.size['control-md'],
            width: theme.dimens.size['control-md'],
          },
        ]}
      >
        <UseSmileIDSampleIcon name="plus" tint={theme.colors.primary} size={theme.dimens.size['icon-md']} />
      </View>
      <View style={{ rowGap: theme.dimens.spacing.xxs }}>
        <Text
          style={[
            atSize(atWeight(theme.type.textStyleBodyStrong, 600), CREATE_TITLE_SIZE),
            { color: theme.colors.textTitle },
          ]}
        >
          Create new profile
        </Text>
        <Text style={[theme.type.textStyleCaption, { color: theme.colors.textMuted }]}>
          Its user details will live under it
        </Text>
      </View>
    </Pressable>
  );
};

/// Everything the profiles list renders; callbacks stay parameters, like every screen.
export type UseSmileIDSampleProfilesState = {
  readonly profiles: readonly UseSmileIDSampleProfile[];
  readonly activeId: string;
};

type Props = {
  state: UseSmileIDSampleProfilesState;
  onProfilePress: (profile: UseSmileIDSampleProfile) => void;
  onCreate: () => void;
  onBack: () => void;
};

/// Every profile the app can act as. Tapping one configures it; switching happens on the sheet.
export const ProfilesScreen = ({ state, onProfilePress, onCreate, onBack }: Props) => {
  const theme = useSmileIDSampleTheme();
  const insets = useSafeAreaInsets();

  return (
    <View
      testID={UseSmileIDSampleTestIds.PROFILES_SCREEN}
      style={[styles.screen, { backgroundColor: theme.colors.background }]}
    >
      <UseSmileIDSampleTopAppBar title="Profiles" onBack={onBack} />
      <ScrollView
        contentContainerStyle={{
          paddingBottom: insets.bottom + theme.dimens.spacing.md,
          rowGap: theme.dimens.spacing.xs,
        }}
      >
        {state.profiles.map((profile, index) => (
          <UseSmileIDSampleProfileRow
            key={profile.id}
            // Position in the list, cycled, which is what picks a profile's avatar hue.
            avatarColor={smileProfileHues[index % smileProfileHues.length]}
            organisation={profile.organisation}
            supportingText={
              profile.id === state.activeId
                ? smileIDSampleProfileCaption(profile) + ACTIVE_SUFFIX
                : smileIDSampleProfileCaption(profile)
            }
            initials={smileIDSampleProfileInitials(profile)}
            selected={false}
            onPress={() => onProfilePress(profile)}
            testID={UseSmileIDSampleSuffixedTestIds.profileRow(profile.id)}
            trailing={<UseSmileIDSampleSettingRowChevron />}
            style={{ marginHorizontal: theme.dimens.spacing.md }}
          />
        ))}
        <CreateProfileRow onPress={onCreate} />
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  screen: { flex: 1 },
  createRow: { alignItems: 'center', flexDirection: 'row' },
  createTile: { alignItems: 'center', justifyContent: 'center' },
});
