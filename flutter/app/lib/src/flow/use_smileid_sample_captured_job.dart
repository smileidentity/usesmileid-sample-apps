import 'dart:io';

import 'package:usesmileid/usesmileid.dart';

/// What this sample does with a job the SDK hands back: it forwards nothing, and the SDK never deletes the files.
extension UseSmileIDSampleCapturedJob on CapturedJob {
  /// Deletes every file the job lists, then its session directory; one already gone, or that the file system refuses, is skipped.
  Future<void> deleteFiles() async {
    final List<FileSystemEntity> entries = <FileSystemEntity>[
      for (final String path in <String?>[
        selfieImage,
        ...livenessImages,
        frontDocument,
        backDocument,
        visaDocument,
      ].nonNulls)
        File(path),
      if (sessionDirectory case final String session) Directory(session),
    ];
    for (final FileSystemEntity entry in entries) {
      try {
        if (entry.existsSync()) await entry.delete(recursive: true);
      } on FileSystemException {
        // A file left behind is harmless: the SDK writes each session to a folder of its own.
      }
    }
  }
}
