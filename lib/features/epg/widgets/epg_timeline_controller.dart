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
    double viewportWidth = 1080.0,
  })  : _gridStartTime = gridStartTime,
        _pixelsPerMinute = pixelsPerMinute,
        _viewportWidth = viewportWidth;

  DateTime _gridStartTime;
  double _pixelsPerMinute;
  double _viewportWidth;

  final ValueNotifier<DateTime> now = ValueNotifier(DateTime.now());
  final ValueNotifier<double> gridOffset = ValueNotifier(0);
  final ValueNotifier<DateTime?> scheduledJump = ValueNotifier(null);
  final ValueNotifier<String?> targetedChannel = ValueNotifier(null);

  DateTime get gridStartTimeValue => _gridStartTime;
  set gridStartTime(DateTime v) => _gridStartTime = v;

  double get pixelsPerMinuteValue => _pixelsPerMinute;
  set pixelsPerMinute(double v) => _pixelsPerMinute = v;

  double get viewportWidth => _viewportWidth;
  set viewportWidth(double v) => _viewportWidth = v;

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
