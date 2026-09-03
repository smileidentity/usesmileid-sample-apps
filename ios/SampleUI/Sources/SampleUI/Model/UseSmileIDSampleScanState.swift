/// What the scanner is doing, said out loud on screen.
///
/// A scan used to decode, release the camera and navigate in one frame, which reads as the preview
/// freezing for no reason: the work all happened, and none of it was acknowledged. Each state here
/// exists to be *shown* — found before linked, and a rejection that names itself and can be retried.
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
