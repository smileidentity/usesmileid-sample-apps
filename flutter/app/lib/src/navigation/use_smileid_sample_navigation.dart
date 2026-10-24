import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_njia/usesmileid_njia.dart';

import 'use_smileid_sample_njia.dart';

/// The shell's engine, over the app's own step kinds and facts.
typedef UseSmileIDSampleEngine =
    NjiaEngine<UseSmileIDSampleStep, UseSmileIDSampleFact>;

/// What each of the app's steps sees of the flow.
typedef UseSmileIDSampleStepScope =
    NjiaStepScope<UseSmileIDSampleStep, UseSmileIDSampleFact>;

/// Where the shell's engines come from: njia's native core in the app, its Dart reference in tests.
abstract interface class UseSmileIDSampleNjiaEngines {
  /// A fresh flow on [graph].
  Future<UseSmileIDSampleEngine> start(UseSmileIDSampleGraph graph);

  /// The flow [state] describes, on [graph].
  Future<UseSmileIDSampleEngine> restore(
    UseSmileIDSampleGraph graph,
    NjiaState<UseSmileIDSampleFact> state,
  );

  /// A flow opened at [link] under [facts], or null when the graph refuses the link.
  Future<UseSmileIDSampleEngine?> openLink(
    UseSmileIDSampleGraph graph,
    String link,
    Set<UseSmileIDSampleFact> facts,
  );
}

/// njia's native core, which the app runs on.
final class UseSmileIDSampleNativeNjia implements UseSmileIDSampleNjiaEngines {
  /// The one native source.
  const UseSmileIDSampleNativeNjia();

  @override
  Future<UseSmileIDSampleEngine> start(UseSmileIDSampleGraph graph) =>
      NjiaKit.start(useSmileIDSampleNjiaCodec, graph);

  @override
  Future<UseSmileIDSampleEngine> restore(
    UseSmileIDSampleGraph graph,
    NjiaState<UseSmileIDSampleFact> state,
  ) => NjiaKit.restore(useSmileIDSampleNjiaCodec, graph, state);

  @override
  Future<UseSmileIDSampleEngine?> openLink(
    UseSmileIDSampleGraph graph,
    String link,
    Set<UseSmileIDSampleFact> facts,
  ) => NjiaKit.openLink(useSmileIDSampleNjiaCodec, graph, link, facts: facts);
}

/// The shell's engine source: njia's native core, which tests replace with its Dart reference.
final Provider<UseSmileIDSampleNjiaEngines>
useSmileIDSampleNjiaEnginesProvider = Provider<UseSmileIDSampleNjiaEngines>(
  (Ref ref) => const UseSmileIDSampleNativeNjia(),
);

/// The app's graph, read from its bundled copy; tests hand in the spec's.
final FutureProvider<UseSmileIDSampleGraph> useSmileIDSampleNjiaGraphProvider =
    FutureProvider<UseSmileIDSampleGraph>(
      (Ref ref) => useSmileIDSampleNjiaGraph(),
    );

/// Holds the shell's engine and tells the shell whenever the flow moves or is replaced.
class UseSmileIDSampleNavigationModel extends ChangeNotifier {
  /// A model for [graph] whose engines come from [engines].
  UseSmileIDSampleNavigationModel(this.graph, this._engines);

  /// The app's graph.
  final UseSmileIDSampleGraph graph;

  final UseSmileIDSampleNjiaEngines _engines;

  UseSmileIDSampleEngine? _engine;

  /// The flow on screen, null until [start] has finished.
  UseSmileIDSampleEngine? get engine => _engine;

  /// Starts at [link] under [facts] when the graph opens it, else on the products tab.
  Future<void> start({
    String? link,
    Set<UseSmileIDSampleFact> facts = const <UseSmileIDSampleFact>{},
  }) async {
    final UseSmileIDSampleEngine? opened = link == null
        ? null
        : await _engines.openLink(graph, link, facts);
    _replace(opened ?? await _engines.start(graph));
  }

  /// Opens [link] under [facts] as a new flow; a link the graph refuses leaves the current one.
  Future<bool> open(String link, Set<UseSmileIDSampleFact> facts) async {
    final UseSmileIDSampleEngine? opened = await _engines.openLink(
      graph,
      link,
      facts,
    );
    if (opened == null) {
      return false;
    }
    final UseSmileIDSampleEngine? current = _engine;
    _replace(
      current == null ? opened : await _keepingOtherTabs(current.state, opened),
    );
    return true;
  }

  /// A fresh flow on the products tab.
  Future<void> restart() async => _replace(await _engines.start(graph));

  /// [next], with the stacks [previous] held on the tabs the link didn't open, up to a run.
  Future<UseSmileIDSampleEngine> _keepingOtherTabs(
    NjiaState<UseSmileIDSampleFact> previous,
    UseSmileIDSampleEngine next,
  ) async {
    final String? previousTab = previous.entries.firstOrNull?.step;
    final String? openedTab = next.state.entries.firstOrNull?.step;
    if (previousTab == null || openedTab == null) {
      return next;
    }
    final Map<String, List<NjiaEntry>> stacks = <String, List<NjiaEntry>>{
      ...previous.parked,
      previousTab: previous.entries.skip(1).toList(),
    };
    final Map<String, List<NjiaEntry>> parked = <String, List<NjiaEntry>>{
      ...next.state.parked,
    };
    int nextId = next.state.nextId;
    for (final MapEntry<String, List<NjiaEntry>>(
          :String key,
          :List<NjiaEntry> value,
        )
        in stacks.entries) {
      if (key == openedTab || parked.containsKey(key)) {
        continue;
      }
      // Up to a run, not past it: a parked run's entry takes a new id, so its result would find nothing to leave.
      final List<NjiaEntry> kept = value
          .takeWhile(
            (NjiaEntry entry) => !_runKinds.contains(graph.stepOf(entry).kind),
          )
          .toList();
      if (kept.isEmpty) {
        continue;
      }
      parked[key] = <NjiaEntry>[
        for (final NjiaEntry entry in kept)
          NjiaEntry(
            id: nextId++,
            step: entry.step,
            visit: entry.visit,
            answer: entry.answer,
            arg: entry.arg,
          ),
      ];
    }
    if (parked.length == next.state.parked.length) {
      return next;
    }
    try {
      final UseSmileIDSampleEngine merged = await _engines.restore(
        graph,
        NjiaState<UseSmileIDSampleFact>(
          entries: next.state.entries,
          phase: next.state.phase,
          facts: next.state.facts,
          nextId: nextId,
          parked: parked,
        ),
      );
      unawaited(next.dispose());
      return merged;
    } on Object {
      return next;
    }
  }

  void _replace(UseSmileIDSampleEngine next) {
    final UseSmileIDSampleEngine? previous = _engine;
    previous?.removeListener(_moved);
    _engine = next..addListener(_moved);
    notifyListeners();
    if (previous != null) {
      unawaited(previous.dispose());
    }
  }

  void _moved(NjiaTransition<UseSmileIDSampleFact> _) => notifyListeners();

  @override
  void dispose() {
    _engine?.removeListener(_moved);
    final UseSmileIDSampleEngine? engine = _engine;
    if (engine != null) {
      unawaited(engine.dispose());
    }
    super.dispose();
  }
}

/// Gives the steps the shell's model, so a step reaches the engine for what its own navigator can't do.
class UseSmileIDSampleNavigationScope extends InheritedWidget {
  /// Puts [model] above [child].
  const UseSmileIDSampleNavigationScope({
    required this.model,
    required super.child,
    super.key,
  });

  /// The shell's model.
  final UseSmileIDSampleNavigationModel model;

  /// The flow on screen; a step is only ever built once it has started.
  static UseSmileIDSampleEngine engineOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<UseSmileIDSampleNavigationScope>()!
      .model
      .engine!;

  @override
  bool updateShouldNotify(UseSmileIDSampleNavigationScope oldWidget) =>
      oldWidget.model != model;
}

/// The runs, whose entries a link to another tab never parks.
const Set<UseSmileIDSampleStep> _runKinds = <UseSmileIDSampleStep>{
  UseSmileIDSampleStep.sdkFlow,
  UseSmileIDSampleStep.sdkFlowFullScreen,
};

/// The wizard's step kinds, which a run's product is read through.
const Set<UseSmileIDSampleStep> _wizardKinds = <UseSmileIDSampleStep>{
  UseSmileIDSampleStep.consentDetailsForm,
  UseSmileIDSampleStep.authUserId,
  UseSmileIDSampleStep.idDetailsForm,
  UseSmileIDSampleStep.sdkFlow,
  UseSmileIDSampleStep.sdkFlowFullScreen,
};

/// Where a run starts: the facts it runs under and the step a product tap goes to.
@immutable
final class UseSmileIDSampleRunEntry {
  /// A run under [facts] that opens at [step].
  const UseSmileIDSampleRunEntry({required this.facts, required this.step});

  /// The facts the graph's `skipWhen` reads for this run.
  final Set<UseSmileIDSampleFact> facts;

  /// The id of the run's first step.
  final String step;
}

/// The run helpers the shell's steps share, as Android's and iOS's shells have them.
extension UseSmileIDSampleRuns on UseSmileIDSampleEngine {
  /// The entry a run started at: the nearest wizard entry at or below [entry] that carries the product.
  NjiaEntry? runStart(NjiaEntry entry) {
    final List<NjiaEntry> entries = state.entries;
    final int at = entries.indexWhere((NjiaEntry it) => it.id == entry.id);
    if (at < 0) {
      return null;
    }
    return entries
        .take(at + 1)
        .where(
          (NjiaEntry it) =>
              it.arg != null && _wizardKinds.contains(graph.stepOf(it).kind),
        )
        .lastOrNull;
  }

  /// The product the run [entry] belongs to, read from the run's first entry.
  String? runProductId(NjiaEntry entry) => runStart(entry)?.arg;

  /// Starts a run of [product] from [from], in place of [replace] if given, under the run's facts alone.
  Future<void> startRun(
    NjiaEntry from,
    UseSmileIDSampleProduct product,
    UseSmileIDSampleRunEntry run, {
    int? replace,
  }) async {
    await send(
      NjiaIntent<UseSmileIDSampleFact>.facts(
        set: run.facts.toList(),
        clear: UseSmileIDSampleFact.values
            .where((UseSmileIDSampleFact it) => !run.facts.contains(it))
            .toList(),
      ),
    );
    await navigator(from).go(run.step, arg: product.id, replace: replace);
  }

  /// Leaves the run [entry] belongs to by going to [step] in its place, with [arg].
  Future<void> leaveRun(
    NjiaEntry entry,
    UseSmileIDSampleStep step, {
    String? arg,
  }) => navigator(
    entry,
  ).go(step.name, arg: arg, replace: (runStart(entry) ?? entry).id);

  /// Back to the products tab's root, which leaves a run however deep it went.
  Future<void> leaveToProducts() async {
    await select(UseSmileIDSampleStep.products.name);
  }
}

/// Steps named by kind: every step's id is its kind's wire name, which the graph test pins.
extension UseSmileIDSampleNavigatorSteps on NjiaNavigator {
  /// Goes to [step] carrying [arg].
  Future<void> goStep(UseSmileIDSampleStep step, {String? arg}) =>
      go(step.name, arg: arg);
}
