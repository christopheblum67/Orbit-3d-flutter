import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/browse/browse_screen.dart'
    show FlixPatrolView;
import 'package:orbit_3d_flutter/features/matchmaking/widgets/matchmaking_tab.dart'
    show MatchmakingTab;
import 'package:orbit_3d_flutter/models/recommendation.dart';

/// Ouvre un contenu recommandé (série → détail, film → lecteur).
void openRecommendation(BuildContext context, Recommendation reco) {
  if (reco.kind == RecommendationKind.series) {
    context.push('/series/detail?id=${Uri.encodeComponent(reco.id)}');
  } else {
    final movie = reco.movie!;
    context.push(
      '/player?url=${Uri.encodeComponent(movie.streamUrl)}'
      '&title=${Uri.encodeComponent(reco.title)}&type=vod'
      '&poster=${Uri.encodeComponent(reco.posterUrl)}'
      '&genre=${Uri.encodeComponent(reco.genre)}'
      '&year=${reco.year}'
      '&rating=${reco.rating}',
    );
  }
}

/// Matchmaking : recommandations d'affinité (Films / Séries, solo & duo)
/// + classements populaires TMDB (onglet FlixPatrol).
class MatchmakingScreen extends ConsumerStatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text('Matchmaking'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Films'),
            Tab(text: 'Séries'),
            Tab(text: 'FlixPatrol'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MatchmakingTab(kind: RecommendationKind.movie),
          MatchmakingTab(kind: RecommendationKind.series),
          FlixPatrolView(),
        ],
      ),
    );
  }
}