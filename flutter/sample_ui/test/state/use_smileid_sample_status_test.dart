import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// Every job status, one table each: its label, its stored name, its chips and its pill's fill.
void main() {
  final UseSmileIDSampleStrings en = UseSmileIDSampleStrings.forLanguage('en');

  UseSmileIDSampleJob job(UseSmileIDSampleStatus status) => UseSmileIDSampleJob(
    id: 'job_00',
    userId: 'user_00',
    product: UseSmileIDSampleProduct.values.first,
    status: status,
    createdAtMillis: 0,
  );

  test('each status reads in Title case', () {
    expect(
      UseSmileIDSampleStatus.values.map(
        (UseSmileIDSampleStatus it) => it.label(en),
      ),
      <String>['Clear', 'Attention', 'Blocked', 'Error', 'Processing'],
    );
  });

  test('each status is stored by name and reads back as itself', () {
    for (final UseSmileIDSampleStatus status in UseSmileIDSampleStatus.values) {
      final Map<String, Object?> stored = job(status).toJson();
      expect(stored['status'], status.name, reason: status.name);
      expect(
        UseSmileIDSampleJob.fromStored(stored)!.status,
        status,
        reason: status.name,
      );
    }
  });

  test('a stored name no status has reads back as Processing', () {
    final Map<String, Object?> stored = job(
      UseSmileIDSampleStatus.clear,
    ).toJson()..['status'] = 'quarantined';
    expect(
      UseSmileIDSampleJob.fromStored(stored)!.status,
      UseSmileIDSampleStatus.processing,
    );
  });

  test('each status is listed by its own chip and by All, and by no other', () {
    expect(
      <UseSmileIDSampleStatus, List<UseSmileIDSampleJobFilter>>{
        for (final UseSmileIDSampleStatus status
            in UseSmileIDSampleStatus.values)
          status: UseSmileIDSampleJobFilter.values
              .where((UseSmileIDSampleJobFilter f) => f.matches(job(status)))
              .toList(),
      },
      <UseSmileIDSampleStatus, List<UseSmileIDSampleJobFilter>>{
        UseSmileIDSampleStatus.clear: <UseSmileIDSampleJobFilter>[
          UseSmileIDSampleJobFilter.all,
          UseSmileIDSampleJobFilter.clear,
        ],
        UseSmileIDSampleStatus.attention: <UseSmileIDSampleJobFilter>[
          UseSmileIDSampleJobFilter.all,
          UseSmileIDSampleJobFilter.attention,
        ],
        UseSmileIDSampleStatus.blocked: <UseSmileIDSampleJobFilter>[
          UseSmileIDSampleJobFilter.all,
          UseSmileIDSampleJobFilter.blocked,
        ],
        UseSmileIDSampleStatus.error: <UseSmileIDSampleJobFilter>[
          UseSmileIDSampleJobFilter.all,
          UseSmileIDSampleJobFilter.error,
        ],
        UseSmileIDSampleStatus.processing: <UseSmileIDSampleJobFilter>[
          UseSmileIDSampleJobFilter.all,
        ],
      },
    );
  });

  test("each status's pill is its role's soft fill, in both schemes", () {
    expect(
      UseSmileIDSampleStatus.values.map((UseSmileIDSampleStatus it) => it.role),
      <String>['success', 'warning', 'error', 'neutral', 'info'],
    );
    for (final UseSmileIDSampleColors scheme in <UseSmileIDSampleColors>[
      UseSmileIDSampleColorSchemes.light,
      UseSmileIDSampleColorSchemes.dark,
    ]) {
      final UseSmileIDSampleBadgeTokens badge = scheme.badge;
      expect(
        <Color>[
          badge.successBackground,
          badge.successText,
          badge.warningBackground,
          badge.warningText,
          badge.errorBackground,
          badge.errorText,
          badge.neutralBackground,
          badge.neutralText,
          badge.infoBackground,
          badge.infoText,
        ],
        <String>['success', 'warning', 'error', 'neutral', 'info']
            .map((String role) => smileSoftBadgeFills[role]!)
            .expand(
              (SmileSoftBadgeFill fill) => <Color>[fill.background, fill.text],
            )
            .toList(),
      );
    }
  });
}
