import SwiftUI

/// Reports a shake, which is how the loupe opens without permanent chrome in the app.
extension UIWindow {
  override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    super.motionEnded(motion, with: event)
    guard motion == .motionShake else { return }
    NotificationCenter.default.post(name: .loupeShakeDetected, object: nil)
  }
}

extension Notification.Name {
  /// Posted by the window, because the responder chain ends there rather than at a SwiftUI view.
  static let loupeShakeDetected = Notification.Name("com.usesmileid.sample.loupe.shake")
}

/// Presents the loupe over whatever is on screen when the device is shaken.
struct LoupePresentation: ViewModifier {
  @Bindable private var loupe = Loupe.shared

  func body(content: Content) -> some View {
    content
      .onReceive(NotificationCenter.default.publisher(for: .loupeShakeDetected)) { _ in
        loupe.isPresented = true
      }
      .sheet(isPresented: $loupe.isPresented) {
        LoupeRootView(store: loupe.store, loupe: loupe) { loupe.isPresented = false }
      }
  }
}

extension View {
  /// Attaches the shake-to-open loupe.
  func loupePresentation() -> some View {
    modifier(LoupePresentation())
  }
}
