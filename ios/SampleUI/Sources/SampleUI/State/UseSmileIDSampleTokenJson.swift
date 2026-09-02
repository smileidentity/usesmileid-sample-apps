/// The smallest JSON reader that can tell a string from a number from a boolean, which is what every
/// token binding rule turns on. Hand-written rather than `JSONSerialization`, which reads `true` and
/// `1` back as the same `NSNumber` and has no nesting cap a test can pin.
indirect enum TokenJson: Equatable {
  case obj([String: TokenJson])
  case arr([TokenJson])
  case str(String)
  /// Held as written, so an epoch second reads back exactly.
  case num(String)
  case bool(Bool)
  case null
}

extension [String: TokenJson] {
  func obj(_ key: String) -> [String: TokenJson]? {
    if case .obj(let members)? = self[key] {
      return members
    }
    return nil
  }

  func string(_ key: String) -> String? {
    if case .str(let value)? = self[key] {
      return value
    }
    return nil
  }

  func boolean(_ key: String) -> Bool? {
    if case .bool(let value)? = self[key] {
      return value
    }
    return nil
  }

  /// RFC 7519 allows a non-integer NumericDate, so the literal reads as a Double and truncates.
  func seconds(_ key: String) -> Double? {
    guard case .num(let literal)? = self[key], let value = Double(literal), value.isFinite else { return nil }
    return value.rounded(.towardZero)
  }
}

/// Nil on anything malformed or trailing; the caller turns that into a rejection with a reason.
/// A token arrives from a clipboard or a QR code, so its nesting is untrusted: without a cap a deeply
/// nested payload takes the app down with a stack overflow.
func parseTokenJson(_ text: String) -> TokenJson? {
  var reader = TokenJsonReader(text)
  return reader.parse()
}

private struct TokenJsonReader {
  private let text: [Character]
  private var at = 0

  init(_ text: String) {
    self.text = Array(text)
  }

  mutating func parse() -> TokenJson? {
    guard let value = value(depth: 0) else { return nil }
    skipWhitespace()
    return at == text.count ? value : nil
  }

  private mutating func value(depth: Int) -> TokenJson? {
    // Untrusted nesting: capped, see parseTokenJson.
    guard depth <= Self.maxDepth else { return nil }
    skipWhitespace()
    guard let char = peek() else { return nil }
    switch char {
    case "{": return obj(depth: depth)
    case "[": return arr(depth: depth)
    case "\"": return string().map(TokenJson.str)
    case "t": return literal("true", .bool(true))
    case "f": return literal("false", .bool(false))
    case "n": return literal("null", .null)
    default: return number()
    }
  }

  private mutating func obj(depth: Int) -> TokenJson? {
    at += 1
    var members: [String: TokenJson] = [:]
    skipWhitespace()
    if peek() == "}" {
      at += 1
      return .obj(members)
    }
    while true {
      skipWhitespace()
      guard peek() == "\"", let key = string() else { return nil }
      skipWhitespace()
      guard peek() == ":" else { return nil }
      at += 1
      guard let member = value(depth: depth + 1) else { return nil }
      members[key] = member
      skipWhitespace()
      switch peek() {
      case ",": at += 1
      case "}":
        at += 1
        return .obj(members)
      default: return nil
      }
    }
  }

  private mutating func arr(depth: Int) -> TokenJson? {
    at += 1
    var items: [TokenJson] = []
    skipWhitespace()
    if peek() == "]" {
      at += 1
      return .arr(items)
    }
    while true {
      guard let item = value(depth: depth + 1) else { return nil }
      items.append(item)
      skipWhitespace()
      switch peek() {
      case ",": at += 1
      case "]":
        at += 1
        return .arr(items)
      default: return nil
      }
    }
  }

  private mutating func string() -> String? {
    at += 1
    var value = ""
    while true {
      guard let char = peek() else { return nil }
      at += 1
      switch char {
      case "\"": return value
      case "\\":
        guard let escaped = escape() else { return nil }
        value.append(escaped)
      default: value.append(char)
      }
    }
  }

  private mutating func escape() -> Character? {
    guard let marker = peek() else { return nil }
    at += 1
    switch marker {
    case "\"", "\\", "/": return marker
    case "b": return "\u{8}"
    case "f": return "\u{C}"
    case "n": return "\n"
    case "r": return "\r"
    case "t": return "\t"
    case "u": return unicodeEscape()
    default: return nil
    }
  }

  /// One escaped code unit, or a surrogate pair written as two escapes, which is how JSON spells an emoji.
  private mutating func unicodeEscape() -> Character? {
    guard let unit = hex4() else { return nil }
    if let scalar = Unicode.Scalar(unit) {
      return Character(scalar)
    }
    guard UTF16.isLeadSurrogate(unit), peek() == "\\", peek(1) == "u" else { return nil }
    at += 2
    guard let trail = hex4(), UTF16.isTrailSurrogate(trail) else { return nil }
    var decoder = UTF16()
    var units = [unit, trail].makeIterator()
    guard case .scalarValue(let scalar) = decoder.decode(&units) else { return nil }
    return Character(scalar)
  }

  private mutating func hex4() -> UInt16? {
    guard at + Self.hexDigits <= text.count,
          let code = UInt16(String(text[at..<(at + Self.hexDigits)]), radix: 16)
    else { return nil }
    at += Self.hexDigits
    return code
  }

  private mutating func literal(_ word: String, _ value: TokenJson) -> TokenJson? {
    let end = at + word.count
    guard end <= text.count, String(text[at..<end]) == word else { return nil }
    at = end
    return value
  }

  private mutating func number() -> TokenJson? {
    let start = at
    if peek() == "-" {
      at += 1
    }
    while let char = peek(), char.isNumberPart {
      at += 1
    }
    let literal = String(text[start..<at])
    // Checked here rather than at the call site, so `{"exp":+}` cannot read as a claim.
    guard let value = Double(literal), value.isFinite else { return nil }
    return .num(literal)
  }

  private func peek(_ ahead: Int = 0) -> Character? {
    at + ahead < text.count ? text[at + ahead] : nil
  }

  private mutating func skipWhitespace() {
    while let char = peek(), char.isWhitespace {
      at += 1
    }
  }

  private static let maxDepth = 32
  private static let hexDigits = 4
}

private extension Character {
  var isNumberPart: Bool {
    isASCII && (isNumber || ".eE+-".contains(self))
  }
}
