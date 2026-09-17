import type { ReactNode } from 'react';
import { ScrollView } from 'react-native';

import { UseSmileIDSampleEmptyState } from './use-smile-id-sample-empty-state';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

type Props = {
  empty: boolean;
  emptyLabel: string;
  emptyTestID: string;
  children: ReactNode;
};

/// An empty result is a state a search must have, or a typo looks like a broken sheet.
export const UseSmileIDSamplePickerList = ({ empty, emptyLabel, emptyTestID, children }: Props) => {
  const theme = useSmileIDSampleTheme();

  if (empty) return <UseSmileIDSampleEmptyState text={emptyLabel} testID={emptyTestID} />;

  return (
    <ScrollView contentContainerStyle={{ rowGap: theme.dimens.spacing.xxs }}>{children}</ScrollView>
  );
};
