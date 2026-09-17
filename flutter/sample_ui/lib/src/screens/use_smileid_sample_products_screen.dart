import 'package:flutter/material.dart';

import '../components/use_smileid_sample_avatar.dart';
import '../components/use_smileid_sample_icon.dart';
import '../components/use_smileid_sample_product_card.dart';
import '../components/use_smileid_sample_product_grid.dart';
import '../components/use_smileid_sample_section_header.dart';
import '../components/use_smileid_sample_session_card.dart';
import '../model/use_smileid_sample_product.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';

/// What the products header and session strip render, so the screen holds no clock and no store.
@immutable
class UseSmileIDSampleProductsState {
  /// [sessionRemaining] arrives formatted, because the deadline is absolute and the tick is above.
  const UseSmileIDSampleProductsState({
    required this.initials,
    this.avatarColor,
    this.sessionId,
    this.sessionRemaining,
    this.sessionEnded = false,
  });

  /// The active profile's initials.
  final String initials;

  /// The active profile's hue, so every screen showing it agrees; the first when none is passed.
  final Color? avatarColor;

  /// The linked session's id, null when nothing is linked.
  final String? sessionId;

  /// The countdown, already formatted as m:ss.
  final String? sessionRemaining;

  /// Whether the session has expired, which replaces the card with the neutral banner.
  final bool sessionEnded;
}

/// The products grid, the entry point every flow starts from.
class UseSmileIDSampleProductsScreen extends StatelessWidget {
  /// [bottomInset] is the room the floating nav bar needs; the screen is not inset by it.
  const UseSmileIDSampleProductsScreen({
    required this.state,
    required this.onProductTap,
    required this.onProfileTap,
    required this.onScanTap,
    this.bottomInset = 0,
    super.key,
  });

  /// What to render.
  final UseSmileIDSampleProductsState state;

  /// Starts a product's pre-flow forms.
  final void Function(UseSmileIDSampleProduct product) onProductTap;

  /// Opens the profile-switch sheet.
  final VoidCallback onProfileTap;

  /// Opens the scan screen to link or relink a session.
  final VoidCallback onScanTap;

  /// Trailing room so the last card can scroll clear of the floating bar.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Semantics(
      identifier: UseSmileIDSampleTestIds.productsScreen,
      child: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.viewPaddingOf(context).top + SmileDimens.spacingSm,
          bottom: bottomInset,
        ),
        children: <Widget>[
          _Header(state: state, onProfileTap: onProfileTap, colors: colors),
          const SizedBox(height: SmileDimens.spacingSm),
          if (state.sessionEnded)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SmileDimens.spacingMd,
              ),
              child: UseSmileIDSampleSessionEndedBanner(onScan: onScanTap),
            )
          else if (state.sessionId != null && state.sessionRemaining != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SmileDimens.spacingMd,
              ),
              child: UseSmileIDSampleSessionCard(
                sessionId: state.sessionId!,
                remaining: state.sessionRemaining!,
              ),
            ),
          for (final UseSmileIDSampleProductSection section
              in UseSmileIDSampleProductSection.values)
            Padding(
              padding: const EdgeInsets.only(
                left: SmileDimens.spacingMd,
                right: SmileDimens.spacingMd,
                top: SmileDimens.spacingSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  UseSmileIDSampleSectionHeader(text: section.label),
                  const SizedBox(height: SmileDimens.spacingXs),
                  _Grid(section: section, onProductTap: onProductTap),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The page title, the avatar button and the subtitle.
///
/// The environment chip is deliberately absent — node 5447:1705 keeps it hidden, because the
/// environment is a property of the session token and the result card is what publishes it.
class _Header extends StatelessWidget {
  const _Header({
    required this.state,
    required this.onProfileTap,
    required this.colors,
  });

  final UseSmileIDSampleProductsState state;
  final VoidCallback onProfileTap;
  final UseSmileIDSampleColors colors;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: SmileDimens.spacingMd),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Smile ID',
                style: UseSmileIDSampleType.textStyleHeadingPage.copyWith(
                  fontSize: smileHeadingPageSize,
                  height: smileHeadingPageLineHeight / smileHeadingPageSize,
                  letterSpacing: smileHeadingPageTracking,
                  fontWeight:
                      FontWeight.values[smileHeadingPageWeight ~/ 100 - 1],
                  color: colors.foreground,
                ),
              ),
            ),
            const SizedBox(width: SmileDimens.spacingXs),
            Semantics(
              identifier: UseSmileIDSampleTestIds.profileAvatarButton,
              button: true,
              label: 'Switch profile',
              child: InkResponse(
                onTap: onProfileTap,
                radius: SmileDimens.sizeControlMd / 2,
                child: UseSmileIDSampleAvatar(
                  initials: state.initials,
                  containerColor: state.avatarColor ?? smileProfileHues.first,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: SmileDimens.spacingXxs),
        Text(
          'Try our suite of products powered by our Anti-Fraud SDKs',
          style: UseSmileIDSampleType.textStyleCaption.copyWith(
            color: colors.foreground,
          ),
        ),
      ],
    ),
  );
}

class _Grid extends StatelessWidget {
  const _Grid({required this.section, required this.onProductTap});

  final UseSmileIDSampleProductSection section;
  final void Function(UseSmileIDSampleProduct product) onProductTap;

  @override
  Widget build(BuildContext context) {
    final List<UseSmileIDSampleProduct> products = UseSmileIDSampleProduct.of(
      section,
    );
    return UseSmileIDSampleProductGrid(
      itemCount: products.length,
      itemBuilder: (BuildContext context, int index) {
        final UseSmileIDSampleProduct product = products[index];
        final String asset = productIcon(product);
        return UseSmileIDSampleProductCard(
          title: product.cardTitle,
          family: product.cardFamily,
          hue: productHue(product),
          onTap: () => onProductTap(product),
          testId: UseSmileIDSampleTestIds.productCard(product.id),
          icon: (Color tint) => UseSmileIDSampleIcon(asset: asset, tint: tint),
          ghost: (Color tint) =>
              UseSmileIDSampleIcon(asset: asset, tint: tint, size: _ghostSize),
        );
      },
    );
  }
}

/// The watermark, read off the board rather than the scale; 69.3 in the design.
const double _ghostSize = SmileDimens.space64 + SmileDimens.space4;
