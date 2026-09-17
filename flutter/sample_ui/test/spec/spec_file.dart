import 'dart:convert';
import 'dart:io';

/// One `spec/` file, parsed. Dart reads JSON properly, so these tests compare structure rather
/// than matching patterns the way the Kotlin twins have to.
Map<String, Object?> spec(String name) {
  final File file = File('../../spec/$name');
  if (!file.existsSync()) {
    throw StateError('spec/$name not found at ${file.absolute.path}');
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

/// Every object in a JSON list, typed.
List<Map<String, Object?>> objects(Object? value) =>
    (value as List<Object?>).cast<Map<String, Object?>>();
