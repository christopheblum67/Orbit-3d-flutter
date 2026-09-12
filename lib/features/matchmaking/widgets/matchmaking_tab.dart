import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/widgets/media_card.dart';
import 'package:orbit_3d_flutter/features/matchmaking/matchmaking_screen.dart'
    show openRecommendation;
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

// ---------------------------------------------------------------------------
// Mode d'affichage (Pour vous / En groupe 2-4 profils)
// ---------------------------------------------------------------------------

enum _TabMode { single, group }

/// Contenu matchmaking d'un onglet Films ou Séries : mode Pour vous / En groupe,
/// grille avec chargement infini (paquets de 50), badge % d'affinité en groupe.
class MatchmakingTab extends ConsumerStatefulWidget {
  const MatchmakingTab({super.key, required this.kind, this.initialGroup});

  final RecommendationKind kind;
  final List<String>? initialGroup;

  @override
  ConsumerState<MatchmakingTab> createState() => _MatchmakingTabState();
}

class _MatchmakingTabState extends ConsumerState<MatchmakingTab> {
  _TabMode _mode = _TabMode.single;
  final Set<String> _selectedProfileIds = {}; // 2-4 profils
  int _visibleCount = kMatchmakingPageSize;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Auto-switch to group mode if initialGroup is provided
    if (widget.initialGroup != null && widget.initialGroup!.length >= 2) {
      final profile = ref.read(currentProfileProvider);
      if (profile != null && widget.initialGroup!.contains(profile.id)) {
        final others =
            widget.initialGroup!.where((id) => id != profile.id).toSet();
        _selectedProfileIds.addAll(others);
        _mode = _TabMode.group;
      }
    }
  }

  bool get _isMovie => widget.kind == RecommendationKind.movie;

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !_hasMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 600) {
      setState(() => _visibleCount += kMatchmakingPageSize);
    }
  }

  void _reset() {
    if (_visibleCount != kMatchmakingPageSize) {
      setState(() => _visibleCount = kMatchmakingPageSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);

    if (profile == null) return _buildNoProfile();

    return Column(
      children: [
        _buildModeSwitcher(profile),
        if (_mode == _TabMode.group) _buildGroupHeader(profile),
        Expanded(
          child: _mode == _TabMode.single
              ? _buildSingle(profile)
              : _buildGroup(profile),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Mode switcher
  // ---------------------------------------------------------------------------

  Widget _buildModeSwitcher(UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<_TabMode>(
              segments: const [
                ButtonSegment(
                  value: _TabMode.single,
                  label: Text('Pour vous'),
                  icon: Icon(Icons.person_outline),
                ),
                ButtonSegment(
                  value: _TabMode.group,
                  label: Text('En groupe'),
                  icon: Icon(Icons.groups_outlined),
                ),
              ],
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: (sel) {
                setState(() => _mode = sel.first);
                _reset();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // En groupe – sélection de 2 à 4 profils
  // ---------------------------------------------------------------------------

  Widget _buildGroupHeader(UserProfile profile) {
    final profiles =
        ref.watch(profilesProvider).valueOrNull ?? const <UserProfile>[];
    final others = profiles.where((p) => p.id != profile.id).toList();

    // Validation : max 4 profils (incluant le profil courant)
    const maxAdditional = 3; // 1 courant + 3 autres = 4 max

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profil courant : ${profile.firstName}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: others.map((p) {
              final selected = _selectedProfileIds.contains(p.id);
              final disabled =
                  !selected && _selectedProfileIds.length >= maxAdditional;
              return FilterChip(
                label: Text(p.firstName),
                selected: selected,
                onSelected: disabled
                    ? null
                    : (sel) {
                        setState(() {
                          if (sel) {
                            _selectedProfileIds.add(p.id);
                          } else {
                            _selectedProfileIds.remove(p.id);
                          }
                        });
                        _reset();
                      },
                showCheckmark: true,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: disabled
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : null,
                ),
              );
            }).toList(),
          ),
          if (_selectedProfileIds.length < 2)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Sélectionnez au moins 2 profils au total (${_selectedProfileIds.length + 1}/4)',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_selectedProfileIds.length + 1} profils sélectionnés',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Placeholder pas de profil
  // ---------------------------------------------------------------------------

  Widget _buildNoProfile() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search, size: 56, color: scheme.outline),
          const SizedBox(height: 12),
          const Text('Sélectionnez un profil pour voir ses recommandations'),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pour vous
  // ---------------------------------------------------------------------------

  Widget _buildSingle(UserProfile profile) {
    final async = ref.watch(matchmakingTabProvider(profile.id));
    return async.when(
      data: (tab) {
        final list = _isMovie ? tab.movies : tab.series;
        if (list.isEmpty) return _emptyState();
        _hasMore = _visibleCount < list.length;
        final shown = list.take(_visibleCount).toList();
        return _buildGrid(list: shown, hasMore: _hasMore);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  // ---------------------------------------------------------------------------
  // En groupe (2-4 profils)
  // ---------------------------------------------------------------------------

  Widget _buildGroup(UserProfile profile) {
    if (_selectedProfileIds.length < 2) {
      return Center(
        child: Text(
          'Sélectionnez au moins 2 profils supplémentaires',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    final group = [profile.id, ..._selectedProfileIds];
    final async = ref.watch(matchmakingGroupTabProvider(group));
    return async.when(
      data: (tab) {
        final list = _isMovie ? tab.movies : tab.series;
        if (list.isEmpty) return _emptyState(group: true);
        _hasMore = _visibleCount < list.length;
        final shown = list.take(_visibleCount).toList();
        return _buildGroupGrid(list: shown, hasMore: _hasMore);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  // ---------------------------------------------------------------------------
  // Grilles
  // ---------------------------------------------------------------------------

  Widget _buildGrid({
    required List<ScoredReco> list,
    required bool hasMore,
  }) {
    final totalShown = list.length;
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: totalShown,
      itemBuilder: (context, index) {
        final scored = list[index];
        return _buildCard(
          scored.reco,
          matchPercent: (scored.affinity * 100).round(),
        );
      },
    );
  }

  Widget _buildGroupGrid({
    required List<GroupReco> list,
    required bool hasMore,
  }) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final grouped = list[index];
        return _buildCard(
          grouped.reco,
          matchPercent: (grouped.combined * 100).round(),
        );
      },
    );
  }

  Widget _buildCard(Recommendation reco, {int? matchPercent}) {
    return MediaCard(
      title: reco.title,
      posterUrl: reco.posterUrl,
      year: reco.year,
      genre: reco.genre,
      rating: reco.rating,
      ageLabel: matchPercent != null ? null : reco.pegiLabel,
      fallbackIcon:
          _isMovie ? Icons.movie_outlined : Icons.video_library_outlined,
      isNew: reco.isNew,
      matchPercent: matchPercent,
      onTap: () => openRecommendation(context, reco),
    );
  }

  Widget _emptyState({bool group = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            group ? Icons.groups_outlined : Icons.movie_filter_outlined,
            size: 64,
            color: scheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            group
                ? 'Aucune affinité commune trouvée'
                : 'Aucune recommandation disponible',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
