import { type UseSmileIDSampleStrings } from '../use-smile-id-sample-strings';

/// The confirmation a removal reports, in the shared package so four shells cannot word it differently.
export const smileIDSampleRemovalNotice = (count: number, strings: UseSmileIDSampleStrings) => ({
  message: count === 1 ? strings.verificationsHiddenOne : strings.verificationsHiddenMany({ count }),
  actionLabel: strings.commonUndo,
});
