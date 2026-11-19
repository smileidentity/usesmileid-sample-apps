import { isValidElement, type ReactElement } from 'react';
import { useSmileIDSampleShellExtension } from '../src/extension';
import { smileIDSampleDebugRows, smileIDSampleDebugSheetOpens } from '../src/use-smile-id-sample-shell-extension';

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

/// A debug sheet opens only in a debug build whose extension draws it; a release build, no extension or an unknown id closes it at once.
describe('smileIDSampleDebugSheetOpens', () => {
  const timings = { hasDebugSheet: (sheetId: string) => sheetId === 'captureTimings' };

  it('a debug build opens a sheet its extension draws', () => {
    expect(smileIDSampleDebugSheetOpens(true, timings, 'captureTimings')).toBe(true);
  });

  it('a release build never opens it', () => {
    expect(smileIDSampleDebugSheetOpens(false, timings, 'captureTimings')).toBe(false);
  });

  it('an id the extension does not draw closes', () => {
    expect(smileIDSampleDebugSheetOpens(true, timings, 'unknown')).toBe(false);
  });

  it('a build with no extension has nothing to draw', () => {
    expect(smileIDSampleDebugSheetOpens(true, null, 'captureTimings')).toBe(false);
  });
});
