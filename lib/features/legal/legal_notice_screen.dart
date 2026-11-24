import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/config/startup_config.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_safe_area.dart';
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
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _back() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/settings');
    }
  }

  KeyEventResult _scrollWithRemote(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.pageDown => 1,
      LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.pageUp => -1,
      _ => 0,
    };
    if (direction == 0 || !_scrollController.hasClients) {
      return KeyEventResult.ignored;
    }
    final position = _scrollController.position;
    final page = event.logicalKey == LogicalKeyboardKey.pageDown ||
        event.logicalKey == LogicalKeyboardKey.pageUp;
    final distance = page ? position.viewportDimension * 0.8 : 80.0;
    final target = (position.pixels + direction * distance)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    _scrollController.jumpTo(target);
    return KeyEventResult.handled;
  }

  Future<void> _accept() async {
    if (_accepted) return;
    setState(() => _accepted = true);
    final storage = ref.read(storageServiceProvider);
    await storage.setSetting(kLegalNoticeDoneKey, true);
    if (!mounted) return;
    final onboardingDone = storage.getSetting('onboarding_done') == true;
    context.go(
      onboardingDone
          ? (kCacheFirstStartup ? '/profiles' : '/startup')
          : '/onboarding',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.contactLegal),
        leading: widget.firstLaunch ? null : BackButton(onPressed: _back),
      ),
      body: TvSafeArea(
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: _scrollWithRemote,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    key: const ValueKey('legal-document-scroll'),
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Container(
                          key: const ValueKey('legal-document'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 28,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLowest,
                            border: Border.all(color: scheme.outlineVariant),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l.legalIntroTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: scheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l.legalIntro,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: scheme.onSurface,
                                      height: 1.55,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              Divider(color: scheme.outlineVariant),
                              _LegalSection(
                                title: l.serviceNature,
                                paragraphs: [
                                  l.legalServicePlayer,
                                  l.legalServiceMetadata,
                                ],
                              ),
                              _LegalSection(
                                title: l.rightsHolders,
                                paragraphs: [
                                  l.legalRightsProvider,
                                  l.legalRightsMetadata,
                                  l.legalRightsContent,
                                ],
                              ),
                              _LegalSection(
                                title: l.legalUsageTitle,
                                paragraphs: [
                                  l.legalUsageRights,
                                  l.legalUsageRestrictions,
                                  l.legalUsageEditorial,
                                ],
                              ),
                              _LegalSection(
                                title: l.dataAndPrivacy,
                                paragraphs: [
                                  l.legalPrivacyStorage,
                                  l.legalPrivacyConsent,
                                ],
                              ),
                              _LegalSection(
                                title: l.legalWarningTitle,
                                danger: true,
                                paragraphs: [
                                  l.legalWarningBody,
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: widget.firstLaunch
                    ? TvFocus(
                        autofocus: true,
                        onActivate: _accepted ? null : _accept,
                        child: FilledButton.icon(
                          onPressed: _accepted ? null : _accept,
                          icon: const Icon(Icons.verified_outlined),
                          label: Text(l.legalAccept),
                        ),
                      )
                    : TvFocus(
                        autofocus: true,
                        onActivate: _back,
                        child: FilledButton.icon(
                          onPressed: _back,
                          icon: const Icon(Icons.arrow_back),
                          label: Text(l.profileBack),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({
    required this.title,
    required this.paragraphs,
    this.danger = false,
  });

  final String title;
  final List<String> paragraphs;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = danger ? scheme.error : scheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          for (final paragraph in paragraphs) ...[
            Text(
              paragraph,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface,
                    height: 1.55,
                  ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
