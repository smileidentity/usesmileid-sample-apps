import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_njia/usesmileid_njia.dart';
import 'package:usesmileid_sample_flutter/src/navigation/use_smileid_sample_navigation.dart';
import 'package:usesmileid_sample_flutter/src/navigation/use_smileid_sample_njia.dart';

import '../support/use_smileid_sample_test_njia.dart';

void main() {
  final UseSmileIDSampleGraph graph = useSmileIDSampleSpecGraph();

  /// A model on njia's reference engine, started on the products tab.
  Future<UseSmileIDSampleNavigationModel> started() async {
    final UseSmileIDSampleNavigationModel model =
        UseSmileIDSampleNavigationModel(graph, UseSmileIDSampleReferenceNjia());
    await model.start();
    return model;
  }

  UseSmileIDSampleStep topOf(UseSmileIDSampleNavigationModel model) =>
      graph.stepOf(model.engine!.state.top!).kind;

  test('a plain launch starts on the products tab', () async {
    expect(topOf(await started()), UseSmileIDSampleStep.products);
  });

  test(
    'a launch link opens at its step, with the sheet over its owner',
    () async {
      final UseSmileIDSampleNavigationModel model =
          UseSmileIDSampleNavigationModel(
            graph,
            UseSmileIDSampleReferenceNjia(),
          );
      await model.start(link: 'settings/capture-mode');

      expect(
        model.engine!.state.entries.map((NjiaEntry it) => it.step),
        <String>['settings', 'captureMode'],
      );
    },
  );

  test('a launch link the graph refuses starts on the products tab', () async {
    final UseSmileIDSampleNavigationModel model =
        UseSmileIDSampleNavigationModel(graph, UseSmileIDSampleReferenceNjia());
    await model.start(link: 'nowhere');

    expect(topOf(model), UseSmileIDSampleStep.products);
  });

  test('a refused link leaves the flow on screen', () async {
    final UseSmileIDSampleNavigationModel model = await started();
    final UseSmileIDSampleEngine before = model.engine!;

    expect(
      await model.open('nowhere', const <UseSmileIDSampleFact>{}),
      isFalse,
    );
    expect(model.engine, same(before));
  });

  test(
    'a link to another tab keeps the stack the user left, up to a run',
    () async {
      final UseSmileIDSampleNavigationModel model = await started();
      final UseSmileIDSampleEngine engine = model.engine!;
      await engine.navigator(engine.state.top!).go('scanToken');

      await model.open('settings/licenses', const <UseSmileIDSampleFact>{});
      expect(topOf(model), UseSmileIDSampleStep.licenses);
      await model.engine!.select(UseSmileIDSampleStep.products.name);

      expect(topOf(model), UseSmileIDSampleStep.scanToken);
    },
  );

  test(
    'a run started from a product carries the product and its facts',
    () async {
      final UseSmileIDSampleNavigationModel model = await started();
      final UseSmileIDSampleEngine engine = model.engine!;

      await engine.startRun(
        engine.state.top!,
        UseSmileIDSampleProduct.documentVerification,
        const UseSmileIDSampleRunEntry(
          facts: <UseSmileIDSampleFact>{UseSmileIDSampleFact.needsIdDetails},
          step: 'consentDetailsForm',
        ),
      );

      final NjiaEntry form = engine.state.top!;
      expect(form.step, 'consentDetailsForm');
      expect(form.arg, UseSmileIDSampleProduct.documentVerification.id);
      expect(engine.state.facts, <UseSmileIDSampleFact>{
        UseSmileIDSampleFact.needsIdDetails,
      });
      await engine.navigator(form).next();
      await engine.navigator(engine.state.top!).next();

      expect(engine.state.top!.step, 'sdkFlow');
      expect(
        engine.runProductId(engine.state.top!),
        UseSmileIDSampleProduct.documentVerification.id,
      );
    },
  );

  test(
    'a run that ends replaces its whole wizard with where it went',
    () async {
      final UseSmileIDSampleNavigationModel model = await started();
      final UseSmileIDSampleEngine engine = model.engine!;
      await engine.startRun(
        engine.state.top!,
        UseSmileIDSampleProduct.smartSelfieEnrollment,
        const UseSmileIDSampleRunEntry(
          facts: <UseSmileIDSampleFact>{},
          step: 'consentDetailsForm',
        ),
      );
      await engine.navigator(engine.state.top!).next();

      await engine.leaveRun(
        engine.state.top!,
        UseSmileIDSampleStep.verificationDetails,
        arg: 'job-1',
      );

      expect(engine.state.entries.map((NjiaEntry it) => it.step), <String>[
        'verifications',
        'verificationDetails',
      ]);
      expect(engine.state.top!.arg, 'job-1');
      await engine.select(UseSmileIDSampleStep.products.name);
      expect(engine.state.entries.map((NjiaEntry it) => it.step), <String>[
        'products',
      ]);
    },
  );

  test('leaving to products drops a run however deep it went', () async {
    final UseSmileIDSampleNavigationModel model = await started();
    final UseSmileIDSampleEngine engine = model.engine!;
    await engine.startRun(
      engine.state.top!,
      UseSmileIDSampleProduct.smartSelfieEnrollment,
      const UseSmileIDSampleRunEntry(
        facts: <UseSmileIDSampleFact>{},
        step: 'consentDetailsForm',
      ),
    );
    await engine.navigator(engine.state.top!).next();

    await engine.leaveToProducts();

    expect(engine.state.entries.map((NjiaEntry it) => it.step), <String>[
      'products',
    ]);
  });

  test(
    "the user-details form's profile chip reaches the switch sheet",
    () async {
      final UseSmileIDSampleNavigationModel model = await started();
      final UseSmileIDSampleEngine engine = model.engine!;
      await engine.startRun(
        engine.state.top!,
        UseSmileIDSampleProduct.smartSelfieEnrollment,
        const UseSmileIDSampleRunEntry(
          facts: <UseSmileIDSampleFact>{},
          step: 'consentDetailsForm',
        ),
      );

      await engine
          .navigator(engine.state.top!)
          .goStep(UseSmileIDSampleStep.profileSwitch);

      expect(topOf(model), UseSmileIDSampleStep.profileSwitch);
    },
  );

  test('a restart drops every stack for a fresh products tab', () async {
    final UseSmileIDSampleNavigationModel model = await started();
    await model.open('settings/licenses', const <UseSmileIDSampleFact>{});

    await model.restart();

    expect(model.engine!.state.entries.map((NjiaEntry it) => it.step), <String>[
      'products',
    ]);
    expect(model.engine!.state.parked, isEmpty);
  });

  test('the model tells the shell when the flow moves', () async {
    final UseSmileIDSampleNavigationModel model = await started();
    int told = 0;
    model.addListener(() => told++);

    await model.engine!
        .navigator(model.engine!.state.top!)
        .goStep(UseSmileIDSampleStep.scanToken);
    await model.open('settings', const <UseSmileIDSampleFact>{});

    expect(told, 2);
  });
}
