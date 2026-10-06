import SwiftUI

public enum UseSmileIDSampleMarks {
  public static let smartSelfie = "SmartSelfie\u{2122}"
}

public enum UseSmileIDSampleProductSection: String, CaseIterable, Sendable {
  case authentication = "Authentication"
  case verifications = "Onboarding"

  /// The heading in the app's language; the raw value stays the English the spec records.
  public var label: String {
    switch self {
    case .authentication: UseSmileIDSampleStrings.productsSectionAuthentication
    case .verifications: UseSmileIDSampleStrings.productsSectionOnboarding
    }
  }
}

/// The products grid in design order, asserted against `spec/scenarios.json` by a unit test.
public enum UseSmileIDSampleProduct: String, CaseIterable, Sendable {
  case smartSelfieEnrollment
  case smartSelfieAuth
  case documentVerification
  case enhancedDocumentVerification
  case residencyDocumentVerification
  case biometricKyc
  case enhancedKyc

  public var id: String {
    rawValue
  }

  /// The SDK's job-type name in full, which the verifications row and the result card read.
  public var label: String {
    switch self {
    case .smartSelfieEnrollment: UseSmileIDSampleStrings.productSmartSelfieEnrollment
    case .smartSelfieAuth: UseSmileIDSampleStrings.productSmartSelfieAuthentication
    case .documentVerification: UseSmileIDSampleStrings.productDocumentVerification
    case .enhancedDocumentVerification: UseSmileIDSampleStrings.productEnhancedDocumentVerification
    case .residencyDocumentVerification: UseSmileIDSampleStrings.productResidencyDocumentVerification
    case .biometricKyc: UseSmileIDSampleStrings.productBiometricKyc
    case .enhancedKyc: UseSmileIDSampleStrings.productEnhancedKyc
    }
  }

  /// The card's two runs, shortened to fit its text column.
  public var cardTitle: String {
    switch self {
    case .smartSelfieEnrollment: UseSmileIDSampleStrings.productCardRegistration
    case .smartSelfieAuth: UseSmileIDSampleStrings.productCardAuth
    case .documentVerification: UseSmileIDSampleStrings.productCardDocument
    case .enhancedDocumentVerification: UseSmileIDSampleStrings.productCardEnhancedDoc
    case .residencyDocumentVerification: UseSmileIDSampleStrings.productCardResidencyDoc
    case .biometricKyc: UseSmileIDSampleStrings.productCardBiometric
    case .enhancedKyc: UseSmileIDSampleStrings.productCardEnhanced
    }
  }

  public var cardFamily: String {
    switch self {
    case .smartSelfieEnrollment, .smartSelfieAuth: UseSmileIDSampleMarks.smartSelfie
    case .documentVerification, .enhancedDocumentVerification, .residencyDocumentVerification: UseSmileIDSampleStrings.productFamilyVerification
    case .biometricKyc, .enhancedKyc: UseSmileIDSampleStrings.productFamilyKyc
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
    case .residencyDocumentVerification: SmileIcons.residencyDocumentVerification
    case .biometricKyc: SmileIcons.biometricKyc
    case .enhancedKyc: SmileIcons.enhancedKyc
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
