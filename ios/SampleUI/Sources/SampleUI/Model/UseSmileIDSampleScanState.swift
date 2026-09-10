/// What the scanner is doing, said out loud: each state exists to be shown, since decoding and navigating in one frame reads as a freeze.
public enum UseSmileIDSampleScanState: Equatable, Sendable {
  /// Camera live, nothing in hand.
  case searching
  /// A code is in hand and being decoded. Brief, but it is the moment worth acknowledging.
  case found
  /// Decoded, and held on screen long enough to be read before the screen leaves.
  case linked(handle: String, remaining: String)
  /// Decoded into something that is not a session. The reason names a claim, never a value.
  case rejected(reason: String)
}
