import AVFoundation
import SwiftUI

/// The token QR reader: the session stops when the view leaves, codes report only while `enabled`, and one code reports once without deadening the scanner.
struct UseSmileIDSampleQrScanner: UIViewRepresentable {
  let onCode: (String) -> Void
  let torchOn: Bool
  let enabled: Bool

  func makeCoordinator() -> Coordinator {
    Coordinator(onCode: onCode)
  }

  func makeUIView(context: Context) -> UseSmileIDSamplePreviewView {
    let view = UseSmileIDSamplePreviewView()
    context.coordinator.start(previewing: view)
    return view
  }

  func updateUIView(_: UseSmileIDSamplePreviewView, context: Context) {
    context.coordinator.onCode = onCode
    context.coordinator.set(enabled: enabled)
    context.coordinator.set(torch: torchOn)
  }

  static func dismantleUIView(_: UseSmileIDSamplePreviewView, coordinator: Coordinator) {
    coordinator.stop()
  }

  /// Owns the session. Every mutable member is touched on `queue` only, which is what the unchecked mark asserts.
  final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate, @unchecked Sendable {
    var onCode: (String) -> Void
    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "com.usesmileid.sample.qr")
    private var device: AVCaptureDevice?
    private var lastReported: String?
    private var enabled = true
    private var stopped = false

    init(onCode: @escaping (String) -> Void) {
      self.onCode = onCode
    }

    func start(previewing view: UseSmileIDSamplePreviewView) {
      AVCaptureDevice.requestAccess(for: .video) { granted in
        guard granted else { return }
        // Configuring and starting block, so neither runs on the main thread, and a dismantled view has already stopped.
        self.queue.async {
          guard !self.stopped else { return }
          self.configure()
          self.session.startRunning()
          DispatchQueue.main.async { view.previewLayer.session = self.session }
        }
      }
    }

    private func configure() {
      guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device)
      else { return }
      session.beginConfiguration()
      // Pinned to 1920x1080: a dense token QR fails at the default 640x480, and `.high` varies by device.
      if session.canSetSessionPreset(.hd1920x1080) {
        session.sessionPreset = .hd1920x1080
      }
      if session.canAddInput(input) {
        session.addInput(input)
      }
      let output = AVCaptureMetadataOutput()
      if session.canAddOutput(output) {
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: queue)
        output.metadataObjectTypes = [.qr]
      }
      session.commitConfiguration()
      self.device = device
    }

    /// The value is a bearer credential, so it goes straight to `onCode` — never to a log or an identifier.
    func metadataOutput(_: AVCaptureMetadataOutput, didOutput objects: [AVMetadataObject], from _: AVCaptureConnection) {
      guard enabled else { return }
      let codes = objects.compactMap { ($0 as? AVMetadataMachineReadableCodeObject)?.stringValue }
      guard let code = codes.first(where: { !$0.isEmpty }), code != lastReported else { return }
      lastReported = code
      DispatchQueue.main.async { self.onCode(code) }
    }

    /// Re-enabling forgets the last code, so a retry can read the very same QR the screen just refused.
    func set(enabled: Bool) {
      queue.async {
        self.enabled = enabled
        if enabled {
          self.lastReported = nil
        }
      }
    }

    func set(torch on: Bool) {
      queue.async {
        guard let device = self.device, device.hasTorch, (try? device.lockForConfiguration()) != nil else { return }
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
      }
    }

    /// Stopping the session is what hands the camera back; it also puts the torch out.
    func stop() {
      queue.async {
        self.stopped = true
        if self.session.isRunning {
          self.session.stopRunning()
        }
      }
    }
  }
}

/// A view whose layer is the preview layer, so the preview resizes with SwiftUI's layout for free.
final class UseSmileIDSamplePreviewView: UIView {
  override class var layerClass: AnyClass {
    AVCaptureVideoPreviewLayer.self
  }

  var previewLayer: AVCaptureVideoPreviewLayer {
    layer as! AVCaptureVideoPreviewLayer
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    previewLayer.videoGravity = .resizeAspectFill
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    nil
  }
}
