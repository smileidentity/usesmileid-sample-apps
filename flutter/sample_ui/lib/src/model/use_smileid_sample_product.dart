import '../use_smileid_sample_marks.dart';

/// Constant names outlive their labels: the second section is the Onboarding heading, not the tab.
enum UseSmileIDSampleProductSection {
  /// The authentication products.
  authentication('Authentication'),

  /// The onboarding products; the constant keeps its original name across all four apps.
  verifications('Onboarding');

  const UseSmileIDSampleProductSection(this.label);

  /// The heading the design draws.
  final String label;
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
