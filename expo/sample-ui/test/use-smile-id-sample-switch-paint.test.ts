import type { LaidOutNode } from './layout/layout-tree';
import { PIXEL_RATIO, paintTree } from './paint/paint-tree';

const ON = 'rgb(0, 0, 255)';
const THUMB = 'rgb(255, 0, 0)';
const OFF = 'rgb(0, 255, 0)';
const edges = { top: 0, right: 0, bottom: 0, left: 0 };

/// An on switch at (10, 10), alone in a view laid out in [direction], with [overrides] on its props.
const tree = (direction: 'ltr' | 'rtl', overrides: Record<string, unknown> = {}): LaidOutNode => ({
  type: 'View',
  props: { style: { direction } },
  left: 0,
  top: 0,
  width: 80,
  height: 50,
  padding: edges,
  border: edges,
  children: [
    {
      type: 'RCTSwitch',
      props: {
        value: true,
        onTintColor: ON,
        tintColor: OFF,
        thumbTintColor: THUMB,
        style: { backgroundColor: OFF },
        ...overrides,
      },
      left: 10,
      top: 10,
      width: 51,
      height: 31,
      padding: edges,
      border: edges,
      children: [],
    },
  ],
});

/// The colour painted at a layout point.
const colourAt = (root: LaidOutNode, x: number, y: number): string => {
  const [r, g, b] = paintTree(root)
    .getContext('2d')
    .getImageData(Math.round(x * PIXEL_RATIO), Math.round(y * PIXEL_RATIO), 1, 1).data;
  return `rgb(${r ?? 0}, ${g ?? 0}, ${b ?? 0})`;
};

/// An on switch puts its thumb at the end its layout reads towards, as UISwitch mirrors right to left.
describe('the painted switch', () => {
  const nearEnd = 10 + 2 + 13.5;
  const farEnd = 10 + 51 - 2 - 13.5;

  it('puts an on thumb at the right end left to right', () => {
    expect(colourAt(tree('ltr'), farEnd, 25.5)).toBe(THUMB);
    expect(colourAt(tree('ltr'), nearEnd, 25.5)).toBe(ON);
  });

  it('puts an on thumb at the left end right to left', () => {
    expect(colourAt(tree('rtl'), nearEnd, 25.5)).toBe(THUMB);
    expect(colourAt(tree('rtl'), farEnd, 25.5)).toBe(ON);
  });

  it('fades a disabled switch as one layer, so the thumb shows no track through it', () => {
    const [red, green, blue] = (colourAt(tree('ltr', { disabled: true }), farEnd, 25.5).match(/\d+/g) ?? []).map(Number);
    expect(blue).toBe(0);
    expect(Math.abs((red ?? 0) - 128)).toBeLessThanOrEqual(3);
    expect(Math.abs((green ?? 0) - 128)).toBeLessThanOrEqual(3);
  });

  it.each([
    ['a border', { style: { backgroundColor: OFF, borderWidth: 1 } }, /draws no border or shadow/],
    ['a shadow', { style: { backgroundColor: OFF, shadowOpacity: 0.2 } }, /draws no border or shadow/],
    ['no thumb tint', { thumbTintColor: undefined }, /string track and thumb tints/],
    [
      'a rotated disabled fade',
      { disabled: true, style: { backgroundColor: OFF, transform: [{ rotate: '90deg' }] } },
      /unrotated, unmirrored layer/,
    ],
  ] as const)('fails rather than drawing %s', (_case, overrides, message) => {
    expect(() => paintTree(tree('ltr', overrides))).toThrow(message);
  });
});
