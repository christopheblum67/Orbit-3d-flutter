# EPG — grille : 5. timeline, gestes et en-têtes

> **Partie 1/4**

> Fiche générée depuis le code source — extraction fidèle, commentaires compris. Chaque bloc est limité à 200 lignes pour rester copiable sans saturer le presse-papier.

Sources : `lib/features/epg/widgets/epg_timeline.dart`, `lib/features/epg/widgets/epg_timeline_controller.dart`, `lib/features/epg/widgets/epg_scroll_gesture.dart`, `lib/features/epg/widgets/epg_headbar.dart`, `lib/features/epg/widgets/epg_mini_program_bar.dart`, `lib/features/epg/widgets/epg_preview_header.dart`

### 5.1 `epg_timeline` — échelle horaire

`lib/features/epg/widgets/epg_timeline.dart` · lignes 1–176

#### `lib/features/epg/widgets/epg_timeline.dart` · lignes 1–176 · partie 1/1

```dart
import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_timeline_controller.dart';

/// Frise temporelle continue en haut de la grille EPG.
///
/// Peinte par un CustomPainter synchronisé avec le défilement horizontal de la
/// grille via [EpgTimelineController.gridOffset]. Le drag (scrubbing) applique
/// un défilement en temps réel sans `setState` : tout passe par des notifiers
/// (repaint ciblé via `repaint:`).
class EpgTimeline extends StatefulWidget {
  final EpgTimelineController controller;
  final double height;
  final ValueChanged<DateTime>? onTimeSelected;
  final ValueChanged<DateTime>? onScrub;

  const EpgTimeline({
    super.key,
    required this.controller,
    this.height = 48,
    this.onTimeSelected,
    this.onScrub,
  });

  @override
  State<EpgTimeline> createState() => _EpgTimelineState();
}

class _EpgTimelineState extends State<EpgTimeline> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        widget.onTimeSelected?.call(
          controller.pixelsToTime(
            controller.gridOffset.value + details.localPosition.dx,
          ),
        );
      },
      onHorizontalDragStart: (details) {
        widget.onScrub?.call(
          controller.pixelsToTime(
            controller.gridOffset.value + details.localPosition.dx,
          ),
        );
      },
      onHorizontalDragUpdate: (details) {
        widget.onScrub?.call(
          controller.pixelsToTime(
            controller.gridOffset.value + details.localPosition.dx,
          ),
        );
      },
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _EpgTimelinePainter(
            controller: controller,
            repaint: Listenable.merge([
              controller.gridOffset,
              controller.now,
            ]),
          ),
        ),
      ),
    );
  }
}

class _EpgTimelinePainter extends CustomPainter {
  final EpgTimelineController controller;

  _EpgTimelinePainter({required this.controller, super.repaint});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0D0E12);
    canvas.drawRect(Offset.zero & size, bg);

    final offset = controller.gridOffset.value;
    final ppm = controller.pixelsPerMinuteValue;
    final now = controller.now.value;

    // Culling : heures dont le pixel absolu tombe dans le viewport + marge
    // d'une heure. La position écran d'un marker = pixel absolu - offset.
    final startHourPixels = offset - 60 * ppm;
    final endHourPixels = offset + size.width + 60 * ppm;
    final startTime = controller.pixelsToTime(startHourPixels);
    final endTime = controller.pixelsToTime(endHourPixels);
    final firstHour = DateTime(
      startTime.year,
      startTime.month,
      startTime.day,
      startTime.hour,
    );
    final lastHour = DateTime(
      endTime.year,
      endTime.month,
      endTime.day,
      endTime.hour + 1,
    );

    final majorLine = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    final minorLine = Paint()
      ..color = Colors.white10
      ..strokeWidth = 0.5;

    // Graduations + libellés toutes les 2 heures (blocs de 2h).
    for (var win = firstHour;
        !win.isAfter(lastHour);
        win = win.add(const Duration(hours: 2))) {
      final px = controller.timeToPixels(win);
      if (px < startHourPixels || px > endHourPixels) continue;
      final x = px - offset;
      canvas.drawLine(
        Offset(x, size.height - 8),
        Offset(x, size.height),
        majorLine,
      );

      // Graduations fines toutes les 30 minutes (dans le viewport).
      for (int m = 30; m < 120; m += 30) {
        final sAbs = px + m * ppm;
        if (sAbs < offset || sAbs > offset + size.width) continue;
        canvas.drawLine(
          Offset(sAbs - offset, size.height - 4),
          Offset(sAbs - offset, size.height),
          minorLine,
        );
      }

      final isNowHour = false; // Affiché toutes les 2h, pas l'heure courante
      final tp = TextPainter(
        text: TextSpan(
          text: '${win.hour.toString().padLeft(2, '0')}:00',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x + 6, 4));
    }

    // Indicateur "maintenant" (position courante sur la frise).
    final nowAbs = controller.timeToPixels(now);
    if (nowAbs >= startHourPixels && nowAbs <= endHourPixels) {
      final nowX = nowAbs - offset;
      final nowPaint = Paint()
        ..color = Colors.redAccent
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(nowX, 0),
        Offset(nowX, size.height),
        nowPaint,
      );
      canvas.drawCircle(
        Offset(nowX, size.height - 4),
        4,
        Paint()..color = Colors.redAccent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EpgTimelinePainter old) =>
      old.controller != controller ||
      old.controller.now.value != controller.now.value ||
      old.controller.gridOffset.value != controller.gridOffset.value;
}
```

### 5.2 `epg_timeline_controller` — contrôle d’échelle/défilement

`lib/features/epg/widgets/epg_timeline_controller.dart` · lignes 1–89

#### `lib/features/epg/widgets/epg_timeline_controller.dart` · lignes 1–89 · partie 1/1

```dart
import 'package:flutter/foundation.dart';

class EpgTimelineController {
  /// Densité par défaut de la frise et de la grille, en px/min.
  ///
  /// Vivait dans EpgGrid2DView, qui n'est qu'un des deux consommateurs :
  /// le définir ici évite a l ecran EPG de dependre de la vue pour choisir
  /// une valeur.
  static const double defaultPixelsPerMinute = 4.0;

  EpgTimelineController({
    required DateTime gridStartTime,
    required double pixelsPerMinute,
    this.viewportWidth = 1080.0,
  })  : _gridStartTime = gridStartTime,
        _pixelsPerMinute = pixelsPerMinute;

  DateTime _gridStartTime;
  double _pixelsPerMinute;
  double viewportWidth;

  final ValueNotifier<DateTime> now = ValueNotifier(DateTime.now());
  final ValueNotifier<double> gridOffset = ValueNotifier(0);
  final ValueNotifier<DateTime?> scheduledJump = ValueNotifier(null);
  final ValueNotifier<String?> targetedChannel = ValueNotifier(null);

  /// Dernier défilement connu (px), mémorisé par la grille quand elle est
  /// détruite et restauré quand elle est recréée (changement de catégorie).
  ///
  /// L'état vit sur le contrôleur, et non dans la grille, parce que `EpgScreen`
  /// recrée la grille à chaque catégorie : un champ local repartait de zéro, et
  /// l'écran sautait sur l'heure courante en perdant la position de
  /// l'utilisateur.
  double lastHorizontalOffset = 0;
  double lastVerticalOffset = 0;

  /// Vrai dès qu'une position a été mémorisée : distingue « jamais positionné »
  /// (on se place alors sur l'heure courante) de « positionné à 0 ».
  bool hasSavedScroll = false;

  void saveScrollOffsets({
    required double horizontal,
    required double vertical,
  }) {
    lastHorizontalOffset = horizontal;
    lastVerticalOffset = vertical;
    hasSavedScroll = true;
  }

  DateTime get gridStartTimeValue => _gridStartTime;
  set gridStartTime(DateTime v) => _gridStartTime = v;

  double get pixelsPerMinuteValue => _pixelsPerMinute;
  set pixelsPerMinute(double v) => _pixelsPerMinute = v;

  double timeToPixels(DateTime t) {
    return t.difference(_gridStartTime).inSeconds / 60.0 * _pixelsPerMinute;
  }

  DateTime pixelsToTime(double pixels) {
    final diffMinutes = pixels / _pixelsPerMinute;
    return _gridStartTime.add(
      Duration(milliseconds: (diffMinutes * 60000).round()),
    );
  }

  void onGridScroll(double offset) {
    gridOffset.value = offset;
  }

  void jumpTo(DateTime time) {
    scheduledJump.value = time;
  }

  void clearJump() {
    scheduledJump.value = null;
  }

  void setTargetedChannel(String? name) {
    targetedChannel.value = name;
  }

  void dispose() {
    now.dispose();
    gridOffset.dispose();
    scheduledJump.dispose();
    targetedChannel.dispose();
  }
}
```

### 5.3 `epg_scroll_gesture` — gestes de défilement

`lib/features/epg/widgets/epg_scroll_gesture.dart` · lignes 1–108

#### `lib/features/epg/widgets/epg_scroll_gesture.dart` · lignes 1–108 · partie 1/1

```dart
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
```
