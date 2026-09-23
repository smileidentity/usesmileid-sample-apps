import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/use_smileid_sample_glyphs.dart';
import '../components/use_smileid_sample_scan_glyph.dart';
import '../components/use_smileid_sample_scan_sheet.dart';
import '../components/use_smileid_sample_scan_status.dart';
import '../components/use_smileid_sample_top_app_bar.dart';
import '../model/use_smileid_sample_environment.dart';
import '../model/use_smileid_sample_simulated_scan.dart';
import '../state/use_smileid_sample_token_decoder.dart';
import '../state/use_smileid_sample_token_session.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';

/// The host's camera preview, handed whether to scan and the one handler every candidate goes through.
typedef UseSmileIDSampleViewfinder =
    Widget Function(
      BuildContext context, {
      required bool enabled,
      required ValueChanged<String> onCandidate,
    });

/// Why the scanner opened, so the eight hosts cannot word it differently.
enum UseSmileIDSampleScanReason {
  /// The expiry gate sent a run here.
  sessionEnded('Token session ended. Scan to continue where you left off.');

  const UseSmileIDSampleScanReason(this.caption);

  /// The sentence shown in place of the generic caption.
  final String caption;
}

/// Scan token: from the camera, by hand, or simulated, a session is linked only after the token decodes.
///
/// Entry state lives in this widget, so it survives a rebuild but not process death, as a typed field does elsewhere.
class UseSmileIDSampleScanTokenScreen extends StatefulWidget {
  /// [viewfinder] absent (a golden, an SDK repo's sample) keeps the glyph in its place.
  const UseSmileIDSampleScanTokenScreen({
    required this.onBack,
    required this.onLink,
    required this.onSimulate,
    required this.onPaste,
    this.reason,
    this.torchOn = false,
    this.onTorchToggle,
    this.viewfinder,
    this.nowMillis,
    super.key,
  });

  /// Leaves without linking.
  final VoidCallback onBack;

  /// Links a decoded session.
  final ValueChanged<UseSmileIDSampleTokenSession> onLink;

  /// Mints and links a fixture token.
  final void Function(
    UseSmileIDSampleSimulatedSpan span,
    UseSmileIDSampleSimulatedBindings bindings,
    UseSmileIDSampleEnvironment environment,
  )
  onSimulate;

  /// The host's clipboard, null when it holds no text.
  final Future<String?> Function() onPaste;

  /// Why the screen opened when something sent the user here; null when opened deliberately.
  final UseSmileIDSampleScanReason? reason;

  /// Whether the host's torch is on.
  final bool torchOn;

  /// Toggles the host's torch.
  final VoidCallback? onTorchToggle;

  /// The host's camera.
  final UseSmileIDSampleViewfinder? viewfinder;

  /// A fixed clock for a golden; the wall clock otherwise.
  final int Function()? nowMillis;

  @override
  State<UseSmileIDSampleScanTokenScreen> createState() =>
      _UseSmileIDSampleScanTokenScreenState();
}

class _UseSmileIDSampleScanTokenScreenState
    extends State<UseSmileIDSampleScanTokenScreen> {
  String _token = '';
  String? _rejection;
  UseSmileIDSampleSimulatedSpan _span =
      UseSmileIDSampleSimulatedSpan.fifteenMinutes;
  UseSmileIDSampleEnvironment _environment =
      UseSmileIDSampleEnvironment.sandbox;
  UseSmileIDSampleSimulatedBindings _bindings =
      const UseSmileIDSampleSimulatedBindings();
  bool _expanded = false;
  UseSmileIDSampleScanState _scan = const UseSmileIDSampleScanSearching();
  Timer? _dwell;

  @override
  void dispose() {
    _dwell?.cancel();
    super.dispose();
  }

  int _now() =>
      widget.nowMillis?.call() ?? DateTime.now().millisecondsSinceEpoch;

  /// Scanned, pasted or typed, a candidate is judged here and nowhere else; decoding is not verification.
  void _judge(String candidate, {required bool fromField}) {
    final UseSmileIDSampleTokenDecode decoded =
        UseSmileIDSampleTokenDecoder.decode(candidate);
    switch (decoded) {
      case UseSmileIDSampleTokenDecoded(
        :final UseSmileIDSampleTokenSession session,
      ):
        unawaited(HapticFeedback.mediumImpact());
        setState(() {
          _rejection = null;
          _scan = UseSmileIDSampleScanLinked(
            handle: session.id,
            remaining: useSmileIDSampleCountdown(session.remaining(_now())),
          );
        });
        // Held long enough to be read: leaving on the decode's frame looked like nothing happening.
        _dwell?.cancel();
        _dwell = Timer(_linkedDwell, () {
          if (mounted) {
            widget.onLink(session);
          }
        });
      // A field's error sits under the field; a scanned code has no field, so the pill answers. Never both.
      case UseSmileIDSampleTokenRejected(:final String reason):
        unawaited(HapticFeedback.heavyImpact());
        setState(() {
          if (fromField) {
            _rejection = reason;
          } else {
            _scan = UseSmileIDSampleScanRejected(reason);
          }
        });
    }
  }

  void _scanned(String candidate) {
    if (_scan is! UseSmileIDSampleScanSearching) {
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    setState(() => _scan = const UseSmileIDSampleScanFound());
    _judge(candidate, fromField: false);
  }

  Future<void> _paste() async {
    String? pasted;
    try {
      pasted = await widget.onPaste();
    } on Object {
      // A clipboard the platform refuses to read is, to the person holding the phone, an empty one.
      pasted = null;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      if (pasted == null || pasted.trim().isEmpty) {
        _rejection = 'The clipboard holds no text to paste.';
      } else {
        _token = pasted;
        _rejection = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final String caption = widget.reason?.caption ?? _scanCaption;
    return Semantics(
      identifier: UseSmileIDSampleTestIds.scanTokenScreen,
      container: true,
      child: ColoredBox(
        color: colors.background,
        child: Column(
          children: <Widget>[
            UseSmileIDSampleTopAppBar(
              title: 'Scan token',
              onBack: widget.onBack,
              action: UseSmileIDSampleTopAppBarButton(
                semanticLabel: widget.torchOn
                    ? 'Turn flash off'
                    : 'Turn flash on',
                onTap: widget.onTorchToggle ?? () {},
                emphasis: UseSmileIDSampleTopAppBarEmphasis.filled,
                glyph: UseSmileIDSampleGlyphs.flash,
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) =>
                    widget.viewfinder == null
                    ? _placeholder(colors, caption, constraints)
                    : _camera(context, colors, caption, constraints),
              ),
            ),
            UseSmileIDSampleScanSheet(
              state: UseSmileIDSampleScanSheetState(
                token: _token,
                rejection: _rejection,
                span: _span,
                environment: _environment,
                bindings: _bindings,
                expanded: _expanded,
              ),
              onTokenChanged: (String value) => setState(() {
                _token = value;
                _rejection = null;
              }),
              onPaste: _paste,
              onLink: () => _judge(_token, fromField: true),
              onExpandToggle: () => setState(() => _expanded = !_expanded),
              onSpanSelect: (UseSmileIDSampleSimulatedSpan span) =>
                  setState(() => _span = span),
              onEnvironmentSelect: (UseSmileIDSampleEnvironment environment) =>
                  setState(() => _environment = environment),
              onBindingsChanged: (UseSmileIDSampleSimulatedBindings bindings) =>
                  setState(() => _bindings = bindings),
              onSimulate: () =>
                  widget.onSimulate(_span, _bindings, _environment),
            ),
          ],
        ),
      ),
    );
  }

  /// Centred and scrolling in one: at 2x the fixed glyph's copy no longer fits above the sheet.
  Widget _placeholder(
    UseSmileIDSampleColors colors,
    String caption,
    BoxConstraints constraints,
  ) => SingleChildScrollView(
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: constraints.maxHeight),
      child: Padding(
        padding: const EdgeInsets.all(SmileDimens.spacingMd),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const UseSmileIDSampleScanGlyph(),
            const SizedBox(height: SmileDimens.spacingSm),
            _copy(
              _scanTitle,
              UseSmileIDSampleType.textStyleTitle,
              colors.textTitle,
            ),
            const SizedBox(height: SmileDimens.spacingSm),
            _copy(caption, _captionStyle, colors.textMuted),
          ],
        ),
      ),
    ),
  );

  Widget _camera(
    BuildContext context,
    UseSmileIDSampleColors colors,
    String caption,
    BoxConstraints constraints,
  ) {
    final bool searching = _scan is UseSmileIDSampleScanSearching;
    // Sized to the space, not the design's fixed 279: the sheet takes the lower half here.
    final double reticle =
        _reticleWidth * constraints.maxWidth <
            _reticleHeight * constraints.maxHeight
        ? _reticleWidth * constraints.maxWidth
        : _reticleHeight * constraints.maxHeight;
    final List<Shadow> overCamera = <Shadow>[
      Shadow(color: colors.textTitle, blurRadius: _copyShadowBlur),
    ];
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.viewfinder!(context, enabled: searching, onCandidate: _scanned),
        Padding(
          padding: const EdgeInsets.all(SmileDimens.spacingMd),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedOpacity(
                opacity: searching ? _reticleIdleAlpha : 1,
                duration: kThemeAnimationDuration,
                child: UseSmileIDSampleScanGlyph(
                  size: reticle,
                  tint: switch (_scan) {
                    UseSmileIDSampleScanSearching() => colors.textInverse,
                    UseSmileIDSampleScanFound() => colors.infoFill,
                    UseSmileIDSampleScanLinked() => colors.successFill,
                    UseSmileIDSampleScanRejected() => colors.errorFill,
                  },
                ),
              ),
              const SizedBox(height: SmileDimens.spacingMd),
              // Straight on the camera: a container here was a white slab over the preview.
              if (searching) ...<Widget>[
                _copy(
                  _scanTitle,
                  UseSmileIDSampleType.textStyleTitle.copyWith(
                    shadows: overCamera,
                  ),
                  colors.textInverse,
                ),
                const SizedBox(height: SmileDimens.spacingMd),
                _copy(
                  caption,
                  _captionStyle.copyWith(shadows: overCamera),
                  colors.textInverse,
                ),
              ] else
                UseSmileIDSampleScanStatus(
                  state: _scan,
                  // Re-enables the scanner, so the same QR reads again.
                  onRetry: () => setState(() {
                    _rejection = null;
                    _scan = const UseSmileIDSampleScanSearching();
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _copy(String text, TextStyle style, Color color) => SizedBox(
    width: double.infinity,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: style.copyWith(color: color),
    ),
  );
}

final TextStyle _captionStyle = UseSmileIDSampleType.textStyleCaption.copyWith(
  fontSize: 12.5,
);

const String _scanTitle = 'Point at a Smile token QR';
const String _scanCaption =
    'Line up the code inside the frame to link this device to a verification session.';

/// Long enough to read "Session linked" and its handle, short enough not to feel like a wait.
const Duration _linkedDwell = Duration(milliseconds: 900);

/// The design's own reticle opacity, which keeps it from competing with the preview.
const double _reticleIdleAlpha = 0.45;
const double _reticleWidth = 0.72;
const double _reticleHeight = 0.52;
const double _copyShadowBlur = 8;
