import '../use_smileid_sample_marks.dart';
import '../use_smileid_sample_strings.dart';

/// Constant names outlive their labels: the second section is the Onboarding heading, not the tab.
enum UseSmileIDSampleProductSection {
  /// The authentication products.
  authentication,

  /// The onboarding products; the constant keeps its original name across all four apps.
  verifications;

  /// The heading the design draws.
  String label(UseSmileIDSampleStrings strings) => switch (this) {
    UseSmileIDSampleProductSection.authentication =>
      strings.productsSectionAuthentication,
    UseSmileIDSampleProductSection.verifications =>
      strings.productsSectionOnboarding,
  };
}

/// The products grid in design order, asserted against `spec/scenarios.json` by a unit test.
enum UseSmileIDSampleProduct {
  /// SmartSelfie Enrollment.
  smartSelfieEnrollment(
    id: 'smartSelfieEnrollment',
    label: 'SmartSelfie Enrollment',
    cardTitle: 'Registration',
    cardFamily: UseSmileIDSampleMarks.smartSelfie,
    section: UseSmileIDSampleProductSection.authentication,
  ),

  /// SmartSelfie Authentication.
  smartSelfieAuth(
    id: 'smartSelfieAuth',
    label: 'SmartSelfie Authentication',
    cardTitle: 'Auth',
    cardFamily: UseSmileIDSampleMarks.smartSelfie,
    section: UseSmileIDSampleProductSection.authentication,
  ),

  /// Document Verification.
  documentVerification(
    id: 'documentVerification',
    label: 'Document Verification',
    cardTitle: 'Document',
    cardFamily: 'Verification',
    section: UseSmileIDSampleProductSection.verifications,
    needsIdDetails: true,
  ),

  /// Enhanced Document Verification.
  enhancedDocumentVerification(
    id: 'enhancedDocumentVerification',
    label: 'Enhanced Document Verification',
    cardTitle: 'Enhanced Doc.',
    cardFamily: 'Verification',
    section: UseSmileIDSampleProductSection.verifications,
    needsIdDetails: true,
  ),

  /// Residency Document Verification: a passport, then the visa page the SDK captures after it.
  residencyDocumentVerification(
    id: 'residencyDocumentVerification',
    label: 'Residency Document Verification',
    cardTitle: 'Residency Doc.',
    cardFamily: 'Verification',
    section: UseSmileIDSampleProductSection.verifications,
    needsIdDetails: true,
  ),

  /// Biometric KYC.
  biometricKyc(
    id: 'biometricKyc',
    label: 'Biometric KYC',
    cardTitle: 'Biometric',
    cardFamily: 'KYC',
    section: UseSmileIDSampleProductSection.verifications,
    needsIdDetails: true,
  ),

  /// Enhanced KYC, the one journey whose flow composes without a capture step.
  enhancedKyc(
    id: 'enhancedKyc',
    label: 'Enhanced KYC',
    cardTitle: 'Enhanced',
    cardFamily: 'KYC',
    section: UseSmileIDSampleProductSection.verifications,
    capture: false,
    needsIdDetails: true,
  );

  const UseSmileIDSampleProduct({
    required this.id,
    required this.label,
    required this.cardTitle,
    required this.cardFamily,
    required this.section,
    this.capture = true,
    this.needsIdDetails = false,
  });

  /// The stable id automation passes and every other spec file references.
  final String id;

  /// The SDK's job-type name in full, which the verifications row and the result card read.
  final String label;

  /// The card's first run, shortened to fit its text column.
  final String cardTitle;

  /// The card's second run.
  final String cardFamily;

  /// Whether a run enrols the user it submits, so its user ID can later be authenticated.
  bool get enrollsUser =>
      capture && this != UseSmileIDSampleProduct.smartSelfieAuth;

  /// The full name in the app's language; [label] stays the English the spec records.
  String title(UseSmileIDSampleStrings strings) => switch (this) {
    UseSmileIDSampleProduct.smartSelfieEnrollment =>
      strings.productSmartSelfieEnrollment,
    UseSmileIDSampleProduct.smartSelfieAuth =>
      strings.productSmartSelfieAuthentication,
    UseSmileIDSampleProduct.documentVerification =>
      strings.productDocumentVerification,
    UseSmileIDSampleProduct.enhancedDocumentVerification =>
      strings.productEnhancedDocumentVerification,
    UseSmileIDSampleProduct.residencyDocumentVerification =>
      strings.productResidencyDocumentVerification,
    UseSmileIDSampleProduct.biometricKyc => strings.productBiometricKyc,
    UseSmileIDSampleProduct.enhancedKyc => strings.productEnhancedKyc,
  };

  /// The card's first run, translated from [cardTitle].
  String localizedCardTitle(UseSmileIDSampleStrings strings) => switch (this) {
    UseSmileIDSampleProduct.smartSelfieEnrollment =>
      strings.productCardRegistration,
    UseSmileIDSampleProduct.smartSelfieAuth => strings.productCardAuth,
    UseSmileIDSampleProduct.documentVerification => strings.productCardDocument,
    UseSmileIDSampleProduct.enhancedDocumentVerification =>
      strings.productCardEnhancedDoc,
    UseSmileIDSampleProduct.residencyDocumentVerification =>
      strings.productCardResidencyDoc,
    UseSmileIDSampleProduct.biometricKyc => strings.productCardBiometric,
    UseSmileIDSampleProduct.enhancedKyc => strings.productCardEnhanced,
  };

  /// The card's second line; the SmartSelfie mark is never translated.
  String localizedCardFamily(UseSmileIDSampleStrings strings) =>
      switch (cardFamily) {
        UseSmileIDSampleMarks.smartSelfie => cardFamily,
        'KYC' => strings.productFamilyKyc,
        _ => strings.productFamilyVerification,
      };

  /// Which grid section the card sits in.
  final UseSmileIDSampleProductSection section;

  /// Whether the SDK flow includes a capture step.
  final bool capture;

  /// Whether the pre-flow forms include the ID details form.
  final bool needsIdDetails;

  /// Every product shows the Consent Details Form — the design attaches those fields to every job.
  bool get needsUserDetails => true;

  /// The products in one section, in design order.
  static List<UseSmileIDSampleProduct> of(
    UseSmileIDSampleProductSection section,
  ) => values
      .where((UseSmileIDSampleProduct it) => it.section == section)
      .toList();

  /// Resolves an id from a launch argument, falling back rather than throwing on a rename.
  static UseSmileIDSampleProduct? byId(String? id) =>
      values.where((UseSmileIDSampleProduct it) => it.id == id).firstOrNull;
}
