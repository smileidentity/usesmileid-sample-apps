import 'package:flutter/material.dart';

import '../components/use_smileid_sample_empty_state.dart';
import '../components/use_smileid_sample_option_row.dart';
import '../components/use_smileid_sample_search_field.dart';
import '../state/use_smileid_sample_id_details.dart';
import '../use_smileid_sample_test_ids.dart';

/// Picks a country, filtering on the NAME and never the ISO code.
///
/// The query is this sheet's own and resets on every open: a stale filter would hide the option a
/// reader came back for.
class UseSmileIDSampleCountryPickerSheet extends StatefulWidget {
  /// [onSelect] both chooses and dismisses; there is no confirm.
  const UseSmileIDSampleCountryPickerSheet({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  /// The country already chosen, if any.
  final UseSmileIDSampleCountry? selected;

  /// Chooses one.
  final ValueChanged<UseSmileIDSampleCountry> onSelect;

  @override
  State<UseSmileIDSampleCountryPickerSheet> createState() =>
      _UseSmileIDSampleCountryPickerSheetState();
}

class _UseSmileIDSampleCountryPickerSheetState
    extends State<UseSmileIDSampleCountryPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final List<UseSmileIDSampleCountry> shown = UseSmileIDSampleCountry.values
        .where(
          (UseSmileIDSampleCountry country) =>
              country.label.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        UseSmileIDSampleSearchField(
          query: _query,
          onQueryChanged: (String value) => setState(() => _query = value),
          placeholder: 'Search country',
          testId: UseSmileIDSampleTestIds.countrySearch,
        ),
        if (shown.isEmpty)
          UseSmileIDSampleEmptyState(
            text: 'No country matches “$_query”',
            testId: UseSmileIDSampleTestIds.countryEmpty,
          )
        else
          for (final UseSmileIDSampleCountry country in shown)
            UseSmileIDSampleOptionRow(
              label: country.label,
              leadingText: country.flag,
              selected: country == widget.selected,
              onTap: () => widget.onSelect(country),
              testId: UseSmileIDSampleTestIds.countryOption(country.code),
            ),
      ],
    );
  }
}

/// Picks an ID type from the ones the chosen country issues.
class UseSmileIDSampleIdTypePickerSheet extends StatefulWidget {
  /// A null [country] leaves the list empty, which is a state a deep link can reach.
  const UseSmileIDSampleIdTypePickerSheet({
    required this.country,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  /// The chosen country, which decides the list.
  final UseSmileIDSampleCountry? country;

  /// The type already chosen, if any.
  final UseSmileIDSampleIdType? selected;

  /// Chooses one.
  final ValueChanged<UseSmileIDSampleIdType> onSelect;

  @override
  State<UseSmileIDSampleIdTypePickerSheet> createState() =>
      _UseSmileIDSampleIdTypePickerSheetState();
}

class _UseSmileIDSampleIdTypePickerSheetState
    extends State<UseSmileIDSampleIdTypePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final List<UseSmileIDSampleIdType> shown =
        UseSmileIDSampleIdType.of(widget.country)
            .where(
              (UseSmileIDSampleIdType type) =>
                  type.label.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        UseSmileIDSampleSearchField(
          query: _query,
          onQueryChanged: (String value) => setState(() => _query = value),
          placeholder: 'Search ID type',
          testId: UseSmileIDSampleTestIds.idTypeSearch,
        ),
        if (shown.isEmpty)
          UseSmileIDSampleEmptyState(
            // Two reasons for an empty list, and they call for different words: no country chosen
            // at all, or a query that matched none of the ones this country issues.
            text: _query.trim().isEmpty
                ? 'No ID type for this country'
                : 'No ID type matches “$_query”',
            testId: UseSmileIDSampleTestIds.idTypeEmpty,
          )
        else
          for (final UseSmileIDSampleIdType type in shown)
            UseSmileIDSampleOptionRow(
              label: type.label,
              selected: type == widget.selected,
              onTap: () => widget.onSelect(type),
              testId: UseSmileIDSampleTestIds.idTypeOption(type.id),
            ),
      ],
    );
  }
}
