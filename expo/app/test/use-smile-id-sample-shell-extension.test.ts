import { isValidElement, type ReactElement } from 'react';
import { useSmileIDSampleShellExtension } from '../src/extension';
import { smileIDSampleDebugRows } from '../src/use-smile-id-sample-shell-extension';

describe('the shell extension', () => {
  it('is absent from a registry build', () => {
    expect(useSmileIDSampleShellExtension).toBeNull();
  });

  it("draws the extension's leading rows before its others", () => {
    const rows = smileIDSampleDebugRows({ leadingDebugRows: () => 'leading', debugRows: () => 'others' });

    expect(isValidElement(rows)).toBe(true);
    expect((rows as ReactElement<{ children: unknown[] }>).props.children).toEqual(['leading', 'others']);
  });

  it('draws no rows without an extension, so a release build has no DEBUG section', () => {
    expect(smileIDSampleDebugRows(null)).toBeUndefined();
    expect(smileIDSampleDebugRows({})).toBeUndefined();
  });
});
