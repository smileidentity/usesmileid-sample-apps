import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_njia/usesmileid_njia.dart';

import '../catalogue/use_smileid_sample_catalogue_providers.dart';
import '../flow/use_smileid_sample_token_binding_rules.dart';
import '../navigation/use_smileid_sample_navigation.dart';
import '../navigation/use_smileid_sample_njia.dart';
import '../state/use_smileid_sample_flow_result_provider.dart';
import '../state/use_smileid_sample_forms.dart';
import '../state/use_smileid_sample_providers.dart';
import '../state/use_smileid_sample_session_providers.dart';
import '../use_smileid_sample_journey.dart';

/// The products tab: the grid every flow starts from.
class UseSmileIDSampleProductsTab extends ConsumerStatefulWidget {
  /// The tab's root, for [scope]'s entry.
  const UseSmileIDSampleProductsTab({required this.scope, super.key});

  /// The tab root's entry, which a run starts from.
  final UseSmileIDSampleStepScope scope;

  @override
  ConsumerState<UseSmileIDSampleProductsTab> createState() =>
      _UseSmileIDSampleProductsTabState();
}

class _UseSmileIDSampleProductsTabState
    extends ConsumerState<UseSmileIDSampleProductsTab> {
  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleProfiles profiles = ref.watch(
      useSmileIDSampleProfilesProvider,
    );
    final UseSmileIDSampleSessionRecord session = ref.watch(
      useSmileIDSampleSessionProvider,
    );
    // Read, not watched: expiry lands as a retirement, which the watch above sees.
    final bool ended = useSmileIDSampleSessionEnded(
      session,
      ref.read(useSmileIDSampleWallClockProvider)(),
    );
    final UseSmileIDSampleTokenSession? live = session.live;
    return UseSmileIDSampleProductsScreen(
      state: UseSmileIDSampleProductsState(
        initials: profiles.active?.initials ?? '',
        result: ref.watch(useSmileIDSampleFlowResultProvider),
        // By POSITION, not by id: the hue is the profile's place in the list, and every screen
        // showing the same profile has to agree on it.
        avatarColor: avatarColorForProfile(profiles.activeIndex),
        sessionId: ended ? null : live?.id,
        sessionCountdown: ended || live == null
            ? null
            : Consumer(
                builder: (BuildContext context, WidgetRef ref, Widget? _) =>
                    UseSmileIDSampleSessionCountdown(
                      remaining: useSmileIDSampleCountdown(
                        live.remaining(
                          ref.watch(useSmileIDSampleClockProvider),
                        ),
                      ),
                    ),
              ),
        sessionEnded: ended,
      ),
      onProductTap: (UseSmileIDSampleProduct product) => unawaited(
        useSmileIDSampleStartProductRun(
          ref,
          UseSmileIDSampleNavigationScope.engineOf(context),
          widget.scope.entry,
          product,
        ),
      ),
      onProfileTap: () => unawaited(
        widget.scope.navigator.goStep(UseSmileIDSampleStep.profileSwitch),
      ),
      onScanTap: () => unawaited(
        widget.scope.navigator.goStep(UseSmileIDSampleStep.scanToken),
      ),
      bottomInset: useSmileIDSampleNavBarClearance(context),
    );
  }
}

/// A product tap's run from [from], in place of [replace] if given: fresh forms, the run's partner, and the scanner first with no live session.
Future<void> useSmileIDSampleStartProductRun(
  WidgetRef ref,
  UseSmileIDSampleEngine engine,
  NjiaEntry from,
  UseSmileIDSampleProduct product, {
  int? replace,
}) async {
  // Fresh from the profile, so one run's ID details never carry into another, least of all another partner's.
  ref
      .read(useSmileIDSampleFormsProvider.notifier)
      .startRun(ref.read(useSmileIDSampleProfilesProvider).active);
  final UseSmileIDSampleTokenSession? live = ref
      .read(useSmileIDSampleSessionProvider)
      .live;
  final UseSmileIDSampleRunEntry? run = useSmileIDSampleEntryFor(
    ref,
    engine.graph,
    product,
  );
  ref
      .read(useSmileIDSampleRunPartnerProvider.notifier)
      .record(run == null ? null : live?.partnerId);
  // Fetched ahead, so the list is usually there by the time the picker opens.
  if (run != null && useSmileIDSampleCatalogueFamily(product) != null) {
    final UseSmileIDSampleCatalogueStore store =
        ref.read(useSmileIDSampleCatalogueStoreProvider)..begin(
          useSmileIDSampleCatalogueEnvironment(live),
          useSmileIDSampleCatalogueLocale(),
        );
    useSmileIDSampleEnsureEnabled(store, product, live);
  }
  await (run == null
      ? engine
            .navigator(from)
            .go(UseSmileIDSampleStep.scanToken.name, replace: replace)
      : engine.startRun(from, product, run, replace: replace));
}
