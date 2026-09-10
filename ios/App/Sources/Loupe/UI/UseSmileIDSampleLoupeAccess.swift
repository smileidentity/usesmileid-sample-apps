import SwiftUI

/// The shell's one line of contact with the loupe.
///
/// A modifier rather than a `#if DEBUG` block inside the shell's `body`: a conditional in a view
/// builder changes the view's type between configurations, and the shell's structure is what its
/// navigation tests walk.
struct UseSmileIDSampleLoupeAccess: ViewModifier {
  func body(content: Content) -> some View {
    #if DEBUG
      content.loupePresentation()
    #else
      content
    #endif
  }
}
