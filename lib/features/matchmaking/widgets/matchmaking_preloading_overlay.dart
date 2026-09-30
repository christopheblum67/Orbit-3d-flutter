import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// État du préchargement Matchmaking.
enum MatchmakingPreloadStep {
  initialising,
  loading,
  ready,
  error,
  cancelled,
}

/// Widget d'overlay de préchargement Matchmaking.
/// Affiche le progrès en étapes avec chronomètre et bouton d'annulation.
class MatchmakingPreloadingOverlay extends ConsumerWidget {
  const MatchmakingPreloadingOverlay({
    super.key,
    required this.step,
    required this.elapsed,
    this.onCancel,
  });

  final MatchmakingPreloadStep step;
  final Duration elapsed;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Texte par étape
    final stepLabel = switch (step) {
      MatchmakingPreloadStep.initialising => l.matchmakingInitialising,
      MatchmakingPreloadStep.loading => l.matchmakingLoading,
      MatchmakingPreloadStep.ready => l.matchmakingReady,
      MatchmakingPreloadStep.error => l.matchmakingError,
      MatchmakingPreloadStep.cancelled => l.matchmakingCancelled,
    };

    // Icône par étape
    final icon = switch (step) {
      MatchmakingPreloadStep.initialising => Icons.schedule,
      MatchmakingPreloadStep.loading => Icons.cloud_download,
      MatchmakingPreloadStep.ready => Icons.check_circle,
      MatchmakingPreloadStep.error => Icons.error,
      MatchmakingPreloadStep.cancelled => Icons.cancel,
    };

    // Bouton d'annulation visible sauf à l'étape ready/cancelled
    final showCancel = step != MatchmakingPreloadStep.ready &&
        step != MatchmakingPreloadStep.cancelled;

    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône + titre
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Icon(icon, size: 48, color: theme.colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      stepLabel,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Chronomètre
              Container(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  _formatDuration(elapsed),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Barre de progression (optionnelle)
              LinearProgressIndicator(
                value: _stepProgress(step),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),

              // Bouton d'annulation
              if (showCancel) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onCancel,
                  child: Text(l.cancel),
                ),
              ],

              // Bouton OK (visible uniquement à l'étape ready)
              if (step == MatchmakingPreloadStep.ready) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    // Masquer l'overlay, la screen principale continuera
                    // Note: la gestion de la visibilité incombe au parent
                  },
                  child: Text(l.start),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _stepProgress(MatchmakingPreloadStep step) {
    // Progression simplifiée par étape
    return switch (step) {
      MatchmakingPreloadStep.initialising => 0.1,
      MatchmakingPreloadStep.loading => 0.5,
      MatchmakingPreloadStep.ready => 1.0,
      MatchmakingPreloadStep.error => 0.8,
      MatchmakingPreloadStep.cancelled => 0.6,
    };
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${d.inHours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

/// Définition des clés de localisation utilisées par l'overlay.
extension MatchmakingPreloadLocalization on AppLocalizations {
  String get matchmakingInitialising =>
      'Initialisation du matchmaking…';
  String get matchmakingLoading => 'Chargement des recommandations…';
  String get matchmakingReady => 'Prêt';
  String get matchmakingError => 'Erreur de chargement';
  String get matchmakingCancelled => 'Annulé';
  String get cancel => 'Annuler';
  String get start => 'Démarrer';
}