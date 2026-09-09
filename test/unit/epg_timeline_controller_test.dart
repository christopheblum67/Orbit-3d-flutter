import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_timeline_controller.dart';

void main() {
  final gridStart = DateTime(2026, 9, 8, 6, 0);
  EpgTimelineController make(double ppm) => EpgTimelineController(
        gridStartTime: gridStart,
        pixelsPerMinute: ppm,
      );

  group('timeToPixels / pixelsToTime', () {
    test('time at gridStart maps to 0 px', () {
      final c = make(4);
      expect(c.timeToPixels(gridStart), 0);
    });

    test('1h later maps to 60min * ppm px', () {
      final c = make(4);
      expect(c.timeToPixels(gridStart.add(const Duration(hours: 1))), 240);
    });

    test('pixels map back to the same time', () {
      final c = make(2.5);
      final t = gridStart.add(const Duration(minutes: 37));
      final px = c.timeToPixels(t);
      expect(c.pixelsToTime(px).isAtSameMomentAs(t), true);
    });

    test('pixelsToTime accepts fractional pixels (scrub)', () {
      final c = make(4);
      final t = c.pixelsToTime(123.45);
      expect(t.isAfter(gridStart), true);
      expect(t.isBefore(gridStart.add(const Duration(minutes: 31))), true);
    });
  });

  group('gridOffset / onGridScroll', () {
    test('onGridScroll updates gridOffset notifier', () {
      final c = make(4);
      var received = false;
      c.gridOffset.addListener(() => received = true);
      c.onGridScroll(480);
      expect(c.gridOffset.value, 480);
      expect(received, true);
    });
  });

  group('jumpTo / scheduledJump', () {
    test('jumpTo sets scheduledJump', () {
      final c = make(4);
      final target = gridStart.add(const Duration(hours: 3));
      c.jumpTo(target);
      expect(c.scheduledJump.value, target);
    });

    test('clearJump resets scheduledJump to null', () {
      final c = make(4);
      c.jumpTo(gridStart);
      c.clearJump();
      expect(c.scheduledJump.value, isNull);
    });
  });

  group('targetedChannel', () {
    test('setTargetedChannel notifies listeners', () {
      final c = make(4);
      String? last;
      c.targetedChannel.addListener(() => last = c.targetedChannel.value);
      c.setTargetedChannel('TF1');
      expect(last, 'TF1');
      c.setTargetedChannel(null);
      expect(last, isNull);
    });
  });

  group('mutation of geometry', () {
    test('gridStartTime / pixelsPerMinute setters are reflected', () {
      final c = make(4);
      final newStart = DateTime(2026, 9, 8, 8, 30);
      c.gridStartTime = newStart;
      c.pixelsPerMinute = 1;
      expect(c.timeToPixels(newStart), 0);
      expect(c.pixelsToTime(60), newStart.add(const Duration(hours: 1)));
    });
  });
}