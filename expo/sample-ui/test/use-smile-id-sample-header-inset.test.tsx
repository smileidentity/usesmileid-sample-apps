import { Text } from 'react-native';

import {
  UseSmileIDSampleTopCutoutContext,
  useSmileIDSampleHeaderTopInset,
} from '../src/components/use-smile-id-sample-header-inset';
import { renderInTheme } from './render-in-theme';

const HeaderInsetProbe = () => <Text testID="probe">{useSmileIDSampleHeaderTopInset()}</Text>;

/// iOS's safe area already leaves room below the sensor housing, so the header takes the inset alone.
describe('the header inset under iOS', () => {
  it('adds nothing to the safe area, even under a top cutout', async () => {
    const rendered = await renderInTheme(
      <UseSmileIDSampleTopCutoutContext.Provider value>
        <HeaderInsetProbe />
      </UseSmileIDSampleTopCutoutContext.Provider>,
      false,
      undefined,
      { top: 59 },
    );
    expect(rendered.getByTestId('probe').props.children).toBe(59);
  });
});
