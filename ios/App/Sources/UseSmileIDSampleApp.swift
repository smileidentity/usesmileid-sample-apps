import SwiftUI

@main
struct UseSmileIDSampleApp: App {
  init() {
    // Debug only: recording replays every request through its own session, which is a change to
    // how the app reaches the network
    #if DEBUG
      Loupe.shared.start()
    #endif
  }

  var body: some Scene {
    WindowGroup {
      UseSmileIDSampleShell()
    }
  }
}
