import type { ReactNode } from 'react';

import { UseSmileIDSampleEmptyState } from './use-smile-id-sample-empty-state';
import { UseSmileIDSamplePickerList } from './use-smile-id-sample-picker-list';
import { UseSmileIDSampleSearchField } from './use-smile-id-sample-search-field';
import { useSmileIDSampleSkeletonGate, UseSmileIDSampleSkeletonRows } from './use-smile-id-sample-skeleton';
import type { UseSmileIDSampleCatalogue } from '../state/use-smile-id-sample-catalogue';
import { smileIDSampleOptionMatches } from '../state/use-smile-id-sample-id-details';
import { UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';

type Props<T> = {
  catalogue: UseSmileIDSampleCatalogue<T>;
  /// What is listed, in "Loading countries" and "Couldn't load countries".
  what: string;
  query: string;
  onQueryChange: (query: string) => void;
  searchPlaceholder: string;
  searchTestID: string;
  label: (item: T) => string;
  emptyTestID: string;
  /// What a search that matched nothing says.
  emptyLabel: (query: string) => string;
  /// What an empty list says, and what to do about it.
  nothingToList: readonly [string, string];
  onRetry: () => void;
  row: (item: T) => ReactNode;
  /// Whether the skeleton leads each row with a flag-sized circle.
  leadingCircle?: boolean;
};

/// One picker's body: skeleton rows while loading, an error with Retry, an empty state without one, and a search.
export const UseSmileIDSampleCataloguePicker = <T,>({
  catalogue,
  what,
  query,
  onQueryChange,
  searchPlaceholder,
  searchTestID,
  label,
  emptyTestID,
  emptyLabel,
  nothingToList,
  onRetry,
  row,
  leadingCircle = false,
}: Props<T>) => {
  const skeleton = useSmileIDSampleSkeletonGate(catalogue.kind === 'loading');
  const search = (
    <UseSmileIDSampleSearchField
      query={query}
      onQueryChange={onQueryChange}
      placeholder={searchPlaceholder}
      enabled={catalogue.kind === 'ready' && !skeleton}
      testID={searchTestID}
    />
  );
  if (skeleton) {
    return (
      <>
        {search}
        <UseSmileIDSampleSkeletonRows
          announcement={`Loading ${what}`}
          leadingCircle={leadingCircle}
          testID={UseSmileIDSampleTestIds.CATALOGUE_LOADING}
        />
      </>
    );
  }
  switch (catalogue.kind) {
    // The first 300 ms draw nothing, so a fast answer never flashes a skeleton.
    case 'loading':
      return search;
    case 'failed':
      return (
        <>
          {search}
          <UseSmileIDSampleEmptyState
            text={`Couldn't load ${what}`}
            supportingText="Check your connection, then try again"
            testID={UseSmileIDSampleTestIds.CATALOGUE_ERROR}
            onRetry={onRetry}
            retryTestID={UseSmileIDSampleTestIds.CATALOGUE_RETRY}
          />
        </>
      );
    case 'empty':
      return (
        <>
          {search}
          <UseSmileIDSampleEmptyState text={nothingToList[0]} supportingText={nothingToList[1]} testID={emptyTestID} />
        </>
      );
    case 'ready': {
      const matches = catalogue.items.filter((item) => smileIDSampleOptionMatches(label(item), query));
      return (
        <>
          {search}
          <UseSmileIDSamplePickerList
            empty={matches.length === 0}
            emptyLabel={emptyLabel(query)}
            emptyTestID={emptyTestID}
          >
            {matches.map(row)}
          </UseSmileIDSamplePickerList>
        </>
      );
    }
  }
};
