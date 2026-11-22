import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/widgets/profile_avatar.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_safe_area.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/tv_mode_provider.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Écran de pré-configuration TV — s'affiche au premier lancement sur TV
///
/// Détecte si on est sur TV, pré-charge l'abonnement actif et le profil
/// depuis Hive (mêmes données que S20), et propose une configuration
/// guidée TV-friendly.
class TvPreconfigScreen extends ConsumerStatefulWidget {
  const TvPreconfigScreen({super.key});

  @override
  ConsumerState<TvPreconfigScreen> createState() => _TvPreconfigScreenState();
}

class _TvPreconfigScreenState extends ConsumerState<TvPreconfigScreen> {
  int _currentStep = 0;
  Subscription? _loadedSubscription;
  UserProfile? _loadedProfile;
  bool _isLoading = true;
  String? _error;
  bool _skipRequested = false;

  static const List<String> _steps = [
    'Détection TV',
    'Abonnement',
    'Profil',
    'Configuration',
  ];

  @override
  void initState() {
    super.initState();
    _runPreconfig();
  }

  Future<void> _runPreconfig() async {
    try {
      // Étape 1 : Détection TV
      _setStep(0);
      await _detectTvMode();
      if (!mounted) return;

      // Étape 2 : Charger l'abonnement actif
      _setStep(1);
      await _loadSubscription();
      if (!mounted) return;

      // Étape 3 : Charger le profil
      _setStep(2);
      await _loadProfile();
      if (!mounted) return;

      // Étape 4 : Configuration finale
      _setStep(3);
      await _finalizeConfig();
    } catch (e, st) {
      LoggerService.instance.error('TV Preconfig error', error: e, stackTrace: st);
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  void _setStep(int step) {
    if (mounted) {
      setState(() => _currentStep = step);
    }
  }

  Future<void> _detectTvMode() async {
    // Force la détection TV via le controller
    final controller = ref.read(tvModeControllerProvider);
    if (!controller.enabled) {
      controller.enable();
    }
    // Attend un peu pour que la détection se fasse
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _loadSubscription() async {
    final storage = ref.read(storageServiceProvider);
    final activeSub = storage.getActiveSubscriptionSync();

    if (activeSub != null) {
      // Charge aussi la validité si Xtream
      if (activeSub.type == SubscriptionType.xtream) {
        try {
          await ref
              .read(subscriptionsProvider.notifier)
              .refreshValidity(activeSub.id, api: ref.read(apiServiceProvider));
        } catch (_) {
          // Non bloquant
        }
      }
      if (mounted) {
        setState(() => _loadedSubscription = activeSub);
      }
    }
  }

  Future<void> _loadProfile() async {
    final storage = ref.read(storageServiceProvider);
    final profiles = await storage.getProfiles();

    if (profiles.isNotEmpty) {
      // Prend le dernier profil utilisé ou le premier
      final profile = profiles.firstWhere(
        (p) => p.id == ref.read(currentProfileProvider)?.id,
        orElse: () => profiles.first,
      );
      if (mounted) {
        setState(() => _loadedProfile = profile);
        ref.read(currentProfileProvider.notifier).setUserProfile(profile);
      }
    }
  }

  Future<void> _finalizeConfig() async {
    // Initialise la session Cloudflare si Xtream
    final sub = _loadedSubscription;
    if (sub != null && sub.type == SubscriptionType.xtream) {
      try {
        final baseUrl = 'https://${Uri.parse(sub.baseUrl!).host}';
        await ref
            .read(cloudflareSessionProvider)
            .initialize(baseUrl: baseUrl)
            .timeout(const Duration(seconds: 30));
      } catch (_) {
        // Non bloquant
      }
    }

    // Lance le refresh EPG/catalogue en arrière-plan (style splash screen)
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      _goToHome();
    }
  }

  void _goToHome() {
    if (mounted) {
      context.go('/home');
    }
  }

  void _skip() {
    if (mounted) {
      setState(() => _skipRequested = true);
      _goToHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isTv = ref.watch(tvModeProvider);

    if (_skipRequested) {
      return const SizedBox.shrink();
    }

    if (_error != null) {
      return _buildErrorScreen();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isLoading) _skip();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0E1117),
        body: TvSafeArea(
          child: Column(
            children: [
              // Barre de progression des étapes
              _buildProgressBar(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingStep()
                    : _buildCompleteScreen(),
              ),
              // Bouton "Ignorer" en bas
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: TvFocus(
                    onActivate: _skip,
                    autofocus: true,
                    child: OutlinedButton.icon(
                      onPressed: _skip,
                      icon: const Icon(Icons.skip_next_rounded),
                      label: const Text('Passer'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        children: [
          Row(
            children: List.generate(_steps.length, (index) {
              final isActive = index <= _currentStep;
              final isDone = index < _currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        decoration: BoxDecoration(
                          color: isActive || isDone
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (index < _steps.length - 1) const SizedBox(width: 8),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            _steps[_currentStep],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStep() {
    final icons = [
      Icons.tv_rounded,
      Icons.wifi_rounded,
      Icons.person_rounded,
      Icons.check_circle_rounded,
    ];
    final colors = [
      Colors.cyanAccent,
      Colors.greenAccent,
      Colors.amberAccent,
      Colors.blueAccent,
    ];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Container(
              key: ValueKey(_currentStep),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colors[_currentStep].withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors[_currentStep].withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Icon(
                icons[_currentStep],
                size: 60,
                color: colors[_currentStep],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _steps[_currentStep],
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _getStepDescription(_currentStep),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _steps.length,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(colors[_currentStep]),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ));
  }

  String _getStepDescription(int step) {
    switch (step) {
      case 0:
        return 'Détection du mode télévision...';
      case 1:
        return _loadedSubscription != null
            ? 'Abonnement "${_loadedSubscription!.name}" chargé'
            : 'Recherche d\'un abonnement actif...';
      case 2:
        return _loadedProfile != null
            ? 'Profil "${_loadedProfile!.firstName}" chargé'
            : 'Recherche d\'un profil...';
      case 3:
        return 'Configuration finale en cours...';
      default:
        return '';
    }
  }

  Widget _buildCompleteScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.greenAccent.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 60,
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Prêt pour la TV !',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Abonnement et profil configurés automatiquement.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_loadedSubscription != null) ...[
              _InfoRow(
                icon: Icons.wifi_rounded,
                label: 'Abonnement',
                value: _loadedSubscription!.name,
                color: Colors.cyanAccent,
              ),
              const SizedBox(height: 8),
            ],
            if (_loadedProfile != null) ...[
              _InfoRow(
                icon: Icons.person_rounded,
                label: 'Profil',
                value: _loadedProfile!.firstName,
                color: Colors.amberAccent,
              ),
              const SizedBox(height: 24),
            ],
            TvFocus(
              autofocus: true,
              onActivate: _goToHome,
              child: FilledButton.icon(
                onPressed: _goToHome,
                icon: const Icon(Icons.tv_rounded),
                label: const Text('Accéder à l\'accueil'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: const Color(0xFF00CFE8),
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: Colors.redAccent.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 24),
            Text(
              'Erreur de configuration',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TvFocus(
              autofocus: true,
              onActivate: _skip,
              child: FilledButton.icon(
                onPressed: _skip,
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Continuer quand même'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}