import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/media_card.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

class MatchmakingScreen extends ConsumerWidget {
  const MatchmakingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(currentProfileProvider);

    if (profile == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_search, size: 56, color: scheme.outline),
              const SizedBox(height: 12),
              const Text('Sélectionnez un profil pour voir ses recommandations'),
            ],
          ),
        ),
      );
    }

    final profileId = profile.id;
    final recommendationsAsync = ref.watch(matchmakingProvider(profileId));
    final hasFavoriteGenres = profile.favoriteGenres.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text('Pour vous · ${profile.firstName}'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(matchmakingProvider(profileId));
              ref.invalidate(dismissedRecoIdsProvider(profileId));
            },
          ),
        ],
      ),
      body: recommendationsAsync.when(
        data: (recos) {
          if (recos.isEmpty) {
            return _EmptyState(
              scheme: scheme,
              hasFavoriteGenres: hasFavoriteGenres,
            );
          }

          final dismissed = ref.watch(dismissedRecoIdsProvider(profileId));
          final movies = recos
              .where(
                (r) =>
                    r.kind == RecommendationKind.movie &&
                    !dismissed.contains(r.id),
              )
              .toList();
          final series = recos
              .where(
                (r) =>
                    r.kind == RecommendationKind.series &&
                    !dismissed.contains(r.id),
              )
              .toList();

          if (movies.isEmpty && series.isEmpty) {
            return _EmptyState(
              scheme: scheme,
              hasFavoriteGenres: true,
              allDismissed: true,
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              if (movies.isNotEmpty)
                _RecoSection(
                  title: 'Films',
                  icon: Icons.movie_outlined,
                  items: movies,
                  profileId: profileId,
                ),
              if (series.isNotEmpty)
                _RecoSection(
                  title: 'Séries',
                  icon: Icons.video_library_outlined,
                  items: series,
                  profileId: profileId,
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorWidget(err.toString()),
      ),
    );
  }
}

class _RecoSection extends ConsumerWidget {
  const _RecoSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.profileId,
  });

  final String title;
  final IconData icon;
  final List<Recommendation> items;
  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final reco = items[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 160,
                  child: MediaCard(
                    title: reco.title,
                    posterUrl: reco.posterUrl,
                    year: reco.year,
                    genre: reco.genre,
                    rating: reco.rating,
                    ageLabel: reco.pegiLabel,
                    fallbackIcon: reco.kind == RecommendationKind.series
                        ? Icons.video_library_outlined
                        : Icons.movie_outlined,
                    onTap: () => _openReco(context, reco),
                    onLongPress: () => _dismissReco(ref, reco),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _openReco(BuildContext context, Recommendation reco) {
    if (reco.kind == RecommendationKind.series) {
      context.push('/series/detail?id=${Uri.encodeComponent(reco.id)}');
    } else {
      context.push(
        '/player?url=${Uri.encodeComponent(reco.movie!.streamUrl)}'
        '&title=${Uri.encodeComponent(reco.title)}&type=vod',
      );
    }
  }

  void _dismissReco(WidgetRef ref, Recommendation reco) async {
    final notifier = ref.read(dismissedRecoIdsProvider(profileId).notifier);
    await notifier.dismiss(reco.id);
    ref.invalidate(matchmakingProvider(profileId));

    if (ref.context.mounted) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Text('"${reco.title}" retiré'),
          action: SnackBarAction(
            label: 'Annuler',
            onPressed: () async {
              final current =
                  ref.read(dismissedRecoIdsProvider(profileId));
              final updated = {...current}..remove(reco.id);
              final storage = ref.read(storageServiceProvider);
              await storage.setSetting(
                'dismissed_recos_$profileId',
                updated.toList(),
              );
              ref.invalidate(dismissedRecoIdsProvider(profileId));
              ref.invalidate(matchmakingProvider(profileId));
            },
          ),
        ),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.scheme,
    required this.hasFavoriteGenres,
    this.allDismissed = false,
  });

  final ColorScheme scheme;
  final bool hasFavoriteGenres;
  final bool allDismissed;

  @override
  Widget build(BuildContext context) {
    final title = allDismissed
        ? 'Toutes les recommandations ont été retirées'
        : hasFavoriteGenres
            ? 'Aucun contenu ne matche vos goûts pour l’instant'
            : 'Pas encore de recommandations';

    final subtitle = allDismissed
        ? 'Actualisez pour en découvrir de nouvelles.'
        : hasFavoriteGenres
            ? 'Essayez d’actualiser ou élargissez vos genres favoris.'
            : 'Ajoutez vos genres favoris dans votre profil pour voir des '
                'films correspondants.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              allDismissed
                  ? Icons.visibility_off_outlined
                  : hasFavoriteGenres
                      ? Icons.movie_filter
                      : Icons.manage_search,
              size: 64,
              color: scheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.person_outline),
              label: const Text('Modifier mes genres'),
              onPressed: () => context.go('/profiles'),
            ),
          ],
        ),
      ),
    );
  }
}
