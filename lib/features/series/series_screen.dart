import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/matchmaking/widgets/matchmaking_tab.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';

class SeriesScreen extends StatelessWidget {
  const SeriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Séries'),
        actions: [
          IconButton(
            tooltip: 'Rechercher une série',
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search?type=series'),
          ),
        ],
      ),
      body: const MatchmakingTab(kind: RecommendationKind.series),
    );
  }
}
