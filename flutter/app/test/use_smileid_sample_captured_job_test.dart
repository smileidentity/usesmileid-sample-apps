import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:usesmileid/usesmileid.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_captured_job.dart';

/// What the sample does with a captured job: it forwards nothing, so the files go.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('captured'));

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test(
    "a captured job's files and session directory are deleted, since this sample forwards nothing",
    () async {
      final Directory session = Directory('${root.path}/session')..createSync();
      final File selfie = File('${session.path}/selfie.jpg')
        ..writeAsStringSync('selfie');
      final File liveness = File('${session.path}/liveness.jpg')
        ..writeAsStringSync('liveness');
      File('${session.path}/left-over.json').writeAsStringSync('{}');
      final File front = File('${root.path}/front.jpg')
        ..writeAsStringSync('front');

      await CapturedJob(
        jobType: JobType.smartSelfieEnrollment,
        sessionId: 'session',
        sessionDirectory: session.path,
        selfieImage: selfie.path,
        livenessImages: <String>[liveness.path],
        frontDocument: front.path,
        backDocument: null,
        headers: const <String, String>{},
        encryptedPackage: '00',
        packageNonce: '00',
        packageTag: '00',
      ).deleteFiles();

      expect(session.existsSync(), isFalse);
      expect(
        front.existsSync(),
        isFalse,
        reason: 'a listed file outside the session directory goes too',
      );
    },
  );

  test(
    'a delete the file system refuses is skipped, and the rest still go',
    () async {
      final Directory locked = Directory('${root.path}/locked')..createSync();
      final File refused = File('${locked.path}/selfie.jpg')
        ..writeAsStringSync('selfie');
      final Directory session = Directory('${root.path}/session')..createSync();
      final File front = File('${session.path}/front.jpg')
        ..writeAsStringSync('front');
      // Read-only, so deleting the file inside it fails as a permission error would.
      await Process.run('chmod', <String>['500', locked.path]);
      addTearDown(() => Process.runSync('chmod', <String>['700', locked.path]));

      await CapturedJob(
        jobType: JobType.smartSelfieEnrollment,
        sessionId: 'session',
        sessionDirectory: session.path,
        selfieImage: refused.path,
        livenessImages: const <String>[],
        frontDocument: front.path,
        backDocument: null,
        headers: const <String, String>{},
        encryptedPackage: '00',
        packageNonce: '00',
        packageTag: '00',
      ).deleteFiles();

      expect(refused.existsSync(), isTrue);
      expect(front.existsSync(), isFalse);
      expect(session.existsSync(), isFalse);
    },
  );

  test(
    'a job with nothing on disk deletes nothing and does not throw',
    () async {
      await const CapturedJob(
        jobType: JobType.smartSelfieEnrollment,
        sessionId: 'session',
        sessionDirectory: null,
        selfieImage: null,
        livenessImages: <String>[],
        frontDocument: '/nowhere/front.jpg',
        backDocument: null,
        headers: <String, String>{},
        encryptedPackage: '00',
        packageNonce: '00',
        packageTag: '00',
      ).deleteFiles();
    },
  );
}
