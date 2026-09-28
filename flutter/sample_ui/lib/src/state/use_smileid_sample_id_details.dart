import 'use_smileid_sample_catalogue.dart';
import 'use_smileid_sample_id_number_hint.dart';

/// A country from the Smile ID API; the flag is derived from the ISO code, so no table is needed.
class UseSmileIDSampleCountry {
  /// [name] is as the API returns it, in the locale the request asked for.
  const UseSmileIDSampleCountry(this.code, this.name);

  /// The ISO code, which also suffixes this row's test id.
  final String code;

  /// The country's name, which is the only thing the search filters on.
  final String name;

  /// Two regional-indicator letters, which every platform renders as the country's flag.
  String get flag {
    final String upper = code.toUpperCase();
    if (upper.length != 2 || !RegExp(r'^[A-Z]{2}$').hasMatch(upper)) {
      return '🌍';
    }
    return String.fromCharCodes(
      upper.codeUnits.map((int unit) => 0x1F1E6 + unit - 0x41),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleCountry &&
      other.code == code &&
      other.name == name;

  @override
  int get hashCode => Object.hash(code, name);
}

/// A KYC ID type from `supported_id_types`; [id] is [type] with `_2`, `_3` on a repeat (spec/catalogue-rules.json).
class UseSmileIDSampleKycIdType {
  /// Every field as the rules derived it.
  const UseSmileIDSampleKycIdType({
    required this.id,
    required this.type,
    required this.label,
    required this.regex,
  });

  /// The row's id, which suffixes its test id.
  final String id;

  /// The API's `type`, which is what the server receives.
  final String type;

  /// The type's name, which is what the search filters on.
  final String label;

  /// The number's format, which the hint and the check are derived from.
  final String regex;

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleKycIdType &&
      other.id == id &&
      other.type == type &&
      other.label == label &&
      other.regex == regex;

  @override
  int get hashCode => Object.hash(id, type, label, regex);
}

/// A document from `supported_documents`; a standalone sub-type row carries [subType] and submits the parent [code].
class UseSmileIDSampleDocument {
  /// Every field as the rules derived it.
  const UseSmileIDSampleDocument({
    required this.code,
    required this.name,
    required this.hasBack,
    required this.format,
    this.subType,
  });

  /// The API's `code`, which is what the server receives.
  final String code;

  /// The sub-type's id on a flattened sub-type row, null otherwise.
  final String? subType;

  /// The document's name, which is what the search filters on.
  final String name;

  /// The API's `has_back`.
  final bool hasBack;

  /// The API's undocumented `format`: 3 a booklet, 7 the Green Book, anything else a card.
  final int format;

  /// The row's id, which suffixes its test id.
  String get id => subType == null ? code : '${code}_$subType';

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleDocument &&
      other.code == code &&
      other.subType == subType &&
      other.name == name &&
      other.hasBack == hasBack &&
      other.format == format;

  @override
  int get hashCode => Object.hash(code, subType, name, hasBack, format);
}

/// How the SDK photographs the chosen document, each the SDK's own type; never what the server receives.
enum UseSmileIDSampleCaptureAs {
  /// A GenericDocument shaped in its own sheet, the SDK's defaults until then.
  genericDocument('genericDocument', 'Generic document'),

  /// The SDK's Green Book preset.
  greenBook('greenBook', 'Green Book preset'),

  /// The SDK's Passport preset.
  passport('passport', 'Passport preset');

  const UseSmileIDSampleCaptureAs(this.id, this.label);

  /// The id that suffixes this row's test id.
  final String id;

  /// What the row and the trigger say.
  final String label;
}

/// A generic document's capture orientation.
enum UseSmileIDSampleDocumentOrientation {
  /// Wider than tall.
  landscape('landscape', 'Landscape'),

  /// Taller than wide.
  portrait('portrait', 'Portrait');

  const UseSmileIDSampleDocumentOrientation(this.id, this.label);

  /// The id that suffixes this chip's test id.
  final String id;

  /// What the chip says.
  final String label;
}

/// The frame ratios the sheet offers, as width over height.
enum UseSmileIDSampleAspectRatio {
  /// The SDK's own frame.
  off('off', 'Off', null),

  /// An ID-1 card.
  card('card', 'Card 1.586', 1.586),

  /// A passport data page.
  passport('passport', 'Passport 1.309', 1.309),

  /// A tall booklet.
  booklet('booklet', 'Booklet 0.748', 0.748);

  const UseSmileIDSampleAspectRatio(this.id, this.label, this.ratio);

  /// The id that suffixes this chip's test id.
  final String id;

  /// What the chip says.
  final String label;

  /// The ratio handed to the SDK, null for its own.
  final double? ratio;
}

/// What the generic-document sheet builds, as the SDK's GenericDocument takes it.
class UseSmileIDSampleGenericDocument {
  /// The SDK's own generic defaults.
  const UseSmileIDSampleGenericDocument({
    this.displayName = 'Document',
    this.hasBackSide = true,
    this.orientation = UseSmileIDSampleDocumentOrientation.landscape,
    this.aspectRatio = UseSmileIDSampleAspectRatio.off,
  });

  /// The name the SDK's instructions show.
  final String displayName;

  /// Whether the back is captured after the front.
  final bool hasBackSide;

  /// The capture orientation.
  final UseSmileIDSampleDocumentOrientation orientation;

  /// The frame ratio.
  final UseSmileIDSampleAspectRatio aspectRatio;

  /// A copy with the given fields replaced.
  UseSmileIDSampleGenericDocument copyWith({
    String? displayName,
    bool? hasBackSide,
    UseSmileIDSampleDocumentOrientation? orientation,
    UseSmileIDSampleAspectRatio? aspectRatio,
  }) => UseSmileIDSampleGenericDocument(
    displayName: displayName ?? this.displayName,
    hasBackSide: hasBackSide ?? this.hasBackSide,
    orientation: orientation ?? this.orientation,
    aspectRatio: aspectRatio ?? this.aspectRatio,
  );

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleGenericDocument &&
      other.displayName == displayName &&
      other.hasBackSide == hasBackSide &&
      other.orientation == orientation &&
      other.aspectRatio == aspectRatio;

  @override
  int get hashCode =>
      Object.hash(displayName, hasBackSide, orientation, aspectRatio);
}

/// What the ID-details form has collected, holding whole rows so a flow rebuilt from it needs no catalogue.
class UseSmileIDSampleIdDetails {
  /// Every field starts empty; nothing is prefilled, not even from the active profile.
  const UseSmileIDSampleIdDetails({
    this.country,
    this.idType,
    this.document,
    this.captureAs = UseSmileIDSampleCaptureAs.genericDocument,
    this.genericDocument = const UseSmileIDSampleGenericDocument(),
    this.idNumber = '',
  });

  /// The chosen country.
  final UseSmileIDSampleCountry? country;

  /// The chosen KYC ID type, which a country change clears.
  final UseSmileIDSampleKycIdType? idType;

  /// The chosen document, which a country change clears.
  final UseSmileIDSampleDocument? document;

  /// How the SDK photographs the document.
  final UseSmileIDSampleCaptureAs captureAs;

  /// What "Capture as: Generic document" builds.
  final UseSmileIDSampleGenericDocument genericDocument;

  /// The typed number.
  final String idNumber;

  /// Whether Continue can enable for [family]: every field it shows is set, and the number fits its type.
  bool isComplete(UseSmileIDSampleCatalogueFamily family) => switch (family) {
    UseSmileIDSampleCatalogueFamily.document =>
      country != null && document != null,
    UseSmileIDSampleCatalogueFamily.kyc =>
      country != null &&
          idType != null &&
          UseSmileIDSampleIdNumberHint.accepts(idType!.regex, idNumber),
  };

  /// A copy with [country] chosen, which CLEARS the type and document and keeps the typed number.
  UseSmileIDSampleIdDetails withCountry(UseSmileIDSampleCountry country) =>
      UseSmileIDSampleIdDetails(
        country: country,
        captureAs: captureAs,
        genericDocument: genericDocument,
        idNumber: idNumber,
      );

  /// A copy with the given fields replaced.
  UseSmileIDSampleIdDetails copyWith({
    UseSmileIDSampleKycIdType? idType,
    UseSmileIDSampleDocument? document,
    UseSmileIDSampleCaptureAs? captureAs,
    UseSmileIDSampleGenericDocument? genericDocument,
    String? idNumber,
  }) => UseSmileIDSampleIdDetails(
    country: country,
    idType: idType ?? this.idType,
    document: document ?? this.document,
    captureAs: captureAs ?? this.captureAs,
    genericDocument: genericDocument ?? this.genericDocument,
    idNumber: idNumber ?? this.idNumber,
  );

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleIdDetails &&
      other.country == country &&
      other.idType == idType &&
      other.document == document &&
      other.captureAs == captureAs &&
      other.genericDocument == genericDocument &&
      other.idNumber == idNumber;

  @override
  int get hashCode => Object.hash(
    country,
    idType,
    document,
    captureAs,
    genericDocument,
    idNumber,
  );
}
