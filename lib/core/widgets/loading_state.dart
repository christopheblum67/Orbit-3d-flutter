import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/features/startup/widgets/refresh_progress_view.dart';

/// État de chargement unifié avec logo animé Orbit IPTV.
/// Même logo animé que l'écran de démarrage (pulse + IPTV séquentiel).
/// Les paramètres message/subtitle sont conservés pour compatibilité mais non affichés.
class LoadingState extends StatelessWidget {
  const LoadingState({
    super.key,
    this.showLogo = true,
    this.message,
    this.subtitle,
  });

  /// Affiche le logo animé au-dessus de l'anneau.
  final bool showLogo;

  /// @deprecated Conservé pour compatibilité, non affiché.
  final String? message;

  /// @deprecated Conservé pour compatibilité, non affiché.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLogo) ...[
                const LoadingLogo(size: 80),
                const SizedBox(height: 20),
              ],
              const _OrbitSpinner(),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbitSpinner extends StatefulWidget {
  const _OrbitSpinner();

  @override
  State<_OrbitSpinner> createState() => _OrbitSpinnerState();
}

class _OrbitSpinnerState extends State<_OrbitSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer
                    .withValues(alpha: 0.45 - 0.2 * value),
              ),
            ),
            Transform.rotate(
              angle: _controller.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size.square(56),
                painter: _RingPainter(
                  color: scheme.primary,
                  accent: scheme.tertiary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color, required this.accent});

  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.25);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [accent, color, accent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      1.5 * math.pi,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accent != accent;
}