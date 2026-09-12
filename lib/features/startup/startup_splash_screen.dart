import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_3d_flutter/core/services/startup_refresh_controller.dart';
import 'package:orbit_3d_flutter/core/services/personalized_recommendations.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/models/startup_recommendation.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';

/// Écran de démarrage : régénère les flux et affiche une barre de progression
/// (%) pendant qu'un carrousel de recommandations personnalisées défile
/// (geste « swipe »).
class StartupSplashScreen extends ConsumerStatefulWidget {
  const StartupSplashScreen({super.key});

  @override
  ConsumerState<StartupSplashScreen> createState() =>
      _StartupSplashScreenState();
}

class _StartupSplashScreenState extends ConsumerState<StartupSplashScreen> {
  late final StartupRefreshController _controller;
  late final PageController _pageController;
  Timer? _autoAdvance;
  List<StartupRecommendation> _recommendations = [];
  StartupRecommendation? _featured;
  int _page = 0;
  bool _navigated = false;

  void _pickFeatured() {
    if (_recommendations.isEmpty) {
      _featured = null;
      return;
    }
    _featured = _recommendations[Random().nextInt(_recommendations.length)];
  }

  @override
  void initState() {
    super.initState();
    final api = ref.read(apiServiceProvider);
    _controller = StartupRefreshController(
      api,
      epgCache: ref.read(epgDataCacheProvider),
    );
    _controller.addListener(_onProgress);
    _pageController = PageController(viewportFraction: 0.46);
    // Lance le préchargement après le premier frame pour ne pas muter l'état
    // pendant la phase de build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _kickOff();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onProgress);
    _controller.dispose();
    _pageController.dispose();
    _autoAdvance?.cancel();
    super.dispose();
  }

  void _onProgress() {
    if (!mounted) return;
    setState(() {});
    if (_controller.isFinished && !_navigated) {
      _navigated = true;
      // Marque la mise à jour comme faite pour que le bouton d'accueil
      // affiche l'horodatage au lieu de « Jamais mis à jour ».
      ref.read(lastRefreshTimestampProvider.notifier).state = DateTime.now();
      Future<void>.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) context.go('/home');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1117),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildCarousel()),
            _buildProgress(context),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _kickOff() async {
    // Génère les recommandations dès que possible à partir des favoris.
    final profile = ref.read(currentProfileProvider);
    final engine = PersonalizedRecommendations(
      favoriteGenres: profile?.favoriteGenres ?? const [],
    );
    final history = ref.read(mediaLibraryManagerProvider).recentlyWatched;
    final watched = history.map((h) => h.title.toLowerCase()).toSet();
    _recommendations = engine.build(
      movies: _controller.movies,
      series: _controller.series,
      radios: ref.read(radioChannelsProvider).valueOrNull ?? const [],
      replays: ref.read(replaysProvider).valueOrNull ?? const [],
      watchedTitles: watched.toList(),
    );
    if (_recommendations.isEmpty) {
      _recommendations = [
        const StartupRecommendation(
          title: 'Orbit IPTV',
          category: 'Bienvenue',
          posterUrl: '',
          reason: 'Vos recommandations personnalisées arrivent…',
          rating: 0,
          id: 'welcome',
        ),
      ];
    }
    _pickFeatured();
    if (mounted) setState(() {});
    _pageController.addListener(() {
      if (mounted) {
        setState(() => _page = _pageController.page?.round() ?? 0);
      }
      _restartAutoAdvance();
    });
    _startAutoAdvance();
    await _controller.start();
    if (!mounted) return;
    // Rafraîchit la validité de l'abonnement Xtream actif (affichée en bas de
    // l'accueil) : évite le « Sans limite » erroné au démarrage.
    await _refreshSubscriptionValidity();
    if (!mounted) return;
    // Initialise la session Cloudflare pour le zapping (cookies cf_clearance + UA).
    // Récupère l'URL de base du fournisseur IPTV actif.
    try {
      final sub =
          await ref.read(subscriptionManagerProvider).getActiveSubscription();
      if (sub['type'] == 'xtream') {
        final baseUrl = 'https://${Uri.parse(sub['baseUrl']!).host}';
        await ref.read(cloudflareSessionProvider).initialize(baseUrl: baseUrl);
      }
    } catch (_) {
      // Non bloquant : si le challenge échoue, on continuera sans cookies Cloudflare.
    }
    if (!mounted) return;
    // Après le fetch, rafraîchit les recommandations avec les contenus reçus.
    final refreshed = engine.build(
      movies: _controller.movies,
      series: _controller.series,
      radios: ref.read(radioChannelsProvider).valueOrNull ?? const [],
      replays: ref.read(replaysProvider).valueOrNull ?? const [],
      watchedTitles: watched.toList(),
    );
    if (mounted && refreshed.isNotEmpty) {
      setState(() {
        _recommendations = refreshed;
        _pickFeatured();
        _page = 0;
        if (_pageController.hasClients) _pageController.jumpToPage(0);
      });
    }
    // Auto-resume: check for last session playback progress
    if (mounted) {
      await _checkAutoResume();
    }
  }

  Future<void> _checkAutoResume() async {
    final progress = ref.read(playbackProgressProvider('last_session'));
    if (progress != null &&
        progress.positionMs > 60000 &&
        progress.hasProgress) {
      final title = _getResumeTitle(progress);
      final timestamp = _formatTimestamp(progress.positionMs);
      final shouldResume = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E222D),
          title: const Text('Reprendre la lecture ?',
              style: TextStyle(color: Colors.white),),
          content: Text(
            'Reprendre "$title" à $timestamp ?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Plus tard',
                  style: TextStyle(color: Colors.white54),),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00CFE8),),
              child: const Text('Reprendre',
                  style: TextStyle(color: Colors.black),),
            ),
          ],
        ),
      );
      if (shouldResume == true && mounted) {
        context.go('/player',
            extra: PlayerRouteData(
              streamUrl: '',
              title: title,
              initialPositionMs: progress.positionMs,
              progressId: 'last_session',
            ),);
      }
    }
  }

  String _getResumeTitle(PlaybackProgress progress) {
    // Try to get title from recently watched history
    final history = ref.read(mediaLibraryManagerProvider).recentlyWatched;
    if (history.isNotEmpty) {
      return history.first.title;
    }
    return 'Dernière session';
  }

  String _formatTimestamp(int positionMs) {
    final minutes = (positionMs / 60000).floor();
    final seconds = ((positionMs % 60000) / 1000).floor();
    return '${minutes}m ${seconds}s';
  }

  Future<void> _refreshSubscriptionValidity() async {
    try {
      // Attend la résolution du provider actif : `valueOrNull` peut être nul
      // si le FutureProvider n'a pas encore terminé, ce qui ferait sauter le
      // refresh et afficher « Sans limite » au démarrage.
      final active = await ref.read(activeSubscriptionProvider.future);
      if (active != null && active.type == SubscriptionType.xtream) {
        await ref
            .read(subscriptionsProvider.notifier)
            .refreshValidity(active.id, api: ref.read(apiServiceProvider));
      }
    } catch (_) {
      // Non bloquant : l'affichage retombera sur « Sans limite ».
    }
  }

  void _startAutoAdvance() {
    _autoAdvance?.cancel();
    _autoAdvance = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _recommendations.isEmpty) {
        _autoAdvance?.cancel();
        return;
      }
      if (!_pageController.hasClients) {
        _autoAdvance?.cancel();
        return;
      }
      final next = (_page + 1) % _recommendations.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  void _restartAutoAdvance() {
    _autoAdvance?.cancel();
    if (_controller.isFinished) return;
    if (!_pageController.hasClients) return;
    _startAutoAdvance();
  }

  Widget _buildCarousel() {
    final featured = _featured;
    if (_recommendations.isEmpty || featured == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00CFE8)),
      );
    }
    return Column(
      children: [
        const SizedBox(height: 24),
        const OrbitLogoIcon(size: 56),
        const SizedBox(height: 16),
        const Text(
          'Pour vous',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sélection du jour',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: _pickFeaturedOnTap,
              child: _buildCard(featured, true),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _pickFeaturedOnTap() {
    if (_recommendations.isEmpty) return;
    setState(() => _pickFeatured());
  }

  Widget _buildCard(StartupRecommendation rec, bool active) {
    return Center(
      child: Container(
        width: 520,
        height: 300,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF00CFE8) : Colors.white12,
            width: active ? 2 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFF00CFE8).withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ]
              : const [],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fond : affiche la pochette si disponible, sinon un dégradé.
            if (rec.posterUrl.isNotEmpty)
              Image.network(
                rec.posterUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPosterFallback(rec),
              )
            else
              _buildPosterFallback(rec),
            // Voile dégradé pour la lisibilité
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xCC0E1117),
                  ],
                ),
              ),
            ),
            // Texte superposé
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CategoryBadge(category: rec.category),
                  const SizedBox(height: 8),
                  Text(
                    rec.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rec.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  if (rec.rating > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rec.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterFallback(StartupRecommendation rec) {
    return Container(
      color: const Color(0xFF16181E),
      child: Center(
        child: Icon(
          rec.category == 'Film'
              ? Icons.movie_outlined
              : Icons.video_library_rounded,
          size: 60,
          color: const Color(0xFF00CFE8).withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    final percent = _controller.percent;
    final current = _controller.currentStep;

    // Mini-icônes thématiques : Live / Film / Série / EPG
    final sections = [
      _ProgressIcon(
          icon: Icons.live_tv,
          label: 'Live',
          done: _controller.doneSteps.contains(StartupStep.live),
          active: current == StartupStep.live,),
      _ProgressIcon(
          icon: Icons.movie_outlined,
          label: 'Films',
          done: _controller.doneSteps.contains(StartupStep.movies),
          active: current == StartupStep.movies,),
      _ProgressIcon(
          icon: Icons.video_library_outlined,
          label: 'Séries',
          done: _controller.doneSteps.contains(StartupStep.series),
          active: current == StartupStep.series,),
      _ProgressIcon(
          icon: Icons.receipt_long_outlined,
          label: 'EPG',
          done: _controller.doneSteps.contains(StartupStep.epg),
          active: current == StartupStep.epg,),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne mini-icônes (état de chaque playlist)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: sections.map((s) => _buildMiniIcon(s)).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            _controller.isFinished
                ? 'Prêt !'
                : 'Régénération des flux… ${current?.label ?? ''}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _controller.progress,
              minHeight: 10,
              backgroundColor: Colors.white12,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF00CFE8)),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$percent %',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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

/// Donnée pour l'affichage d'une mini-icône de progression
class _ProgressIcon {
  final IconData icon;
  final String label;
  final bool done;
  final bool active;

  _ProgressIcon({
    required this.icon,
    required this.label,
    required this.done,
    required this.active,
  });
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF00CFE8).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: const Color(0xFF00CFE8).withValues(alpha: 0.5)),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: Color(0xFF00CFE8),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
