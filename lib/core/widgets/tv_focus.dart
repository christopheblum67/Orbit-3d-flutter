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

  const TvFocus({
    super.key,
    required this.child,
    this.focusNode,
    this.onActivate,
    this.onLongPress,
    this.onFocusChange,
    this.autofocus = false,
    this.enableTvEffects = true,
  });

  @override
  ConsumerState<TvFocus> createState() => _TvFocusState();
}

class _TvFocusState extends ConsumerState<TvFocus> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;
  bool _isTvMode = false;

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
    _isTvMode = notifier.enabled;
    notifier.addListener(_onTvModeChange);
  }

  void _onTvModeChange() {
    if (mounted) {
      setState(() => _isTvMode = ref.read(tvModeNotifierProvider).enabled);
    }
  }

  @override
  void dispose() {
    ref.read(tvModeNotifierProvider).removeListener(_onTvModeChange);
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
                      borderRadius: BorderRadius.circular(12),
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
    );
  }
}

/// Wrapper pour détecter la première interaction clavier/D-pad et activer le mode TV
class TvModeDetector extends ConsumerWidget {
  final Widget child;
  const TvModeDetector({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          ref.read(tvModeNotifierProvider).enable();
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