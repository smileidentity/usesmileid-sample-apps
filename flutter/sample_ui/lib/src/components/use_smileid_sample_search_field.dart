import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';

/// The sheet search field. The glyph is the platform's own mark: `design/icons/` carries no search
/// asset, and hand-drawing one would port the Compose workaround instead of the design.
class UseSmileIDSampleSearchField extends StatefulWidget {
  /// Takes the query rather than owning it, so the sheet's filter and the field cannot disagree.
  const UseSmileIDSampleSearchField({
    required this.query,
    required this.onQueryChanged,
    this.placeholder = '',
    this.testId,
    super.key,
  });

  /// The current query.
  final String query;

  /// Called on every edit.
  final ValueChanged<String> onQueryChanged;

  /// Shown while the query is empty.
  final String placeholder;

  /// The `sample_*` id the sheet supplies.
  final String? testId;

  @override
  State<UseSmileIDSampleSearchField> createState() =>
      _UseSmileIDSampleSearchFieldState();
}

class _UseSmileIDSampleSearchFieldState
    extends State<UseSmileIDSampleSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.query,
  );
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocusChanged);
  bool _focused = false;

  @override
  void didUpdateWidget(UseSmileIDSampleSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Against the old widget, not the live text: a parent that rebuilds without changing the
    // value would otherwise collapse the selection to the end while the field is being edited.
    if (widget.query != oldWidget.query && widget.query != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
        composing: TextRange.empty,
      );
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() => _focused = _focusNode.hasFocus);

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: SmileDimens.sizeControlMd),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.search.background,
          borderRadius: UseSmileIDSampleShapes.field,
          border: Border.all(
            color: _focused ? colors.search.borderFocus : colors.search.border,
            width: _focused
                ? SmileDimens.borderWidthThin
                : SmileDimens.borderWidthHairline,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SmileDimens.spacingMd,
            vertical: SmileDimens.spacingSm,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.search,
                size: SmileDimens.sizeIconMd,
                color: colors.search.icon,
              ),
              const SizedBox(width: SmileDimens.spacingXs),
              Expanded(
                child: Semantics(
                  identifier: widget.testId,
                  textField: true,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: widget.onQueryChanged,
                    maxLines: 1,
                    cursorColor: colors.search.borderFocus,
                    style: UseSmileIDSampleType.searchFont.copyWith(
                      color: colors.search.text,
                    ),
                    decoration: InputDecoration.collapsed(
                      hintText: widget.placeholder,
                      hintStyle: UseSmileIDSampleType.searchFont.copyWith(
                        color: colors.search.placeholder,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
