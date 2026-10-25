import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_njia/usesmileid_njia.dart';

import 'navigation/use_smileid_sample_deep_links.dart';
import 'navigation/use_smileid_sample_navigation.dart';
import 'navigation/use_smileid_sample_njia.dart';
import 'navigation/use_smileid_sample_steps.dart';
import 'state/use_smileid_sample_providers.dart';
import 'use_smileid_sample_journey.dart';
import 'use_smileid_sample_launch.dart';

/// The window's root: njia draws the three tabs' stacks from `spec/njia-graph.json`, and the shell opens links.
class UseSmileIDSampleShell extends ConsumerStatefulWidget {
  /// A shell that opens at [launchLink], then at each of [links], and hands the dev gallery to [onGallery].
  const UseSmileIDSampleShell({
    required this.links,
    required this.onGallery,
    this.launchLink,
    super.key,
  });

  /// The link the app launched at, or null for a launch from the icon.
  final Uri? launchLink;

  /// Each link the platform delivers while the app runs.
  final Stream<Uri> links;

  /// Opens the dev-only component gallery, which is outside the graph.
  final VoidCallback onGallery;

  @override
  ConsumerState<UseSmileIDSampleShell> createState() =>
      _UseSmileIDSampleShellState();
}

class _UseSmileIDSampleShellState extends ConsumerState<UseSmileIDSampleShell> {
  UseSmileIDSampleNavigationModel? _model;

  /// The engine drawn, so a transition doesn't rebuild the host, only a replaced flow does.
  UseSmileIDSampleEngine? _drawn;

  StreamSubscription<Uri>? _links;

  /// Links that arrived before the flow had started, opened once it has.
  final List<Uri> _pending = <Uri>[];

  /// iOS delivers its cold link again after the first frame; folded, it would replace the flow it opened.
  Uri? _echo;

  Timer? _echoExpiry;

  @override
  void initState() {
    super.initState();
    _echo = widget.launchLink;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_echo != null) {
        _echoExpiry = Timer(useSmileIDSampleColdLinkWindow, () => _echo = null);
      }
    });
    _links = widget.links.listen(_open);
    unawaited(_start());
  }

  @override
  void dispose() {
    unawaited(_links?.cancel());
    _echoExpiry?.cancel();
    _model?.removeListener(_moved);
    _model?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final UseSmileIDSampleGraph graph = await ref.read(
      useSmileIDSampleNjiaGraphProvider.future,
    );
    final UseSmileIDSampleNavigationModel model =
        UseSmileIDSampleNavigationModel(
          graph,
          ref.read(useSmileIDSampleNjiaEnginesProvider),
        );
    final Uri? launch = widget.launchLink;
    final UseSmileIDSampleProduct? autostart = ref
        .read(useSmileIDSampleLaunchArgsProvider)
        .autostart;
    final UseSmileIDSampleLink? link = autostart != null || launch == null
        ? null
        : UseSmileIDSampleDeepLinks.linkOf(launch);
    await model.start(
      link: link?.path,
      facts: link == null
          ? const <UseSmileIDSampleFact>{}
          : useSmileIDSampleLinkFacts(ref, link),
    );
    if (!mounted) {
      model.dispose();
      return;
    }
    model.addListener(_moved);
    setState(() {
      _model = model;
      _drawn = model.engine;
    });
    if (autostart != null) {
      final UseSmileIDSampleEngine engine = model.engine!;
      unawaited(
        engine.startRun(
          engine.state.top!,
          autostart,
          useSmileIDSampleRunOnly(
            ref,
            autostart,
            ref.read(useSmileIDSampleLaunchArgsProvider).route,
          ),
        ),
      );
    } else if (launch != null && UseSmileIDSampleDeepLinks.isGallery(launch)) {
      widget.onGallery();
    }
    _pending.forEach(_open);
    _pending.clear();
  }

  /// Opens a delivered link as a new flow, under the facts its product runs with, or the dev gallery.
  void _open(Uri uri) {
    if (_echo != null && uri == _echo) {
      _echo = null;
      _echoExpiry?.cancel();
      return;
    }
    final UseSmileIDSampleNavigationModel? model = _model;
    if (model == null) {
      _pending.add(uri);
      return;
    }
    if (UseSmileIDSampleDeepLinks.isGallery(uri)) {
      widget.onGallery();
      return;
    }
    final UseSmileIDSampleLink? link = UseSmileIDSampleDeepLinks.linkOf(uri);
    if (link != null) {
      unawaited(model.open(link.path, useSmileIDSampleLinkFacts(ref, link)));
    }
  }

  void _moved() {
    final UseSmileIDSampleNavigationModel model = _model!;
    final UseSmileIDSampleEngine engine = model.engine!;
    if (engine.state.phase is NjiaDonePhase) {
      // Back from the products tab's root finishes the flow: the app goes to the background and comes back on a fresh one.
      unawaited(SystemNavigator.pop());
      unawaited(model.restart());
      return;
    }
    if (!identical(engine, _drawn)) {
      setState(() => _drawn = engine);
    }
  }

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final UseSmileIDSampleNavigationModel? model = _model;
    final UseSmileIDSampleEngine? engine = _drawn;
    if (model == null || engine == null) {
      return ColoredBox(color: colors.background);
    }
    return UseSmileIDSampleNavigationScope(
      model: model,
      child: NjiaHost<UseSmileIDSampleStep, UseSmileIDSampleFact>.withSteps(
        key: ObjectKey(engine),
        engine: engine,
        steps: useSmileIDSampleSteps,
        // Each screen names itself `sample_*`, and a second identifier on its element would replace the first.
        stepIds: false,
        // The design's own scrim and corners, which njia's default sheet style would replace.
        sheetStyle: NjiaSheetStyle(
          scrim: colors.overlayScrim,
          shape: RoundedRectangleBorder(
            borderRadius: UseSmileIDSampleShapes.sheet,
          ),
        ),
      ),
    );
  }
}
