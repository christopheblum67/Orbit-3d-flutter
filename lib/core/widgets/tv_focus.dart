import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/tv_mode_provider.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';

/// Simple global notifier for TV mode (avoids Riverpod 3.x provider API changes)
/// Maintenu pour compatibilité rétroactive - délègue au controller centralisé
class TvModeNotifier extends ChangeNotifier {
  final TvModeController _controller;

  TvModeNotifier(this._controller) {
    _controller.addListener(_onControllerChange);
  }

  bool get enabled => _controller.enabled;

  void enable() => _controller.enable();
  void disable() => _controller.disable();
  void setEnabled(bool v) => _controller.setEnabled(v);

  void _onControllerChange() {
    notifyListeners();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    super.dispose();
  }
}

final tvModeNotifierProvider = Provider<TvModeNotifier>((ref) {
  final controller = ref.watch(tvModeControllerProvider);
  final notifier = TvModeNotifier(controller);
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

/// Widget de focus TV amélioré avec :
/// - Halo lumineux (glow) + scale + bordure colorée au focus
/// - Navigation D-pad (flèches) + Enter/Select
/// - Feedback haptique
/// - Support du mode souris/tactile (désactive les effets TV si pas en mode TV)
class TvFocus extends ConsumerStatefulWidget {
  final Widget child;
  final FocusNode? focusNode;
  final void Function()? onActivate;
  final void Function()? onLongPress;
  final void Function(bool focused)? onFocusChange;
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;
  final bool autofocus;
  final bool enableTvEffects;

  const TvFocus({
    super.key,
    required this.child,
    this.focusNode,
    this.onActivate,
    this.onLongPress,
    this.onFocusChange,
    this.onKeyEvent,
    this.autofocus = false,
    this.enableTvEffects = true,
  });

  @override
  ConsumerState<TvFocus> createState() => _TvFocusState();
}

class _TvFocusState extends ConsumerState<TvFocus>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;
  bool _isTvMode = false;

  /// Notifier lu une seule fois dans [initState] : Riverpod interdit d'utiliser
  /// `ref` dans [dispose] (l'élément est déjà démonté), ce qui levait
  /// « Bad state: Using "ref" when a widget is about to or has been unmounted »
  /// à chaque sortie d'écran.
  TvModeNotifier? _tvModeNotifier;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
    try {
      final notifier = ref.read(tvModeNotifierProvider);
      _tvModeNotifier = notifier;
      _isTvMode = notifier.enabled;
      notifier.addListener(_onTvModeChange);
    } catch (_) {
      _tvModeNotifier = null;
      _isTvMode = false;
    }
  }

  void _onTvModeChange() {
    final was = _isTvMode;
    if (mounted) {
      setState(() => _isTvMode = _tvModeNotifier?.enabled ?? _isTvMode);
    }
    // Des centaines d'instances de `TvFocus` sont à l'écoute : on ne
    // journalise que le changement sur le widget réellement focalisé, sinon le
    // basculement du mode TV remplirait logcat en une seule fois.
    if (_isTvMode != was && _isTvMode && _isFocused) {
      LoggerService.instance.info('TVFOCUS tvMode ON while focused');
    }
  }

  @override
  void dispose() {
    _tvModeNotifier?.removeListener(_onTvModeChange);
    _tvModeNotifier = null;
    _scaleController.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool focused) {
    setState(() => _isFocused = focused);
    if (focused) {
      _scaleController.forward();
      HapticFeedback.selectionClick();
      // Diagnostic : on ne journalise que le GAIN de focus et seulement si le
      // halo TV sera réellement dessiné. Une tuile focalisée sans mode TV
      // n'est pas le sujet du diagnostic.
      if (widget.enableTvEffects && _isTvMode) {
        LoggerService.instance.info('TVFOCUS focused=true (border+halo drawn)');
      }
    } else {
      _scaleController.reverse();
    }
    widget.onFocusChange?.call(focused);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final logicalKey = event.logicalKey;
    // Navigation D-pad / flèches : laisser le système gérer
    if (logicalKey == LogicalKeyboardKey.arrowUp ||
        logicalKey == LogicalKeyboardKey.arrowDown ||
        logicalKey == LogicalKeyboardKey.arrowLeft ||
        logicalKey == LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.ignored;
    }

    // Enter / Select / Space / Gamepad A = activer
    if (logicalKey == LogicalKeyboardKey.enter ||
        logicalKey == LogicalKeyboardKey.select ||
        logicalKey == LogicalKeyboardKey.space ||
        logicalKey == LogicalKeyboardKey.gameButtonA) {
      HapticFeedback.heavyImpact();
      widget.onActivate?.call();
      return KeyEventResult.handled;
    }

    // Escape / Back / Gamepad B = retour
    if (logicalKey == LogicalKeyboardKey.escape ||
        logicalKey == LogicalKeyboardKey.goBack ||
        logicalKey == LogicalKeyboardKey.gameButtonB) {
      return KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final tvMode = _isTvMode && widget.enableTvEffects;
    final scheme = Theme.of(context).colorScheme;

    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: _handleFocusChange,
      onKeyEvent: widget.onKeyEvent ?? _handleKeyEvent,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          final showEffects = tvMode && _isFocused;
          if (!showEffects && !widget.enableTvEffects) {
            // Sans effets TV et hors mode TV : ne pas ajouter de containers
            // supplémentaires pour préserver la structure attendue par les tests.
            return Material(
              color: Colors.transparent,
              child: child,
            );
          }
          return Transform.scale(
            scale: showEffects ? _scaleAnimation.value : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              decoration: showEffects
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.primary, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.95),
                          blurRadius: 32,
                          spreadRadius: 4,
                          offset: const Offset(0, 0),
                        ),
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.6),
                          blurRadius: 72,
                          spreadRadius: 10,
                          offset: const Offset(0, 0),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.25),
                          blurRadius: 16,
                          spreadRadius: 1,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    )
                  : null,
              child: Material(
                color: Colors.transparent,
                child: child,
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Touches qui trahissent une télécommande ou une manette.
///
/// Le mode TV ne doit s'activer QUE sur celles-ci. Avant, n'importe quelle
/// touche (`KeyDownEvent`) suffisait : une pression sur le clavier d'un
/// téléphone basculait l'interface en mode TV, sans revenir en arrière
/// possible. Les touches de volume, les caractères saisis ou les touches système
/// ne comptent plus comme signal « télécommande ».
///
/// `space` et `goBack` sont également exclus : tous deux sont émis par un
/// téléphone tactile (touche Espace du clavier virtuel, bouton Retour système),
/// jamais par une télécommande de TV.
// `final` et non `const` : `LogicalKeyboardKey` redéfinit `==` / `hashCode`, ce
// qui interdit un ensemble constant de ce type.
final Set<LogicalKeyboardKey> _tvTriggerKeys = {
  LogicalKeyboardKey.arrowUp,
  LogicalKeyboardKey.arrowDown,
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.arrowRight,
  LogicalKeyboardKey.select,
  LogicalKeyboardKey.enter,
  LogicalKeyboardKey.gameButtonA,
  LogicalKeyboardKey.gameButtonB,
  LogicalKeyboardKey.gameButtonX,
  LogicalKeyboardKey.gameButtonY,
  LogicalKeyboardKey.escape,
  LogicalKeyboardKey.mediaPlayPause,
  LogicalKeyboardKey.mediaPlay,
  LogicalKeyboardKey.mediaPause,
  LogicalKeyboardKey.mediaStop,
  LogicalKeyboardKey.mediaFastForward,
  LogicalKeyboardKey.mediaRewind,
  LogicalKeyboardKey.mediaTrackNext,
  LogicalKeyboardKey.mediaTrackPrevious,
};

/// Wrapper pour détecter la première interaction clavier/D-pad et activer le mode TV
class TvModeDetector extends ConsumerWidget {
  final Widget child;
  const TvModeDetector({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            _tvTriggerKeys.contains(event.logicalKey)) {
          ref.read(tvModeControllerProvider).enable();
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

/// Extension pour faciliter l'utilisation
extension TvFocusExtension on Widget {
  Widget tvFocus({
    void Function()? onActivate,
    void Function()? onLongPress,
    FocusNode? focusNode,
    bool autofocus = false,
    bool enableTvEffects = true,
    KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent,
    String? a11yLabel,
    String? a11yHint,
    bool a11yButton = false,
    bool a11ySelected = false,
  }) {
    Widget w = TvFocus(
      focusNode: focusNode,
      onActivate: onActivate,
      onLongPress: onLongPress,
      onKeyEvent: onKeyEvent,
      autofocus: autofocus,
      enableTvEffects: enableTvEffects,
      child: this,
    );
    if (a11yLabel != null || a11yHint != null || a11yButton || a11ySelected) {
      w = Semantics(
        label: a11yLabel,
        hint: a11yHint,
        button: a11yButton,
        selected: a11ySelected,
        child: w,
      );
    }
    return w;
  }
}
