import 'package:flutter/material.dart';

import 'package:orbit_3d_flutter/core/services/refresh_steps_controller.dart';
import 'package:orbit_3d_flutter/core/widgets/orbit_logo_icon.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Clé globale pour préserver l'état du logo animé à travers les reconstructions.
final GlobalKey<_LoadingLogoState> _loadingLogoKey = GlobalKey<_LoadingLogoState>();

/// Logo Orbit avec animation complète :
/// - Logo plus grand
/// - "Orbit " fixe, "IPTV" lettres apparaissent séquentiellement
/// - "IPTV" clignote ensuite
/// - Animation en boucle
class LoadingLogo extends StatefulWidget {
  const LoadingLogo({super.key, this.size = 180});

  final double size;

  @override
  State<LoadingLogo> createState() => _LoadingLogoState();
}

class _LoadingLogoState extends State<LoadingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Phases de l'animation (durée totale ~4s) :
  // 0.0-0.3 : scale pulse
  // 0.3-0.55 : "I" apparaît
  // 0.55-0.7 : "P" apparaît
  // 0.7-0.85 : "T" apparaît
  // 0.85-0.95 : "V" apparaît
  // 0.95-1.0 : "IPTV" clignote 2x
  // puis boucle

  static const _totalDuration = Duration(milliseconds: 4000);

  late final Animation<double> _scale;
  late final List<Animation<double>> _letterOpacities;
  late final Animation<double> _blink;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: _totalDuration,
      vsync: this,
    )..repeat();

    _scale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    // 4 lettres IPTV - chaque apparition dure ~15% de la durée
    _letterOpacities = List.generate(4, (i) {
      final start = 0.30 + i * 0.12; // 0.30, 0.42, 0.54, 0.66
      final end = start + 0.15;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    // Clignotement IPTV : 2 flashs entre 0.95 et 1.0
    _blink = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.95, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final scale = _scale.value;
        final iptvVisible = _blink.value > 0.5 || _ctrl.value < 0.95;

        return Transform.scale(
          scale: scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OrbitLogoIcon(
                size: widget.size,
                glow: true,
              ),
              const SizedBox(height: 24),
              // "Orbit IPTV" avec animation lettres
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Orbit ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.size * 0.28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  // I P T V - chaque lettre avec son opacité
                  ...List.generate(4, (i) {
                    final letters = ['I', 'P', 'T', 'V'];
                    final opacity = iptvVisible ? _letterOpacities[i].value : 0.0;
                    return AnimatedOpacity(
                      opacity: opacity,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        letters[i],
                        style: TextStyle(
                          color: const Color(0xFF00CFE8),
                          fontSize: widget.size * 0.28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

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
    this.showBranding = true,
  });

  final int percent;
  final StartupStep? currentStep;
  final Set<StartupStep> doneSteps;
  final bool isFinished;

  /// Remplace le texte d'état par défaut (« Mise à jour du contenu multimédia
  /// en cours… »). Ignoré quand [isFinished].
  final String? title;

  /// Affiche le logo + le nom de l'application au-dessus de la progression.
  final bool showBranding;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // « Paysage » = plus large que haut ET assez large pour deux colonnes.
        // En dessous de 720 px de large, deux colonnes tasseraient le texte.
        final wide = constraints.maxWidth >= 720 &&
            constraints.maxWidth > constraints.maxHeight;
        final branding = _buildBranding(l);
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

  Widget _buildBranding(AppLocalizations l) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showBranding) ...[
          LoadingLogo(key: _loadingLogoKey, size: 180),
          const SizedBox(height: 32),
        ],
      ],
    );
  }

  Widget _buildProgress(AppLocalizations l) {
    // Mini-icônes thématiques des sections d'abonnement : Live / Films / Séries / EPG
    final sections = [
      _ProgressIcon(
        icon: Icons.live_tv,
        label: 'Chaînes TV',
        done: doneSteps.contains(StartupStep.live),
        active: currentStep == StartupStep.live,
      ),
      _ProgressIcon(
        icon: Icons.movie_outlined,
        label: 'Films & VOD',
        done: doneSteps.contains(StartupStep.movies),
        active: currentStep == StartupStep.movies,
      ),
      _ProgressIcon(
        icon: Icons.video_library_outlined,
        label: l.series,
        done: doneSteps.contains(StartupStep.series),
        active: currentStep == StartupStep.series,
      ),
      _ProgressIcon(
        icon: Icons.receipt_long_outlined,
        label: 'EPG',
        done: doneSteps.contains(StartupStep.epg),
        active: currentStep == StartupStep.epg,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ligne mini-icônes (état de chaque section)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: sections.map(_buildMiniIcon).toList(),
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 10,
            backgroundColor: Colors.white12,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF00CFE8)),
          ),
        ),
        const SizedBox(height: 16),
        // Texte de chargement APRÈS les icônes et la barre de progression
        Text(
          isFinished ? 'Prêt !' : (title ?? l.updatingMediaContent),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
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
