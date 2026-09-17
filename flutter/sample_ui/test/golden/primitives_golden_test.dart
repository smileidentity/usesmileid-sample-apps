import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'golden_harness.dart';

/// Every state of the eight primitives, light and dark, at the shared 393-unit width.
void main() {
  setUpAll(loadSampleFonts);

  testWidgets('avatars', (WidgetTester tester) async {
    await goldens(tester, 'avatars', _avatars);
  });

  testWidgets('avatars survive max text scale', (WidgetTester tester) async {
    await assertSurvivesMaxTextScale(tester, _avatars());
  });

  testWidgets('button states', (WidgetTester tester) async {
    await goldens(tester, 'button_states', _buttons);
  });

  testWidgets('buttons survive max text scale', (WidgetTester tester) async {
    await assertSurvivesMaxTextScale(tester, _buttons(loading: true));
  });

  testWidgets('text input states', (WidgetTester tester) async {
    await goldens(tester, 'text_input_states', _textInputs);
  });

  testWidgets('text inputs survive max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(tester, _textInputs());
  });

  testWidgets('search field', (WidgetTester tester) async {
    await goldens(tester, 'search_field', _searchFields);
  });

  testWidgets('search fields survive max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(tester, _searchFields());
  });

  testWidgets('switch states', (WidgetTester tester) async {
    await goldens(tester, 'switch_states', _switches);
  });

  testWidgets('status badges', (WidgetTester tester) async {
    await goldens(tester, 'status_badges', _statusBadges);
  });

  testWidgets('status badges survive max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(tester, _statusBadges());
  });

  testWidgets('section label', (WidgetTester tester) async {
    await goldens(tester, 'section_label', _sectionLabels);
  });

  testWidgets('section labels survive max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(tester, _sectionLabels());
  });

  testWidgets('toast', (WidgetTester tester) async {
    await goldens(tester, 'toast', _toasts);
  });

  testWidgets('toasts survive max text scale', (WidgetTester tester) async {
    await assertSurvivesMaxTextScale(tester, _toasts());
  });
}

Widget _column(List<Widget> children) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    for (int index = 0; index < children.length; index++) ...<Widget>[
      if (index > 0) const SizedBox(height: SmileDimens.spacingXs),
      children[index],
    ],
  ],
);

/// The four profile hues in list order, plus the placeholder and the 44 a profile row passes.
Widget _avatars() => _column(<Widget>[
  Row(
    children: <Widget>[
      for (int index = 0; index < 4; index++) ...<Widget>[
        if (index > 0) const SizedBox(width: SmileDimens.spacingXs),
        UseSmileIDSampleAvatar(
          initials: 'P${index + 1}',
          containerColor: avatarColorForProfile(index),
        ),
      ],
    ],
  ),
  Row(
    children: <Widget>[
      const UseSmileIDSampleAvatar(initials: ''),
      const SizedBox(width: SmileDimens.spacingXs),
      UseSmileIDSampleAvatar(
        initials: 'AB',
        size: SmileDimens.sizeControlMd,
        containerColor: avatarColorForProfile(1),
      ),
    ],
  ),
]);

/// Loading is separated so no baseline pins frame zero of an animation.
Widget _buttons({bool loading = false}) => _column(<Widget>[
  UseSmileIDSampleButton(text: 'Continue', onPressed: () {}),
  UseSmileIDSampleButton(text: 'Continue', onPressed: () {}, enabled: false),
  if (loading)
    UseSmileIDSampleButton(text: 'Continue', onPressed: () {}, loading: true),
  UseSmileIDSampleButton(text: 'SmartSelfie Authentication', onPressed: () {}),
]);

Widget _textInputs() => _column(<Widget>[
  UseSmileIDSampleTextInput(
    value: '',
    onChanged: _ignore,
    placeholder: 'ID number',
  ),
  UseSmileIDSampleTextInput(
    value: '22222222',
    onChanged: _ignore,
    placeholder: 'ID number',
  ),
  UseSmileIDSampleTextInput(
    value: '22',
    onChanged: _ignore,
    isError: true,
    errorMessage: 'Enter a valid ID number',
  ),
  UseSmileIDSampleTextInput(
    value: 'Kobo Bank',
    onChanged: _ignore,
    enabled: false,
    placeholder: 'Organisation',
  ),
  UseSmileIDSampleTextInput(
    value: 'Kobo Bank',
    onChanged: _ignore,
    leading: (Color tint) =>
        Icon(Icons.business, size: SmileDimens.sizeIconSm, color: tint),
  ),
]);

Widget _searchFields() => _column(<Widget>[
  UseSmileIDSampleSearchField(
    query: '',
    onQueryChanged: _ignore,
    placeholder: 'Search country',
  ),
  UseSmileIDSampleSearchField(
    query: 'Kenya',
    onQueryChanged: _ignore,
    placeholder: 'Search country',
  ),
]);

/// Four states in one shot, which is what makes a tint regression visible rather than plausible.
Widget _switches() => _column(<Widget>[
  Row(
    children: <Widget>[
      UseSmileIDSampleSwitch(value: true, onChanged: _ignoreBool),
      const SizedBox(width: SmileDimens.spacingXs),
      UseSmileIDSampleSwitch(value: false, onChanged: _ignoreBool),
    ],
  ),
  Row(
    children: const <Widget>[
      UseSmileIDSampleSwitch(value: true, onChanged: null, enabled: false),
      SizedBox(width: SmileDimens.spacingXs),
      UseSmileIDSampleSwitch(value: false, onChanged: null, enabled: false),
    ],
  ),
]);

Widget _statusBadges() => Wrap(
  spacing: SmileDimens.spacingXs,
  runSpacing: SmileDimens.spacingXs,
  children: <Widget>[
    for (final UseSmileIDSampleStatus status in UseSmileIDSampleStatus.values)
      UseSmileIDSampleStatusBadge(status: status),
  ],
);

Widget _sectionLabels() => _column(const <Widget>[
  UseSmileIDSampleSectionLabel(text: 'AUTHENTICATION'),
  UseSmileIDSampleSectionLabel(text: 'USER DETAILS — ATTACHED TO EVERY JOB'),
]);

/// The long message is the harder case the other platforms take too, so the pair can be read.
Widget _toasts() => _column(<Widget>[
  const UseSmileIDSampleToast(message: 'Kobo Bank created'),
  UseSmileIDSampleToast(
    message: '1 verification hidden from App list',
    actionLabel: 'Undo',
    onAction: () {},
  ),
  UseSmileIDSampleToast(
    message: 'Kobo Bank created',
    actionLabel: 'Make active',
    onAction: () {},
  ),
]);

void _ignore(String value) {}

void _ignoreBool(bool value) {}
