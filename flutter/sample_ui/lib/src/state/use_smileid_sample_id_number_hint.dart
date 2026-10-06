import '../use_smileid_sample_strings.dart';
import 'use_smileid_sample_id_details.dart';

/// The ID-number hint and format check from `spec/id-number-hints.json`: the API gives a regex, never an example.
abstract final class UseSmileIDSampleIdNumberHint {
  /// An example that fully matches [regex], or null when the regex uses syntax outside the subset.
  static String? example(String regex) {
    try {
      return _HintParser(regex).parse();
    } on _Unsupported {
      return null;
    }
  }

  /// What the empty field shows for the chosen type.
  static String placeholder(
    UseSmileIDSampleKycIdType? type,
    UseSmileIDSampleStrings strings,
  ) {
    if (type == null) {
      return strings.kycChooseIdTypeFirst;
    }
    final String? hint =
        type.regex.trim().isEmpty || compiled(type.regex) == null
        ? null
        : example(type.regex);
    return hint == null
        ? strings.kycIdNumberPlaceholder(idType: type.label)
        : strings.kycIdNumberExample(example: hint);
  }

  /// The trimmed number against the whole regex; a blank regex, or one this engine cannot compile, checks nothing.
  static bool accepts(String regex, String number) {
    final String trimmed = number.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    if (regex.trim().isEmpty) {
      return true;
    }
    if (compiled(regex) == null) {
      return true;
    }
    return compiled('^(?:$regex)\$')?.hasMatch(trimmed) ?? true;
  }

  /// The line under a non-empty number that does not fit, which repeats the example; null when it fits.
  static String? error(
    UseSmileIDSampleKycIdType? type,
    String number,
    UseSmileIDSampleStrings strings,
  ) {
    if (type == null || number.trim().isEmpty || accepts(type.regex, number)) {
      return null;
    }
    final String? hint = example(type.regex);
    return hint == null
        ? strings.kycIdNumberInvalid(idType: type.label)
        : strings.kycIdNumberInvalidExample(idType: type.label, example: hint);
  }

  /// The regex as Dart compiles it, or null when it will not.
  static RegExp? compiled(String regex) {
    try {
      return RegExp(regex);
    } on FormatException {
      return null;
    }
  }
}

class _Unsupported implements Exception {}

/// A longer repeat is outside the subset, so an API regex cannot make the hint allocate without limit.
const int _maxRepeat = 64;

/// A recursive-descent reading of the subset the server's regexes use; anything else throws [_Unsupported].
class _HintParser {
  _HintParser(this._source);

  final String _source;
  int _at = 0;

  String parse() {
    if (_peek() == '^') {
      _at++;
    }
    final String out = _alternation();
    if (_at != _source.length) {
      throw _Unsupported();
    }
    return out;
  }

  String? _peek([int offset = 0]) =>
      _at + offset < _source.length ? _source[_at + offset] : null;

  String _take() {
    final String? c = _peek();
    if (c == null) {
      throw _Unsupported();
    }
    _at++;
    return c;
  }

  String _alternation() {
    final String first = _sequence();
    while (_peek() == '|') {
      _at++;
      _sequence();
    }
    return first;
  }

  String _sequence() {
    final StringBuffer out = StringBuffer();
    while (true) {
      final String? c = _peek();
      if (c == null || c == '|' || c == ')') {
        return out.toString();
      }
      if (c == r'$') {
        _at++;
        final String? next = _peek();
        if (next != null && next != '|' && next != ')') {
          throw _Unsupported();
        }
        continue;
      }
      final String atom = _atom();
      out.write(atom * _quantifier());
    }
  }

  String _atom() {
    final String c = _take();
    switch (c) {
      case '(':
        if (_peek() == '?') {
          _at++;
          if (_take() != ':') {
            throw _Unsupported();
          }
        }
        final String inner = _alternation();
        if (_take() != ')') {
          throw _Unsupported();
        }
        return inner;
      case '[':
        return _charClass();
      case r'\':
        final String escaped = _take();
        if (escaped == 'd') {
          return '0';
        }
        if (escaped == 'w') {
          return 'A';
        }
        if (_isAlnum(escaped)) {
          throw _Unsupported();
        }
        return escaped;
      case '.' || '*' || '+' || '?' || '{' || '}' || '^' || r'$':
        throw _Unsupported();
      default:
        return c;
    }
  }

  String _charClass() {
    if (_peek() == '^') {
      throw _Unsupported();
    }
    final List<(int, int)> members = <(int, int)>[];
    while (true) {
      String c = _take();
      if (c == ']' && members.isNotEmpty) {
        break;
      }
      if (c == r'\') {
        final String escaped = _take();
        if (escaped == 'd') {
          members.add((0x30, 0x39));
          continue;
        }
        if (escaped == 'w') {
          members.addAll(<(int, int)>[
            (0x41, 0x5A),
            (0x61, 0x7A),
            (0x30, 0x39),
            (0x5F, 0x5F),
          ]);
          continue;
        }
        if (_isAlnum(escaped)) {
          throw _Unsupported();
        }
        c = escaped;
      }
      final String? next = _peek(1);
      if (_peek() == '-' && next != null && next != ']') {
        _at++;
        final String high = _take();
        if (high == r'\') {
          throw _Unsupported();
        }
        members.add((c.codeUnitAt(0), high.codeUnitAt(0)));
      } else {
        members.add((c.codeUnitAt(0), c.codeUnitAt(0)));
      }
    }
    for (final String pick in <String>['A', '0', 'a']) {
      final int unit = pick.codeUnitAt(0);
      if (members.any(((int, int) m) => m.$1 <= unit && unit <= m.$2)) {
        return pick;
      }
    }
    return String.fromCharCode(members.first.$1);
  }

  int _quantifier() {
    final int n;
    switch (_peek()) {
      case '*' || '?':
        _at++;
        n = 0;
      case '+':
        _at++;
        n = 1;
      case '{':
        final Match? match = RegExp(
          r'\{(\d+)(,(\d*))?\}',
        ).matchAsPrefix(_source, _at);
        if (match == null) {
          throw _Unsupported();
        }
        _at = match.end;
        final int low = int.parse(match.group(1)!);
        if (match.group(2) == null) {
          n = low;
        } else if (match.group(3)!.isNotEmpty) {
          n = int.parse(match.group(3)!);
        } else {
          n = low < 1 ? 1 : low;
        }
      default:
        return 1;
    }
    if (_peek() == '?' || _peek() == '+' || n > _maxRepeat) {
      throw _Unsupported();
    }
    return n;
  }

  static bool _isAlnum(String c) => RegExp(r'^[A-Za-z0-9]$').hasMatch(c);
}
