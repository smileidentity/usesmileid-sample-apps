import type { UseSmileIDSampleKycIdType } from './use-smile-id-sample-id-details';

/// The regex as this engine compiles it, or null when it will not.
export const smileIDSampleCompiled = (regex: string): RegExp | null => {
  try {
    return new RegExp(regex);
  } catch {
    return null;
  }
};

/// The trimmed number against the whole regex; a regex this engine cannot compile checks nothing.
export const smileIDSampleIdNumberAccepts = (regex: string, number: string): boolean => {
  const trimmed = number.trim();
  if (trimmed.length === 0) return false;
  if (smileIDSampleCompiled(regex) === null) return true;
  return smileIDSampleCompiled(`^(?:${regex})$`)?.test(trimmed) ?? true;
};

/// An example that fully matches `regex` (spec/id-number-hints.json), or null outside the subset.
export const smileIDSampleIdNumberExample = (regex: string): string | null => {
  try {
    return new HintParser(regex).parse();
  } catch (error) {
    if (error instanceof Unsupported) return null;
    throw error;
  }
};

/// What the empty field shows for the chosen type.
export const smileIDSampleIdNumberPlaceholder = (type: UseSmileIDSampleKycIdType | null): string => {
  if (type === null) return 'Choose an ID type first';
  const hint = smileIDSampleCompiled(type.regex) === null ? null : smileIDSampleIdNumberExample(type.regex);
  return hint === null ? `Enter your ${type.label}` : `e.g. ${hint}`;
};

/// The line under a non-empty number that does not fit, which repeats the example; null when it fits.
export const smileIDSampleIdNumberError = (type: UseSmileIDSampleKycIdType | null, number: string): string | null => {
  if (type === null || number.trim().length === 0 || smileIDSampleIdNumberAccepts(type.regex, number)) return null;
  const hint = smileIDSampleIdNumberExample(type.regex);
  return hint === null
    ? `Doesn't match the ${type.label} format`
    : `Doesn't match the ${type.label} format, e.g. ${hint}`;
};

class Unsupported extends Error {}

const isAlnum = (c: string) => /^[A-Za-z0-9]$/.test(c);

/// A recursive-descent reading of the subset the server's regexes use; anything else throws Unsupported.
class HintParser {
  private at = 0;

  constructor(private readonly source: string) {}

  parse(): string {
    if (this.peek() === '^') this.at++;
    const out = this.alternation();
    if (this.at !== this.source.length) throw new Unsupported();
    return out;
  }

  private peek(offset = 0): string | null {
    return this.at + offset < this.source.length ? this.source[this.at + offset]! : null;
  }

  private take(): string {
    const c = this.peek();
    if (c === null) throw new Unsupported();
    this.at++;
    return c;
  }

  private alternation(): string {
    const first = this.sequence();
    while (this.peek() === '|') {
      this.at++;
      this.sequence();
    }
    return first;
  }

  private sequence(): string {
    let out = '';
    for (;;) {
      const c = this.peek();
      if (c === null || c === '|' || c === ')') return out;
      if (c === '$') {
        this.at++;
        const next = this.peek();
        if (next !== null && next !== '|' && next !== ')') throw new Unsupported();
        continue;
      }
      const atom = this.atom();
      out += atom.repeat(this.quantifier());
    }
  }

  private atom(): string {
    const c = this.take();
    switch (c) {
      case '(': {
        if (this.peek() === '?') {
          this.at++;
          if (this.take() !== ':') throw new Unsupported();
        }
        const inner = this.alternation();
        if (this.take() !== ')') throw new Unsupported();
        return inner;
      }
      case '[':
        return this.charClass();
      case '\\': {
        const escaped = this.take();
        if (escaped === 'd') return '0';
        if (escaped === 'w') return 'A';
        if (isAlnum(escaped)) throw new Unsupported();
        return escaped;
      }
      case '.':
      case '*':
      case '+':
      case '?':
      case '{':
      case '}':
      case '^':
      case '$':
        throw new Unsupported();
      default:
        return c;
    }
  }

  private charClass(): string {
    if (this.peek() === '^') throw new Unsupported();
    const members: [number, number][] = [];
    for (;;) {
      let c = this.take();
      if (c === ']' && members.length > 0) break;
      if (c === '\\') {
        const escaped = this.take();
        if (escaped === 'd') {
          members.push([0x30, 0x39]);
          continue;
        }
        if (escaped === 'w') {
          members.push([0x41, 0x5a], [0x61, 0x7a], [0x30, 0x39], [0x5f, 0x5f]);
          continue;
        }
        if (isAlnum(escaped)) throw new Unsupported();
        c = escaped;
      }
      const next = this.peek(1);
      if (this.peek() === '-' && next !== null && next !== ']') {
        this.at++;
        const high = this.take();
        if (high === '\\') throw new Unsupported();
        members.push([c.charCodeAt(0), high.charCodeAt(0)]);
      } else {
        members.push([c.charCodeAt(0), c.charCodeAt(0)]);
      }
    }
    for (const pick of ['A', '0', 'a']) {
      const unit = pick.charCodeAt(0);
      if (members.some(([low, high]) => low <= unit && unit <= high)) return pick;
    }
    return String.fromCharCode(members[0]![0]);
  }

  private quantifier(): number {
    let n: number;
    switch (this.peek()) {
      case '*':
      case '?':
        this.at++;
        n = 0;
        break;
      case '+':
        this.at++;
        n = 1;
        break;
      case '{': {
        const match = /^\{(\d+)(,(\d*))?\}/.exec(this.source.slice(this.at));
        if (match === null) throw new Unsupported();
        this.at += match[0].length;
        const low = Number(match[1]);
        if (match[2] === undefined) n = low;
        else if (match[3] !== '') n = Number(match[3]);
        else n = Math.max(low, 1);
        break;
      }
      default:
        return 1;
    }
    if (this.peek() === '?' || this.peek() === '+') throw new Unsupported();
    return n;
  }
}
