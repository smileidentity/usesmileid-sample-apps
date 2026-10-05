import SampleUI
import SwiftUI
import UIKit

/// Keeps `deviceDark` on the device's theme; the scene cannot say, since a preferred scheme overrides its traits.
struct UseSmileIDSampleDeviceScheme: ViewModifier {
  @ObservedObject var app: UseSmileIDSampleAppState
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.colorScheme) private var colorScheme

  func body(content: Content) -> some View {
    content
      .onAppear(perform: read)
      // Live under System, where the scheme is the device's; a pinned scheme hides the change until the app returns.
      .onChange(of: colorScheme) { _ in read() }
      .onChange(of: scenePhase) { phase in
        if phase == .active {
          read()
        }
      }
  }

  /// The screen's traits, which no window or scene override reaches.
  private func read() {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first else { return }
    let dark = scene.screen.traitCollection.userInterfaceStyle == .dark
    if app.deviceDark != dark {
      app.deviceDark = dark
    }
  }
}

extension UseSmileIDSampleAppearance {
  /// Nil hands the scheme back to the device.
  var colorScheme: ColorScheme? {
    switch self {
    case .system: nil
    case .light: .light
    case .dark: .dark
    }
  }
}
