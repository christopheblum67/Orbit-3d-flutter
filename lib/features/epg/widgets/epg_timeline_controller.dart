import 'package:flutter/foundation.dart';

class EpgTimelineController {
  EpgTimelineController({
    required DateTime gridStartTime,
    required double pixelsPerMinute,
  })  : _gridStartTime = gridStartTime,
        _pixelsPerMinute = pixelsPerMinute;

  DateTime _gridStartTime;
  double _pixelsPerMinute;

  final ValueNotifier<DateTime> now = ValueNotifier(DateTime.now());
  final ValueNotifier<double> gridOffset = ValueNotifier(0);
  final ValueNotifier<DateTime?> scheduledJump = ValueNotifier(null);
  final ValueNotifier<String?> targetedChannel = ValueNotifier(null);

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
