import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// Skeleton rows wait 300 ms before showing, then stay at least 400 ms.
void main() {
  testWidgets('a fast answer never shows the rows', (
    WidgetTester tester,
  ) async {
    final UseSmileIDSampleSkeletonGate gate = UseSmileIDSampleSkeletonGate()
      ..loading(true);
    addTearDown(gate.dispose);

    await tester.pump(const Duration(milliseconds: 299));
    gate.loading(false);
    await tester.pump(const Duration(seconds: 1));

    expect(gate.visible, isFalse);
  });

  testWidgets('a slow answer shows them, and they stay 400 ms', (
    WidgetTester tester,
  ) async {
    DateTime now = DateTime(2026);
    final UseSmileIDSampleSkeletonGate gate = UseSmileIDSampleSkeletonGate(
      now: () => now,
    )..loading(true);
    addTearDown(gate.dispose);

    await tester.pump(const Duration(milliseconds: 300));
    expect(gate.visible, isTrue);

    now = now.add(const Duration(milliseconds: 100));
    gate.loading(false);
    await tester.pump(const Duration(milliseconds: 299));
    expect(gate.visible, isTrue, reason: 'only 399 ms since the rows appeared');

    await tester.pump(const Duration(milliseconds: 1));
    expect(gate.visible, isFalse);
  });

  testWidgets('rows already shown past the minimum go at once', (
    WidgetTester tester,
  ) async {
    DateTime now = DateTime(2026);
    final UseSmileIDSampleSkeletonGate gate = UseSmileIDSampleSkeletonGate(
      now: () => now,
    )..loading(true);
    addTearDown(gate.dispose);
    await tester.pump(const Duration(milliseconds: 300));

    now = now.add(const Duration(seconds: 2));
    gate.loading(false);
    await tester.pump();

    expect(gate.visible, isFalse);
  });
}
