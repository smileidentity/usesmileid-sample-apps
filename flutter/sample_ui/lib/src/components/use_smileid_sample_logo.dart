import 'dart:ui';

/// The SmileID logo as path data, in the SDK attribution drawable's 143 × 16 viewport, split into the parts the intro animates.
abstract final class UseSmileIDSampleLogo {
  /// The lock and the "SmileID" name together.
  static const Rect bounds = Rect.fromLTRB(79.5, 3, 132.5, 13);

  /// The lock: the square body and the dome shackle sitting on its top-right edge.
  static const Rect markBounds = Rect.fromLTRB(79.5, 3, 88.7, 12.84);

  /// The "SmileID" letters, which the intro unrolls out of the lock.
  static const Rect wordmarkBounds = Rect.fromLTRB(90.69, 5.55, 132.5, 13);

  /// The middle of the body's bottom edge, where it squashes from when the shackle lands.
  static const Offset bodyBase = Offset(82.16, 12.84);

  /// The body's top edge, which the shackle rides.
  static const double bodyTop = 7.86;

  /// How far left the shackle moves to sit squarely on the body, which reads as locked.
  static const double lockedShackleShift = -3.9;

  static const String _wordmark =
      'M92.77,10.54C92.83,10.96 93.14,11.46 93.99,11.46C94.72,11.46 95.07,11.21 95.07,10.79C95.07,10.38 94.82,10.19 94.38,10.14L92.88,9.98C91.57,9.84 90.8,9.08 90.8,7.85C90.8,6.47 91.84,5.55 93.93,5.55C96.17,5.55 97.07,6.61 97.15,7.86H95.05C94.98,7.39 94.6,7.09 93.94,7.09C93.35,7.09 92.95,7.3 92.95,7.69C92.95,8 93.14,8.23 93.65,8.27L94.88,8.38C96.53,8.52 97.22,9.31 97.22,10.62C97.22,12.02 96.34,13 93.95,13C91.56,13 90.8,11.78 90.69,10.54H92.77V10.54Z'
      'M107.51,9.61V12.82H105.42V9.95C105.42,9.37 105.21,9 104.64,9C104.01,9 103.74,9.4 103.74,10.23V12.82H101.69V9.95C101.69,9.37 101.47,9 100.9,9C100.27,9 100.01,9.4 100.01,10.23V12.82H97.92V7.49H100.01V8.31C100.34,7.69 100.9,7.32 101.78,7.32C102.67,7.32 103.26,7.73 103.55,8.45C103.89,7.75 104.47,7.32 105.41,7.32C106.85,7.32 107.51,8.21 107.51,9.61H107.51Z'
      'M108.5,7.82V5.73H110.58V7.82H108.5ZM108.5,12.82V8.31H110.58V12.82H108.5Z'
      'M111.57,12.82V5.73H113.65V12.82H111.57V12.82Z'
      'M118.27,11.17H120.33C120.13,12.15 119.34,12.99 117.38,12.99C115.12,12.99 114.36,11.57 114.36,10.14C114.36,8.61 115.26,7.32 117.38,7.32C119.71,7.32 120.34,8.74 120.34,10.22C120.34,10.4 120.33,10.57 120.31,10.67H116.39C116.5,11.36 116.84,11.61 117.42,11.61C117.83,11.61 118.13,11.42 118.27,11.17L118.27,11.17ZM116.4,9.52H118.37C118.31,8.97 118.04,8.66 117.41,8.66C116.83,8.66 116.52,8.88 116.4,9.52Z'
      'M124.41,12.82H122.28L122.28,5.73H124.41L124.41,12.82H124.41Z'
      'M132.5,9.26C132.5,11.08 131.43,12.82 129.14,12.82H125.39V5.73H129.14C131.43,5.73 132.5,7.43 132.5,9.26ZM128.64,11.13C129.77,11.13 130.27,10.49 130.27,9.26C130.27,8.02 129.75,7.41 128.64,7.41H127.53V11.13H128.64Z';

  static const String _body = 'M84.82,7.86H79.5V12.84H84.82V7.86Z';

  static const String _shackle =
      'M86.11,3C86.08,3 86.06,3 86.04,3C86.01,3 85.99,3 85.96,3C84.61,3 83.4,3.89 83.4,5.84V7.86H88.7V5.84C88.7,3.89 87.47,3 86.11,3Z';

  /// The "SmileID" letters, parsed once; only ever drawn, never mutated.
  static final Path wordmark = _parse(_wordmark);

  /// The square body.
  static final Path body = _parse(_body);

  /// The dome shackle.
  static final Path shackle = _parse(_shackle);
}

/// Parses the absolute M, L, H, V, C and Z commands, which is all the logo's data uses.
Path _parse(String data) {
  final Path path = Path();
  final Iterable<RegExpMatch> tokens = RegExp(
    r'[MLHVCZ]|-?(?:\d+\.?\d*|\.\d+)',
  ).allMatches(data);
  String command = 'M';
  final List<double> numbers = <double>[];
  double x = 0;
  double y = 0;

  void flush() {
    int at = 0;
    bool has(int count) => numbers.length - at >= count;
    switch (command) {
      case 'M' || 'L':
        while (has(2)) {
          x = numbers[at++];
          y = numbers[at++];
          if (command == 'M') {
            path.moveTo(x, y);
            // A moveto's further pairs are linetos, as SVG defines them.
            command = 'L';
          } else {
            path.lineTo(x, y);
          }
        }
      case 'H':
        while (has(1)) {
          x = numbers[at++];
          path.lineTo(x, y);
        }
      case 'V':
        while (has(1)) {
          y = numbers[at++];
          path.lineTo(x, y);
        }
      case 'C':
        while (has(6)) {
          path.cubicTo(
            numbers[at++],
            numbers[at++],
            numbers[at++],
            numbers[at++],
            numbers[at],
            numbers[at + 1],
          );
          x = numbers[at++];
          y = numbers[at++];
        }
    }
    numbers.clear();
  }

  for (final RegExpMatch token in tokens) {
    final String text = token[0]!;
    final double? number = double.tryParse(text);
    if (number != null) {
      numbers.add(number);
      continue;
    }
    flush();
    command = text;
    if (command == 'Z') {
      path.close();
    }
  }
  flush();
  return path;
}
