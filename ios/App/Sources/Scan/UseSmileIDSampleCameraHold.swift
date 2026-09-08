import AVFoundation
import os
import SampleUI
import SwiftUI

/// Honours `holdCamera`: the host keeps the product's lens while the SDK starts. Frames are counted
/// because a probe that never acquired the camera passes vacuously.
struct UseSmileIDSampleCameraHold: View {
  let hold: UseSmileIDSampleHoldCamera?
  let product: UseSmileIDSampleProduct

  var body: some View {
    // `.task` is cancelled when the flow goes, which is what releases a `keep`.
    Color.clear
      .frame(width: 0, height: 0)
      .task(id: product) {
        guard let hold else { return }
        await useSmileIDSampleHoldCamera(hold, lens: product.holdLens)
      }
  }
}

/// The lens the product captures with, so the hold contends with the run rather than beside it.
enum UseSmileIDSampleHoldLens: String {
  case front
  case back

  var position: AVCaptureDevice.Position {
    self == .front ? .front : .back
  }
}

extension UseSmileIDSampleProduct {
  var holdLens: UseSmileIDSampleHoldLens {
    switch self {
    case .smartSelfieEnrollment, .smartSelfieAuth, .biometricKyc: .front
    default: .back
    }
  }
}

/// Never requests permission: a dialog over a starting flow would change what is measured.
private func useSmileIDSampleHoldCamera(_ hold: UseSmileIDSampleHoldCamera, lens: UseSmileIDSampleHoldLens) async {
  guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
    logger.warning("\(hold.description, privacy: .public) did nothing: no camera permission, so the hand-off was uncontended")
    return
  }
  guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: lens.position),
        let input = try? AVCaptureDeviceInput(device: device)
  else {
    logger.warning("\(hold.description, privacy: .public) found no \(lens.rawValue, privacy: .public) camera, so the hand-off was uncontended")
    return
  }
  let counter = UseSmileIDSampleFrameCounter()
  let session = AVCaptureSession()
  let output = AVCaptureVideoDataOutput()
  output.alwaysDiscardsLateVideoFrames = true
  output.setSampleBufferDelegate(counter, queue: DispatchQueue(label: "com.usesmileid.sample.camerahold"))
  guard session.canAddInput(input), session.canAddOutput(output) else {
    logger.warning("\(hold.description, privacy: .public) could not bind the \(lens.rawValue, privacy: .public) camera, so the hand-off was uncontended")
    return
  }
  session.addInput(input)
  session.addOutput(output)
  session.startRunning()
  defer {
    session.stopRunning()
    counter.report(hold, lens: lens)
  }
  switch hold {
  case .keep: try? await Task.sleep(nanoseconds: .max)
  case .millis(let value): try? await Task.sleep(nanoseconds: UInt64(value) * nanosecondsPerMillisecond)
  }
}

/// Tells a hold that acquired the camera from one that only asked for it.
private final class UseSmileIDSampleFrameCounter: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
  private let lock = NSLock()
  private var frames = 0
  private var lastFrameAt: Date?

  func captureOutput(
    _: AVCaptureOutput,
    didOutput _: CMSampleBuffer,
    from _: AVCaptureConnection
  ) {
    lock.lock()
    defer { lock.unlock() }
    frames += 1
    lastFrameAt = Date()
  }

  func report(_ hold: UseSmileIDSampleHoldCamera, lens: UseSmileIDSampleHoldLens) {
    lock.lock()
    let frames = frames
    let lastFrameAt = lastFrameAt
    lock.unlock()
    guard frames > 0, let lastFrameAt else {
      logger.warning("\(hold.description, privacy: .public) released the \(lens.rawValue, privacy: .public) camera without a single frame — treat the run as uncontended")
      return
    }
    // Frames stopping early means something else took the camera.
    let quietFor = Int(Date().timeIntervalSince(lastFrameAt) * 1000)
    logger.info("\(hold.description, privacy: .public) released the \(lens.rawValue, privacy: .public) camera after \(frames, privacy: .public) frames, last one \(quietFor, privacy: .public)ms before release")
  }
}

private let logger = Logger(subsystem: "UseSmileIDSample", category: "CameraHold")
private let nanosecondsPerMillisecond: UInt64 = 1000000
