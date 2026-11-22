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
