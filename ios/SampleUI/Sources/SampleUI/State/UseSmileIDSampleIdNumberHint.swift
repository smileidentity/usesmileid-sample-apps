import Foundation

/// The ID-number hint and format check from `spec/id-number-hints.json`: the API gives a regex, never an example.
public enum UseSmileIDSampleIdNumberHint {
  /// An example that fully matches `regex`, or nil when the regex uses syntax outside the subset.
  public static func example(_ regex: String) -> String? {
    var parser = HintParser(Array(regex))
    return try? parser.parse()
  }

  /// What the empty field shows for the chosen type.
  public static func placeholder(_ type: UseSmileIDSampleKycIdType?) -> String {
    guard let type else { return "Choose an ID type first" }
    guard !type.regex.isBlank, compiled(type.regex) != nil, let example = example(type.regex) else {
      return "Enter your \(type.label)"
    }
    return "e.g. \(example)"
  }

  /// The trimmed number against the whole regex; a blank regex, or one this engine cannot compile, checks nothing.
  public static func accepts(_ regex: String, _ number: String) -> Bool {
    let trimmed = number.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return false }
    guard !regex.isBlank else { return true }
    guard compiled(regex) != nil, let whole = compiled("^(?:\(regex))$") else { return true }
    return whole.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) != nil
  }

  /// The line under a non-empty number that does not fit, which repeats the example; nil when it fits.
  public static func error(_ type: UseSmileIDSampleKycIdType?, _ number: String) -> String? {
    guard let type, !number.isBlank, !accepts(type.regex, number) else { return nil }
    return example(type.regex).map { "Doesn't match the \(type.label) format, e.g. \($0)" }
      ?? "Doesn't match the \(type.label) format"
  }

  static func compiled(_ regex: String) -> NSRegularExpression? {
    try? NSRegularExpression(pattern: regex)
  }
}

private struct Unsupported: Error {}

/// A recursive-descent reading of the subset the server's regexes use; anything else throws `Unsupported`.
private struct HintParser {
  /// A longer repeat is outside the subset, so an API regex cannot make the hint allocate without limit.
  static let maxRepeat = 64

  private let source: [Character]
  private var at = 0

  init(_ source: [Character]) {
    self.source = source
  }

  mutating func parse() throws -> String {
    if peek() == "^" {
      at += 1
    }
    let out = try alternation()
    guard at == source.count else { throw Unsupported() }
    return out
  }

  private func peek(_ offset: Int = 0) -> Character? {
    at + offset < source.count ? source[at + offset] : nil
  }

  private mutating func take() throws -> Character {
    guard let c = peek() else { throw Unsupported() }
    at += 1
    return c
  }

  private mutating func alternation() throws -> String {
    let first = try sequence()
    while peek() == "|" {
      at += 1
      _ = try sequence()
    }
    return first
  }

  private mutating func sequence() throws -> String {
    var out = ""
    while let c = peek(), c != "|", c != ")" {
      if c == "$" {
        at += 1
        if let next = peek(), next != "|", next != ")" {
          throw Unsupported()
        }
        continue
      }
      let part = try atom()
      try out += String(repeating: part, count: quantifier())
    }
    return out
  }

  private mutating func atom() throws -> String {
    let c = try take()
    switch c {
    case "(":
      if peek() == "?" {
        at += 1
        guard try take() == ":" else { throw Unsupported() }
      }
      let inner = try alternation()
      guard try take() == ")" else { throw Unsupported() }
      return inner
    case "[":
      return try String(charClass())
    case "\\":
      let escaped = try take()
      switch escaped {
      case "d": return "0"
      case "w": return "A"
      default:
        if escaped.isLetter || escaped.isNumber {
          throw Unsupported()
        }
        return String(escaped)
      }
    case ".", "*", "+", "?", "{", "}", "^", "$":
      throw Unsupported()
    default:
      return String(c)
    }
  }

  private mutating func charClass() throws -> Character {
    if peek() == "^" {
      throw Unsupported()
    }
    var members: [ClosedRange<Character>] = []
    while true {
      var c = try take()
      if c == "]", !members.isEmpty {
        break
      }
      if c == "\\" {
        let escaped = try take()
        switch escaped {
        case "d":
          members.append("0"..."9")
          continue
        case "w":
          members += ["A"..."Z", "a"..."z", "0"..."9", "_"..."_"]
          continue
        default:
          if escaped.isLetter || escaped.isNumber {
            throw Unsupported()
          }
          c = escaped
        }
      }
      if peek() == "-", let next = peek(1), next != "]" {
        at += 1
        let high = try take()
        if high == "\\" || high < c {
          throw Unsupported()
        }
        members.append(c...high)
      } else {
        members.append(c...c)
      }
    }
    return ["A", "0", "a"].first { pick in members.contains { $0.contains(pick) } } ?? members[0].lowerBound
  }

  private mutating func quantifier() throws -> Int {
    let n: Int
    switch peek() {
    case "*", "?":
      at += 1
      n = 0
    case "+":
      at += 1
      n = 1
    case "{":
      at += 1
      let low = digits()
      guard let lower = Int(low) else { throw Unsupported() }
      if peek() == "," {
        at += 1
        let high = digits()
        if high.isEmpty {
          n = max(lower, 1)
        } else {
          guard let upper = Int(high) else { throw Unsupported() }
          n = upper
        }
      } else {
        n = lower
      }
      guard try take() == "}" else { throw Unsupported() }
    default:
      return 1
    }
    if peek() == "?" || peek() == "+" || n > Self.maxRepeat {
      throw Unsupported()
    }
    return n
  }

  private mutating func digits() -> String {
    var out = ""
    while let c = peek(), c.isASCII, c.isNumber {
      out.append(c)
      at += 1
    }
    return out
  }
}
