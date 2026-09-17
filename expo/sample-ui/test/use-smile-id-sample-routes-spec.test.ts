import { existsSync } from 'node:fs';
import { join } from 'node:path';

import { spec } from './spec-file';

type Route = {
  readonly id: string;
  readonly path: string;
  readonly presentation: string;
  readonly platform: Record<string, string>;
};

const routes = spec<{ routes: readonly Route[] }>('routes.json').routes;

/// The shell's route directory, which this test reads as a filesystem rather than importing from.
const APP = join(__dirname, '..', '..', 'app');

const expoRoutes = routes.filter((route) => typeof route.platform.expo === 'string');

/// The routes this tranche has not built yet, each named so a finished one cannot stay listed.
const notBuiltYet: Record<string, string> = {
  sdkFlow: 'the SDK flow host lands with the flow tranche',
  scanToken: 'the token scanner lands with the token tranche',
  scenarioDrawer: 'the dev scenario drawer lands with the shell tranche',
};

const built = expoRoutes.filter((route) => notBuiltYet[route.id] === undefined);

describe('every route the spec binds to a file', () => {
  it('names a file that exists, so a renamed route cannot go unnoticed', () => {
    const missing = built
      .filter((route) => !existsSync(join(APP, route.platform.expo!)))
      .map((route) => `${route.id} -> ${route.platform.expo}`);
    expect(missing).toEqual([]);
  });

  it('has a reason recorded for each one not built yet, and none of them exists', () => {
    for (const [id, reason] of Object.entries(notBuiltYet)) {
      const route = expoRoutes.find((entry) => entry.id === id);
      expect(reason.length).toBeGreaterThan(0);
      // An id that is no longer in the spec, or a file that now exists, makes the note stale.
      expect(route).toBeDefined();
      expect(existsSync(join(APP, route!.platform.expo!))).toBe(false);
    }
  });

  it('is a file under app/, never an absolute or escaping path', () => {
    for (const route of expoRoutes) {
      expect(route.platform.expo).toMatch(/^app\//);
      expect(route.platform.expo).not.toContain('..');
    }
  });
});

describe('a sheet route', () => {
  /// routes.json R12: a sheet is a layer over the screen that owns it, never a replacement.
  const sheets = built.filter((route) => route.presentation.toLowerCase().includes('sheet'));

  it('exists in the table at all, or R12 has nothing to govern', () => {
    expect(sheets.length).toBeGreaterThan(0);
  });

  it('sits beside its owner rather than replacing it, which a group or an index makes explicit', () => {
    for (const route of sheets) {
      const file = route.platform.expo!;
      const directory = file.slice(0, file.lastIndexOf('/'));
      // Either the owner is the index of the same directory, or the sheet is grouped under the
      // route that owns it — both are how expo-router keeps the owner mounted beneath.
      const ownerIsSibling = existsSync(join(APP, directory, 'index.tsx'));
      const grouped = /\/\([^)]+\)\//.test(`/${file}`);
      expect(ownerIsSibling || grouped).toBe(true);
    }
  });
});
