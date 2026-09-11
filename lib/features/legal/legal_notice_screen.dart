import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Clé de réglage : mentions légales acceptées au premier lancement.
const kLegalNoticeDoneKey = 'legal_notice_seen';

/// Écran « Lisez-moi » : usage de l'application et ayants droit.
///
/// Affiche un résumé des mentions légales (lib/../LEGAL_README.md) : nature du
/// service (lecteur IPTV, aucun hébergement), responsabilité éditoriale,
/// registre des droits (TMDb, lieux, synopsis) et avertissement utilisateur.
///
/// - [firstLaunch] : affiché au démarrage (bouton « J'ai compris et j'accepte »
///   qui bascule le flag [kLegalNoticeDoneKey]), sinon mode consultation.
class LegalNoticeScreen extends ConsumerStatefulWidget {
  const LegalNoticeScreen({super.key, this.firstLaunch = false});

  /// `true` au premier lancement (validation obligatoire avant de continuer).
  final bool firstLaunch;

  @override
  ConsumerState<LegalNoticeScreen> createState() => _LegalNoticeScreenState();
}

class _LegalNoticeScreenState extends ConsumerState<LegalNoticeScreen> {
  bool _accepted = false;

  Future<void> _accept() async {
    if (_accepted) return;
    setState(() => _accepted = true);
    final storage = ref.read(storageServiceProvider);
    await storage.setSetting(kLegalNoticeDoneKey, true);
    if (!mounted) return;
    final onboardingDone =
        storage.getSetting('onboarding_done') == true;
    context.go(onboardingDone ? '/startup' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lisez-moi · Mentions légales'),
        leading: widget.firstLaunch
            ? null
            : BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildIntroCard(scheme),
                    const SizedBox(height: 14),
                    const _LegalSection(
                      title: 'Nature du service',
                      icon: Icons.play_circle_outline,
                      paragraphs: [
                        'Orbit IPTV est un lecteur IPTV : il affiche des flux '
                            'fournis par des serveurs tiers (abonnement M3U / '
                            'Xtream Codes) sans héberger aucun contenu vidéo, '
                            'audio ou sous-titre.',
                        'Il agrège et présente des métadonnées (affiches, '
                            'synopsis, EPG) récupérées via des API publiques. '
                            'Il fonctionne comme un navigateur spécialisé pour '
                            'les flux HLS/DASH.',
                      ],
                    ),
                    const SizedBox(height: 10),
                    const _LegalSection(
                      title: 'Ayants droit',
                      icon: Icons.copyright_outlined,
                      paragraphs: [
                        'Le fournisseur d\'abonnement IPTV est seul responsable '
                            'des licences des chaînes, des droits de diffusion '
                            'et du géoblocage des flux qu\'il fournit.',
                        'Les affiches et synopsis proviennent de TMDb sous '
                            'licence API ; l\'attribution TMDb est affichée en '
                            'bas de page des classements.',
                        'Orbit IPTV ne stocke, ne redistribue et ne monétise '
                            'aucun contenu diffusé.',
                      ],
                    ),
                    const SizedBox(height: 10),
                    const _LegalSection(
                      title: 'Usage de l\'application',
                      icon: Icons.gavel_outlined,
                      paragraphs: [
                        'À utiliser uniquement avec un abonnement dont vous '
                            'détenez les droits de diffusion.',
                        'Interdiction de contourner le géoblocage ou les DRM, '
                            'et de partager son compte hors du foyer.',
                        'L\'application ne fait aucune sélection éditoriale du '
                            'contenu diffusé : aucun contrôle sur les flux des '
                            'serveurs tiers.',
                      ],
                    ),
                    const SizedBox(height: 10),
                    const _LegalSection(
                      title: 'Données & confidentialité',
                      icon: Icons.privacy_tip_outlined,
                      paragraphs: [
                        'Profil, favoris, historique et réglages sont stockés '
                            'localement sur l\'appareil (Hive), jamais transmis.',
                        'Aucune collecte par défaut : notifications et accès '
                            'optionnels font l\'objet d\'un consentement '
                            'explicite.',
                      ],
                    ),
                    const SizedBox(height: 10),
                    const _LegalSection(
                      title: 'Avertissement',
                      icon: Icons.error_outline,
                      danger: true,
                      paragraphs: [
                        'Ce document ne constitue pas un conseil juridique. '
                            'Les règles varient selon les juridictions : '
                            'vérifiez que votre usage est autorisé dans votre '
                            'pays (loi applicable, âge minimum).',
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: widget.firstLaunch
                  ? FilledButton.icon(
                      onPressed: _accepted ? null : _accept,
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text(
                          'J\'ai lu et j\'accepte · Continuer',
                        ),
                    )
                  : FilledButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Retour'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard(ColorScheme scheme) {
    return AppCard(
      color: scheme.primaryContainer.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.balance_outlined, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Orbit IPTV · Lisez-moi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bonjour ! Avant de commencer, quelques informations courtes sur '
            'l\'usage de cette application et les droits associés aux '
            'contenus affichés.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// Section d'informations légales avec titre, icône et paragraphes.
class _LegalSection extends StatelessWidget {
  const _LegalSection({
    required this.title,
    required this.icon,
    required this.paragraphs,
    this.danger = false,
  });

  final String title;
  final IconData icon;
  final List<String> paragraphs;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = danger ? scheme.error : scheme.primary;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final paragraph in paragraphs) ...[
            Text(
              paragraph,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}