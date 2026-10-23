import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_sample_flutter/src/navigation/use_smileid_sample_deep_links.dart';

void main() {
  UseSmileIDSampleLink? linkOf(String uri) =>
      UseSmileIDSampleDeepLinks.linkOf(Uri.parse(uri));

  test('a link names its graph path, its scheme and host folded together', () {
    expect(
      linkOf('usesmileid-sample-flutter://settings/licenses')?.path,
      'settings/licenses',
    );
    expect(
      linkOf('usesmileid-sample-flutter://verifications/job-1/')?.path,
      'verifications/job-1',
    );
  });

  test('an in-app path reads the same as the link it came from', () {
    expect(linkOf('/settings/capture-mode')?.path, 'settings/capture-mode');
  });

  test('the plain launch and the dev gallery open no graph step', () {
    expect(linkOf('/'), isNull);
    expect(linkOf('usesmileid-sample-flutter://debug/components'), isNull);
    expect(
      UseSmileIDSampleDeepLinks.isGallery(
        Uri.parse('usesmileid-sample-flutter://debug/components'),
      ),
      isTrue,
    );
  });

  test('the run opens full screen unless its route asks for the shell', () {
    final UseSmileIDSampleLink full = linkOf(
      'usesmileid-sample-flutter://flow/biometricKyc/run',
    )!;
    expect(full.path, 'flow/biometricKyc/run-fullscreen');
    expect(full.route, UseSmileIDSampleFlowRoute.fullscreen);

    final UseSmileIDSampleLink shell = linkOf(
      'usesmileid-sample-flutter://flow/biometricKyc/run?route=shell&probes=true',
    )!;
    expect(shell.path, 'flow/biometricKyc/run');
    expect(shell.route, UseSmileIDSampleFlowRoute.shell);
  });

  test('a flow link names its product, and no other link does', () {
    expect(
      UseSmileIDSampleDeepLinks.productIdOf(
        linkOf('/flow/documentVerification/id-details')!,
      ),
      'documentVerification',
    );
    expect(UseSmileIDSampleDeepLinks.productIdOf(linkOf('/settings')!), isNull);
  });
}
