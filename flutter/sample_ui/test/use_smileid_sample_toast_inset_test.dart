import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// Every screen's toast clears the chrome at the bottom.
void main() {
  /// A three-button Android navigation bar.
  const double systemBar = 48;
  const Size screen = Size(393, 852);

  Future<Rect> toastIn(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: systemBar);
    tester.view.viewPadding = const FakeViewPadding(bottom: systemBar);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: UseSmileIDSampleTheme.light(),
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
    return tester.getRect(find.byType(UseSmileIDSampleToast));
  }

  testWidgets('the details refresh notice sits above the system bar', (
    WidgetTester tester,
  ) async {
    final Rect toast = await toastIn(
      tester,
      UseSmileIDSampleVerificationDetailsScreen(
        jobId: 'job_1',
        job: const UseSmileIDSampleJobLookup.none(),
        onBack: () {},
        refreshNotice: 'Clear — Job completed',
      ),
    );
    expect(
      toast.bottom,
      lessThanOrEqualTo(screen.height - systemBar - SmileDimens.spacingMd),
    );
  });

  testWidgets('the profiles notice sits above the system bar', (
    WidgetTester tester,
  ) async {
    final Rect toast = await toastIn(
      tester,
      UseSmileIDSampleProfilesScreen(
        profiles: UseSmileIDSampleProfiles.fixtures(),
        activeId: 'p-1',
        onBack: () {},
        onProfileTap: (_) {},
        onCreate: () {},
        createdNotice: 'Kobo Bank',
        onMakeCreatedActive: () {},
      ),
    );
    expect(
      toast.bottom,
      lessThanOrEqualTo(screen.height - systemBar - SmileDimens.spacingLg),
    );
  });

  testWidgets('the removal notice sits above the nav pill a tab root draws', (
    WidgetTester tester,
  ) async {
    const double pill = 96 + systemBar;
    final Rect toast = await toastIn(
      tester,
      UseSmileIDSampleVerificationsScreen(
        state: UseSmileIDSampleVerificationsState(
          jobs: const <UseSmileIDSampleJob>[],
          nowMillis: 0,
          removedCount: 1,
        ),
        onFilterChanged: (_) {},
        bottomInset: pill,
      ),
    );
    expect(toast.bottom, lessThanOrEqualTo(screen.height - pill));
  });
}
