import 'dart:io';

import 'package:usesmileid/usesmileid.dart';

/// What this sample does with a job the SDK hands back: it forwards nothing, and the SDK never deletes the files.
extension UseSmileIDSampleCapturedJob on CapturedJob {
  /// Deletes every file the job lists, then its session directory; a path already gone is skipped.
  Future<void> deleteFiles() async {
    for (final String path in <String?>[
      selfieImage,
      ...livenessImages,
      frontDocument,
      backDocument,
      visaDocument,
    ].nonNulls) {
      final File file = File(path);
      if (file.existsSync()) await file.delete();
    }
    final String? session = sessionDirectory;
    if (session == null) return;
    final Directory directory = Directory(session);
    if (directory.existsSync()) await directory.delete(recursive: true);
  }
}
