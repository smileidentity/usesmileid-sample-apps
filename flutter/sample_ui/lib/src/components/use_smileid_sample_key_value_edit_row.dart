import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';

/// A label and a value that edits in place with a caret, rather than pushing a form.
///
/// The field NAME is title-coloured and only the PLACEHOLDER is muted; Android had that inverted.
class UseSmileIDSampleKeyValueEditRow extends StatefulWidget {
  /// [required] appends an asterisk to the label, which is how the design marks a required field.
  const UseSmileIDSampleKeyValueEditRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.placeholder = '',
    this.required = false,
    this.enabled = true,
    this.keyboardType,
    this.testId,
    super.key,
  });

  /// The field name.
  final String label;

  /// The current value.
  final String value;

  /// Called on every edit.
  final ValueChanged<String> onChanged;

  /// Shown while the value is empty, and the only muted run in the row.
  final String placeholder;

  /// Whether the field is required.
  final bool required;

  /// Whether the row accepts input.
  final bool enabled;

  /// The keyboard to raise.
  final TextInputType? keyboardType;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  @override
  State<UseSmileIDSampleKeyValueEditRow> createState() =>
      _UseSmileIDSampleKeyValueEditRowState();
}

class _UseSmileIDSampleKeyValueEditRowState
    extends State<UseSmileIDSampleKeyValueEditRow> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(UseSmileIDSampleKeyValueEditRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
        composing: TextRange.empty,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final TextStyle rowStyle = UseSmileIDSampleType.textStyleSubtitle.copyWith(
      fontSize: _rowTextSize,
    );
    return ColoredBox(
      color: colors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: SmileDimens.sizeControlMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _rowPaddingX,
            vertical: _rowPaddingY,
          ),
          // The value sits at the right edge and drops below the label at 2x, matching DataFieldRow.
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: SmileDimens.spacingXxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                widget.required ? '${widget.label} *' : widget.label,
                style: rowStyle.copyWith(color: colors.textTitle),
              ),
              Semantics(
                identifier: widget.testId,
                textField: true,
                child: IntrinsicWidth(
                  child: TextField(
                    controller: _controller,
                    enabled: widget.enabled,
                    onChanged: widget.onChanged,
                    keyboardType: widget.keyboardType,
                    maxLines: 1,
                    textAlign: TextAlign.end,
                    cursorColor: colors.primary,
                    // Muted when disabled, so a row that cannot be edited does not look editable.
                    style: rowStyle.copyWith(
                      color: widget.enabled
                          ? colors.textTitle
                          : colors.textMuted,
                    ),
                    decoration: InputDecoration.collapsed(
                      hintText: widget.placeholder,
                      hintStyle: rowStyle.copyWith(color: colors.textMuted),
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

/// Label, value and placeholder alike — NOT text-style.body, which is weight 400.
const double _rowTextSize = 13.5;

/// The design's own padding; no scale token carries 15 or 14.
const double _rowPaddingX = 15;
const double _rowPaddingY = 14;
