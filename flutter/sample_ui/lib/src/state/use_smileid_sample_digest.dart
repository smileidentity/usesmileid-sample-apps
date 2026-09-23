import 'dart:convert';
import 'dart:typed_data';

/// SHA-256 of [text] as lowercase hex, cut to [bytes].
String useSmileIDSampleDigest(String text, {int bytes = 4}) {
  final Uint8List digest = _sha256(utf8.encode(text));
  return <String>[
    for (final int byte in digest.take(bytes))
      byte.toRadixString(16).padLeft(2, '0'),
  ].join();
}

Uint8List _sha256(List<int> message) {
  final int bitLength = message.length * 8;
  final List<int> padded = <int>[...message, 0x80];
  while (padded.length % 64 != 56) {
    padded.add(0);
  }
  for (int shift = 56; shift >= 0; shift -= 8) {
    padded.add((bitLength >> shift) & 0xff);
  }
  final List<int> hash = List<int>.of(_initial);
  final List<int> w = List<int>.filled(64, 0);
  for (int chunk = 0; chunk < padded.length; chunk += 64) {
    for (int i = 0; i < 16; i++) {
      final int at = chunk + i * 4;
      w[i] =
          (padded[at] << 24) |
          (padded[at + 1] << 16) |
          (padded[at + 2] << 8) |
          padded[at + 3];
    }
    for (int i = 16; i < 64; i++) {
      final int s0 =
          _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
      final int s1 =
          _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & _mask;
    }
    int a = hash[0], b = hash[1], c = hash[2], d = hash[3];
    int e = hash[4], f = hash[5], g = hash[6], h = hash[7];
    for (int i = 0; i < 64; i++) {
      final int s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final int choice = (e & f) ^ (~e & _mask & g);
      final int t1 = (h + s1 + choice + _k[i] + w[i]) & _mask;
      final int s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final int majority = (a & b) ^ (a & c) ^ (b & c);
      final int t2 = (s0 + majority) & _mask;
      h = g;
      g = f;
      f = e;
      e = (d + t1) & _mask;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & _mask;
    }
    final List<int> round = <int>[a, b, c, d, e, f, g, h];
    for (int i = 0; i < 8; i++) {
      hash[i] = (hash[i] + round[i]) & _mask;
    }
  }
  final ByteData out = ByteData(32);
  for (int i = 0; i < 8; i++) {
    out.setUint32(i * 4, hash[i]);
  }
  return out.buffer.asUint8List();
}

int _rotr(int value, int by) => ((value >> by) | (value << (32 - by))) & _mask;

const int _mask = 0xffffffff;

const List<int> _initial = <int>[
  0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, //
  0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
];

const List<int> _k = <int>[
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, //
  0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
  0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
  0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
  0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
  0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];
