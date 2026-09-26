import { Text } from 'react-native';

import { UseSmileIDSampleTopAppBar } from '../src/components/use-smile-id-sample-top-app-bar';
import { renderInTheme } from './render-in-theme';

const noop = () => {};

/// The app bar's controls have to be reachable one at a time, which a golden cannot show.
describe('the top app bar keeps its controls apart', () => {
  it('announces the back control as a button and the title as a header, separately', async () => {
    const rendered = await renderInTheme(<UseSmileIDSampleTopAppBar title="Verification details" onBack={noop} />, false);

    const back = rendered.getByRole('button', { name: 'Back' });
    const title = rendered.getByRole('header', { name: 'Verification details' });
    expect(back).not.toBe(title);
    expect(rendered.queryAllByRole('button', { name: /Verification details/ })).toHaveLength(0);
  });

  it('keeps a trailing action its own element', async () => {
    const rendered = await renderInTheme(
      <UseSmileIDSampleTopAppBar title="Verification details" onBack={noop} action={<Text accessibilityRole="button">Delete</Text>} />,
      false,
    );

    expect(rendered.getByRole('button', { name: 'Delete' })).toBeTruthy();
    expect(rendered.getByRole('header', { name: 'Verification details' })).toBeTruthy();
  });

  it('groups nothing: no ancestor of the controls is itself one accessible element', async () => {
    const rendered = await renderInTheme(<UseSmileIDSampleTopAppBar title="Verification details" onBack={noop} />, false);

    let node = rendered.getByRole('button', { name: 'Back' }).parent;
    while (node) {
      expect(node.props.accessible).not.toBe(true);
      node = node.parent;
    }
  });
});
