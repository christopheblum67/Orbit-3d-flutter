import 'dart:async';

import 'package:flutter/material.dart';

class OrbitLoadingCinematic extends StatefulWidget {
  const OrbitLoadingCinematic({super.key, this.showBanner = true});

  final bool showBanner;

  @override
  State<OrbitLoadingCinematic> createState() => _OrbitLoadingCinematicState();
}

class _OrbitLoadingCinematicState extends State<OrbitLoadingCinematic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'ORBIT IPTV',
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 270,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showBanner)
                  Image.asset(
                    'assets/icons/orbit_loading_banner.jpg',
                    width: 270,
                    height: 90,
                    fit: BoxFit.contain,
                    semanticLabel: 'ORBIT IPTV',
                  ),
                if (widget.showBanner) const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final elapsed = _controller.value * 3500;
                    final blinkOff = (elapsed >= 1900 && elapsed < 2100) ||
                        (elapsed >= 2500 && elapsed < 2700);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < 5; i++)
                          Opacity(
                            key: ValueKey('orbit-letter-$i'),
                            opacity: reducedMotion ||
                                    (elapsed >= i * 250 && !blinkOff)
                                ? 1
                                : 0,
                            child: Text(
                              'ORBIT'[i],
                              style: const TextStyle(
                                color: Color(0xFF00CFE8),
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 10,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OrbitDelayedLoadingIndicator extends StatefulWidget {
  const OrbitDelayedLoadingIndicator({
    super.key,
    this.delay = const Duration(seconds: 2),
    this.initialChild = const CircularProgressIndicator(),
  });

  final Duration delay;
  final Widget initialChild;

  @override
  State<OrbitDelayedLoadingIndicator> createState() =>
      _OrbitDelayedLoadingIndicatorState();
}

class _OrbitDelayedLoadingIndicatorState
    extends State<OrbitDelayedLoadingIndicator> {
  Timer? _timer;
  bool _showCinematic = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _showCinematic = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _showCinematic ? const OrbitLoadingCinematic() : widget.initialChild;
}
