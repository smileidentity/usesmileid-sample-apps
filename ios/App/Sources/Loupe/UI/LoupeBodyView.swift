import SwiftUI

/// A body on its own screen, monospaced and selectable.
struct LoupeBodyView: View {
  let title: String
  let text: String

  var body: some View {
    ScrollView([.horizontal, .vertical]) {
      Text(text)
        .font(.caption.monospaced())
        .textSelection(.enabled)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button("Copy") { UIPasteboard.general.string = text }
      }
    }
  }
}
