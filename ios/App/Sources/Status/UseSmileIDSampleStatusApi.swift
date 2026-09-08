import Foundation
import SampleUI

/// `GET /v3/status/{jobId}` — the partner's own call: the SDK stops at the 202 that creates the job.
/// `URLSession` stays in the shell; the library defines the seam.
struct UseSmileIDSampleStatusApi: UseSmileIDSampleJobStatusSource {
  private let session: URLSession

  init(session: URLSession = UseSmileIDSampleStatusApi.bounded) {
    self.session = session
  }

  /// Ten seconds, matching the Compose adapter's client: `URLSession.shared` waits a minute, and a
  /// pull that hangs that long reads worse than one that fails.
  private static let bounded: URLSession = {
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 10
    return URLSession(configuration: configuration)
  }()

  func check(jobId: String, token: String, sandbox: Bool) async throws -> UseSmileIDSampleStatusRefresh {
    guard let url = useSmileIDSampleStatusUrl(jobId: jobId, sandbox: sandbox) else {
      throw URLError(.badURL)
    }
    var request = URLRequest(url: url)
    // The session's own JWT from `POST /v3/token`. Never logged.
    request.setValue(token, forHTTPHeaderField: "SmileID-Token")
    let (data, response) = try await session.data(for: request)
    return useSmileIDSampleStatusOutcome(
      code: (response as? HTTPURLResponse)?.statusCode ?? 0,
      // Unknown keys are ignored, so a field added server-side cannot turn a good response into a failure.
      body: try? JSONDecoder().decode(UseSmileIDSampleStatusResponse.self, from: data)
    )
  }
}

/// The status URL for one job, with the id percent-encoded as a single path segment: an id carrying
/// `/`, `?` or `#` would otherwise change which request the session's token is sent with. Pure, so
/// the encoding is unit-testable, and nil rather than a guess when nothing is left to ask about.
func useSmileIDSampleStatusUrl(jobId: String, sandbox: Bool) -> URL? {
  let environment: UseSmileIDSampleEnvironment = sandbox ? .sandbox : .production
  let unreserved = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
  guard let segment = jobId.addingPercentEncoding(withAllowedCharacters: unreserved), !segment.isEmpty else {
    return nil
  }
  return URL(string: environment.baseUrl + "v3/status/\(segment)")
}

/// The HTTP code and body onto an outcome. Pure, so the branch table is unit-testable.
func useSmileIDSampleStatusOutcome(
  code: Int,
  body: UseSmileIDSampleStatusResponse?
) -> UseSmileIDSampleStatusRefresh {
  guard let body, (200..<300).contains(code) else { return .failed(reason: "HTTP \(code)") }
  if body.status == UseSmileIDSampleStatusResponse.processing {
    return .stillProcessing
  }
  guard let status = body.sampleStatus else {
    return .failed(reason: "Unrecognised status '\(body.status)'")
  }
  return .updated(status: status, message: body.message, httpCode: code)
}

struct UseSmileIDSampleStatusResponse: Decodable {
  let status: String
  let message: String
  /// Carried for the payload's shape, not read: required, one of them missing from an otherwise
  /// good 2xx would fail the decode and report a readable status as a transport failure.
  let jobId: String?
  let userId: String?
  let createdAt: String?

  /// Five API states onto the four badges: `error` lands on Blocked and leans on the server's message.
  var sampleStatus: UseSmileIDSampleStatus? {
    switch status {
    case "clear": .clear
    case "attention": .attention
    case "block", "error": .blocked
    default: nil
    }
  }

  static let processing = "processing"

  enum CodingKeys: String, CodingKey {
    case status
    case message
    case jobId = "job_id"
    case userId = "user_id"
    case createdAt = "created_at"
  }
}
