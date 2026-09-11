import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/matchmaking/widgets/matchmaking_tab.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';

class VodScreen extends StatelessWidget {
  const VodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Films (VOD)'),
        actions: [
          IconButton(
            tooltip: 'Rechercher un film',
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search?type=vod'),
          ),
        ],
      ),
      body: const MatchmakingTab(kind: RecommendationKind.movie),
    );
  }
}
