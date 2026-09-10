import SwiftUI

public enum UseSmileIDSampleMarks {
  public static let smartSelfie = "SmartSelfie\u{2122}"
}

public enum UseSmileIDSampleProductSection: String, CaseIterable, Sendable {
  case authentication = "Authentication"
  case verifications = "Onboarding"

  public var label: String {
    rawValue
  }
}

/// The products grid in design order, asserted against `spec/scenarios.json` by a unit test.
public enum UseSmileIDSampleProduct: String, CaseIterable, Sendable {
  case smartSelfieEnrollment
  case smartSelfieAuth
  case documentVerification
  case enhancedDocumentVerification
  case biometricKyc
  case enhancedKyc

  public var id: String {
    rawValue
  }

  /// The SDK's job-type name in full, which the verifications row and the result card read.
  public var label: String {
    switch self {
    case .smartSelfieEnrollment: "SmartSelfie Enrollment"
    case .smartSelfieAuth: "SmartSelfie Authentication"
    case .documentVerification: "Document Verification"
    case .enhancedDocumentVerification: "Enhanced Document Verification"
    case .biometricKyc: "Biometric KYC"
    case .enhancedKyc: "Enhanced KYC"
    }
  }

  /// The card's two runs, shortened to fit its text column.
  public var cardTitle: String {
    switch self {
    case .smartSelfieEnrollment: "Registration"
    case .smartSelfieAuth: "Auth"
    case .documentVerification: "Document"
    case .enhancedDocumentVerification: "Enhanced Doc."
    case .biometricKyc: "Biometric"
    case .enhancedKyc: "Enhanced"
    }
  }

  public var cardFamily: String {
    switch self {
    case .smartSelfieEnrollment, .smartSelfieAuth: UseSmileIDSampleMarks.smartSelfie
    case .documentVerification, .enhancedDocumentVerification: "Verification"
    case .biometricKyc, .enhancedKyc: "KYC"
    }
  }

  public var section: UseSmileIDSampleProductSection {
    switch self {
    case .smartSelfieEnrollment, .smartSelfieAuth: .authentication
    default: .verifications
    }
  }

  /// Enhanced KYC is the one journey without `capture()`.
  public var capture: Bool {
    self != .enhancedKyc
  }

  public var needsIdDetails: Bool {
    switch self {
    case .smartSelfieEnrollment, .smartSelfieAuth: false
    default: true
    }
  }

  /// The two document products share one mark by design, told apart by the card's hue.
  public var icon: SmileIcon {
    switch self {
    case .smartSelfieEnrollment: SmileIcons.smartSelfieEnrollment
    case .smartSelfieAuth: SmileIcons.smartSelfieAuth
    case .documentVerification, .enhancedDocumentVerification: SmileIcons.documentVerification
    case .biometricKyc: SmileIcons.biometricKyc
    // Still owed an icon of its own, so it keeps the generic product mark.
    case .enhancedKyc: SmileIcons.productMark
    }
  }

  public var hue: SmileProductHue? {
    smileProductHues[id]
  }

  /// Named, not `values.first`, which is unordered; unreachable, but a wrong colour beats a trap on a partner's device.
  public var resolvedHue: SmileProductHue {
    hue ?? smileProductHues[UseSmileIDSampleProduct.smartSelfieEnrollment.id]!
  }

  public static func of(_ section: UseSmileIDSampleProductSection) -> [UseSmileIDSampleProduct] {
    allCases.filter { $0.section == section }
  }
}
