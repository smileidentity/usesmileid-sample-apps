import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

import { UseSmileIDSampleSuffixedTestIds, UseSmileIDSampleTestIds } from '../src/use-smile-id-sample-test-ids';

const DECLARATIONS = join(__dirname, '../src/use-smile-id-sample-test-ids.ts');

/// Declared for parity and attached to nothing on Expo, each with its reason; a stale entry fails.
const EXCUSED: Record<string, string> = {
  SCENARIO_DRAWER: 'no Expo shell presents the scenario drawer yet',
  SCENARIO_ITEM: 'no Expo shell presents the scenario drawer yet',
  THEME_ITEM: 'no Expo shell presents the scenario drawer yet',
  ENV_CHIP: 'the chip is hidden on every shipped screen',
  LICENSE_LINK: 'every licence ships its text, so none opens a page',
  SIGN_OUT_CONFIRM: 'a native Alert button takes no test id',
  PROFILE_DELETE_CONFIRM: 'a native Alert button takes no test id',
};

/// Every source file under a directory, recursively.
const sourcesUnder = (dir: string): string[] =>
  readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) return sourcesUnder(path);
    return /\.tsx?$/.test(entry.name) ? [path] : [];
  });

/// The other direction of the id contract: a declared id has to reach a view, not only the spec.
describe('every declared id is attached somewhere', () => {
  // Both packages: a sheet's id is supplied by the shell route that presents it.
  const callers = [join(__dirname, '../src'), join(__dirname, '../../app/app'), join(__dirname, '../../app/src')]
    .flatMap(sourcesUnder)
    .filter((path) => path !== DECLARATIONS)
    .map((path) => readFileSync(path, 'utf8'))
    .join('\n');

  const declarations = readFileSync(DECLARATIONS, 'utf8');
  /// A suffixed id reaches a view through its builder, whose body is the only place that names its base.
  const builderOf = (key: string) =>
    Object.keys(UseSmileIDSampleSuffixedTestIds).find((name) =>
      new RegExp(`\\b${name}: [^\\n]*UseSmileIDSampleTestIds\\.${key}\\b`).test(declarations),
    );

  it('reads the declarations', () => {
    expect(Object.keys(UseSmileIDSampleTestIds).length).toBeGreaterThan(40);
  });

  it('finds a caller for every id', () => {
    const unattached = Object.keys(UseSmileIDSampleTestIds).filter((key) => {
      const builder = builderOf(key);
      return !(
        new RegExp(`UseSmileIDSampleTestIds\\.${key}\\b`).test(callers) ||
        (builder !== undefined && new RegExp(`UseSmileIDSampleSuffixedTestIds\\.${builder}\\b`).test(callers))
      );
    });
    expect(unattached.filter((key) => !(key in EXCUSED))).toEqual([]);
    expect(Object.keys(EXCUSED).filter((key) => !unattached.includes(key))).toEqual([]);
  });
});
