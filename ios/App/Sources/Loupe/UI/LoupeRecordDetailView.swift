import SwiftUI

/// One exchange in full: what was sent, what came back, and the curl that reproduces it.
struct LoupeRecordDetailView: View {
  let record: LoupeRecord

  var body: some View {
    List {
      Section("Summary") {
        LoupeDetailRow(name: "URL", value: record.url?.absoluteString ?? "")
        LoupeDetailRow(name: "Method", value: record.method)
        if let statusCode = record.statusCode {
          LoupeDetailRow(name: "Status", value: String(statusCode))
        }
        if let duration = record.duration {
          LoupeDetailRow(
            name: "Duration",
            value: duration.formatted(.units(allowed: [.seconds, .milliseconds], fractionalPart: .hide))
          )
        }
        LoupeDetailRow(name: "Started", value: record.requestDate.formatted(date: .omitted, time: .standard))
        if let errorDescription = record.errorDescription {
          LoupeDetailRow(name: "Error", value: errorDescription)
        }
      }

      headerSection("Request headers", headers: record.requestHeaders)
      if record.isRequestBodyStreamed {
        Section("Request body") {
          Text("Streamed, so it is not captured — reading it would empty the request.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      } else {
        bodySection("Request body", data: record.requestBody, kind: .other)
      }
      headerSection("Response headers", headers: record.responseHeaders)
      bodySection("Response body", data: record.responseBody, kind: record.bodyKind)

      Section {
        Button("Copy as curl") { UIPasteboard.general.string = record.curl }
        ShareLink("Share exchange", item: LoupeExport.text(for: record))
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle(record.path)
    .navigationBarTitleDisplayMode(.inline)
  }

  @ViewBuilder private func headerSection(_ title: String, headers: [String: String]) -> some View {
    if !headers.isEmpty {
      Section(title) {
        ForEach(headers.keys.sorted(), id: \.self) { key in
          LoupeDetailRow(name: key, value: headers[key] ?? "")
        }
      }
    }
  }

  @ViewBuilder private func bodySection(_ title: String, data: Data?, kind: LoupeBodyKind) -> some View {
    if let data, !data.isEmpty {
      Section(title) {
        if kind == .image, let image = UIImage(data: data) {
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 240)
        } else if let text = LoupeRecord.displayBody(data, kind: kind) {
          NavigationLink {
            LoupeBodyView(title: title, text: text)
          } label: {
            Text(text.count <= 300 ? text : String(text.prefix(300)) + "…")
              .font(.caption.monospaced())
              .lineLimit(3)
          }
        } else {
          Text("\(data.count) bytes, not text")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
  }
}

/// A name and a selectable value, because a token or a request id is there to be copied.
struct LoupeDetailRow: View {
  let name: String
  let value: String

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(name)
        .font(.caption2)
        .foregroundStyle(.secondary)
      Text(value)
        .font(.caption.monospaced())
        .textSelection(.enabled)
    }
    .padding(.vertical, 2)
  }
}
