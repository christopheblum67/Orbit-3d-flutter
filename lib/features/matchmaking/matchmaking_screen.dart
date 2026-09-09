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
    final recommendationsAsync = ref.watch(matchmakingProvider(profileId));
    final hasFavoriteGenres = profile.favoriteGenres.isNotEmpty;

    return recommendationsAsync.when(
      data: (recos) {
        if (recos.isEmpty) {
          return _EmptyState(
            scheme: scheme,
            hasFavoriteGenres: hasFavoriteGenres,
          );
        }

        final dismissed = ref.watch(dismissedRecoIdsProvider(profileId));
        final seen = ref.watch(seenRecoIdsProvider(profileId));
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
                profileId: profileId,
              ),
            if (movies.isNotEmpty && series.isNotEmpty)
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            if (series.isNotEmpty)
              _RecoSectionSliver(
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
    final secondId = secondProfileId;

    UserProfile? secondProfile;
    if (secondId != null) {
      for (final p in profiles) {
        if (p.id == secondId) {
          secondProfile = p;
          break;
        }
      }
    }

    if (secondProfile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_add_outlined, size: 56, color: scheme.outline),
              const SizedBox(height: 12),
              Text(
                'Comparez les goûts de deux profils',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Ajoutez un second profil (ex. « Bibi ») pour découvrir les '
                'contenus qui plaisent aux deux, classés par % d’affinité.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Créer un profil'),
                onPressed: () => context.go('/profiles'),
              ),
            ],
          ),
        ),
      );
    }

    final pairAsync = ref
        .watch(matchmakingPairProvider((a: firstProfile.id, b: secondId!)));

    return Column(
      children: [
        _ProfilePairPicker(
          firstProfile: firstProfile,
          secondProfile: secondProfile,
          others: others,
          onChanged: onSecondChanged,
        ),
        Expanded(
          child: pairAsync.when(
            data: (pairs) {
              if (pairs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 56, color: scheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          'Aucune affinité trouvée',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ajoutez des genres favoris aux deux profils ou '
                          'actualisez pour découvrir des contenus communs.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                itemCount: pairs.length,
                itemBuilder: (context, index) => _AffinityCard(
                  paired: pairs[index],
                  firstName: firstProfile.firstName,
                  secondName: secondProfile!.firstName,
                ),
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

class _ProfilePairPicker extends StatelessWidget {
  const _ProfilePairPicker({
    required this.firstProfile,
    required this.secondProfile,
    required this.others,
    required this.onChanged,
  });

  final UserProfile firstProfile;
  final UserProfile secondProfile;
  final List<UserProfile> others;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _PairChip(
            letter: firstProfile.firstName.isNotEmpty
                ? firstProfile.firstName.characters.first.toUpperCase()
                : '?',
            label: firstProfile.firstName,
            color: scheme.primary,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, size: 18, color: scheme.outline),
          ),
          ActionChip(
            avatar: CircleAvatar(
              backgroundColor: scheme.tertiary.withValues(alpha: 0.2),
              child: Text(
                secondProfile.firstName.isNotEmpty
                    ? secondProfile.firstName.characters.first.toUpperCase()
                    : '?',
                style: TextStyle(
                  color: scheme.tertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            label: Text(secondProfile.firstName),
            onPressed: () => _showSecondProfilePicker(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showSecondProfilePicker(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Comparer avec un autre profil',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            if (others.isEmpty)
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Aucun autre profil disponible'),
              )
            else
              ...others.map(
                (p) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.surfaceContainerHighest,
                    child: Text(
                      p.firstName.isNotEmpty
                          ? p.firstName.characters.first.toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(p.firstName),
                  subtitle: p.favoriteGenres.isEmpty
                      ? const Text('Aucun genre favori')
                      : Text('Genres : ${p.favoriteGenres.join(' · ')}'),
                  onTap: () => Navigator.pop(sheetContext, p.id),
                ),
              ),
          ],
        ),
      ),
    );

    if (picked != null && picked != firstProfile.id) {
      onChanged(picked);
    }
  }
}

class _PairChip extends StatelessWidget {
  const _PairChip({
    required this.letter,
    required this.label,
    required this.color,
  });

  final String letter;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.2),
        child: Text(
          letter,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.08),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
    );
  }
}

class _AffinityCard extends StatelessWidget {
  const _AffinityCard({
    required this.paired,
    required this.firstName,
    required this.secondName,
  });

  final PairedReco paired;
  final String firstName;
  final String secondName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reco = paired.reco;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openRecommendation(context, reco),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 84,
                    height: 120,
                    child: reco.posterUrl.isEmpty
                        ? _PosterFallback(
                            icon: reco.kind == RecommendationKind.series
                                ? Icons.video_library_outlined
                                : Icons.movie_outlined,
                          )
                        : Image.network(
                            reco.posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _PosterFallback(
                              icon: reco.kind == RecommendationKind.series
                                  ? Icons.video_library_outlined
                                  : Icons.movie_outlined,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              reco.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _AffinityPill(value: paired.combined),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${reco.year} · ${reco.genre}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '★ ${reco.rating.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.tertiary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _AffinityBadge(
                            label: firstName,
                            value: paired.affinityA,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          _AffinityBadge(
                            label: secondName,
                            value: paired.affinityB,
                            color: scheme.tertiary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AffinityPill extends StatelessWidget {
  const _AffinityPill({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = (value * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$pct %',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _AffinityBadge extends StatelessWidget {
  const _AffinityBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            '$label $pct %',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Icon(icon, size: 32, color: scheme.outline),
    );
  }
}

class _RecoSectionSliver extends ConsumerWidget {
  const _RecoSectionSliver({
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
    return SliverToBoxAdapter(
      child: Column(
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
                      onTap: () => openRecommendation(context, reco),
                      onLongPress: () => _showRecoActions(context, ref, reco),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
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
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Déjà vu'),
              subtitle: const Text('Marquer comme déjà vue'),
              onTap: () => Navigator.pop(sheetContext, 'seen'),
            ),
          ],
        ),
      ),
    );

    if (action == null || !ref.context.mounted) return;
    if (action == 'dismiss') {
      await _dismissReco(ref, reco);
    } else {
      await _markSeen(ref, reco);
    }
  }

  Future<void> _dismissReco(WidgetRef ref, Recommendation reco) async {
    final notifier = ref.read(dismissedRecoIdsProvider(profileId).notifier);
    await notifier.add(reco.id);
    ref.invalidate(matchmakingProvider(profileId));

    if (ref.context.mounted) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Text('"${reco.title}" retiré'),
          action: SnackBarAction(
            label: 'Annuler',
            onPressed: () async {
              final current = ref.read(dismissedRecoIdsProvider(profileId));
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

  Future<void> _markSeen(WidgetRef ref, Recommendation reco) async {
    final notifier = ref.read(seenRecoIdsProvider(profileId).notifier);
    await notifier.add(reco.id);
    ref.invalidate(matchmakingProvider(profileId));

    if (ref.context.mounted) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Text('"${reco.title}" marqué « Déjà vu »'),
          action: SnackBarAction(
            label: 'Annuler',
            onPressed: () async {
              final current = ref.read(seenRecoIdsProvider(profileId));
              final updated = {...current}..remove(reco.id);
              final storage = ref.read(storageServiceProvider);
              await storage.setSetting(
                'seen_recos_$profileId',
                updated.toList(),
              );
              ref.invalidate(seenRecoIdsProvider(profileId));
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