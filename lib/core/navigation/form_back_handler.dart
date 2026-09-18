import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_3d_flutter/core/navigation/route_meta.dart';

/// Mixin pour gérer le bouton "retour" sur les écrans avec formulaire.
///
/// Usage:
/// ```dart
/// class MyFormScreen extends ConsumerStatefulWidget { ... }
/// class _MyFormScreenState extends ConsumerState<MyFormScreen> with FormBackHandler {
///   final _formKey = GlobalKey<FormState>();
///   // ...
///   @override
///   bool get isFormDirty => _formKey.currentState?.validate() != true || _hasChanges;
/// }
/// ```
mixin FormBackHandler<T extends StatefulWidget> on State<T> {
  /// Retourne `true` si le formulaire a des modifications non sauvegardées.
  bool get isFormDirty;

  /// Message personnalisé pour la boîte de dialogue de confirmation.
  String get discardDialogMessage => 'Des modifications non sauvegardées seront perdues. Quitter quand même ?';

  /// Titre de la boîte de dialogue de confirmation.
  String get discardDialogTitle => 'Quitter sans sauvegarder ?';

  /// Focus nodes for TV/D-pad navigation in the discard dialog.
  final _cancelFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _cancelFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _requestFocus(FocusNode focus) {
    if (mounted) {
      FocusScope.of(context).requestFocus(focus);
    }
  }

  /// Gère l'événement "retour" (système, geste, barre de navigation).
  ///
  /// Retourne `true` pour permettre le pop, `false` pour l'annuler.
  Future<bool> onWillPop() async {
    if (isFormDirty) {
      return await _showDiscardDialog();
    }
    return true;
  }

  Future<bool> _showDiscardDialog() async {
    if (!mounted) return false;
    // Reset focus to cancel button when dialog opens
    _cancelFocus.requestFocus();
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(discardDialogTitle),
        content: Text(discardDialogMessage),
        actions: [
          Focus(
            focusNode: _cancelFocus,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                Navigator.of(dialogContext).pop(false);
                return KeyEventResult.handled;
              }
              // Left/Right to navigate between buttons
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                      event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
                _requestFocus(_confirmFocus);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
          ),
          Focus(
            focusNode: _confirmFocus,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                Navigator.of(dialogContext).pop(true);
                return KeyEventResult.handled;
              }
              // Left/Right to navigate between buttons
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                      event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
                _requestFocus(_cancelFocus);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Quitter'),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// Extension pour utiliser [FormBackHandler] avec [WithBackHandling].
///
/// Permet de connecter un widget avec [FormBackHandler] au système de navigation.
extension FormBackHandlerRoute on FormBackHandler {
  /// Crée un [RouteMeta.custom] qui appelle [onWillPop] du mixin.
  RouteMeta get routeMeta => RouteMeta.custom(
        (context, router) async {
          // Le mixin doit être sur le State du widget enfant
          // Cette extension est un helper conceptuel ; l'implémentation réelle
          // se fait via un wrapper widget ou en exposant le callback.
        },
      );
}

/// Widget wrapper qui connecte un [FormBackHandler] à [WithBackHandling].
///
/// Place ce widget autour de ton écran de formulaire :
/// ```dart
/// WithBackHandling(
///   meta: RouteMeta.custom((context, router) async {
///     final handler = context.findAncestorStateOfType<_MyFormScreenState>();
///     if (handler != null && handler is FormBackHandler) {
///       final canPop = await handler.onWillPop();
///       if (canPop && router.canPop()) router.pop();
///     } else if (router.canPop()) {
///       router.pop();
///     }
///   }),
///   child: MyFormScreen(),
/// )
/// ```
class FormBackHandlerScope extends StatelessWidget {
  final Widget child;
  final Future<bool> Function() onWillPop;

  const FormBackHandlerScope({
    super.key,
    required this.child,
    required this.onWillPop,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canPop = await onWillPop();
        if (canPop && context.mounted) {
          final router = GoRouter.of(context);
          if (router.canPop()) {
            router.pop();
          }
        }
      },
      child: child,
    );
  }
}