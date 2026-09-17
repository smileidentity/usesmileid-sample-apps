import { useState } from 'react';
import { ScrollView, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import { UseSmileIDSampleEmptyState } from '../components/use-smile-id-sample-empty-state';
import { UseSmileIDSampleSectionLabel } from '../components/use-smile-id-sample-section-label';
import {
  UseSmileIDSampleSettingRow,
  UseSmileIDSampleSettingRowChevron,
} from '../components/use-smile-id-sample-setting-row';
import { UseSmileIDSampleTopAppBar } from '../components/use-smile-id-sample-top-app-bar';
import { smileCardStrokeWidth } from '../smile-product-hues';
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
            text="No notices shipped"
            supportingText="The generated licence asset is missing from this build"
            testID={UseSmileIDSampleTestIds.LICENSES_EMPTY}
          />
        ) : (
          <View>
            <UseSmileIDSampleSectionLabel
              text="OPEN-SOURCE COMPONENTS"
              style={{ padding: theme.dimens.spacing.md }}
            />
            {licences.map((licence) => (
              <View key={licence.component}>
                <UseSmileIDSampleSettingRow
                  title={licence.component}
                  supportingText={`${licence.version} · ${licence.declared}`}
                  onPress={() =>
                    setExpanded((current) => (current === licence.component ? null : licence.component))
                  }
                  trailing={<UseSmileIDSampleSettingRowChevron />}
                  testID={UseSmileIDSampleSuffixedTestIds.licenseRow(licence.component)}
                />
                {expanded === licence.component ? (
                  <Text
                    testID={UseSmileIDSampleSuffixedTestIds.licenseText(licence.component)}
                    style={[
                      theme.type.textStyleCaption,
                      {
                        color: theme.colors.textBody,
                        paddingHorizontal: theme.dimens.spacing.md,
                        paddingBottom: theme.dimens.spacing.md,
                      },
                    ]}
                  >
                    {licence.notice === undefined
                      ? licence.text
                      : `${licence.text}\n\n${licence.notice}`}
                  </Text>
                ) : null}
                <View
                  style={{ backgroundColor: theme.colors.cardStroke, height: smileCardStrokeWidth }}
                />
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
