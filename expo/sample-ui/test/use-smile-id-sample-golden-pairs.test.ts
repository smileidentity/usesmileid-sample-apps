import { readFileSync } from 'node:fs';
import { join } from 'node:path';

/// Two states whose baselines are byte-identical are not two baselines, so each pair that is
/// identical on purpose is named here and a new one fails — the cheapest dark-mode miss to ship.
const identicalOnPurpose: Record<string, string> = {
  'Avatar/initials': 'the fill is a profile hue and the initials are white, neither of which changes by scheme',
  'Avatar/row_size': 'same as Avatar/initials, at the size the profile row passes',
  'Button/disabled':
    'button.disabled.background points at a primitive so it cannot re-resolve for dark — the buttonDisabledBypassesSemanticTier delta',
  'SectionLabel/default': 'color.text.muted is the same grey in both schemes — the darkMuted delta',
  'StatusBadge/clear': 'the soft badge fills are specified as one pair per role, not per scheme',
  'StatusBadge/attention': 'the soft badge fills are specified as one pair per role, not per scheme',
  'StatusBadge/blocked': 'the soft badge fills are specified as one pair per role, not per scheme',
  'StatusBadge/processing': 'the soft badge fills are specified as one pair per role, not per scheme',
  'DateGroupHeader/withRelativeWord': 'the whole header is color.text.muted — the darkMuted delta',
  'DateGroupHeader/absoluteOnly': 'the whole header is color.text.muted — the darkMuted delta',
  'DataFieldRow/withStatusValue':
    'data-field.label is the muted grey and the value is pinned to a soft badge colour, so nothing in the row varies by scheme',
  'SelectTrigger/disabled':
    'the disabled button pair and input.border are all mode-invariant — the buttonDisabledBypassesSemanticTier and darkBorder deltas together',
};

/// Both suites record light-then-dark, so both are read the same way.
const snapshotFiles = [
  'use-smile-id-sample-primitives.test.tsx.snap',
  'use-smile-id-sample-composites.test.tsx.snap',
];

const expectedStates = 70;

const readPairs = () => {
  const pairs = new Map<string, { light?: string; dark?: string }>();
  for (const file of snapshotFiles) {
    const source = readFileSync(join(__dirname, 'goldens', file), 'utf8');
    const entries = /exports\[`([^`]+)`\] = `([\s\S]*?)`;\n/g;
    let match = entries.exec(source);
    while (match !== null) {
      const name = match[1] ?? '';
      const parsed = name.match(/^(\S+) (light|dark) (.+) 1$/);
      if (parsed) {
        const id = `${parsed[1]}/${parsed[3]}`;
        const existing = pairs.get(id) ?? {};
        pairs.set(id, { ...existing, [parsed[2] as 'light' | 'dark']: match[2] });
      }
      match = entries.exec(source);
    }
  }
  return pairs;
};

describe('the recorded goldens', () => {
  const pairs = readPairs();

  it('records both schemes for every state', () => {
    const halves = [...pairs.entries()].filter(([, v]) => !v.light || !v.dark).map(([id]) => id);
    expect(halves).toEqual([]);
  });

  it('records every state both suites declare', () => {
    expect(pairs.size).toBe(expectedStates);
  });

  it('has no identical light and dark pair that is not explained', () => {
    const identical = [...pairs.entries()]
      .filter(([, v]) => v.light === v.dark)
      .map(([id]) => id)
      .sort();
    expect(identical).toEqual(Object.keys(identicalOnPurpose).sort());
  });

  it('has no explained pair that has since started differing, which would make the note stale', () => {
    const differing = Object.keys(identicalOnPurpose).filter((id) => {
      const pair = pairs.get(id);
      return pair !== undefined && pair.light !== pair.dark;
    });
    expect(differing).toEqual([]);
  });

  it('names a recorded state for every explained pair, so a renamed state cannot orphan its note', () => {
    expect(Object.keys(identicalOnPurpose).filter((id) => !pairs.has(id))).toEqual([]);
  });
});
