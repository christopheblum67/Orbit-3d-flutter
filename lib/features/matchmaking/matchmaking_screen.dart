import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/media_card.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

enum _PairMode { single, duo }

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

class MatchmakingScreen extends ConsumerStatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen> {
  _PairMode _mode = _PairMode.single;
  String? _secondProfileId;

  String? _defaultSecondId(UserProfile? current, List<UserProfile> profiles) {
    if (current == null) return null;
    for (final p in profiles) {
      if (p.id != current.id) return p.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(currentProfileProvider);
    final profilesAsync = ref.watch(profilesProvider);
    final profiles = profilesAsync.valueOrNull ?? const <UserProfile>[];

    final secondId = _secondProfileId != null &&
            _secondProfileId != profile?.id &&
            profiles.any((p) => p.id == _secondProfileId)
        ? _secondProfileId!
        : _defaultSecondId(profile, profiles);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          _mode == _PairMode.single
              ? 'Pour vous · ${profile?.firstName ?? '—'}'
              : 'En duo',
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (profile == null) return;
              final pid = profile.id;
              ref.invalidate(matchmakingProvider(pid));
              ref.invalidate(dismissedRecoIdsProvider(pid));
              ref.invalidate(seenRecoIdsProvider(pid));
              if (_mode == _PairMode.duo && secondId != null) {
                ref.invalidate(matchmakingPairProvider((a: pid, b: secondId)));
              }
            },
          ),
        ],
      ),
      body: profile == null
          ? _NoProfilePlaceholder(scheme: scheme)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: SegmentedButton<_PairMode>(
                    segments: const [
                      ButtonSegment(
                        value: _PairMode.single,
                        label: Text('Pour vous'),
                        icon: Icon(Icons.person_outline),
                      ),
                      ButtonSegment(
                        value: _PairMode.duo,
                        label: Text('En duo'),
                        icon: Icon(Icons.people_outline),
                      ),
                    ],
                    selected: {_mode},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) =>
                        setState(() => _mode = selection.first),
                  ),
                ),
                Expanded(
                  child: _mode == _PairMode.single
                      ? _SingleView(profile: profile)
                      : _DuoView(
                          firstProfile: profile,
                          profiles: profiles,
                          secondProfileId: secondId,
                          onSecondChanged: (id) =>
                              setState(() => _secondProfileId = id),
                        ),
                ),
              ],
            ),
    );
  }
}

class _NoProfilePlaceholder extends StatelessWidget {
  const _NoProfilePlaceholder({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search, size: 56, color: scheme.outline),
          const SizedBox(height: 12),
          const Text('Sélectionnez un profil pour voir ses recommandations'),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.person_outline),
            label: const Text('Choisir un profil'),
            onPressed: () => context.go('/profiles'),
          ),
        ],
      ),
    );
  }
}

class _SingleView extends ConsumerWidget {
  const _SingleView({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final profileId = profile.id;

    return Column(
      children: [
        // Filtres genres session (OR logic, chips horizontales)
        Consumer(
          builder: (context, ref, _) {
            final selectedGenres = ref.watch(matchmakingGenreFilterProvider);
            final availableGenres = profile.favoriteGenres
                .map((g) => g.trim())
                .where((g) => g.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
            if (availableGenres.isEmpty) return const SizedBox.shrink();
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  ...availableGenres.map((genre) {
                    final isSelected = selectedGenres.contains(genre);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(genre, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (_) {
                          ref.read(matchmakingGenreFilterProvider.notifier).toggle(genre);
                          ref.invalidate(matchmakingProvider(profileId));
                        },
                        backgroundColor: scheme.surfaceContainerHighest,
                        selectedColor: scheme.primaryContainer,
                        checkmarkColor: scheme.onPrimaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }),
                  if (selectedGenres.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: TextButton.icon(
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Tout effacer', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          ref.read(matchmakingGenreFilterProvider.notifier).clear();
                          ref.invalidate(matchmakingProvider(profileId));
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.error,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        // Recommandations
        Expanded(
          child: Consumer(
            builder: (context, ref, _) {
              final recommendationsAsync = ref.watch(matchmakingProvider(profile.id));
              final hasFavoriteGenres = profile.favoriteGenres.isNotEmpty;
              return recommendationsAsync.when(
                data: (recos) {
                  if (recos.isEmpty) {
                    return _EmptyState(
                      scheme: scheme,
                      hasFavoriteGenres: hasFavoriteGenres,
                    );
                  }

                  final dismissed = ref.watch(dismissedRecoIdsProvider(profile.id));
                  final seen = ref.watch(seenRecoIdsProvider(profile.id));
                  final movies = recos
                      .where(
                        (r) =>
                            r.kind == RecommendationKind.movie &&
                            !dismissed.contains(r.id) &&
                            !seen.contains(r.id),
                      )
                      .toList();
                  final series = recos
                      .where(
                        (r) =>
                            r.kind == RecommendationKind.series &&
                            !dismissed.contains(r.id) &&
                            !seen.contains(r.id),
                      )
                      .toList();

                  if (movies.isEmpty && series.isEmpty) {
                    return _EmptyState(
                      scheme: scheme,
                      hasFavoriteGenres: true,
                      allDismissed: true,
                    );
                  }

                  return CustomScrollView(
                    slivers: [
                      if (movies.isNotEmpty)
                        _RecoSectionSliver(
                          title: 'Films',
                          icon: Icons.movie_outlined,
                          items: movies,
                          profileId: profile.id,
                        ),
                      if (movies.isNotEmpty && series.isNotEmpty)
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      if (series.isNotEmpty)
                        _RecoSectionSliver(
                          title: 'Séries',
                          icon: Icons.video_library_outlined,
                          items: series,
                          profileId: profile.id,
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => ErrorWidget(err.toString()),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DuoView extends ConsumerWidget {
  const _DuoView({
    required this.firstProfile,
    required this.profiles,
    required this.secondProfileId,
    required this.onSecondChanged,
  });

  final UserProfile firstProfile;
  final List<UserProfile> profiles;
  final String? secondProfileId;
  final ValueChanged<String?> onSecondChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final others = profiles.where((p) => p.id != firstProfile.id).toList();

    final pairProvider = secondProfileId != null
        ? ref.watch(matchmakingPairProvider(
              (a: firstProfile.id, b: secondProfileId!),
            ))
        : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Profil 1 : ${firstProfile.firstName}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (others.isNotEmpty)
                DropdownButton<String>(
                  value: secondProfileId,
                  hint: const Text('Choisir le 2e profil'),
                  isExpanded: true,
                  items: others
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.firstName),
                        ),
                      )
                      .toList(),
                  onChanged: onSecondChanged,
                ),
            ],
          ),
        ),
        if (pairProvider == null)
          Expanded(
            child: Center(
              child: Text(
                'Sélectionnez un second profil',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          )
        else
          Expanded(
            child: pairProvider.when(
              data: (paired) {
                if (paired.isEmpty) {
                  return _EmptyState(
                    scheme: scheme,
                    hasFavoriteGenres: true,
                    duo: true,
                  );
                }

                final dismissedA = ref.watch(dismissedRecoIdsProvider(firstProfile.id));
                final dismissedB = ref.watch(dismissedRecoIdsProvider(secondProfileId!));
                final seenA = ref.watch(seenRecoIdsProvider(firstProfile.id));
                final seenB = ref.watch(seenRecoIdsProvider(secondProfileId!));

                final movies = paired
                    .where(
                      (p) =>
                          p.reco.kind == RecommendationKind.movie &&
                          !dismissedA.contains(p.reco.id) &&
                          !dismissedB.contains(p.reco.id) &&
                          !seenA.contains(p.reco.id) &&
                          !seenB.contains(p.reco.id),
                    )
                    .toList();
                final series = paired
                    .where(
                      (p) =>
                          p.reco.kind == RecommendationKind.series &&
                          !dismissedA.contains(p.reco.id) &&
                          !dismissedB.contains(p.reco.id) &&
                          !seenA.contains(p.reco.id) &&
                          !seenB.contains(p.reco.id),
                    )
                    .toList();

                if (movies.isEmpty && series.isEmpty) {
                  return _EmptyState(scheme: scheme, hasFavoriteGenres: true, allDismissed: true);
                }

                return CustomScrollView(
                  slivers: [
                    if (movies.isNotEmpty)
                      _RecoSectionSliver(
                        title: 'Films (Duo)',
                        icon: Icons.movie_outlined,
                        items: movies.map((p) => p.reco).toList(),
                        profileId: firstProfile.id,
                        showAffinity: true,
                        pairedItems: movies,
                      ),
                    if (movies.isNotEmpty && series.isNotEmpty)
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    if (series.isNotEmpty)
                      _RecoSectionSliver(
                        title: 'Séries (Duo)',
                        icon: Icons.video_library_outlined,
                        items: series.map((p) => p.reco).toList(),
                        profileId: firstProfile.id,
                        showAffinity: true,
                        pairedItems: series,
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorWidget(err.toString()),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.scheme,
    this.hasFavoriteGenres = false,
    this.allDismissed = false,
    this.duo = false,
  });

  final ColorScheme scheme;
  final bool hasFavoriteGenres;
  final bool allDismissed;
  final bool duo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              duo ? Icons.people_outline : Icons.movie_filter_outlined,
              size: 64,
              color: scheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              duo
                  ? 'Aucune affinité commune trouvée'
                  : allDismissed
                      ? 'Tout a été retiré ou vu'
                      : hasFavoriteGenres
                          ? 'Aucune recommandation pour ces genres'
                          : 'Ajoutez des genres favoris au profil',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (!duo && !hasFavoriteGenres)
              FilledButton.icon(
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Configurer les genres favoris'),
                onPressed: () => context.go('/profile/preferences'),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecoSectionSliver extends ConsumerWidget {
  const _RecoSectionSliver({
    required this.title,
    required this.icon,
    required this.items,
    required this.profileId,
    this.showAffinity = false,
    this.pairedItems,
  });

  final String title;
  final IconData icon;
  final List<Recommendation> items;
  final String profileId;
  final bool showAffinity;
  final List<PairedReco>? pairedItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              children: [
                Icon(icon, color: scheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  '$title (${items.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final reco = items[index];
                PairedReco? paired;
                if (showAffinity && pairedItems != null) {
                  paired = pairedItems!.firstWhere(
                    (p) => p.reco.id == reco.id,
                    orElse: () => PairedReco(
                      reco: reco,
                      affinityA: 0,
                      affinityB: 0,
                    ),
                  );
                }
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
                      onTap: () => openRecommendation(context, reco),
                      onLongPress: () => _showRecoActions(context, ref, reco),
                      isNew: reco.isNew,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRecoActions(
    BuildContext context,
    WidgetRef ref,
    Recommendation reco,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Retirer'),
              subtitle: const Text('Ne plus proposer cette recommandation'),
              onTap: () => Navigator.pop(sheetContext, 'dismiss'),
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Marquer comme vu'),
              subtitle: const Text('Ne plus afficher dans les suggestions'),
              onTap: () => Navigator.pop(sheetContext, 'seen'),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Détails'),
              subtitle: Text('${reco.year > 0 ? '${reco.year} · ' : ''}${reco.genre}'),
              onTap: () {
                Navigator.pop(sheetContext);
                openRecommendation(context, reco);
              },
            ),
          ],
        ),
      ),
    );
    if (action == 'dismiss') {
      ref.read(dismissedRecoIdsProvider(profileId).notifier).add(reco.id);
    } else if (action == 'seen') {
      ref.read(seenRecoIdsProvider(profileId).notifier).add(reco.id);
    }
  }
}