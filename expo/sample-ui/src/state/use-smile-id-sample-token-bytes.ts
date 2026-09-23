/// Byte helpers the decoder needs, in plain TypeScript: Hermes has no Buffer and no synchronous digest.

const BASE64_URL_ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

/// Padding-optional base64url to bytes; null when the length cannot be a base64 encoding.
export const smileIDSampleBase64UrlBytes = (segment: string): Uint8Array | null => {
  const text = segment.replace(/=+$/, '');
  if (text.length % 4 === 1) return null;
  const bytes = new Uint8Array(Math.floor((text.length * 3) / 4));
  let buffer = 0;
  let bits = 0;
  let at = 0;
  for (const char of text) {
    const value = BASE64_URL_ALPHABET.indexOf(char);
    if (value < 0) return null;
    buffer = (buffer << 6) | value;
    bits += 6;
    if (bits >= 8) {
      bits -= 8;
      bytes[at++] = (buffer >> bits) & 0xff;
    }
  }
  return bytes;
};

/// Base64url without padding, the form a JWT segment is minted in.
export const smileIDSampleBase64UrlEncode = (text: string): string => {
  const bytes = smileIDSampleUtf8Bytes(text);
  let out = '';
  for (let at = 0; at < bytes.length; at += 3) {
    const chunk = (bytes[at]! << 16) | ((bytes[at + 1] ?? 0) << 8) | (bytes[at + 2] ?? 0);
    const count = Math.min(3, bytes.length - at) + 1;
    for (let index = 0; index < count; index++) {
      out += BASE64_URL_ALPHABET[(chunk >> (18 - index * 6)) & 0x3f];
    }
  }
  return out;
};

/// UTF-8 bytes to text, replacing a malformed sequence the way Kotlin's decoder does.
export const smileIDSampleUtf8Text = (bytes: Uint8Array): string => {
  let out = '';
  let at = 0;
  while (at < bytes.length) {
    const lead = bytes[at]!;
    const width = lead < 0x80 ? 1 : lead >> 5 === 0x6 ? 2 : lead >> 4 === 0xe ? 3 : lead >> 3 === 0x1e ? 4 : 0;
    const tail = bytes.subarray(at + 1, at + width);
    if (width === 0 || tail.length !== width - 1 || tail.some((byte) => byte >> 6 !== 0x2)) {
      out += '�';
      at += 1;
      continue;
    }
    let code = width === 1 ? lead : lead & (0xff >> (width + 1));
    for (const byte of tail) code = (code << 6) | (byte & 0x3f);
    out += String.fromCodePoint(code);
    at += width;
  }
  return out;
};

/// Text to UTF-8 bytes.
export const smileIDSampleUtf8Bytes = (text: string): Uint8Array => {
  const bytes: number[] = [];
  for (const char of text) {
    const code = char.codePointAt(0)!;
    if (code < 0x80) bytes.push(code);
    else if (code < 0x800) bytes.push(0xc0 | (code >> 6), 0x80 | (code & 0x3f));
    else if (code < 0x10000)
      bytes.push(0xe0 | (code >> 12), 0x80 | ((code >> 6) & 0x3f), 0x80 | (code & 0x3f));
    else
      bytes.push(
        0xf0 | (code >> 18),
        0x80 | ((code >> 12) & 0x3f),
        0x80 | ((code >> 6) & 0x3f),
        0x80 | (code & 0x3f),
      );
  }
  return Uint8Array.from(bytes);
};

const ROUND = Uint32Array.from([
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
]);

const rotate = (value: number, by: number) => (value >>> by) | (value << (32 - by));

/// SHA-256, so the session handle matches the other three apps byte for byte.
export const smileIDSampleSha256 = (message: Uint8Array): Uint8Array => {
  const length = message.length;
  const padded = new Uint8Array(Math.ceil((length + 9) / 64) * 64);
  padded.set(message);
  padded[length] = 0x80;
  const view = new DataView(padded.buffer);
  view.setUint32(padded.length - 8, Math.floor((length * 8) / 0x100000000));
  view.setUint32(padded.length - 4, (length * 8) >>> 0);

  const hash = Uint32Array.from([
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ]);
  const words = new Uint32Array(64);
  for (let block = 0; block < padded.length; block += 64) {
    for (let index = 0; index < 16; index++) words[index] = view.getUint32(block + index * 4);
    for (let index = 16; index < 64; index++) {
      const early = words[index - 15]!;
      const late = words[index - 2]!;
      const s0 = rotate(early, 7) ^ rotate(early, 18) ^ (early >>> 3);
      const s1 = rotate(late, 17) ^ rotate(late, 19) ^ (late >>> 10);
      words[index] = (words[index - 16]! + s0 + words[index - 7]! + s1) >>> 0;
    }
    let [a, b, c, d, e, f, g, h] = Array.from(hash);
    for (let index = 0; index < 64; index++) {
      const s1 = rotate(e!, 6) ^ rotate(e!, 11) ^ rotate(e!, 25);
      const choose = (e! & f!) ^ (~e! & g!);
      const first = (h! + s1 + choose + ROUND[index]! + words[index]!) >>> 0;
      const s0 = rotate(a!, 2) ^ rotate(a!, 13) ^ rotate(a!, 22);
      const majority = (a! & b!) ^ (a! & c!) ^ (b! & c!);
      const second = (s0 + majority) >>> 0;
      h = g;
      g = f;
      f = e;
      e = (d! + first) >>> 0;
      d = c;
      c = b;
      b = a;
      a = (first + second) >>> 0;
    }
    [a, b, c, d, e, f, g, h].forEach((value, index) => {
      hash[index] = (hash[index]! + value!) >>> 0;
    });
  }
  const out = new Uint8Array(32);
  const outView = new DataView(out.buffer);
  hash.forEach((value, index) => outView.setUint32(index * 4, value));
  return out;
};
