import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple global notifier for TV mode (avoids Riverpod 3.x provider API changes)
class TvModeNotifier extends ChangeNotifier {
  bool _enabled = false;
  bool get enabled => _enabled;

  void enable() {
    if (!_enabled) {
      _enabled = true;
      notifyListeners();
    }
  }

  void disable() {
    if (_enabled) {
      _enabled = false;
      notifyListeners();
    }
  }

  void setEnabled(bool v) {
    if (_enabled != v) {
      _enabled = v;
      notifyListeners();
    }
  }
}

final tvModeNotifierProvider = Provider<TvModeNotifier>((ref) {
  final notifier = TvModeNotifier();
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

class _LongPressHolder {
  VoidCallback? callback;
  VoidCallback? favoriteToggle;
}

class _TvLongPressScope extends InheritedWidget {
  const _TvLongPressScope({required this.holder, required super.child});

  final _LongPressHolder holder;

  @override
  bool updateShouldNotify(_TvLongPressScope oldWidget) => false;
}

/// Permet à un descendant (ex. `MediaCard`) de déclarer son action d'appui long
/// au [TvFocus] ancêtre, afin que la télécommande (OK maintenu) la déclenche
/// comme le tactile, sans que chaque écran ne la passe deux fois.
void registerTvLongPress(BuildContext context, VoidCallback? callback) {
  final scope = context.getInheritedWidgetOfExactType<_TvLongPressScope>();
  scope?.holder.callback = callback;
}

/// Comme [registerTvLongPress], mais prioritaire : le cœur favori d'une tuile
/// déclare sa bascule (ajout/retrait + message) pour l'appui long OK.
void registerTvFavoriteToggle(BuildContext context, VoidCallback? toggle) {
  final scope = context.getInheritedWidgetOfExactType<_TvLongPressScope>();
  scope?.holder.favoriteToggle = toggle;
}

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
  final bool autofocus;
  final bool enableTvEffects;
  final bool circular;

  const TvFocus({
    super.key,
    required this.child,
    this.focusNode,
    this.onActivate,
    this.onLongPress,
    this.onFocusChange,
    this.autofocus = false,
    this.enableTvEffects = true,
    this.circular = false,
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
    final notifier = ref.read(tvModeNotifierProvider);
    _tvModeNotifier = notifier;
    _isTvMode = notifier.enabled;
    notifier.addListener(_onTvModeChange);
  }

  void _onTvModeChange() {
    if (mounted) {
      setState(() => _isTvMode = _tvModeNotifier?.enabled ?? _isTvMode);
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
    } else {
      _scaleController.reverse();
    }
    widget.onFocusChange?.call(focused);
  }

  /// Vrai entre l'appui sur une touche de validation et son relâchement.
  bool _selectHeld = false;

  final _LongPressHolder _longPressHolder = _LongPressHolder();

  /// Vrai si l'appui maintenu a déjà déclenché [TvFocus.onLongPress].
  bool _longPressFired = false;

  static bool _isSelectKey(LogicalKeyboardKey k) =>
      k == LogicalKeyboardKey.enter ||
      k == LogicalKeyboardKey.select ||
      k == LogicalKeyboardKey.space ||
      k == LogicalKeyboardKey.gameButtonA;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final logicalKey = event.logicalKey;

    // Appui long télécommande : sans ce chemin, `onLongPress` n'était jamais
    // appelé au D-pad (seul le tactile pouvait le déclencher).
    final longPress = widget.onLongPress ??
        _longPressHolder.favoriteToggle ??
        _longPressHolder.callback;
    if (_isSelectKey(logicalKey) && longPress != null) {
      if (event is KeyDownEvent) {
        _selectHeld = true;
        _longPressFired = false;
        return KeyEventResult.handled;
      }
      if (event is KeyRepeatEvent && _selectHeld) {
        if (!_longPressFired) {
          _longPressFired = true;
          HapticFeedback.heavyImpact();
          longPress();
        }
        return KeyEventResult.handled;
      }
      if (event is KeyUpEvent && _selectHeld) {
        _selectHeld = false;
        if (!_longPressFired && widget.onActivate != null) {
          HapticFeedback.heavyImpact();
          widget.onActivate?.call();
        }
        _longPressFired = false;
        return KeyEventResult.handled;
      }
    }

    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Navigation D-pad / flèches : laisser le système gérer
    if (logicalKey == LogicalKeyboardKey.arrowUp ||
        logicalKey == LogicalKeyboardKey.arrowDown ||
        logicalKey == LogicalKeyboardKey.arrowLeft ||
        logicalKey == LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.ignored;
    }

    // Enter / Select / Space / Gamepad A = activer
    if (_isSelectKey(logicalKey) && widget.onActivate != null) {
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

    return _TvLongPressScope(
      holder: _longPressHolder,
      child: Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: _handleFocusChange,
      onKeyEvent: _handleKeyEvent,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: tvMode && _isFocused ? _scaleAnimation.value : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              decoration: tvMode && _isFocused
                  ? BoxDecoration(
                      shape:
                          widget.circular ? BoxShape.circle : BoxShape.rectangle,
                      borderRadius:
                          widget.circular ? null : BorderRadius.circular(12),
                      border: Border.all(color: scheme.primary, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.6),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 0),
                        ),
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: 6,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    )
                  : null,
              child: Material(
                color: Colors.transparent,
                child: widget.child,
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}

/// Wrapper pour détecter la première interaction clavier/D-pad et activer le mode TV
class TvModeDetector extends ConsumerWidget {
  final Widget child;
  const TvModeDetector({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Listener(
      onPointerDown: (_) => ref.read(tvModeNotifierProvider).disable(),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            ref.read(tvModeNotifierProvider).enable();
          }
          return KeyEventResult.ignored;
        },
        child: child,
      ),
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
  }) {
    return TvFocus(
      focusNode: focusNode,
      onActivate: onActivate,
      onLongPress: onLongPress,
      autofocus: autofocus,
      enableTvEffects: enableTvEffects,
      child: this,
    );
  }
}
