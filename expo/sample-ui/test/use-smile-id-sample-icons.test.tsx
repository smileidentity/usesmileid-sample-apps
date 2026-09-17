import { readdirSync } from 'node:fs';
import { join } from 'node:path';

import { UseSmileIDSampleIcon, UseSmileIDSampleMarkNames } from '../src/components/use-smile-id-sample-icon';
import { smileIcons, type SmileIconName } from '../src/smile-icons';
import { smileLightColors } from '../src/theme/smile-colors';
import { renderInTheme } from './render-in-theme';

/// Two real token colours rather than literals, so the test also proves a token reaches the path.
const tint = smileLightColors.textTitle;
const otherTint = smileLightColors.primary;

const iconDir = join(__dirname, '..', '..', '..', 'design', 'icons');

const camel = (name: string) =>
  name
    .replace(/-/g, '_')
    .split('_')
    .map((part, index) => (index === 0 ? part : part.charAt(0).toUpperCase() + part.slice(1)))
    .join('');

const filesOnDisk = (): string[] => {
  const found: string[] = [];
  const walk = (dir: string) => {
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      if (entry.isDirectory()) walk(join(dir, entry.name));
      else if (entry.name.endsWith('.svg')) found.push(camel(entry.name.replace(/\.svg$/, '')));
    }
  };
  walk(iconDir);
  return found;
};

describe('the generated icon record', () => {
  it('holds exactly the marks design/icons carries, so a new SVG cannot go unused', () => {
    expect(Object.keys(smileIcons).sort()).toEqual(filesOnDisk().sort());
  });

  it('gives every mark a viewBox with a positive size', () => {
    const broken = Object.entries(smileIcons)
      .filter(([, icon]) => icon.width <= 0 || icon.height <= 0)
      .map(([name]) => name);
    expect(broken).toEqual([]);
  });

  it('gives every subpath real path data', () => {
    // A mark with no subpath at all cannot reach here: the emitter raises rather than emitting one,
    // and the generated literal types make the length check provably dead.
    const empty = Object.entries(smileIcons)
      .filter(([, icon]) => icon.parts.some((part) => part.d.trim().length === 0))
      .map(([name]) => name);
    expect(empty).toEqual([]);
  });

  it('states the paint for every subpath rather than leaving a caller to guess', () => {
    const kinds = new Set(
      Object.values(smileIcons).flatMap((icon) => icon.parts.map((part) => part.paint.kind)),
    );
    expect([...kinds].sort()).toEqual(['fill', 'stroke']);
  });

  it('keeps the Material Symbols stand-ins as fills and the design set as strokes', () => {
    // The two families are deliberately not interchangeable; this is the line between them.
    expect(smileIcons.check.parts.every((p) => p.paint.kind === 'fill')).toBe(true);
    expect(smileIcons.arrowBack.parts.every((p) => p.paint.kind === 'stroke')).toBe(true);
  });

  it('names a real mark for every role a composite reaches for', () => {
    const names = Object.keys(smileIcons) as SmileIconName[];
    const missing = Object.values(UseSmileIDSampleMarkNames).filter((n) => !names.includes(n));
    expect(missing).toEqual([]);
  });
});

describe('the icon renderer', () => {
  it('draws every mark in the record without throwing', async () => {
    for (const name of Object.keys(smileIcons) as SmileIconName[]) {
      const rendered = await renderInTheme(<UseSmileIDSampleIcon name={name} tint={tint} />, false);
      expect(rendered.toJSON()).not.toBeNull();
    }
  });

  it('takes its stroke width from the record rather than a default', async () => {
    const part = smileIcons.arrowBack.parts[0];
    const width = part?.paint.kind === 'stroke' ? part.paint.width : null;
    expect(width).toBe(1.5);
    const rendered = await renderInTheme(<UseSmileIDSampleIcon name="arrowBack" tint={tint} />, false);
    expect(JSON.stringify(rendered.toJSON())).toContain('"strokeWidth":1.5');
  });

  it('applies the caller tint, which react-native-svg normalises to an ARGB integer', async () => {
    // Asserted by difference rather than by value, so the test does not reimplement that conversion.
    const one = await renderInTheme(<UseSmileIDSampleIcon name="arrowBack" tint={tint} />, false);
    const two = await renderInTheme(<UseSmileIDSampleIcon name="arrowBack" tint={otherTint} />, false);
    expect(JSON.stringify(one.toJSON())).not.toEqual(JSON.stringify(two.toJSON()));
  });

  it('carries the mark viewBox onto the canvas so a mark is never cropped', async () => {
    const rendered = await renderInTheme(<UseSmileIDSampleIcon name="check" tint={tint} />, false);
    const tree = JSON.stringify(rendered.toJSON());
    // The Material set draws from a negative origin, which a naive 0 0 W H viewBox would clip away.
    expect(tree).toContain(`"minY":${smileIcons.check.minY}`);
    expect(tree).toContain(`"vbWidth":${smileIcons.check.width}`);
  });
});
