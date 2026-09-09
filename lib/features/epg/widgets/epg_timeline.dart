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

    // Graduations + libellés des heures pleines.
    for (var win = firstHour;
        !win.isAfter(lastHour);
        win = win.add(const Duration(hours: 1))) {
      final px = controller.timeToPixels(win);
      if (px < startHourPixels || px > endHourPixels) continue;
      final x = px - offset;
      canvas.drawLine(
        Offset(x, size.height - 8),
        Offset(x, size.height),
        majorLine,
      );

      // Graduations fines toutes les 15 minutes (dans le viewport).
      for (int m = 15; m < 60; m += 15) {
        final sAbs = px + m * ppm;
        if (sAbs < offset || sAbs > offset + size.width) continue;
        canvas.drawLine(
          Offset(sAbs - offset, size.height - 4),
          Offset(sAbs - offset, size.height),
          minorLine,
        );
      }

      final isNowHour = win.hour == now.hour &&
          win.day == now.day &&
          win.month == now.month;
      final tp = TextPainter(
        text: TextSpan(
          text: '${win.hour.toString().padLeft(2, '0')}:00',
          style: TextStyle(
            color: isNowHour ? const Color(0xFF8B5CF6) : Colors.white54,
            fontSize: 10,
            fontWeight: isNowHour ? FontWeight.bold : FontWeight.w500,
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