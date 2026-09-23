import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_providers.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_launch.dart';

/// iOS pushes a cold link after the first frame; only that first push may seed, never a warm one.
void main() {
  late List<Uri> adopted;
  late UseSmileIDSampleColdLink coldLink;

  setUp(() {
    adopted = <Uri>[];
    coldLink = UseSmileIDSampleColdLink(
      onLink: (Uri link) async {
        adopted.add(link);
      },
    );
  });

  tearDown(() => coldLink.close());

  /// What the engine sends: the whole link, down the navigation channel.
  Future<void> push(WidgetTester tester, String link) =>
      tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.navigation.name,
        SystemChannels.navigation.codec.encodeMethodCall(
          MethodCall('pushRouteInformation', <String, Object?>{
            'location': link,
            'state': null,
          }),
        ),
        (_) {},
      );

  const String cold = 'usesmileid-sample-flutter://verifications?seedJobs=true';

  testWidgets('a push before the first frame is the launch link', (
    WidgetTester tester,
  ) async {
    coldLink.listen();
    await push(tester, cold);

    expect(adopted, <Uri>[Uri.parse(cold)]);
  });

  testWidgets('the push that follows the first frame is the launch link', (
    WidgetTester tester,
  ) async {
    coldLink.listen();
    await tester.pumpWidget(const SizedBox());
    await push(tester, cold);

    expect(adopted, <Uri>[Uri.parse(cold)]);
  });

  testWidgets('a second push is a warm link and adopts nothing', (
    WidgetTester tester,
  ) async {
    coldLink.listen();
    await tester.pumpWidget(const SizedBox());
    await push(tester, cold);
    await push(
      tester,
      'usesmileid-sample-flutter://settings?seedProfiles=true',
    );

    expect(adopted, <Uri>[Uri.parse(cold)]);
  });

  testWidgets('a push once the window has passed adopts nothing', (
    WidgetTester tester,
  ) async {
    coldLink.listen();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(useSmileIDSampleColdLinkWindow);
    await push(tester, cold);

    expect(adopted, isEmpty);
  });

  testWidgets('a push after the first touch adopts nothing', (
    WidgetTester tester,
  ) async {
    coldLink.listen();
    await tester.pumpWidget(const SizedBox());
    await tester.tapAt(Offset.zero);
    await push(tester, cold);

    expect(adopted, isEmpty);
  });

  test('an adopted link replaces the startup arguments', () {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        useSmileIDSampleLaunchArgsOverride(const UseSmileIDSampleLaunchArgs()),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(useSmileIDSampleLaunchArgsProvider).seedJobs, false);

    container
        .read(useSmileIDSampleColdLinkArgsProvider.notifier)
        .adopt(UseSmileIDSampleLaunchArgs.fromUri(Uri.parse(cold)));

    expect(container.read(useSmileIDSampleLaunchArgsProvider).seedJobs, true);
  });
}
