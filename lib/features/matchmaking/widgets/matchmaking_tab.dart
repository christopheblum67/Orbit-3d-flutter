import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/widgets/media_card.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/matchmaking/matchmaking_screen.dart'
    show openRecommendation;
import 'package:orbit_3d_flutter/features/matchmaking/widgets/prolong_decision_sheet.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';

// ---------------------------------------------------------------------------
// Mode d'affichage (Pour vous / En groupe 2-4 profils)
// ---------------------------------------------------------------------------

enum _TabMode { single, group }

/// Options de tri de la grille de recommandations.
enum _MatchSort {
  /// Affinité la plus forte d'abord (comportement initial).
  affinityDesc,

  /// Affinité la plus faible d'abord.
  affinityAsc,

  /// Titre A → Z.
  titleAsc,

  /// Titre Z → A.
  titleDesc,
}

extension on _MatchSort {
  String get label => switch (this) {
        _MatchSort.affinityDesc => 'Affinité ↓',
        _MatchSort.affinityAsc => 'Affinité ↑',
        _MatchSort.titleAsc => 'A → Z',
        _MatchSort.titleDesc => 'Z → A',
      };
}

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
  _MatchSort _sort = _MatchSort.affinityDesc;
  final Set<String> _selectedProfileIds = {}; // 2-4 profils
  int _visibleCount = kMatchmakingPageSize;

  /// Longueur totale de la liste courante. Champ simple (pas de setState) :
  /// il ne sert qu'a borner l'incrementation au scroll.
  int _totalCount = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Auto-switch to group mode if initialGroup is provided
    if (widget.initialGroup != null && widget.initialGroup!.length >= 2) {
      final profile = ref.read(currentProfileProvider);
      if (profile != null && widget.initialGroup!.contains(profile.id)) {
        // On repart de la clé canonique pour ne pas réinjecter un Set non trié
        // qui réintroduirait la non-canonicité de la clé de famille.
        final others = canonicalProfileGroup(
          widget.initialGroup!.where((id) => id != profile.id),
        );
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
    if (!_scrollController.hasClients || _visibleCount >= _totalCount) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 600) {
      setState(() => _visibleCount += kMatchmakingPageSize);
    }
  }

  /// Retour en haut + repart d'une page pleine quand la liste ou le mode change.
  void _reset() {
    if (_visibleCount != kMatchmakingPageSize) {
      _visibleCount = kMatchmakingPageSize;
    }
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
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
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 500;
          final refresh = IconButton(
            tooltip: l.refreshRecommendations,
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _reset();
              ref.invalidate(matchmakingTabProvider);
              ref.invalidate(matchmakingGroupTabProvider);
              ref.invalidate(flixPatrolMoviesProvider);
              ref.invalidate(flixPatrolTvProvider);
              ref.invalidate(flixPatrolTrendingMoviesProvider);
              ref.invalidate(flixPatrolTrendingTvProvider);
              ref.invalidate(flixPatrolTopRatedMoviesProvider);
              ref.invalidate(flixPatrolTopRatedTvProvider);
              ref.invalidate(flixPatrolNowPlayingMoviesProvider);
              ref.invalidate(flixPatrolUpcomingMoviesProvider);
              ref.invalidate(flixPatrolOnTheAirTvProvider);
              ref.invalidate(flixPatrolAiringTodayTvProvider);
            },
          );
          final mode = Expanded(
            child: SegmentedButton<_TabMode>(
              segments: [
                ButtonSegment(
                  value: _TabMode.single,
                  label: Text(l.forYou),
                  icon: compact ? null : const Icon(Icons.person_outline),
                ),
                ButtonSegment(
                  value: _TabMode.group,
                  label: Text(l.groupMode),
                  icon: compact ? null : const Icon(Icons.groups_outlined),
                ),
              ],
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: (sel) {
                setState(() => _mode = sel.first);
                _reset();
              },
            ),
          );
          final sort = _SortMenu(
            value: _sort,
            onChanged: (value) {
              setState(() => _sort = value);
              _reset();
            },
          );
          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(children: [refresh, mode]),
                    const SizedBox(height: 8),
                    sort,
                  ],
                )
              : Row(
                  children: [
                    refresh,
                    mode,
                    const SizedBox(width: 10),
                    sort,
                  ],
                );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // En groupe – sélection de 2 à 4 profils
  // ---------------------------------------------------------------------------

  Widget _buildGroupHeader(UserProfile profile) {
    final l = AppLocalizations.of(context);
    final profiles = ref.watch(profilesProvider).value ?? const <UserProfile>[];
    final others = profiles.where((p) => p.id != profile.id).toList();

    // Validation : max 4 profils (incluant le profil courant)
    const maxAdditional = 3; // 1 courant + 3 autres = 4 max

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.currentProfileLabel(profile.firstName),
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
              final scheme = Theme.of(context).colorScheme;
              return AnimatedContainer(
                key: ValueKey('matchmaking-profile-${p.id}'),
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.55),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ]
                      : const [],
                ),
                child: FilterChip(
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
                  selectedColor: scheme.primary,
                  checkmarkColor: scheme.onPrimary,
                  labelStyle: TextStyle(
                    color: selected
                        ? scheme.onPrimary
                        : disabled
                            ? scheme.onSurfaceVariant
                            : null,
                    fontWeight: selected ? FontWeight.w700 : null,
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedProfileIds.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l.selectAtLeastOneProfile(_selectedProfileIds.length + 1),
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
                l.profilesSelected(_selectedProfileIds.length + 1),
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
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search, size: 56, color: scheme.outline),
          const SizedBox(height: 12),
          Text(l.selectProfileForRecommendations),
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
      skipLoadingOnRefresh: false,
      data: (tab) {
        final list = _sortScored(_isMovie ? tab.movies : tab.series);
        if (list.isEmpty) return _emptyState();
        _totalCount = list.length;
        final hasMore = _visibleCount < list.length;
        final shown = list.take(_visibleCount).toList();
        return _buildGrid(list: shown, hasMore: hasMore);
      },
      loading: _loadingView,
      error: (e, _) => Center(child: Text(userFriendlyError(e))),
    );
  }

  /// Tri par affinité ou par titre, sans toucher à la liste du provider
  /// (copie defensive : le provider garde son top-K par affinité).
  List<ScoredReco> _sortScored(List<ScoredReco> list) {
    switch (_sort) {
      case _MatchSort.affinityDesc:
        return list;
      case _MatchSort.affinityAsc:
        return [...list]..sort((a, b) => a.affinity.compareTo(b.affinity));
      case _MatchSort.titleAsc:
        return [...list]..sort(
            (a, b) => a.reco.title
                .toLowerCase()
                .compareTo(b.reco.title.toLowerCase()),
          );
      case _MatchSort.titleDesc:
        return [...list]..sort(
            (a, b) => b.reco.title
                .toLowerCase()
                .compareTo(a.reco.title.toLowerCase()),
          );
    }
  }

  /// Équivalent groupe : l'affinité affichée est la moyenne du groupe.
  List<GroupReco> _sortGrouped(List<GroupReco> list) {
    switch (_sort) {
      case _MatchSort.affinityDesc:
        return list;
      case _MatchSort.affinityAsc:
        return [...list]..sort((a, b) => a.combined.compareTo(b.combined));
      case _MatchSort.titleAsc:
        return [...list]..sort(
            (a, b) => a.reco.title
                .toLowerCase()
                .compareTo(b.reco.title.toLowerCase()),
          );
      case _MatchSort.titleDesc:
        return [...list]..sort(
            (a, b) => b.reco.title
                .toLowerCase()
                .compareTo(a.reco.title.toLowerCase()),
          );
    }
  }

  // ---------------------------------------------------------------------------
  // En groupe (2-4 profils)
  // ---------------------------------------------------------------------------

  Widget _buildGroup(UserProfile profile) {
    final l = AppLocalizations.of(context);
    if (_selectedProfileIds.isEmpty) {
      return Center(
        child: Text(
          l.selectAtLeastOneProfile(_selectedProfileIds.length + 1),
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    // Clé de cache scalaire (chaîne triée) : stable entre deux builds, sinon
    // le provider famille serait recréé en boucle et l'écran ne finirait pas
    // de charger.
    final group = profileGroupCacheKey([profile.id, ..._selectedProfileIds]);
    final async = ref.watch(matchmakingGroupTabProvider(group));
    return async.when(
      skipLoadingOnRefresh: false,
      data: (tab) {
        final list = _sortGrouped(_isMovie ? tab.movies : tab.series);
        if (list.isEmpty) return _emptyState(group: true);
        _totalCount = list.length;
        final hasMore = _visibleCount < list.length;
        final shown = list.take(_visibleCount).toList();
        return _buildGroupGrid(list: shown, hasMore: hasMore);
      },
      loading: _loadingView,
      error: (e, _) => Center(child: Text(userFriendlyError(e))),
    );
  }

  /// Garde-fou : explique à l'utilisateur pourquoi la liste n'est pas encore là
  /// (catalogue en cours de chargement, ou calcul des recommandations).
  Widget _loadingView() {
    final catalogLoading = ref.watch(moviesProvider).isLoading ||
        ref.watch(seriesProvider).isLoading;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/icons/orbit_loading_banner.jpg',
            width: 270,
            height: 90,
            fit: BoxFit.contain,
            semanticLabel: 'ORBIT IPTV',
          ),
          const SizedBox(height: 20),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            catalogLoading
                ? 'Chargement du catalogue en cours…'
                : 'Construction de vos recommandations en cours…',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurface, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Cela peut prendre jusqu\'à 1 minute.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Grilles
  // ---------------------------------------------------------------------------

  Widget _buildGrid({
    required List<ScoredReco> list,
    required bool hasMore,
  }) {
    final l = AppLocalizations.of(context);
    final totalShown = list.length;
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      gridDelegate: mediaCardGridDelegate(
        context,
        childAspectRatio: 0.62,
      ),
      itemCount: totalShown + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == totalShown) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                l.moreResults,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          );
        }
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
    final l = AppLocalizations.of(context);
    final totalShown = list.length;
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      gridDelegate: mediaCardGridDelegate(
        context,
        childAspectRatio: 0.62,
      ),
      itemCount: totalShown + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == totalShown) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                l.moreResults,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          );
        }
        final grouped = list[index];
        return _buildCard(
          grouped.reco,
          matchPercent: (grouped.combined * 100).round(),
        );
      },
    );
  }

  Widget _buildCard(Recommendation reco, {int? matchPercent}) {
    return MatchmakingRecommendationCard(
      reco: reco,
      matchPercent: matchPercent,
      onOpen: () => openRecommendation(context, reco),
      onLongPress: () => showProlongDecision(context, ref, reco),
    );
  }

  Widget _emptyState({bool group = false}) {
    final l = AppLocalizations.of(context);
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
            group ? l.noGroupAffinity : l.noRecommendations,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class MatchmakingRecommendationCard extends StatelessWidget {
  const MatchmakingRecommendationCard({
    super.key,
    required this.reco,
    required this.onOpen,
    required this.onLongPress,
    this.matchPercent,
  });

  final Recommendation reco;
  final int? matchPercent;
  final VoidCallback onOpen;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return TvFocus(
      onActivate: onOpen,
      onLongPress: onLongPress,
      child: MediaCard(
        focusable: false,
        title: reco.title,
        posterUrl: reco.posterUrl,
        year: reco.year,
        genre: reco.genre,
        rating: reco.rating,
        ageLabel: matchPercent != null ? null : reco.pegiLabel,
        fallbackIcon: reco.kind == RecommendationKind.movie
            ? Icons.movie_outlined
            : Icons.video_library_outlined,
        isNew: reco.isNew,
        matchPercent: matchPercent,
        onTap: onOpen,
        onLongPress: onLongPress,
      ),
    );
  }
}

/// Menu de tri compact, aligné avec le sélecteur Pour vous / En groupe.
class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.value, required this.onChanged});

  final _MatchSort value;
  final ValueChanged<_MatchSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<_MatchSort>(
      tooltip: 'Trier',
      initialValue: value,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final sort in _MatchSort.values)
          PopupMenuItem<_MatchSort>(
            value: sort,
            child: Row(
              children: [
                Icon(
                  sort == value ? Icons.check_rounded : Icons.sort,
                  size: 18,
                  color:
                      sort == value ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Text(sort.label),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              value.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
