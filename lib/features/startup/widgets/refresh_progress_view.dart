import 'package:flutter/material.dart';

import 'package:orbit_3d_flutter/core/services/refresh_steps_controller.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Écran de régénération des flux : nom de l'application, état, et progression
/// des **sections d'abonnement** (Chaînes TV / Films & VOD / Séries / EPG).
///
/// Partagé par le démarrage ([StartupSplashScreen]) et le rafraîchissement à la
/// demande (`RefreshProgressScreen`) : l'utilisateur voit EXACTEMENT le même
/// écran, qu'il arrive au lancement (données > 30 min) ou via « Mettre à jour ».
///
/// ## Adaptatif portrait / paysage
///
/// En paysage (ou sur écran large) le branding et la progression sont côte à
/// côte ; en portrait ils sont empilés. La mise en page vit dans un
/// [SingleChildScrollView] pour ne jamais déborder sur un écran bas (TV, pli
/// vertical) — un `Column` nu aurait provoqué un overflow sur ces appareils.
class RefreshProgressView extends StatelessWidget {
  const RefreshProgressView({
    super.key,
    required this.percent,
    required this.currentStep,
    required this.doneSteps,
    required this.isFinished,
    this.title,
    this.visibleSteps,
    this.showBranding = true,
    this.failureMessage,
    this.onOpenSubscriptions,
  });

  final int percent;
  final StartupStep? currentStep;
  final Set<StartupStep> doneSteps;
  final bool isFinished;

  /// Remplace le texte d'état par défaut (« Mise à jour du contenu multimédia
  /// en cours… »). Ignoré quand [isFinished].
  final String? title;

  /// Sections displayed in this phase; defaults to the standard catalog set.
  final List<StartupStep>? visibleSteps;

  /// Affiche le logo + le nom de l'application au-dessus de la progression.
  final bool showBranding;

  /// Explains why progress appears stalled and offers a route back to subscriptions.
  final String? failureMessage;
  final VoidCallback? onOpenSubscriptions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // « Paysage » = plus large que haut ET assez large pour deux colonnes.
        // En dessous de 720 px de large, deux colonnes tasseraient le texte.
        final wide = constraints.maxWidth >= 720 &&
            constraints.maxWidth > constraints.maxHeight;
        final branding = _buildBranding();
        final progress = _buildProgress(l);

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: branding),
                        const SizedBox(width: 56),
                        Expanded(child: progress),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        branding,
                        const SizedBox(height: 36),
                        progress,
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBranding() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showBranding) ...[
          Image.asset(
            'assets/icons/orbit_loading_banner.jpg',
            width: 270,
            height: 90,
            fit: BoxFit.contain,
            semanticLabel: 'ORBIT IPTV',
          ),
        ],
      ],
    );
  }

  Widget _buildProgress(AppLocalizations l) {
    final visibleSteps = this.visibleSteps ??
        const [
          StartupStep.live,
          StartupStep.movies,
          StartupStep.series,
          StartupStep.epg,
        ];
    final sections = visibleSteps.map((step) {
      final (icon, label) = switch (step) {
        StartupStep.live => (Icons.live_tv, 'Chaînes TV'),
        StartupStep.movies => (Icons.movie_outlined, 'Films & VOD'),
        StartupStep.series => (Icons.video_library_outlined, l.series),
        StartupStep.radio => (Icons.radio, 'Radios'),
        StartupStep.replay => (Icons.replay_circle_filled, 'Replay'),
        StartupStep.epg => (Icons.receipt_long_outlined, 'EPG'),
        StartupStep.ai => (Icons.recommend, 'Recommandations'),
      };
      return _ProgressIcon(
        icon: icon,
        label: label,
        done: doneSteps.contains(step),
        active: currentStep == step,
      );
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ligne mini-icônes (état de chaque section)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: sections.map(_buildMiniIcon).toList(),
        ),
        const SizedBox(height: 14),
        Text(
          failureMessage ??
              (isFinished ? 'Prêt !' : (title ?? l.updatingMediaContent)),
          textAlign: TextAlign.center,
          style: TextStyle(
            color:
                failureMessage == null ? Colors.white70 : Colors.orangeAccent,
            fontSize: 14,
          ),
        ),
        if (failureMessage != null && onOpenSubscriptions != null) ...[
          const SizedBox(height: 16),
          TvFocus(
            autofocus: true,
            onActivate: onOpenSubscriptions,
            child: OutlinedButton.icon(
              onPressed: onOpenSubscriptions,
              icon: const Icon(Icons.settings_ethernet),
              label: const Text('Vérifier l’abonnement'),
            ),
          ),
        ],
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 10,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00CFE8)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                isFinished ? '' : (currentStep?.label ?? ''),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$percent %',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniIcon(_ProgressIcon icon) {
    final isDone = icon.done;
    final isActive = icon.active;
    final color = isDone
        ? const Color(0xFF00CFE8)
        : isActive
            ? const Color(0xFF8B5CF6)
            : Colors.white24;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDone ? 0.2 : 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: isActive ? 2 : (isDone ? 1.5 : 1),
            ),
          ),
          child: Icon(icon.icon, size: 18, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          icon.label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight:
                isDone || isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/// Donnée pour l'affichage d'une mini-icône de progression.
class _ProgressIcon {
  _ProgressIcon({
    required this.icon,
    required this.label,
    required this.done,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool done;
  final bool active;
}
