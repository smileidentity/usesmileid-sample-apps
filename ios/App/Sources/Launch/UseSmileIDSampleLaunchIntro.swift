import SampleUI
import SwiftUI
import UIKit

/// Whether a launch plays the intro: a cold start from the app icon does; a launch argument, a restored scene or Reduce Motion goes straight in.
enum UseSmileIDSampleLaunchIntroGate {
  /// The system's own argument prefixes, which Xcode adds to a run from the IDE; any other argument was put there by automation.
  static let systemArgumentPrefixes = ["NS", "Apple"]

  static func plays(arguments: [String: Any], restored: Bool, reduceMotion: Bool) -> Bool {
    !restored && !reduceMotion && arguments.keys.allSatisfy { key in
      systemArgumentPrefixes.contains { key.hasPrefix($0) }
    }
  }

  /// This process's answer, read from its argument domain and the system setting.
  static func playsAtLaunch(restored: Bool) -> Bool {
    plays(
      arguments: UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain),
      restored: restored,
      reduceMotion: UIAccessibility.isReduceMotionEnabled
    )
  }
}

/// Lays the intro over the app on a cold start and fades it out; a link that arrives meanwhile skips it, so the link lands at once.
struct UseSmileIDSampleLaunchIntroHost<Content: View>: View {
  /// The shell's own stored stack: present only when the system restores a scene it ended.
  @SceneStorage("navigation") private var storedNavigation: String = ""
  @State private var showing = UseSmileIDSampleLaunchIntroGate.playsAtLaunch(restored: false)
  @ViewBuilder let content: () -> Content

  var body: some View {
    ZStack {
      content()
        .accessibilityHidden(showing)
      if showing {
        LaunchIntroScreen(onFinished: dismiss)
          .ignoresSafeArea()
          .transition(.opacity)
          .zIndex(1)
      }
    }
    .statusBarHidden(showing)
    .onOpenURL { _ in dismiss() }
    .onAppear {
      if !storedNavigation.isEmpty {
        showing = false
      }
    }
  }

  private func dismiss() {
    withAnimation(.easeOut(duration: SmileMotion.durationSlow)) {
      showing = false
    }
  }
}
