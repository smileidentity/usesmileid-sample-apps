import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';

/// A single-line field on the input tokens, decorated by hand so no Material chrome competes with
/// the design's border, and error outranks focus so tapping back in does not hide the message.
class UseSmileIDSampleTextInput extends StatefulWidget {
  /// [leading] is the glyph slot the new-profile fields use; the KYC form leaves it empty.
  const UseSmileIDSampleTextInput({
    required this.value,
    required this.onChanged,
    this.placeholder = '',
    this.enabled = true,
    this.isError = false,
    this.errorMessage,
    this.keyboardType,
    this.masked = false,
    this.testId,
    this.leading,
    this.trailing,
    super.key,
  });

  /// The current value.
  final String value;

  /// Called on every edit.
  final ValueChanged<String> onChanged;

  /// Shown while the value is empty.
  final String placeholder;

  /// Whether the field accepts input.
  final bool enabled;

  /// Whether the field is in error, which outranks focus.
  final bool isError;

  /// The message drawn below the field while in error.
  final String? errorMessage;

  /// The keyboard to raise.
  final TextInputType? keyboardType;

  /// Masks the value and marks the field a password, keeping a credential out of screenshots and
  /// out of the view hierarchy an automated run dumps on failure.
  final bool masked;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  /// The leading glyph, tinted by the placeholder colour the field passes it.
  final Widget Function(Color tint)? leading;

  /// An action inside the field's border, which is where the design draws the scan sheet's Paste.
  final Widget Function(Color tint)? trailing;

  @override
  State<UseSmileIDSampleTextInput> createState() =>
      _UseSmileIDSampleTextInputState();
}

class _UseSmileIDSampleTextInputState extends State<UseSmileIDSampleTextInput> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocusChanged);
  bool _focused = false;

  @override
  void didUpdateWidget(UseSmileIDSampleTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Against the old widget, not the live text: a parent that rebuilds without changing the
    // value would otherwise collapse the selection to the end while the field is being edited.
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
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
    final Color borderColor = widget.isError
        ? colors.input.borderError
        : _focused
        ? colors.input.borderFocus
        : colors.input.border;
    final double borderWidth = widget.isError || _focused
        ? SmileDimens.borderWidthThin
        : SmileDimens.borderWidthHairline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: SmileDimens.sizeControlMd,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.enabled
                  ? colors.input.background
                  : colors.surfaceMuted,
              borderRadius: UseSmileIDSampleShapes.field,
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SmileDimens.spacingMd,
                vertical: SmileDimens.spacingSm,
              ),
              child: Row(
                children: <Widget>[
                  if (widget.leading != null) ...<Widget>[
                    SizedBox(
                      width: _leadingSide,
                      height: _leadingSide,
                      child: Center(
                        child: widget.leading!(colors.input.placeholder),
                      ),
                    ),
                    const SizedBox(width: SmileDimens.spacingXs),
                  ],
                  Expanded(child: _field(colors)),
                  if (widget.trailing != null) ...<Widget>[
                    const SizedBox(width: SmileDimens.spacingXs),
                    widget.trailing!(colors.input.placeholder),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (widget.isError && (widget.errorMessage?.trim().isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.only(
              left: SmileDimens.spacingMd,
              top: SmileDimens.space4,
            ),
            child: Text(
              widget.errorMessage!,
              style: UseSmileIDSampleType.textStyleCaption.copyWith(
                color: colors.input.borderError,
              ),
            ),
          ),
      ],
    );
  }

  Widget _field(UseSmileIDSampleColors colors) => Semantics(
    identifier: widget.testId,
    textField: true,
    child: TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      obscureText: widget.masked,
      autocorrect: !widget.masked,
      enableSuggestions: !widget.masked,
      keyboardType: widget.masked
          ? TextInputType.visiblePassword
          : widget.keyboardType,
      maxLines: 1,
      cursorColor: colors.input.borderFocus,
      style: UseSmileIDSampleType.inputFont.copyWith(
        color: widget.enabled ? colors.input.text : colors.textMuted,
      ),
      decoration: InputDecoration.collapsed(
        hintText: widget.placeholder,
        hintStyle: UseSmileIDSampleType.inputFont.copyWith(
          color: colors.input.placeholder,
        ),
      ),
    ),
  );
}

/// The design's leading-glyph slot, which no scale token carries.
const double _leadingSide = 17;
