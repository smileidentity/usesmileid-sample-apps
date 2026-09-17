import 'package:flutter/material.dart';

import '../tokens/smile_tokens.dart';

/// Two columns of product cards, an odd count leaving its last cell empty.
///
/// Rows rather than a lazy grid, because the host screen already scrolls; each row takes its
/// tallest card's height so a two-line title beside a one-line one still yields two equal cards.
class UseSmileIDSampleProductGrid extends StatelessWidget {
  /// The empty cell an odd count leaves is a layout affordance, not a placeholder card.
  const UseSmileIDSampleProductGrid({
    required this.itemCount,
    required this.itemBuilder,
    super.key,
  });

  /// How many cards the section holds.
  final int itemCount;

  /// Builds the card at an index.
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (
        int rowStart = 0;
        rowStart < itemCount;
        rowStart += _columns
      ) ...<Widget>[
        if (rowStart > 0) const SizedBox(height: SmileDimens.spacingSm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int column = 0; column < _columns; column++) ...<Widget>[
                if (column > 0) const SizedBox(width: SmileDimens.spacingSm),
                Expanded(
                  child: rowStart + column < itemCount
                      ? itemBuilder(context, rowStart + column)
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      ],
    ],
  );
}

/// The design's 2-up grid.
const int _columns = 2;
