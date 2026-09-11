#if DEBUG
  import SwiftUI

  /// Reports a shake, which is how the loupe opens without permanent chrome over the app.
  ///
  /// The override lives on `UIWindow` because motion events travel the responder chain and end
  /// there: a SwiftUI view cannot become first responder for them, and a view controller in the
  /// hierarchy misses every shake made while a text field holds focus. With no overlay to tap,
  /// a missed shake means no way in at all, so reliability decides it.
  ///
  /// A category overriding its own class's method is a pattern Apple documents as undefined when
  /// two categories collide. This file is the only one that overrides it and is compiled into
  /// debug builds alone, so the collision it warns about cannot arise here.
  extension UIWindow {
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
      super.motionEnded(motion, with: event)
      guard motion == .motionShake else {
        return
      }
      NotificationCenter.default.post(name: .loupeShakeDetected, object: nil)
    }
  }

  extension Notification.Name {
    /// Posted by the window, because the responder chain ends there rather than at a SwiftUI view.
    static let loupeShakeDetected = Notification.Name("com.usesmileid.sample.loupe.shake")
  }

  /// Opens the loupe when the device is shaken.
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
#endif
