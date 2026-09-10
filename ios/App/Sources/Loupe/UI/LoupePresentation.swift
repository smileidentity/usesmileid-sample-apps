import SwiftUI

/// Puts the overlay over the app and opens the loupe from it.
///
/// No shake. netfox needed a gesture because it had no visible chrome; the overlay is chrome, and a
/// gesture would have cost a `UIWindow` category overriding its own class's method — undefined
/// behaviour that would also have changed `UIWindow` in release builds.
struct LoupePresentation: ViewModifier {
  @Bindable private var loupe = Loupe.shared

  func body(content: Content) -> some View {
    content
      .overlay(alignment: .bottomTrailing) {
        LoupeOverlay(store: loupe.store) { loupe.isPresented = true }
      }
      .sheet(isPresented: $loupe.isPresented) {
        LoupeRootView(store: loupe.store, loupe: loupe) { loupe.isPresented = false }
      }
  }
}

extension View {
  /// Attaches the loupe overlay.
  func loupePresentation() -> some View {
    modifier(LoupePresentation())
  }
}
