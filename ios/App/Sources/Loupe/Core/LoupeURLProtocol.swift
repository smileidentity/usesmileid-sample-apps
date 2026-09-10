import Foundation

/// Replays each request through a private session so both halves of the exchange can be recorded.
final class LoupeURLProtocol: URLProtocol, @unchecked Sendable {
  /// Marks a request already forwarded, so replaying it cannot hand it back and loop.
  private static let forwardedKey = "com.usesmileid.sample.loupe.forwarded"

  /// Read from `canInit`, which the loading system calls on its own threads.
  static let configuration = LoupeConfigurationBox()

  /// Where finished records go, installed once at start.
  static let sink = RecordSink()

  /// Everything this instance accumulates while its request is in flight.
  private struct State {
    var id = UUID()
    var requestDate = Date()
    var response: URLResponse?
    var data = Data()
  }

  /// Locked because `startLoading` and the delegate queue are different threads.
  private let state = Locked(State())

  /// Serial, so the response and the bytes that follow it cannot interleave.
  private lazy var session: URLSession = {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    return URLSession(configuration: .default, delegate: self, delegateQueue: queue)
  }()

  override class func canInit(with request: URLRequest) -> Bool {
    canRecord(request)
  }

  override class func canInit(with task: URLSessionTask) -> Bool {
    // A web socket is not an exchange this can replay, and taking it breaks the connection
    if task is URLSessionWebSocketTask {
      return false
    }
    guard let request = task.currentRequest else {
      return false
    }
    return canRecord(request)
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  private class func canRecord(_ request: URLRequest) -> Bool {
    guard URLProtocol.property(forKey: forwardedKey, in: request) == nil else { return false }
    return configuration.current.shouldRecord(request)
  }

  override func startLoading() {
    let started = state.read { $0 }
    // Reported before it is sent, so a request that never comes back is still visible
    Self.sink.deliver(LoupeRecord(
      id: started.id,
      method: request.httpMethod ?? "GET",
      url: request.url,
      requestDate: started.requestDate,
      requestHeaders: request.allHTTPHeaderFields ?? [:],
      requestBody: Self.bodyData(from: request)
    ))
    guard let forwarded = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
      client?.urlProtocol(self, didFailWithError: URLError(.badURL))
      return
    }
    URLProtocol.setProperty(true, forKey: Self.forwardedKey, in: forwarded)
    session.dataTask(with: forwarded as URLRequest).resume()
  }

  override func stopLoading() {
    session.invalidateAndCancel()
  }

  /// The body as it will be sent, reading the stream `httpBody` is nil for, capped.
  private static func bodyData(from request: URLRequest, limit: Int = 1048576) -> Data? {
    if let body = request.httpBody {
      return body
    }
    guard let stream = request.httpBodyStream else {
      return nil
    }
    stream.open()
    defer { stream.close() }
    var data = Data()
    var buffer = [UInt8](repeating: 0, count: 4096)
    while stream.hasBytesAvailable, data.count < limit {
      let read = stream.read(&buffer, maxLength: buffer.count)
      guard read > 0 else { break }
      data.append(contentsOf: buffer[0..<read])
    }
    return data
  }
}

extension LoupeURLProtocol: URLSessionDataDelegate {
  func urlSession(
    _: URLSession,
    dataTask _: URLSessionDataTask,
    didReceive response: URLResponse,
    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
  ) {
    state.write { $0.response = response }
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: Self.configuration.current.cacheStoragePolicy)
    completionHandler(.allow)
  }

  func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive data: Data) {
    state.write { $0.data.append(data) }
    client?.urlProtocol(self, didLoad: data)
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    let snapshot = state.read { $0 }
    let original = task.originalRequest ?? request

    var headers: [String: String] = [:]
    var status: Int?
    var kind = LoupeBodyKind.other
    if let http = snapshot.response as? HTTPURLResponse {
      status = http.statusCode
      headers = http.allHeaderFields.reduce(into: [:]) { result, entry in
        result["\(entry.key)"] = "\(entry.value)"
      }
      if let contentType = headers.first(where: { $0.key.lowercased() == "content-type" })?.value {
        kind = LoupeBodyKind(contentType: contentType)
      }
    }

    let record = LoupeRecord(
      id: snapshot.id,
      method: original.httpMethod ?? "GET",
      url: original.url,
      requestDate: snapshot.requestDate,
      requestHeaders: original.allHTTPHeaderFields ?? [:],
      requestBody: Self.bodyData(from: original),
      responseDate: Date(),
      statusCode: status,
      responseHeaders: headers,
      responseBody: snapshot.data.isEmpty ? nil : snapshot.data,
      bodyKind: kind,
      errorDescription: error.map { String(describing: $0) }
    )
    Self.sink.deliver(record)

    if let error {
      client?.urlProtocol(self, didFailWithError: error)
    } else {
      client?.urlProtocolDidFinishLoading(self)
    }
    session.finishTasksAndInvalidate()
  }

  func urlSession(
    _: URLSession,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
  ) {
    // Re-wrapped because the client answers a sender while the session awaits a handler; without
    // this an authenticating host cannot finish its handshake through the protocol
    let sender = LoupeAuthenticationChallengeSender(handler: completionHandler)
    client?.urlProtocol(self, didReceive: URLAuthenticationChallenge(authenticationChallenge: challenge, sender: sender))
  }

  func urlSession(
    _: URLSession,
    task _: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse,
    newRequest request: URLRequest,
    completionHandler: @escaping (URLRequest?) -> Void
  ) {
    // Stripped so the loading system offers the hop back and it is recorded as its own exchange
    var followed = request
    if URLProtocol.property(forKey: Self.forwardedKey, in: request) != nil,
       let mutable = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest {
      URLProtocol.removeProperty(forKey: Self.forwardedKey, in: mutable)
      followed = mutable as URLRequest
    }
    client?.urlProtocol(self, wasRedirectedTo: followed, redirectResponse: response)
    completionHandler(followed)
  }
}

/// A lock-guarded value, for state that crosses threads with no actor to put it on.
final class Locked<Value>: @unchecked Sendable {
  private let lock = NSLock()
  private var value: Value

  init(_ value: Value) {
    self.value = value
  }

  func read<Result>(_ body: (Value) -> Result) -> Result {
    lock.lock()
    defer { lock.unlock() }
    return body(value)
  }

  func write(_ body: (inout Value) -> Void) {
    lock.lock()
    defer { lock.unlock() }
    body(&value)
  }
}

/// Where finished records go, installed once when recording starts.
final class RecordSink: @unchecked Sendable {
  private let lock = NSLock()
  private var handler: (@Sendable (LoupeRecord) -> Void)?

  func install(_ handler: @escaping @Sendable (LoupeRecord) -> Void) {
    lock.lock()
    defer { lock.unlock() }
    self.handler = handler
  }

  func deliver(_ record: LoupeRecord) {
    lock.lock()
    let handler = self.handler
    lock.unlock()
    handler?(record)
  }
}
