import 'package:flutter/material.dart';

import '../components/use_smileid_sample_empty_state.dart';
import '../components/use_smileid_sample_option_row.dart';
import '../components/use_smileid_sample_search_field.dart';
import '../components/use_smileid_sample_skeleton.dart';
import '../state/use_smileid_sample_catalogue.dart';
import '../state/use_smileid_sample_id_details.dart';
import '../use_smileid_sample_strings_scope.dart';
import '../use_smileid_sample_test_ids.dart';

/// Picks a country, filtering on the NAME and never the ISO code.
class UseSmileIDSampleCountryPickerSheet extends StatelessWidget {
  /// [onSelect] both chooses and dismisses; there is no confirm.
  const UseSmileIDSampleCountryPickerSheet({
    required this.catalogue,
    required this.selected,
    required this.onSelect,
    required this.onRetry,
    super.key,
  });

  /// The list, which may still be arriving.
  final UseSmileIDSampleCatalogue<UseSmileIDSampleCountry> catalogue;

  /// The country already chosen, if any.
  final UseSmileIDSampleCountry? selected;

  /// Chooses one.
  final ValueChanged<UseSmileIDSampleCountry> onSelect;

  /// Asks again after a failure.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) =>
      UseSmileIDSampleCataloguePicker<UseSmileIDSampleCountry>(
        catalogue: catalogue,
        loadingLabel: context.strings.pickerCountryLoading,
        failedLabel: context.strings.pickerCountryLoadFailed,
        searchPlaceholder: context.strings.pickerCountrySearch,
        searchTestId: UseSmileIDSampleTestIds.countrySearch,
        label: (UseSmileIDSampleCountry it) => it.name,
        emptyTestId: UseSmileIDSampleTestIds.countryEmpty,
        emptyLabel: (String query) =>
            context.strings.pickerCountryNoMatch(query: query),
        nothingToList: (
          context.strings.pickerCountryEmpty,
          context.strings.pickerCountryEmptyHint,
        ),
        onRetry: onRetry,
        leadingCircle: true,
        row: (UseSmileIDSampleCountry country) => UseSmileIDSampleOptionRow(
          label: country.name,
          leadingText: country.flag,
          selected: country.code == selected?.code,
          onTap: () => onSelect(country),
          testId: UseSmileIDSampleTestIds.countryOption(country.code),
        ),
      );
}

/// Picks an ID type from the ones the chosen country offers.
class UseSmileIDSampleIdTypePickerSheet extends StatelessWidget {
  /// [onSelect] both chooses and dismisses.
  const UseSmileIDSampleIdTypePickerSheet({
    required this.country,
    required this.catalogue,
    required this.selected,
    required this.onSelect,
    required this.onRetry,
    super.key,
  });

  /// The chosen country, which names the empty state.
  final UseSmileIDSampleCountry? country;

  /// The list, which may still be arriving.
  final UseSmileIDSampleCatalogue<UseSmileIDSampleKycIdType> catalogue;

  /// The type already chosen, if any.
  final UseSmileIDSampleKycIdType? selected;

  /// Chooses one.
  final ValueChanged<UseSmileIDSampleKycIdType> onSelect;

  /// Asks again after a failure.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) =>
      UseSmileIDSampleCataloguePicker<UseSmileIDSampleKycIdType>(
        catalogue: catalogue,
        loadingLabel: context.strings.pickerIdTypeLoading,
        failedLabel: context.strings.pickerIdTypeLoadFailed,
        searchPlaceholder: context.strings.pickerIdTypeSearch,
        searchTestId: UseSmileIDSampleTestIds.idTypeSearch,
        label: (UseSmileIDSampleKycIdType it) => it.label,
        emptyTestId: UseSmileIDSampleTestIds.idTypeEmpty,
        emptyLabel: (String query) =>
            context.strings.pickerIdTypeNoMatch(query: query),
        nothingToList: (
          context.strings.pickerIdTypeEmpty(
            country: country?.name ?? context.strings.pickerThisCountry,
          ),
          context.strings.pickerChooseAnotherCountry,
        ),
        onRetry: onRetry,
        row: (UseSmileIDSampleKycIdType type) => UseSmileIDSampleOptionRow(
          label: type.label,
          selected: type.id == selected?.id,
          onTap: () => onSelect(type),
          testId: UseSmileIDSampleTestIds.idTypeOption(type.id),
        ),
      );
}

/// The document products' picker: the country's supported documents, a standalone sub-type as its own row.
class UseSmileIDSampleDocumentPickerSheet extends StatelessWidget {
  /// [onSelect] both chooses and dismisses.
  const UseSmileIDSampleDocumentPickerSheet({
    required this.country,
    required this.catalogue,
    required this.selected,
    required this.onSelect,
    required this.onRetry,
    super.key,
  });

  /// The chosen country, which names the empty state.
  final UseSmileIDSampleCountry? country;

  /// The list, which may still be arriving.
  final UseSmileIDSampleCatalogue<UseSmileIDSampleDocument> catalogue;

  /// The document already chosen, if any.
  final UseSmileIDSampleDocument? selected;

  /// Chooses one.
  final ValueChanged<UseSmileIDSampleDocument> onSelect;

  /// Asks again after a failure.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) =>
      UseSmileIDSampleCataloguePicker<UseSmileIDSampleDocument>(
        catalogue: catalogue,
        loadingLabel: context.strings.pickerDocumentLoading,
        failedLabel: context.strings.pickerDocumentLoadFailed,
        searchPlaceholder: context.strings.pickerDocumentSearch,
        searchTestId: UseSmileIDSampleTestIds.documentSearch,
        label: (UseSmileIDSampleDocument it) => it.name,
        emptyTestId: UseSmileIDSampleTestIds.documentEmpty,
        emptyLabel: (String query) =>
            context.strings.pickerDocumentNoMatch(query: query),
        nothingToList: (
          context.strings.pickerDocumentEmpty(
            country: country?.name ?? context.strings.pickerThisCountry,
          ),
          context.strings.pickerChooseAnotherCountry,
        ),
        onRetry: onRetry,
        row: (UseSmileIDSampleDocument document) => UseSmileIDSampleOptionRow(
          label: document.name,
          selected: document.id == selected?.id,
          onTap: () => onSelect(document),
          testId: UseSmileIDSampleTestIds.documentOption(document.id),
        ),
      );
}

/// One picker's body: skeleton rows while loading, an error with Retry, an empty state without one, and a search.
class UseSmileIDSampleCataloguePicker<T> extends StatefulWidget {
  /// Every string the picker says, so the three sheets share one behaviour.
  const UseSmileIDSampleCataloguePicker({
    required this.catalogue,
    required this.loadingLabel,
    required this.failedLabel,
    required this.searchPlaceholder,
    required this.searchTestId,
    required this.label,
    required this.emptyTestId,
    required this.emptyLabel,
    required this.nothingToList,
    required this.onRetry,
    required this.row,
    this.leadingCircle = false,
    super.key,
  });

  /// The list, which may still be arriving.
  final UseSmileIDSampleCatalogue<T> catalogue;

  /// What the skeleton announces while the list loads.
  final String loadingLabel;

  /// What the error state says when the list did not load.
  final String failedLabel;

  /// The search field's placeholder.
  final String searchPlaceholder;

  /// The search field's id.
  final String searchTestId;

  /// The text a row is searched on.
  final String Function(T) label;

  /// The empty state's id.
  final String emptyTestId;

  /// What a search that matched nothing says.
  final String Function(String query) emptyLabel;

  /// What an empty list says, and what to do about it.
  final (String, String) nothingToList;

  /// Asks again after a failure.
  final VoidCallback onRetry;

  /// One row.
  final Widget Function(T) row;

  /// Whether the skeleton leads each row with a flag-sized circle.
  final bool leadingCircle;

  @override
  State<UseSmileIDSampleCataloguePicker<T>> createState() =>
      _UseSmileIDSampleCataloguePickerState<T>();
}

class _UseSmileIDSampleCataloguePickerState<T>
    extends State<UseSmileIDSampleCataloguePicker<T>> {
  final UseSmileIDSampleSkeletonGate _gate = UseSmileIDSampleSkeletonGate();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _gate.addListener(_rebuild);
    _gate.loading(widget.catalogue.isLoading);
  }

  @override
  void didUpdateWidget(UseSmileIDSampleCataloguePicker<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.catalogue.isLoading != widget.catalogue.isLoading) {
      _gate.loading(widget.catalogue.isLoading);
    }
  }

  @override
  void dispose() {
    _gate
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleCatalogue<T> catalogue = widget.catalogue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        UseSmileIDSampleSearchField(
          query: _query,
          onQueryChanged: (String value) => setState(() => _query = value),
          placeholder: widget.searchPlaceholder,
          testId: widget.searchTestId,
          enabled:
              catalogue is UseSmileIDSampleCatalogueReady<T> && !_gate.visible,
        ),
        if (_gate.visible)
          UseSmileIDSampleSkeletonRows(
            announcement: widget.loadingLabel,
            leadingCircle: widget.leadingCircle,
            testId: UseSmileIDSampleTestIds.catalogueLoading,
          )
        else
          ..._content(catalogue),
      ],
    );
  }

  List<Widget> _content(UseSmileIDSampleCatalogue<T> catalogue) {
    switch (catalogue) {
      // The first 300 ms draw nothing, so a fast answer never flashes a skeleton.
      case UseSmileIDSampleCatalogueLoading<T>():
        return const <Widget>[];
      case UseSmileIDSampleCatalogueFailed<T>(
        :final UseSmileIDSampleCatalogueAdvice advice,
      ):
        return <Widget>[
          UseSmileIDSampleEmptyState(
            text: widget.failedLabel,
            supportingText: advice.message(context.strings),
            testId: UseSmileIDSampleTestIds.catalogueError,
            onRetry: widget.onRetry,
            retryTestId: UseSmileIDSampleTestIds.catalogueRetry,
          ),
        ];
      case UseSmileIDSampleCatalogueEmpty<T>():
        return <Widget>[
          UseSmileIDSampleEmptyState(
            text: widget.nothingToList.$1,
            supportingText: widget.nothingToList.$2,
            testId: widget.emptyTestId,
          ),
        ];
      case UseSmileIDSampleCatalogueReady<T>(:final List<T> items):
        final String needle = _query.trim().toLowerCase();
        final List<T> shown = items
            .where((T it) => widget.label(it).toLowerCase().contains(needle))
            .toList();
        if (shown.isEmpty) {
          return <Widget>[
            UseSmileIDSampleEmptyState(
              text: widget.emptyLabel(_query),
              testId: widget.emptyTestId,
            ),
          ];
        }
        return <Widget>[for (final T item in shown) widget.row(item)];
    }
  }
}
