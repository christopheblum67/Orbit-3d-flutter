import 'package:flutter/material.dart';
import 'app_card.dart';

class VideoLoadingState extends StatelessWidget {
  const VideoLoadingState({super.key, this.message = 'Chargement du flux…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _PulsingSpinner(),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Un instant, on prépare ta chaîne…',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingSpinner extends StatefulWidget {
  const _PulsingSpinner();

  @override
  State<_PulsingSpinner> createState() => _PulsingSpinnerState();
}

class _PulsingSpinnerState extends State<_PulsingSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
        final scale = 0.85 + 0.15 * value;
        final opacity = 0.55 + 0.45 * value;
        final angle = value * 2 * 3.14159;
        return Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.primary, scheme.tertiary],
                  ),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 34,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
