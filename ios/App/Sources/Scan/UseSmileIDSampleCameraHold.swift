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
    Color.clear
      .frame(width: 0, height: 0)
      // `.task` is cancelled when the flow goes, which is what releases a `keep`.
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
  let held = UseSmileIDSampleHeldSession(hold: hold, lens: lens)
  // Off the cooperative pool: opening the device and `startRunning` both block, and blocking one of
  // its threads could stall the very start-up this hold exists to contend with.
  held.queue.async { held.start() }
  defer { held.queue.async { held.release() } }
  switch hold {
  case .keep: try? await Task.sleep(nanoseconds: .max)
  case .millis(let value): try? await Task.sleep(nanoseconds: UInt64(value) * nanosecondsPerMillisecond)
  }
}

/// The whole lifecycle, on one serial queue: the frames land on it too, so a release cannot report
/// while one is still arriving. Unchecked because that queue is the only caller.
private final class UseSmileIDSampleHeldSession: @unchecked Sendable {
  let queue = DispatchQueue(label: "com.usesmileid.sample.camerahold")

  private let hold: UseSmileIDSampleHoldCamera
  private let lens: UseSmileIDSampleHoldLens
  private let session = AVCaptureSession()
  private let output = AVCaptureVideoDataOutput()
  private let counter = UseSmileIDSampleFrameCounter()
  private var running = false

  init(hold: UseSmileIDSampleHoldCamera, lens: UseSmileIDSampleHoldLens) {
    self.hold = hold
    self.lens = lens
  }

  func start() {
    output.alwaysDiscardsLateVideoFrames = true
    output.setSampleBufferDelegate(counter, queue: queue)
    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: lens.position),
          let input = try? AVCaptureDeviceInput(device: device),
          session.canAddInput(input), session.canAddOutput(output)
    else {
      logger.warning("\(self.hold.description, privacy: .public) could not bind the \(self.lens.rawValue, privacy: .public) camera, so the hand-off was uncontended")
      return
    }
    session.addInput(input)
    session.addOutput(output)
    session.startRunning()
    running = true
  }

  /// Reports nothing when the hold never bound, or a failed start would read as one that lasted.
  func release() {
    guard running else { return }
    session.stopRunning()
    running = false
    guard let counted = counter.counted else {
      logger.warning("\(self.hold.description, privacy: .public) released the \(self.lens.rawValue, privacy: .public) camera without a single frame — treat the run as uncontended")
      return
    }
    // Frames stopping early means something else took the camera.
    let quietFor = Int(Date().timeIntervalSince(counted.lastFrameAt) * 1000)
    logger.info("\(self.hold.description, privacy: .public) released the \(self.lens.rawValue, privacy: .public) camera after \(counted.frames, privacy: .public) frames, last one \(quietFor, privacy: .public)ms before release")
  }
}

/// Tells a hold that acquired the camera from one that only asked for it. Unchecked because every
/// mutable field is behind the lock.
private final class UseSmileIDSampleFrameCounter: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate,
  @unchecked Sendable {
  private let lock = NSLock()
  private var frames = 0
  private var lastFrameAt: Date?

  /// Nil until a frame has actually arrived.
  var counted: (frames: Int, lastFrameAt: Date)? {
    lock.lock()
    defer { lock.unlock() }
    return lastFrameAt.map { (frames, $0) }
  }

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
}

private let logger = Logger(subsystem: "UseSmileIDSample", category: "CameraHold")
private let nanosecondsPerMillisecond: UInt64 = 1000000
