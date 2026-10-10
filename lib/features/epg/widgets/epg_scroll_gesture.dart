import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Geste horizontal qui se partage avec un défilement vertical parent.
///
/// ## Pourquoi ce widget existe
///
/// La grille EPG contient un `ListView` vertical. Le défilement horizontal, lui,
/// n'existait que dans un `Listener` passif : cet écouteur et le `ListView` se
/// disputaient chaque pointeur dans l'arène de gestes de Flutter, et le
/// `ListView` gagnait presque toujours sur un téléphone. Quand il gagnait, le
/// décalage n'avançait plus — la grille restait figée, ou reculait par bonds, ce
/// qui se lit comme un effacement du contenu pendant le défilement.
///
/// Un `Listener` ne réclame rien dans l'arène. Un vrai
/// `HorizontalDragGestureRecognizer` en revanche y participe : il ne gagne que
/// si le mouvement est franchement horizontal, et perd si le doigt descend, ce
/// qui laisse le `ListView` défiler normalement. C'est le comportement de
/// TiviMate, obtenu ici sans toucher à la structure du `ListView`.
///
/// ## Pourquoi le delta repart d'une base figée
///
/// Le tactile n'envoie pas ses positions en nombres entiers. Cumuler les deltas
/// événement par événement accumule l'arrondi et fait dériver la grille par
/// rapport au doigt. On fige donc le décalage au début du geste et on lui
/// retranche le total des deltas reçus.
class HorizontalDragLayer extends StatefulWidget {
  const HorizontalDragLayer({
    super.key,
    required this.offset,
    required this.maxOffset,
    required this.onOffsetChanged,
    required this.child,
    this.onSettled,
  });

  /// Décalage courant, en px depuis le début de la journée.
  ///
  /// C'est un `ValueListenable`, et non un `double` figé : la grille déplace sa
  /// journée via un `ValueNotifier` sans se reconstruire. Un `double` capturé au
  /// build serait périmé dès le premier défilement, et le geste suivant
  /// repartirait d'une base fausse — mesuré à `base=0.0` alors que la grille
  /// était positionnée sur l'heure courante.
  final ValueListenable<double> offset;

  /// Borne haute du défilement ; la borne basse est toujours 0.
  final double maxOffset;

  /// Appelé à chaque déplacement, valeur déjà bornée.
  final ValueChanged<double> onOffsetChanged;

  /// Appelé quand le geste s'arrête.
  final VoidCallback? onSettled;

  final Widget child;

  @override
  State<HorizontalDragLayer> createState() => _HorizontalDragLayerState();
}

class _HorizontalDragLayerState extends State<HorizontalDragLayer> {
  double? _base;
  double _total = 0.0;

  void _handleStart(DragStartDetails details) {
    // On lit l'offset VIVANT, pas la copie du dernier build.
    _base = widget.offset.value;
    _total = 0.0;
  }

  void _handleUpdate(DragUpdateDetails details) {
    final base = _base;
    if (base == null) return;
    _total += details.delta.dx;
    widget.onOffsetChanged((base - _total).clamp(0.0, widget.maxOffset));
  }

  void _handleEnd(DragEndDetails details) {
    _base = null;
    widget.onSettled?.call();
  }

  void _handleCancel() => _base = null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // `GestureDetector` construit lui-même le
      // `HorizontalDragGestureRecognizer` et le fait participer à l'arène. Un
      // `RawGestureDetector` ne serait justifié que pour configurer le seuil de
      // déclenchement du geste, ce dont nous n'avons pas démontré besoin.
      onHorizontalDragStart: _handleStart,
      onHorizontalDragUpdate: _handleUpdate,
      onHorizontalDragEnd: _handleEnd,
      onHorizontalDragCancel: _handleCancel,
      child: widget.child,
    );
  }
}

/// Distance au-delà de laquelle un appui devient un glissement, en px.
@visibleForTesting
const double kTapSlop = 8.0;

/// Vrai si [moved] décrit un glissement plutôt qu'un appui.
@visibleForTesting
bool isDragNotTap(double moved) => moved.abs() > kTapSlop;