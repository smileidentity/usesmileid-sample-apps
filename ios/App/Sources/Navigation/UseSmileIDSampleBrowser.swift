import SafariServices
import SwiftUI

/// An in-app browser for the ABOUT rows; `SFSafariViewController`, not a `WKWebView`, which would lose session and autofill.
struct UseSmileIDSampleBrowser: UIViewControllerRepresentable {
  let url: URL

  func makeUIViewController(context _: Context) -> SFSafariViewController {
    SFSafariViewController(url: url)
  }

  func updateUIViewController(_: SFSafariViewController, context _: Context) {}
}

/// `.sheet(item:)` needs identity, and a retroactive `Identifiable` on `URL` would leak out of here.
struct UseSmileIDSampleInAppLink: Identifiable {
  let url: URL

  var id: String {
    url.absoluteString
  }
}
