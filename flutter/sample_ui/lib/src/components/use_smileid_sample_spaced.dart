import 'package:flutter/widgets.dart';

import '../tokens/smile_tokens.dart';

/// [items] with one [gap] between every pair, which is what a spaced Compose column puts there.
List<Widget> useSmileIDSampleSpaced(
  List<Widget> items, {
  double gap = SmileDimens.spacingXs,
}) => <Widget>[
  for (int index = 0; index < items.length; index++) ...<Widget>[
    if (index > 0) SizedBox(height: gap),
    items[index],
  ],
];
