import 'dart:async';

import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/services/refresh_steps_controller.dart';

/// HUD facultatif pour observer un rafraîchissement depuis un [Stack].
///
/// Le propriétaire conserve et détruit [controller]. Les mesures réseau et
/// cache ne sont pas exposées par ce contrôleur et restent donc indisponibles.
class PerformanceHud extends StatefulWidget {
  const PerformanceHud({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  final RefreshStepsController controller;
  final bool enabled;

  @override
  State<PerformanceHud> createState() => _PerformanceHudState();
}

class _PerformanceHudState extends State<PerformanceHud> {
  Timer? _timer;
  final Stopwatch _elapsed = Stopwatch();
  final Stopwatch _stepElapsed = Stopwatch();
  StartupStep? _lastStep;
  final List<_StepRecord> _stepHistory = [];

  @override
  void initState() {
    super.initState();
    _attachController();
  }

  void _attachController() {
    _elapsed
      ..reset()
      ..start();
    _stepElapsed
      ..reset()
      ..stop();
    _stepHistory.clear();
    _lastStep = widget.controller.currentStep;
    if (_lastStep != null) _stepElapsed.start();
    widget.controller.addListener(_onProgress);
    _updateTimer();
  }

  @override
  void didUpdateWidget(covariant PerformanceHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onProgress);
      _attachController();
    } else if (oldWidget.enabled != widget.enabled) {
      _updateTimer();
    }
  }

  void _updateTimer() {
    _timer?.cancel();
    _timer = null;
    if (widget.enabled && !widget.controller.isFinished) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _onProgress() {
    final step = widget.controller.currentStep;
    if (step != _lastStep) {
      if (_lastStep != null) {
        _stepHistory.add(_StepRecord(_lastStep!, _stepElapsed.elapsed));
      }
      _lastStep = step;
      _stepElapsed
        ..reset()
        ..stop();
      if (step != null) _stepElapsed.start();
    }
    if (widget.controller.isFinished) {
      _elapsed.stop();
      _updateTimer();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller.removeListener(_onProgress);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.controller.isFinished) {
      return const SizedBox.shrink();
    }
    final step = widget.controller.currentStep;
    final percent = widget.controller.percent;
    final elapsed = _elapsed.elapsed;
    final eta = percent > 0 && percent < 100
        ? Duration(
            milliseconds:
                (elapsed.inMilliseconds * (100 - percent) / percent).round(),
          )
        : null;

    return Positioned(
      top: 40,
      right: 20,
      left: 20,
      child: Material(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.speed, color: Color(0xFF00CFE8), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Performance HUD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _getStepIcon(step),
                    color: const Color(0xFF00CFE8),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step?.label ?? 'En attente...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Étape : ${_formatDuration(_stepElapsed.elapsed)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            color: Color(0xFF00CFE8),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        LinearProgressIndicator(value: percent / 100),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Écoulé : ${_formatDuration(elapsed)}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11,),
                      ),
                      Text(
                        'Restant : ${eta == null ? '—' : '~${_formatDuration(eta)}'}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11,),
                      ),
                    ],
                  ),
                ],
              ),
              if (_stepHistory.isNotEmpty) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _stepHistory.length,
                    itemBuilder: (context, index) {
                      final record = _stepHistory[index];
                      return Row(
                        children: [
                          Icon(
                            _getStepIcon(record.step),
                            size: 14,
                            color: Colors.white54,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              record.step.label,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            _formatDuration(record.duration),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'Réseau et cache : données indisponibles',
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStepIcon(StartupStep? step) {
    switch (step) {
      case StartupStep.live:
        return Icons.live_tv;
      case StartupStep.movies:
        return Icons.movie_outlined;
      case StartupStep.series:
        return Icons.video_library_outlined;
      case StartupStep.radio:
        return Icons.radio;
      case StartupStep.replay:
        return Icons.replay;
      case StartupStep.epg:
        return Icons.receipt_long_outlined;
      case StartupStep.ai:
        return Icons.psychology;
      case null:
        return Icons.hourglass_empty;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
  }
}

class _StepRecord {
  const _StepRecord(this.step, this.duration);

  final StartupStep step;
  final Duration duration;
}
