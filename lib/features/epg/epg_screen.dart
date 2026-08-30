import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/epg_program.dart';

class EpgScreen extends ConsumerStatefulWidget {
  const EpgScreen({super.key});

  @override
  ConsumerState<EpgScreen> createState() => _EpgScreenState();
}

class _EpgScreenState extends ConsumerState<EpgScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  List<EPGProgram> _programs = [];
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _selectIndex(int index) {
    if (_programs.isEmpty) return;
    setState(() {
      _selectedIndex = index % _programs.length;
    });
    _rotationController.animateTo(
      (2 * math.pi / _programs.length) * _selectedIndex,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final programsAsync = ref.watch(epgProgramsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Guide TV (EPG Orbit)')),
      body: programsAsync.when(
        data: (data) {
          _programs = data;
          if (_programs.isNotEmpty && _selectedIndex >= _programs.length) {
            _selectedIndex = 0;
          }
          return Column(
            children: [
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity < 0) {
                      _selectIndex(_selectedIndex + 1);
                    } else if (velocity > 0) {
                      _selectIndex(_selectedIndex - 1);
                    }
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.maxWidth * 0.9;
                      return Center(
                        child: AnimatedBuilder(
                          animation: _rotationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: -_rotationController.value,
                              child: SizedBox(
                                width: size,
                                height: size,
                                child: CustomPaint(
                                  painter: OrbitPainter(
                                    selectedIndex: _selectedIndex,
                                    programs: _programs,
                                    ringColor: scheme.primaryContainer.withOpacity(0.45),
                                    accentColor: scheme.tertiary,
                                    textColor: scheme.onSurfaceVariant,
                                    activeTextColor: scheme.secondary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _programs.isNotEmpty
                            ? _programs[_selectedIndex].title
                            : 'Aucun programme',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      if (_programs.isNotEmpty)
                        Text(
                          '${_programs[_selectedIndex].start} - ${_programs[_selectedIndex].end}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur EPG: $err')),
      ),
    );
  }
}

class OrbitPainter extends CustomPainter {
  final int selectedIndex;
  final List<EPGProgram> programs;
  final Color ringColor;
  final Color accentColor;
  final Color textColor;
  final Color activeTextColor;

  OrbitPainter({
    required this.selectedIndex,
    required this.programs,
    required this.ringColor,
    required this.accentColor,
    required this.textColor,
    required this.activeTextColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (programs.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..color = ringColor;
    final activeRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..color = accentColor;

    canvas.drawCircle(center, radius, ringPaint);
    // Arc actif
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + (2 * math.pi / programs.length) * selectedIndex,
      2 * math.pi / programs.length,
      false,
      activeRingPaint,
    );

    for (int i = 0; i < programs.length; i++) {
      final angle = (2 * math.pi / programs.length) * i - math.pi / 2;
      final labelPos = Offset(
        center.dx + math.cos(angle) * (radius + 20),
        center.dy + math.sin(angle) * (radius + 20),
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: programs[i].title.length > 15
              ? programs[i].title.substring(0, 15)
              : programs[i].title,
          style: TextStyle(
            color: i == selectedIndex ? activeTextColor : textColor,
            fontSize: 12,
            fontWeight: i == selectedIndex ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        labelPos - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant OrbitPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.programs != programs ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.activeTextColor != activeTextColor;
  }
}
