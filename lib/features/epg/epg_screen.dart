import 'dart:math' as math;
import 'package:flutter/material.dart';

class EpgScreen extends StatefulWidget {
  const EpgScreen({super.key});

  @override
  State<EpgScreen> createState() => _EpgScreenState();
}

class _EpgScreenState extends State<EpgScreen> {
  int _selectedIndex = 0;
  final List<String> _channels = ['TF1', 'France 2', 'M6', 'Arte', 'Canal+'];
  final List<Map<String, String>> _programs = [
    {'time': '20:00', 'title': 'Journal'},
    {'time': '21:00', 'title': 'Film'},
    {'time': '22:30', 'title': 'Documentaire'},
    {'time': '23:00', 'title': 'Concert'},
    {'time': '23:45', 'title': 'Fin des programmes'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guide TV (EPG Orbit)')),
      body: Column(
        children: [
          // Partie supérieure : anneau des programmes
          Expanded(
            flex: 3,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth * 0.9;
                return Center(
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: CustomPaint(
                      painter: OrbitPainter(
                        selectedIndex: _selectedIndex,
                        channels: _channels,
                        programs: _programs,
                      ),
                      child: GestureDetector(
                        onTapDown: (details) {
                          final angle = _getAngle(details.localPosition, size);
                          final index = ((angle + math.pi / _programs.length) / (2 * math.pi / _programs.length)).floor() % _programs.length;
                          setState(() => _selectedIndex = index);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Partie inférieure : détails du programme sélectionné
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _programs[_selectedIndex]['title'] ?? '',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_programs[_selectedIndex]['time']} - ${_channels[_selectedIndex]}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getAngle(Offset position, double size) {
    final center = Offset(size / 2, size / 2);
    return math.atan2(position.dy - center.dy, position.dx - center.dx);
  }
}

class OrbitPainter extends CustomPainter {
  final int selectedIndex;
  final List<String> channels;
  final List<Map<String, String>> programs;

  OrbitPainter({
    required this.selectedIndex,
    required this.channels,
    required this.programs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..color = Colors.blueGrey.withOpacity(0.2);
    final activeRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..color = ThemeData.light().colorScheme.primary;

    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi / programs.length,
      false,
      activeRingPaint,
    );

    // Dessiner les segments et labels
    for (int i = 0; i < programs.length; i++) {
      final angle = (2 * math.pi / programs.length) * i - math.pi / 2;
      final labelPos = Offset(
        center.dx + math.cos(angle) * (radius + 20),
        center.dy + math.sin(angle) * (radius + 20),
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: programs[i]['time'],
          style: TextStyle(
            color: i == selectedIndex ? Colors.orange : Colors.white,
            fontSize: 14,
            fontWeight: i == selectedIndex ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, labelPos - Offset(textPainter.width / 2, textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant OrbitPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex;
  }
}
