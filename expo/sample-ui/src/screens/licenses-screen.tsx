import { useState } from 'react';
import { ScrollView, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import { UseSmileIDSampleEmptyState } from '../components/use-smile-id-sample-empty-state';
import { UseSmileIDSampleSectionLabel } from '../components/use-smile-id-sample-section-label';
import { UseSmileIDSampleRowDivider } from '../components/use-smile-id-sample-section-surface';
import { UseSmileIDSampleSettingRow } from '../components/use-smile-id-sample-setting-row';
import { UseSmileIDSampleTopAppBar } from '../components/use-smile-id-sample-top-app-bar';
import {
  UseSmileIDSampleSuffixedTestIds,
  UseSmileIDSampleTestIds,
} from '../use-smile-id-sample-test-ids';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

/// One third-party component's notice, as the generator emits it.
export type UseSmileIDSampleLicence = {
  readonly component: string;
  readonly version: string;
  readonly declared: string;
  readonly text: string;
  /// A component that vendors third-party code carries its own notices file.
  readonly notice?: string;
};

type Props = {
  licences: readonly UseSmileIDSampleLicence[];
  onBack: () => void;
  style?: StyleProp<ViewStyle>;
};

/// Every notice the bundle ships. A flat list rather than section cards: five hundred rows inside one card mount all of them at once.
export const LicensesScreen = ({ licences, onBack, style }: Props) => {
  const theme = useSmileIDSampleTheme();
  const [expanded, setExpanded] = useState<string | null>(null);

  return (
    <View style={[styles.screen, { backgroundColor: theme.colors.background }, style]}>
      <UseSmileIDSampleTopAppBar title="Open-source licenses" onBack={onBack} />
      <ScrollView
        testID={UseSmileIDSampleTestIds.LICENSES_SCREEN}
        contentContainerStyle={{ paddingBottom: theme.dimens.spacing.lg }}
      >
        {licences.length === 0 ? (
          // Generated into the bundle at build time, so an empty list means the asset did not ship.
          <UseSmileIDSampleEmptyState
            text="No notices bundled"
            supportingText="The generated licenses.json is missing from this build"
            testID={UseSmileIDSampleTestIds.LICENSES_EMPTY}
          />
        ) : (
          <View>
            <UseSmileIDSampleSectionLabel
              text={`OPEN-SOURCE COMPONENTS — ${licences.length}`}
              style={{ paddingHorizontal: theme.dimens.spacing.md, paddingVertical: theme.dimens.spacing.xs }}
            />
            {licences.map((licence) => (
              // No leading tile and no chevron: the coordinate is the content, and the row expands.
              <View key={licence.component} style={{ backgroundColor: theme.colors.surface }}>
                <UseSmileIDSampleSettingRow
                  title={licence.component}
                  supportingText={`${licence.version} · ${licence.declared}`}
                  onPress={() =>
                    setExpanded((current) => (current === licence.component ? null : licence.component))
                  }
                  testID={UseSmileIDSampleSuffixedTestIds.licenseRow(licence.component)}
                />
                {expanded === licence.component ? (
                  <Text
                    testID={UseSmileIDSampleSuffixedTestIds.licenseText(licence.component)}
                    style={[
                      theme.type.textStyleCaption,
                      {
                        color: theme.colors.textMuted,
                        paddingHorizontal: theme.dimens.spacing.md,
                        paddingBottom: theme.dimens.spacing.sm,
                      },
                    ]}
                  >
                    {licence.notice === undefined
                      ? licence.text
                      : `${licence.text}\n\n${licence.notice}`}
                  </Text>
                ) : null}
                <UseSmileIDSampleRowDivider />
              </View>
            ))}
          </View>
        )}
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  screen: { flex: 1 },
});
