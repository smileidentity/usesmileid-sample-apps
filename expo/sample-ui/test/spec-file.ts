import { readFileSync } from 'node:fs';
import { join } from 'node:path';

/// Reads a spec file from the repository root, which only the tests may do — the package itself must
/// stay usable when an SDK repo maps it in alone, with no spec/ directory above it.
export const spec = <T>(name: string): T =>
  JSON.parse(readFileSync(join(__dirname, '..', '..', '..', 'spec', name), 'utf8')) as T;
