import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:orbit_3d_flutter/features/home/solar_system_controller.dart';

class OrbitPlanetWidget extends StatefulWidget {
  final SolarBody body;
  final bool isFocused;
  final bool isZoomedIn;
  final double orbitRadius;
  final double baseAngle;
  final VoidCallback? onTap;
  final SolarSystemController controller;

  const OrbitPlanetWidget({
    super.key,
    required this.body,
    required this.isFocused,
    required this.isZoomedIn,
    required this.orbitRadius,
    required this.baseAngle,
    required this.controller,
    this.onTap,
  });

  @override
  State<OrbitPlanetWidget> createState() => _OrbitPlanetWidgetState();
}

class _OrbitPlanetWidgetState extends State<OrbitPlanetWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 45),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.controller.getColorForBody(widget.body);
    final icon = widget.controller.getIconForBody(widget.body);
    final label = widget.controller.getLabelForBody(widget.body);

    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        final angle = widget.baseAngle + _rotationAnimation.value;
        final x = widget.orbitRadius * math.cos(angle);
        final y = widget.orbitRadius * math.sin(angle);

        return Transform.translate(
          offset: Offset(x, y),
          child: _buildPlanet(color, icon, label),
        );
      },
    );
  }

  Widget _buildPlanet(Color color, IconData icon, String label) {
    final scale = widget.isFocused && widget.isZoomedIn ? 1.3 : 1.0;
    final glowColor = widget.isFocused && widget.isZoomedIn
        ? const Color(0xFF8B5CF6)
        : color.withValues(alpha: 0.3);

    return AnimatedScale(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      scale: scale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: widget.body == SolarBody.sun ? 100 : 70,
                height: widget.body == SolarBody.sun ? 100 : 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: 0.9),
                      color.withValues(alpha: 0.4),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor,
                      blurRadius: widget.isFocused && widget.isZoomedIn ? 30 : 15,
                      spreadRadius: widget.isFocused && widget.isZoomedIn ? 8 : 3,
                    ),
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: widget.body == SolarBody.sun ? 44 : 30,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (widget.isFocused && widget.isZoomedIn) ...[
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class OrbitRingWidget extends StatelessWidget {
  final double radius;
  final Color color;
  final double strokeWidth;

  const OrbitRingWidget({
    super.key,
    required this.radius,
    required this.color,
    this.strokeWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(radius * 2, radius * 2),
      painter: _OrbitRingPainter(
        radius: radius,
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  final double radius;
  final Color color;
  final double strokeWidth;

  _OrbitRingPainter({
    required this.radius,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);

    final dashPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final dashPath = Path();
    const dashLength = 10.0;
    const gapLength = 8.0;
    const totalSegments = 100;

    for (int i = 0; i < totalSegments; i++) {
      final startAngle = (i * (dashLength + gapLength) / (radius * 2)) * 2 * math.pi;
      final sweepAngle = (dashLength / (radius * 2)) * 2 * math.pi;
      dashPath.addArc(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: radius,
        ),
        startAngle,
        sweepAngle,
      );
    }

    canvas.drawPath(dashPath, dashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}