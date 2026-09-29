import 'dart:convert';

import '../model/use_smileid_sample_product.dart';
import 'use_smileid_sample_id_details.dart';

/// Which list a product's form reads: the KYC products name an ID type, the document products a document.
enum UseSmileIDSampleCatalogueFamily {
  /// Biometric KYC and Enhanced KYC.
  kyc,

  /// Document Verification and Enhanced Document Verification.
  document,
}

/// The family [product]'s form reads, or null for the products that ask for no ID details.
UseSmileIDSampleCatalogueFamily? useSmileIDSampleCatalogueFamily(
  UseSmileIDSampleProduct product,
) => switch (product) {
  UseSmileIDSampleProduct.biometricKyc ||
  UseSmileIDSampleProduct.enhancedKyc => UseSmileIDSampleCatalogueFamily.kyc,
  UseSmileIDSampleProduct.documentVerification ||
  UseSmileIDSampleProduct.enhancedDocumentVerification =>
    UseSmileIDSampleCatalogueFamily.document,
  _ => null,
};

/// One picker's list: still arriving, arrived, arrived with nothing the form can use, or failed.
sealed class UseSmileIDSampleCatalogue<T> {
  const UseSmileIDSampleCatalogue();

  /// Whether the list is still arriving.
  bool get isLoading => this is UseSmileIDSampleCatalogueLoading<T>;
}

/// Still arriving.
final class UseSmileIDSampleCatalogueLoading<T>
    extends UseSmileIDSampleCatalogue<T> {
  /// The one loading state.
  const UseSmileIDSampleCatalogueLoading();
}

/// Arrived, with at least one row.
final class UseSmileIDSampleCatalogueReady<T>
    extends UseSmileIDSampleCatalogue<T> {
  /// [items] in API order.
  const UseSmileIDSampleCatalogueReady(this.items);

  /// The rows.
  final List<T> items;
}

/// Arrived with nothing the form can use.
final class UseSmileIDSampleCatalogueEmpty<T>
    extends UseSmileIDSampleCatalogue<T> {
  /// The one empty state.
  const UseSmileIDSampleCatalogueEmpty();
}

/// Failed or timed out.
final class UseSmileIDSampleCatalogueFailed<T>
    extends UseSmileIDSampleCatalogue<T> {
  /// [reason] is for the log, never the screen.
  const UseSmileIDSampleCatalogueFailed(this.reason);

  /// Why it failed.
  final String reason;
}

/// An ID type as `supported_id_types` returns it.
class UseSmileIDSampleApiIdType {
  /// Every field the rules read.
  const UseSmileIDSampleApiIdType({
    required this.country,
    required this.type,
    required this.label,
    required this.regex,
    required this.requiredFields,
  });

  /// The ISO code.
  final String country;

  /// The API's `type`.
  final String type;

  /// The API's `label`.
  final String label;

  /// The API's `regex`.
  final String regex;

  /// The API's `required_fields`.
  final List<String> requiredFields;
}

/// One country's entry in `supported_documents`, with its documents as the API lists them.
class UseSmileIDSampleApiCountryDocuments {
  /// Every field the rules read.
  const UseSmileIDSampleApiCountryDocuments(this.country, this.documents);

  /// The country, named in the requested locale.
  final UseSmileIDSampleCountry country;

  /// Its documents.
  final List<UseSmileIDSampleApiDocument> documents;
}

/// A document as `supported_documents` returns it.
class UseSmileIDSampleApiDocument {
  /// Every field the rules read.
  const UseSmileIDSampleApiDocument({
    required this.code,
    required this.name,
    required this.hasBack,
    required this.format,
    this.subTypes = const <UseSmileIDSampleApiSubType>[],
  });

  /// The API's `code`.
  final String code;

  /// The API's `name`.
  final String name;

  /// The API's `has_back`.
  final bool hasBack;

  /// The API's `format`.
  final int format;

  /// The API's `sub_types`.
  final List<UseSmileIDSampleApiSubType> subTypes;
}

/// A sub-type as `supported_documents` returns it.
class UseSmileIDSampleApiSubType {
  /// Every field the rules read.
  const UseSmileIDSampleApiSubType({
    required this.id,
    required this.name,
    required this.hasBack,
    required this.format,
    required this.displayStandalone,
  });

  /// The sub-type's id.
  final String id;

  /// Its name.
  final String name;

  /// Its `has_back`.
  final bool hasBack;

  /// Its `format`.
  final int format;

  /// Whether it is its own row.
  final bool displayStandalone;
}

/// Both responses a run of the form reads; fetched together because the KYC countries need names from the second.
class UseSmileIDSampleCatalogueData {
  /// Both lists as decoded.
  const UseSmileIDSampleCatalogueData(this.idTypes, this.documents);

  /// Every ID type.
  final List<UseSmileIDSampleApiIdType> idTypes;

  /// Every country's documents.
  final List<UseSmileIDSampleApiCountryDocuments> documents;
}

/// The pure rules from `spec/catalogue-rules.json`, run on whatever the server returns.
abstract final class UseSmileIDSampleCatalogueRules {
  /// What the SDK fills in plus the two names the user-details form collects; anything else drops a type.
  static const Set<String> allowedRequiredFields = <String>{
    'country',
    'first_name',
    'id_number',
    'id_type',
    'last_name',
    'partner_id',
    'partner_params',
    'timestamp',
  };

  /// The ID types [country] offers, with repeated types numbered in API order.
  static List<UseSmileIDSampleKycIdType> idTypes(
    List<UseSmileIDSampleApiIdType> all,
    String country,
  ) {
    final Map<String, int> seen = <String, int>{};
    return <UseSmileIDSampleKycIdType>[
      for (final UseSmileIDSampleApiIdType type in all)
        if (type.country == country &&
            allowedRequiredFields.containsAll(type.requiredFields))
          () {
            final int count = seen[type.type] = (seen[type.type] ?? 0) + 1;
            return UseSmileIDSampleKycIdType(
              id: count == 1 ? type.type : '${type.type}_$count',
              type: type.type,
              label: type.label,
              regex: type.regex,
            );
          }(),
    ];
  }

  /// The documents [country] offers, standalone sub-types as their own rows.
  static List<UseSmileIDSampleDocument> documents(
    List<UseSmileIDSampleApiCountryDocuments> all,
    String country, {
    UseSmileIDSampleProduct product =
        UseSmileIDSampleProduct.documentVerification,
  }) {
    final UseSmileIDSampleApiCountryDocuments? entry = all
        .where(
          (UseSmileIDSampleApiCountryDocuments it) =>
              it.country.code == country,
        )
        .firstOrNull;
    return <UseSmileIDSampleDocument>[
      for (final UseSmileIDSampleApiDocument document
          in entry?.documents ?? const <UseSmileIDSampleApiDocument>[])
        if (document.code.isNotEmpty) ...<UseSmileIDSampleDocument>[
          UseSmileIDSampleDocument(
            code: document.code,
            name: document.name,
            hasBack: document.hasBack,
            format: document.format,
          ),
          for (final UseSmileIDSampleApiSubType sub in document.subTypes)
            if (sub.displayStandalone)
              UseSmileIDSampleDocument(
                code: document.code,
                subType: sub.id,
                name: sub.name,
                hasBack: sub.hasBack,
                format: sub.format,
              ),
        ],
    ]..removeWhere(
      (UseSmileIDSampleDocument it) =>
          product == UseSmileIDSampleProduct.enhancedDocumentVerification &&
          it.subType == useSmileIDSampleGreenBookSubType,
    );
  }

  /// The countries [family] offers, named from `supported_documents`.
  static List<UseSmileIDSampleCountry> countries(
    UseSmileIDSampleCatalogueData data,
    UseSmileIDSampleCatalogueFamily family,
  ) {
    final List<UseSmileIDSampleCountry> named = <UseSmileIDSampleCountry>[
      for (final UseSmileIDSampleApiCountryDocuments entry in data.documents)
        entry.country,
    ];
    switch (family) {
      case UseSmileIDSampleCatalogueFamily.document:
        return named
            .where(
              (UseSmileIDSampleCountry it) =>
                  documents(data.documents, it.code).isNotEmpty,
            )
            .toList();
      case UseSmileIDSampleCatalogueFamily.kyc:
        final List<String> listed = <String>[];
        for (final UseSmileIDSampleApiIdType type in data.idTypes) {
          if (!listed.contains(type.country) &&
              idTypes(data.idTypes, type.country).isNotEmpty) {
            listed.add(type.country);
          }
        }
        return <UseSmileIDSampleCountry>[
          ...named.where(
            (UseSmileIDSampleCountry it) => listed.contains(it.code),
          ),
          for (final String code in listed)
            if (!named.any((UseSmileIDSampleCountry it) => it.code == code))
              UseSmileIDSampleCountry(code, code),
        ];
    }
  }
}

/// Reads the two response bodies; readers ignore unknown keys, as status refresh does. Null when malformed.
abstract final class UseSmileIDSampleCatalogueJson {
  /// Decodes a `supported_id_types` body.
  static List<UseSmileIDSampleApiIdType>? idTypes(String body) {
    final Object? root = _decode(body);
    if (root is! Map<String, Object?> || root['id_types'] is! List<Object?>) {
      return null;
    }
    return <UseSmileIDSampleApiIdType>[
      for (final Object? item in root['id_types']! as List<Object?>)
        if (item is Map<String, Object?> &&
            item['country'] is String &&
            item['type'] is String &&
            item['label'] is String)
          UseSmileIDSampleApiIdType(
            country: item['country']! as String,
            type: item['type']! as String,
            label: item['label']! as String,
            regex: item['regex'] is String ? item['regex']! as String : '',
            requiredFields: <String>[
              if (item['required_fields'] is List<Object?>)
                for (final Object? field
                    in item['required_fields']! as List<Object?>)
                  if (field is String) field,
            ],
          ),
    ];
  }

  /// Decodes a `supported_documents` body.
  static List<UseSmileIDSampleApiCountryDocuments>? documents(String body) {
    final Object? root = _decode(body);
    if (root is! Map<String, Object?> ||
        root['valid_documents'] is! List<Object?>) {
      return null;
    }
    return <UseSmileIDSampleApiCountryDocuments>[
      for (final Object? item in root['valid_documents']! as List<Object?>)
        if (item is Map<String, Object?> &&
            item['country'] is Map<String, Object?> &&
            (item['country']! as Map<String, Object?>)['code'] is String &&
            (item['country']! as Map<String, Object?>)['name'] is String)
          UseSmileIDSampleApiCountryDocuments(
            UseSmileIDSampleCountry(
              (item['country']! as Map<String, Object?>)['code']! as String,
              (item['country']! as Map<String, Object?>)['name']! as String,
            ),
            <UseSmileIDSampleApiDocument>[
              if (item['id_types'] is List<Object?>)
                for (final Object? document
                    in item['id_types']! as List<Object?>)
                  if (_document(document)
                      case final UseSmileIDSampleApiDocument read)
                    read,
            ],
          ),
    ];
  }

  static UseSmileIDSampleApiDocument? _document(Object? item) {
    if (item is! Map<String, Object?> ||
        item['code'] is! String ||
        item['name'] is! String) {
      return null;
    }
    return UseSmileIDSampleApiDocument(
      code: item['code']! as String,
      name: item['name']! as String,
      hasBack: item['has_back'] is bool ? item['has_back']! as bool : true,
      format: item['format'] is int ? item['format']! as int : 1,
      subTypes: <UseSmileIDSampleApiSubType>[
        if (item['sub_types'] is List<Object?>)
          for (final Object? sub in item['sub_types']! as List<Object?>)
            if (sub is Map<String, Object?> &&
                sub['id'] is String &&
                sub['name'] is String)
              UseSmileIDSampleApiSubType(
                id: sub['id']! as String,
                name: sub['name']! as String,
                hasBack: sub['has_back'] is bool
                    ? sub['has_back']! as bool
                    : true,
                format: sub['format'] is int ? sub['format']! as int : 1,
                displayStandalone: sub['display_standalone'] == true,
              ),
      ],
    );
  }

  static Object? _decode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }
}
