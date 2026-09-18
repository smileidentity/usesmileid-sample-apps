import { readFileSync } from 'node:fs';
import { join } from 'node:path';

/// The advance widths and kern pairs of one bundled face, in font units.
type Face = {
  readonly unitsPerEm: number;
  readonly glyphForCodePoint: ReadonlyMap<number, number>;
  readonly advances: readonly number[];
  readonly kerning: ReadonlyMap<number, number>;
};

/// What a run of text is measured with, as the resolved style props a React Native Text carries.
export type SmileFontRun = {
  readonly fontFamily: string;
  readonly fontSize: number;
  readonly letterSpacing?: number;
};

const FONT_DIR = join(__dirname, '..', '..', 'assets', 'fonts');

const faces = new Map<string, Face>();

const tableOffsets = (data: Buffer): ReadonlyMap<string, number> => {
  const count = data.readUInt16BE(4);
  const offsets = new Map<string, number>();
  for (let index = 0; index < count; index++) {
    const record = 12 + 16 * index;
    offsets.set(data.toString('ascii', record, record + 4), data.readUInt32BE(record + 8));
  }
  return offsets;
};

/// The Unicode-to-glyph map, from the segmented format every one of these faces ships.
const readCmap = (data: Buffer, offset: number): Map<number, number> => {
  const map = new Map<number, number>();
  const tables = data.readUInt16BE(offset + 2);
  let subtable = -1;
  for (let index = 0; index < tables; index++) {
    const record = offset + 4 + 8 * index;
    const platform = data.readUInt16BE(record);
    const encoding = data.readUInt16BE(record + 2);
    if ((platform === 3 && (encoding === 1 || encoding === 10)) || platform === 0) {
      subtable = offset + data.readUInt32BE(record + 4);
    }
  }
  if (subtable < 0 || data.readUInt16BE(subtable) !== 4) {
    throw new Error('a bundled face has no format 4 character map to measure text with');
  }
  const segments = data.readUInt16BE(subtable + 6) / 2;
  const ends = subtable + 14;
  const starts = ends + segments * 2 + 2;
  const deltas = starts + segments * 2;
  const rangeOffsets = deltas + segments * 2;
  for (let segment = 0; segment < segments; segment++) {
    const end = data.readUInt16BE(ends + 2 * segment);
    const start = data.readUInt16BE(starts + 2 * segment);
    const delta = data.readInt16BE(deltas + 2 * segment);
    const rangeOffset = data.readUInt16BE(rangeOffsets + 2 * segment);
    if (start === 0xffff) continue;
    for (let code = start; code <= end; code++) {
      let glyph: number;
      if (rangeOffset === 0) {
        glyph = (code + delta) & 0xffff;
      } else {
        const at = rangeOffsets + 2 * segment + rangeOffset + 2 * (code - start);
        if (at + 1 >= data.length) continue;
        glyph = data.readUInt16BE(at);
        if (glyph !== 0) glyph = (glyph + delta) & 0xffff;
      }
      if (glyph !== 0) map.set(code, glyph);
    }
  }
  return map;
};

/// Glyph index by coverage order, which is how every GPOS subtable addresses its first glyph.
const readCoverage = (data: Buffer, offset: number): Map<number, number> => {
  const covered = new Map<number, number>();
  const format = data.readUInt16BE(offset);
  const count = data.readUInt16BE(offset + 2);
  if (format === 1) {
    for (let index = 0; index < count; index++) {
      covered.set(data.readUInt16BE(offset + 4 + 2 * index), index);
    }
    return covered;
  }
  for (let index = 0; index < count; index++) {
    const record = offset + 4 + 6 * index;
    const start = data.readUInt16BE(record);
    const end = data.readUInt16BE(record + 2);
    const first = data.readUInt16BE(record + 4);
    for (let glyph = start; glyph <= end; glyph++) covered.set(glyph, first + glyph - start);
  }
  return covered;
};

const readClassDef = (data: Buffer, offset: number): Map<number, number> => {
  const classes = new Map<number, number>();
  const format = data.readUInt16BE(offset);
  if (format === 1) {
    const start = data.readUInt16BE(offset + 2);
    const count = data.readUInt16BE(offset + 4);
    for (let index = 0; index < count; index++) {
      classes.set(start + index, data.readUInt16BE(offset + 6 + 2 * index));
    }
    return classes;
  }
  const count = data.readUInt16BE(offset + 2);
  for (let index = 0; index < count; index++) {
    const record = offset + 4 + 6 * index;
    const start = data.readUInt16BE(record);
    const end = data.readUInt16BE(record + 2);
    const value = data.readUInt16BE(record + 4);
    for (let glyph = start; glyph <= end; glyph++) classes.set(glyph, value);
  }
  return classes;
};

const valueRecordSize = (format: number): number => {
  let size = 0;
  for (let bit = 0; bit < 8; bit++) if ((format >> bit) & 1) size += 2;
  return size;
};

const kernKey = (left: number, right: number): number => left * 0x10000 + right;

/// Pair adjustments only: the horizontal advance a shaper adds between two glyphs, which is all Latin needs.
const readPairKerning = (data: Buffer, gposOffset: number): Map<number, number> => {
  const kerning = new Map<number, number>();
  const lookupList = gposOffset + data.readUInt16BE(gposOffset + 8);
  const lookups = data.readUInt16BE(lookupList);
  for (let index = 0; index < lookups; index++) {
    const lookup = lookupList + data.readUInt16BE(lookupList + 2 + 2 * index);
    const declaredType = data.readUInt16BE(lookup);
    const subtables = data.readUInt16BE(lookup + 4);
    for (let sub = 0; sub < subtables; sub++) {
      let offset = lookup + data.readUInt16BE(lookup + 6 + 2 * sub);
      let type = declaredType;
      // An extension lookup names its real type and redirects, and these faces put their kerning behind one.
      if (type === 9) {
        type = data.readUInt16BE(offset + 2);
        offset += data.readUInt32BE(offset + 4);
      }
      if (type !== 2) continue;
      const format = data.readUInt16BE(offset);
      const firstFormat = data.readUInt16BE(offset + 4);
      const secondFormat = data.readUInt16BE(offset + 6);
      // Only the first glyph's x advance is read, so a face adjusting the second would measure short.
      if ((firstFormat & ~0x0004) !== 0 || secondFormat !== 0) continue;
      const firstSize = valueRecordSize(firstFormat);
      const secondSize = valueRecordSize(secondFormat);
      const coverage = readCoverage(data, offset + data.readUInt16BE(offset + 2));
      if (format === 1) {
        const byIndex = new Map<number, number>();
        for (const [glyph, at] of coverage) byIndex.set(at, glyph);
        const sets = data.readUInt16BE(offset + 8);
        for (let set = 0; set < sets; set++) {
          const left = byIndex.get(set);
          if (left === undefined) continue;
          const setOffset = offset + data.readUInt16BE(offset + 10 + 2 * set);
          const pairs = data.readUInt16BE(setOffset);
          for (let pair = 0; pair < pairs; pair++) {
            const record = setOffset + 2 + pair * (2 + firstSize + secondSize);
            const right = data.readUInt16BE(record);
            if (firstSize > 0) kerning.set(kernKey(left, right), data.readInt16BE(record + 2));
          }
        }
        continue;
      }
      if (format !== 2) continue;
      const firstClasses = readClassDef(data, offset + data.readUInt16BE(offset + 8));
      const secondClasses = readClassDef(data, offset + data.readUInt16BE(offset + 10));
      const firstCount = data.readUInt16BE(offset + 12);
      const secondCount = data.readUInt16BE(offset + 14);
      const records = offset + 16;
      const stride = firstSize + secondSize;
      const byClass = new Map<number, number[]>();
      for (const glyph of coverage.keys()) {
        const cls = firstClasses.get(glyph) ?? 0;
        const bucket = byClass.get(cls);
        if (bucket) bucket.push(glyph);
        else byClass.set(cls, [glyph]);
      }
      const secondByClass = new Map<number, number[]>();
      for (const [glyph, cls] of secondClasses) {
        const bucket = secondByClass.get(cls);
        if (bucket) bucket.push(glyph);
        else secondByClass.set(cls, [glyph]);
      }
      for (let first = 0; first < firstCount; first++) {
        const lefts = byClass.get(first);
        if (!lefts) continue;
        for (let second = 0; second < secondCount; second++) {
          const rights = secondByClass.get(second);
          if (!rights || firstSize === 0) continue;
          const value = data.readInt16BE(records + (first * secondCount + second) * stride);
          if (value === 0) continue;
          for (const left of lefts) for (const right of rights) kerning.set(kernKey(left, right), value);
        }
      }
    }
  }
  return kerning;
};

const loadFace = (family: string): Face => {
  const cached = faces.get(family);
  if (cached) return cached;
  const data = readFileSync(join(FONT_DIR, `${family}.ttf`));
  const offsets = tableOffsets(data);
  const head = offsets.get('head');
  const hhea = offsets.get('hhea');
  const hmtx = offsets.get('hmtx');
  const cmap = offsets.get('cmap');
  if (head === undefined || hhea === undefined || hmtx === undefined || cmap === undefined) {
    throw new Error(`the bundled face ${family} is missing a table text cannot be measured without`);
  }
  const metrics = data.readUInt16BE(hhea + 34);
  const advances: number[] = [];
  for (let index = 0; index < metrics; index++) advances.push(data.readUInt16BE(hmtx + 4 * index));
  const gpos = offsets.get('GPOS');
  const face: Face = {
    unitsPerEm: data.readUInt16BE(head + 18),
    glyphForCodePoint: readCmap(data, cmap),
    advances,
    kerning: gpos === undefined ? new Map() : readPairKerning(data, gpos),
  };
  faces.set(family, face);
  return face;
};

/// The glyphs a run maps to, with the unmapped ones falling back to the face's own notdef advance.
const glyphsOf = (face: Face, text: string): number[] =>
  [...text].map((character) => face.glyphForCodePoint.get(character.codePointAt(0) ?? 0) ?? 0);

/// The width one unbroken run of text occupies, kerned as a shaper would kern it.
export const measureRun = (text: string, run: SmileFontRun): number => {
  if (text.length === 0) return 0;
  const face = loadFace(run.fontFamily);
  const glyphs = glyphsOf(face, text);
  let units = 0;
  for (let index = 0; index < glyphs.length; index++) {
    const glyph = glyphs[index]!;
    units += face.advances[Math.min(glyph, face.advances.length - 1)] ?? 0;
    const next = glyphs[index + 1];
    if (next !== undefined) units += face.kerning.get(kernKey(glyph, next)) ?? 0;
  }
  // Letter spacing is added per character including the last, which is what React Native's own text does.
  return (units * run.fontSize) / face.unitsPerEm + (run.letterSpacing ?? 0) * glyphs.length;
};

/// Whether a face is one of the bundled DM Sans weights, so an unmeasurable family fails loudly.
export const isBundledFace = (family: string | undefined): family is string =>
  family !== undefined && family.startsWith('DMSans-');
