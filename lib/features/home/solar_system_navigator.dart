import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_3d_flutter/features/home/solar_system_controller.dart';
import 'package:orbit_3d_flutter/features/home/orbit_planet_widget.dart';

final solarSystemControllerProvider = ChangeNotifierProvider<SolarSystemController>(
  (ref) => SolarSystemController(),
);

class SolarSystemNavigator extends ConsumerStatefulWidget {
  const SolarSystemNavigator({super.key});

  @override
  ConsumerState<SolarSystemNavigator> createState() => _SolarSystemNavigatorState();
}

class _SolarSystemNavigatorState extends ConsumerState<SolarSystemNavigator>
    with WidgetsBindingObserver {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(solarSystemControllerProvider);
    final isZoomedIn = controller.isZoomedIn;
    final currentOrbit = controller.currentOrbit;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        controller.handleKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF0E1117),
              Color(0xFF0A0C10),
              Color(0xFF050608),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildBackgroundStars(),
            _buildOrbitRings(controller),
            _buildPlanets(controller),
            if (currentOrbit == SolarOrbit.sun && !isZoomedIn) _buildSunLabel(),
            if (isZoomedIn) _buildOrbitInfo(controller),
            _buildNavigationHints(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundStars() {
    return CustomPaint(
      size: Size.infinite,
      painter: _StarsPainter(),
    );
  }

  Widget _buildOrbitRings(SolarSystemController controller) {
    return Stack(
      alignment: Alignment.center,
      children: SolarOrbit.values
          .where((orbit) => orbit != SolarOrbit.sun)
          .map((orbit) {
        final isActive = controller.isZoomedIn && controller.currentOrbit == orbit;
        final color = _getOrbitColor(orbit);
        return Opacity(
          opacity: isActive ? 1.0 : 0.4,
          child: OrbitRingWidget(
            radius: controller.getOrbitRadius(orbit),
            color: color,
            strokeWidth: isActive ? 2.5 : 1.5,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlanets(SolarSystemController controller) {
    final isZoomedIn = controller.isZoomedIn;
    final currentOrbit = controller.currentOrbit;

    return Stack(
      alignment: Alignment.center,
      children: [
        _buildBodyAtOrbit(controller, SolarOrbit.sun, 0),
        if (!isZoomedIn || currentOrbit == SolarOrbit.innerPlanets)
          ...List.generate(4, (i) =>
              _buildBodyAtOrbit(controller, SolarOrbit.innerPlanets, i),),
        if (!isZoomedIn || currentOrbit == SolarOrbit.outerPlanets)
          ...List.generate(4, (i) =>
              _buildBodyAtOrbit(controller, SolarOrbit.outerPlanets, i),),
        if (!isZoomedIn || currentOrbit == SolarOrbit.asteroidBelt)
          ...List.generate(3, (i) =>
              _buildBodyAtOrbit(controller, SolarOrbit.asteroidBelt, i),),
        if (!isZoomedIn || currentOrbit == SolarOrbit.comets)
          ...List.generate(3, (i) =>
              _buildBodyAtOrbit(controller, SolarOrbit.comets, i),),
      ],
    );
  }

  Widget _buildBodyAtOrbit(
    SolarSystemController controller,
    SolarOrbit orbit,
    int index,
  ) {
    final body = _getBodyAtOrbit(orbit, index);
    final isFocused = controller.isZoomedIn &&
        controller.currentOrbit == orbit &&
        controller.focusedIndex == index;
    final radius = controller.getOrbitRadius(orbit);
    final count = controller.getBodyCountForOrbit(orbit);
    final baseAngle = (index / count) * 2 * math.pi - math.pi / 2;

    return OrbitPlanetWidget(
      key: ValueKey(body),
      body: body,
      isFocused: isFocused,
      isZoomedIn: controller.isZoomedIn,
      orbitRadius: radius,
      baseAngle: baseAngle,
      controller: controller,
      onTap: () => _onBodyTap(context, controller, body),
    );
  }

  SolarBody _getBodyAtOrbit(SolarOrbit orbit, int index) {
    switch (orbit) {
      case SolarOrbit.sun:
        return SolarBody.sun;
      case SolarOrbit.innerPlanets:
        return SolarBody.values[1 + index];
      case SolarOrbit.outerPlanets:
        return SolarBody.values[5 + index];
      case SolarOrbit.asteroidBelt:
        return SolarBody.values[9 + index];
      case SolarOrbit.comets:
        return SolarBody.values[12 + index];
    }
  }

  Color _getOrbitColor(SolarOrbit orbit) {
    switch (orbit) {
      case SolarOrbit.sun:
        return const Color(0xFFFFD700);
      case SolarOrbit.innerPlanets:
        return const Color(0xFF8A72FF);
      case SolarOrbit.outerPlanets:
        return const Color(0xFF4CAF50);
      case SolarOrbit.asteroidBelt:
        return const Color(0xFFFFB300);
      case SolarOrbit.comets:
        return const Color(0xFF8B5CF6);
    }
  }

  Widget _buildSunLabel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: const Text(
            'LIVE TV',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Appuyez sur OK pour explorer',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildOrbitInfo(SolarSystemController controller) {
    final orbit = controller.currentOrbit;
    final body = controller.focusedBody;
    final color = controller.getColorForBody(body);
    final label = controller.getLabelForBody(body);

    String orbitName;
    switch (orbit) {
      case SolarOrbit.innerPlanets:
        orbitName = 'VOD / FILMS';
        break;
      case SolarOrbit.outerPlanets:
        orbitName = 'SÉRIES';
        break;
      case SolarOrbit.asteroidBelt:
        orbitName = 'REPLAY / CATCH-UP';
        break;
      case SolarOrbit.comets:
        orbitName = 'RADIO / FAVORIS';
        break;
      default:
        orbitName = '';
    }

    return Positioned(
      bottom: 120,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Text(
              orbitName,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E222D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationHints(SolarSystemController controller) {
    final isZoomedIn = controller.isZoomedIn;

    return Positioned(
      bottom: 30,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isZoomedIn) ...[
            _buildHint(Icons.keyboard_arrow_up, '↑', 'Orbite sup.'),
            const SizedBox(width: 24),
            _buildHint(Icons.keyboard_arrow_down, '↓', 'Orbite inf.'),
            const SizedBox(width: 24),
            _buildHint(Icons.radio_button_checked, 'OK', 'Explorer'),
          ] else ...[
            _buildHint(Icons.keyboard_arrow_left, '←', 'Précédent'),
            const SizedBox(width: 24),
            _buildHint(Icons.keyboard_arrow_right, '→', 'Suivant'),
            const SizedBox(width: 24),
            _buildHint(Icons.play_circle, 'OK', 'Lancer'),
            const SizedBox(width: 24),
            _buildHint(Icons.arrow_back, 'Retour', 'Zoom out'),
          ],
        ],
      ),
    );
  }

  Widget _buildHint(IconData icon, String key, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Text(
            key,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _onBodyTap(BuildContext context, SolarSystemController controller, SolarBody body) {
    if (!controller.isZoomedIn) {
      if (body == SolarBody.sun) {
        controller.handleKeyEvent(KeyDownEvent(
          logicalKey: LogicalKeyboardKey.enter,
          physicalKey: PhysicalKeyboardKey.enter,
          character: '\r',
          timeStamp: Duration.zero,
        ),);
      }
      return;
    }

    final route = controller.getRouteForBody(body);
    if (route != '/home') {
      context.go(route);
    }
  }
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.6);

    for (int i = 0; i < 200; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.3;
      final opacity = random.nextDouble() * 0.5 + 0.2;

      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1.5;
      final opacity = random.nextDouble() * 0.3 + 0.1;

      paint.color = const Color(0xFF8B5CF6).withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}