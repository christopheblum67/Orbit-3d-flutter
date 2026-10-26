import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/services/refresh_steps_controller.dart';
import 'package:orbit_3d_flutter/core/services/startup_refresh_controller.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';

/// HUD de performance visible pendant le chargement (visible sur TV sans ADB).
///
/// Affiche en temps réel :
/// - Étape actuelle + temps écoulé
/// - Progression % + temps estimé restant
/// - État du cache (hit/miss, taille)
/// - Vitesse réseau estimée
class PerformanceHud extends ConsumerStatefulWidget {
  const PerformanceHud({
    super.key,
    this.enabled = true,
  });

  final bool enabled;

  @override
  ConsumerState<PerformanceHud> createState() => _PerformanceHudState();
}

class _PerformanceHudState extends ConsumerState<PerformanceHud> {
  Timer? _timer;
  DateTime? _stepStartTime;
  StartupStep? _lastStep;
  String? _lastStepName;
  int _bytesDownloaded = 0;
  int _lastBytes = 0;
  double _networkSpeedKbps = 0;

  // Historique des étapes pour affichage
  final List<_StepRecord> _stepHistory = [];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    final controller = ref.watch(startupRefreshControllerProvider);
    final currentStep = controller.currentStep;
    final percent = controller.percent;
    final isFinished = controller.isFinished;

    // Détection changement d'étape
    if (currentStep != _lastStep) {
      _onStepChanged(currentStep);
    }

    if (isFinished) {
      return const SizedBox.shrink(); // Cache le HUD quand fini
    }

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
              // Header
              Row(
                children: [
                  const Icon(Icons.speed, color: Color(0xFF00CFE8), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Performance HUD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Étape actuelle + temps
              _buildStepInfo(),
              const SizedBox(height: 8),

              // Progression + ETA
              _buildProgressEta(),
              const SizedBox(height: 8),

              // Historique étapes (scrollable)
              _buildStepHistory(),
              const SizedBox(height: 8),

              // Stats réseau
              _buildNetworkStats(),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildStepInfo() {
    final controller = ref.read(startupRefreshControllerProvider);
    final step = controller.currentStep;
    final elapsed = _stepStartTime != null
        ? DateTime.now().difference(_stepStartTime!)
        : Duration.zero;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getStepIcon(ref.read(startupRefreshControllerProvider).currentStep),
            color: const Color(0xFF00CFE8),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.read(startupRefreshControllerProvider).currentStep?.label ?? 'En attente...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Écoulé: ${_formatDuration(ref.read(startupRefreshControllerProvider).currentStep != null ? DateTime.now().difference(_stepStartTime ?? DateTime.now()) : Duration.zero)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Indicateur cache
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getCacheColor(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getCacheLabel(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

  Widget _buildProgressEta() {
    final controller = ref.read(startupRefreshControllerProvider);
    final percent = controller.percent;
    final elapsed = DateTime.now().difference(_bootStartTime);
    final eta = percent > 0 && percent < 100
        ? Duration(milliseconds: (elapsed.inMilliseconds * (100 - percent) / percent).round())
        : Duration.zero;

    return Row(
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
              const SizedBox(height: 2),
              LinearProgressIndicator(
                value: percent / 100,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF00CFE8)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Écoulé: ${_formatDuration(elapsed)}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
            ),
            Text(
              'Restant: ~${_formatDuration(eta)}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepHistory() {
    if (_stepHistory.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _stepHistory.length,
        itemBuilder: (context, index) {
          final record = _stepHistory[index];
          final isCurrent = record.step == ref.read(startupRefreshControllerProvider).currentStep;
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrent
                  ? const Color(0xFF00CFE8).withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
              border: isCurrent
                  ? Border.all(color: const Color(0xFF00CFE8), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  _getStepIcon(record.step),
                  size: 14,
                  color: isCurrent ? const Color(0xFF00CFE8) : Colors.white54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record.step.label,
                    style: TextStyle(
                      color: isCurrent ? Colors.white : Colors.white70,
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                Text(
                  _formatDuration(record.duration),
                  style: TextStyle(
                    color: isCurrent ? const Color(0xFF00CFE8) : Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (record.cacheHit != null)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: record.cacheHit! ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      record.cacheHit! ? 'CACHE HIT' : 'CACHE MISS',
                      style: TextStyle(
                        color: record.cacheHit! ? Colors.green : Colors.orange,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNetworkStats() {
    return Row(
      children: [
        _buildStatChip(
          'Vitesse',
          '${_networkSpeedKbps.toStringAsFixed(0)} KB/s',
          Icons.download,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          'Téléchargé',
          _formatBytes(_bytesDownloaded),
          Icons.cloud_download,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          'Cache',
          _getCacheLabel(),
          Icons.storage,
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white54),
            const SizedBox(width: 4),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.white38, fontSize: 8),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

  Color _getCacheColor() {
    // À adapter selon l'état réel du cache
    return Colors.green.withValues(alpha: 0.3);
  }

  String _getCacheLabel() {
    // À connecter au vrai état du cache
    return 'CACHE: PRÊT';
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
      default:
        return Icons.hourglass_empty;
    }
  }

  String _getCacheLabel() {
    // À connecter au vrai état
    return 'CACHE: PRÊT';
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    if (mins > 0) {
      return '${mins}m ${secs}s';
    }
    return '${secs}s';
  }

  void _onStepChanged(StartupStep? step) {
    if (step == _lastStep) return;

    final now = DateTime.now();
    if (_lastStep != null && _stepStartTime != null) {
      final duration = now.difference(_stepStartTime!);
      _stepHistory.add(_StepRecord(
        step: _lastStep!,
        duration: duration,
        cacheHit: _checkCacheHit(_lastStep!),
      ));
    }
    _lastStep = step;
    _stepStartTime = now;
    _lastStepName = step?.label;
  }

  bool _checkCacheHit(StartupStep step) {
    // À implémenter selon la logique de cache réelle
    return false;
  }

  DateTime _bootStartTime = DateTime.now();
}

class _StepRecord {
  _StepRecord({
    required this.step,
    required this.duration,
    required this.cacheHit,
  });

  final StartupStep step;
  final Duration duration;
  final bool? cacheHit;
}