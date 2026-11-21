import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

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
    final onboardingDone = storage.getSetting('onboarding_done') == true;
    context.go(onboardingDone ? '/startup' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.legalNotice),
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
                    _buildIntroCard(scheme, l),
                    const SizedBox(height: 14),
                    _LegalSection(
                      title: l.serviceNature,
                      icon: Icons.play_circle_outline,
                      paragraphs: [
                        l.legalServicePlayer,
                        l.legalServiceMetadata,
                      ],
                    ),
                    const SizedBox(height: 10),
                    _LegalSection(
                      title: l.rightsHolders,
                      icon: Icons.copyright_outlined,
                      paragraphs: [
                        l.legalRightsProvider,
                        l.legalRightsMetadata,
                        l.legalRightsContent,
                      ],
                    ),
                    const SizedBox(height: 10),
                    _LegalSection(
                      title: l.legalUsageTitle,
                      icon: Icons.gavel_outlined,
                      paragraphs: [
                        l.legalUsageRights,
                        l.legalUsageRestrictions,
                        l.legalUsageEditorial,
                      ],
                    ),
                    const SizedBox(height: 10),
                    _LegalSection(
                      title: l.dataAndPrivacy,
                      icon: Icons.privacy_tip_outlined,
                      paragraphs: [
                        l.legalPrivacyStorage,
                        l.legalPrivacyConsent,
                      ],
                    ),
                    const SizedBox(height: 10),
                    _LegalSection(
                      title: l.legalWarningTitle,
                      icon: Icons.error_outline,
                      danger: true,
                      paragraphs: [
                        l.legalWarningBody,
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
                      label: Text(l.legalAccept),
                    )
                  : FilledButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(l.profileBack),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard(ColorScheme scheme, AppLocalizations l) {
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
                  l.legalIntroTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.legalIntro,
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
