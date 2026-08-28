import SafariServices
import SwiftUI

/// An in-app browser for the ABOUT rows.
///
/// `SFSafariViewController`, not a `WKWebView`: a web view would lose the user's session, autofill
/// and password manager, and this is code partners copy.
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
