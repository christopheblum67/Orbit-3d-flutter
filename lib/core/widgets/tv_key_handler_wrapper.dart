import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Intercepte les touches de télécommande (lecture/pause, avance/retour rapide,
/// retour) au niveau d'un écran, même si le focus est sur un élément secondaire.
///
/// À utiliser sur les écrans principaux (player, home) pour garantir que les
/// touches physiques de la télécommande déclenchent toujours l'action attendue.
class TvKeyHandlerWrapper extends StatelessWidget {
  const TvKeyHandlerWrapper({
    super.key,
    required this.child,
    this.onPlayPause,
    this.onFastForward,
    this.onRewind,
    this.onBackCustom,
  });

  final Widget child;
  final VoidCallback? onPlayPause;
  final VoidCallback? onFastForward;
  final VoidCallback? onRewind;
  final VoidCallback? onBackCustom;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          switch (event.logicalKey) {
            case LogicalKeyboardKey.mediaPlayPause:
            case LogicalKeyboardKey.mediaPlay:
            case LogicalKeyboardKey.mediaPause:
              onPlayPause?.call();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.mediaFastForward:
              onFastForward?.call();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.mediaRewind:
              onRewind?.call();
              return KeyEventResult.handled;
            case LogicalKeyboardKey.goBack:
            case LogicalKeyboardKey.escape:
              if (onBackCustom != null) {
                onBackCustom!();
                return KeyEventResult.handled;
              }
              break;
            default:
              break;
          }
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
