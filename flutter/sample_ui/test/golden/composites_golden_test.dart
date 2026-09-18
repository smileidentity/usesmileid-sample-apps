import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'golden_harness.dart';

/// Every state of the shared composites, light and dark, at the shared 393-unit width.
void main() {
  setUpAll(loadSampleFonts);

  testWidgets('icons', (WidgetTester tester) async {
    await goldens(tester, 'icons', _icons);
  });

  testWidgets('top app bar', (WidgetTester tester) async {
    await goldens(tester, 'top_app_bar', _topAppBars);
  });

  testWidgets('top app bars survive max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(tester, _topAppBars());
  });

  testWidgets('data field row', (WidgetTester tester) async {
    await goldens(tester, 'data_field_row', _dataFieldRows);
  });

  testWidgets('data field rows survive max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(
      tester,
      _dataFieldRows(),
      // A 36-character job id fits no value column at 2x, so where it breaks is not a layout call.
      knownOpenWords: const <String>{'7d2f01aa-4c1e'},
    );
  });

  testWidgets('key value edit row', (WidgetTester tester) async {
    await goldens(tester, 'key_value_edit_row', _keyValueEditRows);
  });

  testWidgets('key value edit rows survive max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(tester, _keyValueEditRows());
  });

  testWidgets('setting row', (WidgetTester tester) async {
    await goldens(tester, 'setting_row', _settingRows);
  });

  testWidgets('setting rows survive max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(tester, _settingRows());
  });

  testWidgets('profile row', (WidgetTester tester) async {
    await goldens(tester, 'profile_row', _profileRows);
  });

  testWidgets('profile rows survive max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(tester, _profileRows());
  });

  testWidgets('option row', (WidgetTester tester) async {
    await goldens(tester, 'option_row', _optionRows);
  });

  testWidgets('option rows survive max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(tester, _optionRows());
  });

  testWidgets('select trigger', (WidgetTester tester) async {
    await goldens(tester, 'select_trigger', _selectTriggers);
  });

  testWidgets('select triggers survive max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(tester, _selectTriggers());
  });

  testWidgets('filter chip', (WidgetTester tester) async {
    await goldens(tester, 'filter_chip', _filterChips);
  });

  testWidgets('filter chips survive max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(tester, _filterChips());
  });

  testWidgets('date group header', (WidgetTester tester) async {
    await goldens(tester, 'date_group_header', _dateGroupHeaders);
  });

  testWidgets('job row', (WidgetTester tester) async {
    await goldens(tester, 'job_row', _jobRows);
  });

  testWidgets('job rows survive max text scale', (WidgetTester tester) async {
    await assertSurvivesMaxTextScale(tester, _jobRows());
  });

  testWidgets('selection checkbox', (WidgetTester tester) async {
    await goldens(tester, 'selection_checkbox', _selectionCheckboxes);
  });

  testWidgets('selection bar', (WidgetTester tester) async {
    await goldens(tester, 'selection_bar', _selectionBars);
  });

  testWidgets('selection bars survive max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(tester, _selectionBars());
  });

  testWidgets('empty state', (WidgetTester tester) async {
    await goldens(tester, 'empty_state', _emptyStates);
  });

  testWidgets('empty states survive max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(tester, _emptyStates());
  });

  testWidgets('sheet chrome', (WidgetTester tester) async {
    await goldens(tester, 'sheet_chrome', _sheetChrome);
  });
}

Widget _stack(List<Widget> children, {double gap = SmileDimens.spacingXs}) =>
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int index = 0; index < children.length; index++) ...<Widget>[
          if (index > 0) SizedBox(height: gap),
          children[index],
        ],
      ],
    );

/// Every mark in the shared record, so a re-export that changes one is visible rather than implied.
Widget _icons() => Builder(
  builder: (BuildContext context) => Wrap(
    spacing: SmileDimens.spacingSm,
    runSpacing: SmileDimens.spacingSm,
    children: <Widget>[
      for (final String asset in SmileIcons.all)
        UseSmileIDSampleIcon(
          asset: asset,
          tint: UseSmileIDSampleTheme.colorsOf(context).textTitle,
        ),
    ],
  ),
);

/// All four variants, so the reserved trailing slot is visible where there is no action.
Widget _topAppBars() => Builder(
  builder: (BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return _stack(<Widget>[
      UseSmileIDSampleTopAppBar(title: 'Scan token', onBack: () {}),
      UseSmileIDSampleTopAppBar(
        title: 'Enhanced Document Verification',
        onBack: () {},
        action: UseSmileIDSampleTopAppBarButton(
          semanticLabel: 'Delete',
          onTap: () {},
          emphasis: UseSmileIDSampleTopAppBarEmphasis.destructive,
          glyph: UseSmileIDSampleGlyphs.trash,
        ),
      ),
      UseSmileIDSampleTopAppBar(
        title: 'Scan token',
        onBack: () {},
        action: UseSmileIDSampleTopAppBarButton(
          semanticLabel: 'Torch',
          onTap: () {},
          emphasis: UseSmileIDSampleTopAppBarEmphasis.filled,
          glyph: UseSmileIDSampleGlyphs.flash,
        ),
      ),
      ColoredBox(
        color: colors.surface,
        child: UseSmileIDSampleTopAppBar(
          title: 'Your details',
          onBack: () {},
          action: UseSmileIDSampleTopAppBarButton(
            semanticLabel: 'Copy',
            onTap: () {},
            glyph: UseSmileIDSampleGlyphs.copy,
          ),
        ),
      ),
    ]);
  },
);

/// The plain, copy and coloured-value variants, plus a value long enough to wrap.
Widget _dataFieldRows() => Builder(
  builder: (BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return ColoredBox(
      color: colors.surface,
      child: _stack(<Widget>[
        const UseSmileIDSampleDataFieldRow(
          label: 'Product',
          value: 'Biometric KYC',
        ),
        UseSmileIDSampleDataFieldRow(
          label: 'Job_id',
          value: '7d2f01aa-4c1e-4b0a-9f2c-1e7b9a3d8c55',
          onCopy: () {},
        ),
        UseSmileIDSampleDataFieldRow(
          label: 'Status',
          value: '202 Accepted',
          valueColor: colors.badge.infoText,
        ),
      ], gap: 0),
    );
  },
);

Widget _keyValueEditRows() => Builder(
  builder: (BuildContext context) => ColoredBox(
    color: UseSmileIDSampleTheme.colorsOf(context).surface,
    child: _stack(<Widget>[
      UseSmileIDSampleKeyValueEditRow(
        label: 'First name',
        value: '',
        onChanged: _ignore,
        placeholder: 'Enter first name',
        required: true,
      ),
      UseSmileIDSampleKeyValueEditRow(
        label: 'Last name',
        value: 'Okonkwo',
        onChanged: _ignore,
      ),
      UseSmileIDSampleKeyValueEditRow(
        label: 'Email',
        value: 'ada@kobobank.example',
        onChanged: _ignore,
        enabled: false,
      ),
    ], gap: 0),
  ),
);

/// The three variants plus the rule between rows, which is the element dark mode got wrong.
Widget _settingRows() => Builder(
  builder: (BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return _stack(<Widget>[
      DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: UseSmileIDSampleShapes.card,
          border: Border.all(
            color: colors.cardStroke,
            width: smileCardStrokeWidth,
          ),
        ),
        child: Column(
          children: <Widget>[
            UseSmileIDSampleSettingRow(
              title: 'Enhanced SmartSelfie™',
              supportingText: 'Face capture uses head-turns',
              leading: (Color tint) =>
                  UseSmileIDSampleIcon(asset: SmileIcons.smile, tint: tint),
              trailing: UseSmileIDSampleSwitch(
                value: true,
                onChanged: _ignoreBool,
              ),
            ),
            const UseSmileIDSampleSettingRowDivider(),
            UseSmileIDSampleSettingRow(
              title: 'Agent mode',
              supportingText: 'Operator captures for the applicant',
              leading: (Color tint) =>
                  UseSmileIDSampleIcon(asset: SmileIcons.agent, tint: tint),
              trailing: UseSmileIDSampleSwitch(
                value: false,
                onChanged: _ignoreBool,
              ),
            ),
            const UseSmileIDSampleSettingRowDivider(),
            UseSmileIDSampleSettingRow(
              title: 'Documentation',
              onTap: () {},
              leading: (Color tint) =>
                  UseSmileIDSampleIcon(asset: SmileIcons.docs, tint: tint),
              trailing: const UseSmileIDSampleSettingRowChevron(),
            ),
          ],
        ),
      ),
      UseSmileIDSampleDestructiveRow(text: 'Sign out', onTap: () {}),
    ]);
  },
);

Widget _profileRows() => _stack(<Widget>[
  UseSmileIDSampleProfileRow(
    organisation: 'Kobo Bank',
    supportingText: 'Ada Okonkwo',
    initials: 'KB',
    selected: true,
    onTap: () {},
    avatarColor: avatarColorForProfile(0),
  ),
  UseSmileIDSampleProfileRow(
    organisation: 'Zanzibar Microfinance',
    supportingText: 'Tap to configure',
    initials: 'ZM',
    selected: false,
    onTap: () {},
    avatarColor: avatarColorForProfile(1),
  ),
  Builder(
    builder: (BuildContext context) => UseSmileIDSampleProfileRow(
      organisation: 'Add a profile',
      supportingText: 'A new organisation and person',
      initials: '',
      selected: false,
      onTap: () {},
      trailing: UseSmileIDSampleGlyphs.plus(
        UseSmileIDSampleTheme.colorsOf(context).primary,
      ),
    ),
  ),
]);

/// Kenya's ID types, the same fixture the other platforms draw, so the pair can be read.
Widget _optionRows() => _stack(<Widget>[
  UseSmileIDSampleOptionRow(
    label: 'Kenya',
    selected: true,
    onTap: () {},
    leadingText: '🇰🇪',
  ),
  UseSmileIDSampleOptionRow(
    label: 'Ghana',
    selected: false,
    onTap: () {},
    leadingText: '🇬🇭',
  ),
  UseSmileIDSampleOptionRow(
    label: 'National ID',
    selected: false,
    onTap: () {},
  ),
], gap: SmileDimens.spacingXxs);

Widget _selectTriggers() => _stack(<Widget>[
  UseSmileIDSampleSelectTrigger(
    value: null,
    placeholder: 'Select country',
    onTap: () {},
    leading: (Color tint) => const UseSmileIDSampleTriggerEmoji(emoji: '🌍'),
  ),
  UseSmileIDSampleSelectTrigger(
    value: 'Kenya',
    placeholder: 'Select country',
    onTap: () {},
    leading: (Color tint) => const UseSmileIDSampleTriggerEmoji(emoji: '🇰🇪'),
  ),
  UseSmileIDSampleSelectTrigger(
    value: null,
    placeholder: 'Select ID type',
    onTap: () {},
    enabled: false,
  ),
]);

Widget _filterChips() => Wrap(
  spacing: SmileDimens.spacingXs,
  runSpacing: SmileDimens.spacingXs,
  children: <Widget>[
    UseSmileIDSampleFilterChip(
      label: 'All',
      count: 11,
      selected: true,
      onTap: () {},
    ),
    UseSmileIDSampleFilterChip(
      label: 'Clear',
      count: 6,
      selected: false,
      onTap: () {},
    ),
    UseSmileIDSampleFilterChip(
      label: 'Attention',
      count: 2,
      selected: false,
      onTap: () {},
    ),
    UseSmileIDSampleFilterChip(
      label: 'Blocked',
      count: 2,
      selected: false,
      onTap: () {},
    ),
  ],
);

/// Both shapes, including the day with no relative word, which renders its date alone.
Widget _dateGroupHeaders() => _stack(const <Widget>[
  UseSmileIDSampleDateGroupHeader(
    relative: 'TODAY',
    absolute: 'THU, 16 JUL 2026',
  ),
  UseSmileIDSampleDateGroupHeader(
    relative: 'YESTERDAY',
    absolute: 'WED, 15 JUL 2026',
  ),
  UseSmileIDSampleDateGroupHeader(relative: '', absolute: 'TUE, 14 JUL 2026'),
]);

/// One row per product, so every tile hue and every mark is in one picture.
Widget _jobRows() => _stack(<Widget>[
  for (final UseSmileIDSampleProduct product in UseSmileIDSampleProduct.values)
    UseSmileIDSampleJobRow(
      product: product,
      jobId: '7d2f01aa…',
      time: '13:03:41',
      status:
          UseSmileIDSampleStatus.values[UseSmileIDSampleProduct.values.indexOf(
                product,
              ) %
              UseSmileIDSampleStatus.values.length],
      onTap: () {},
    ),
]);

Widget _selectionCheckboxes() => Row(
  children: <Widget>[
    UseSmileIDSampleSelectionCheckbox(checked: true, onChanged: _ignoreBool),
    const SizedBox(width: SmileDimens.spacingXs),
    UseSmileIDSampleSelectionCheckbox(checked: false, onChanged: _ignoreBool),
  ],
);

/// Both states: the disabled action is dimmed, not recoloured.
Widget _selectionBars() => _stack(<Widget>[
  UseSmileIDSampleSelectionBar(selectedCount: 0, onRemove: () {}),
  UseSmileIDSampleSelectionBar(selectedCount: 3, onRemove: () {}),
]);

Widget _emptyStates() => _stack(const <Widget>[
  UseSmileIDSampleEmptyState(text: 'No verifications yet'),
  UseSmileIDSampleEmptyState(
    text: 'No verifications yet',
    supportingText: 'Start a product from the Products tab to see it here.',
  ),
]);

/// The sheet's own chrome, drawn in place: a modal route cannot be captured by a widget golden.
Widget _sheetChrome() => Builder(
  builder: (BuildContext context) => ColoredBox(
    color: UseSmileIDSampleTheme.colorsOf(context).surface,
    child: UseSmileIDSampleSheetHeader(title: 'Select country', onClose: () {}),
  ),
);

void _ignore(String value) {}

void _ignoreBool(bool value) {}
