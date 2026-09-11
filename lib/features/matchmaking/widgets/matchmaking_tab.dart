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
// Mode d'affichage (Pour vous / En duo)
// ---------------------------------------------------------------------------

enum _TabMode { single, duo }

// ---------------------------------------------------------------------------
// Widget racine des onglets Films / Séries du Matchmaking
// ---------------------------------------------------------------------------

/// Contenu matchmaking d'un onglet Films ou Séries : mode Pour vous / En duo,
/// grille avec chargement infini (paquets de 50), badge % d'affinité en duo.
class MatchmakingTab extends ConsumerStatefulWidget {
  const MatchmakingTab({super.key, required this.kind});

  final RecommendationKind kind;

  @override
  ConsumerState<MatchmakingTab> createState() => _MatchmakingTabState();
}

class _MatchmakingTabState extends ConsumerState<MatchmakingTab> {
  _TabMode _mode = _TabMode.single;
  String? _secondProfileId;
  int _visibleCount = kMatchmakingPageSize;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  bool get _isMovie => widget.kind == RecommendationKind.movie;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

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
        if (_mode == _TabMode.duo)
          _buildDuoHeader(profile),
        Expanded(
          child: _mode == _TabMode.single
              ? _buildSingle(profile)
              : _buildDuo(profile),
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
                  value: _TabMode.duo,
                  label: Text('En duo'),
                  icon: Icon(Icons.people_outline),
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
  // En duo – sélection du second profil
  // ---------------------------------------------------------------------------

  Widget _buildDuoHeader(UserProfile profile) {
    final profiles = ref.watch(profilesProvider).valueOrNull ?? const <UserProfile>[];
    final others = profiles.where((p) => p.id != profile.id).toList();

    final secondId = _secondProfileId != null &&
            _secondProfileId != profile.id &&
            profiles.any((p) => p.id == _secondProfileId)
        ? _secondProfileId!
        : _defaultSecondId(profile, profiles);

    // Met à jour silencieusement le state si le default a changé
    if (_secondProfileId == null && secondId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _secondProfileId = secondId);
      });
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Profil 1 : ${profile.firstName}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (others.isNotEmpty)
            DropdownButton<String>(
              value: secondId,
              hint: const Text('Choisir le 2e profil'),
              isExpanded: true,
              items: others
                  .map((p) => DropdownMenuItem(value: p.id, child: Text(p.firstName)))
                  .toList(),
              onChanged: (id) {
                setState(() => _secondProfileId = id);
                _reset();
              },
            ),
        ],
      ),
    );
  }

  String? _defaultSecondId(UserProfile current, List<UserProfile> profiles) {
    for (final p in profiles) {
      if (p.id != current.id) return p.id;
    }
    return null;
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
  // En duo
  // ---------------------------------------------------------------------------

  Widget _buildDuo(UserProfile profile) {
    final profiles = ref.watch(profilesProvider).valueOrNull ?? const <UserProfile>[];
    final secondId = _secondProfileId ?? _defaultSecondId(profile, profiles);
    if (secondId == null) {
      return Center(
        child: Text(
          'Sélectionnez un second profil',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    final async = ref.watch(matchmakingPairTabProvider((a: profile.id, b: secondId)));
    return async.when(
      data: (tab) {
        final list = _isMovie ? tab.movies : tab.series;
        if (list.isEmpty) return _emptyState(duo: true);
        _hasMore = _visibleCount < list.length;
        final shown = list.take(_visibleCount).toList();
        return _buildPairGrid(list: shown, hasMore: _hasMore);
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
        final reco = list[index].reco;
        return _buildCard(reco);
      },
    );
  }

  Widget _buildPairGrid({
    required List<PairedReco> list,
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
        final paired = list[index];
        return _buildCard(
          paired.reco,
          affinityPercent: (paired.combined * 100).round(),
        );
      },
    );
  }

  Widget _buildCard(Recommendation reco, {int? affinityPercent}) {
    return MediaCard(
      title: reco.title,
      posterUrl: reco.posterUrl,
      year: reco.year,
      genre: reco.genre,
      rating: reco.rating,
      ageLabel: affinityPercent != null ? null : reco.pegiLabel,
      fallbackIcon: _isMovie ? Icons.movie_outlined : Icons.video_library_outlined,
      isNew: reco.isNew,
      topBadge: affinityPercent != null ? _AffinityBadge(percent: affinityPercent) : null,
      onTap: () => openRecommendation(context, reco),
    );
  }

  Widget _emptyState({bool duo = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
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
                : 'Aucune recommandation disponible',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badge affinité (en haut à gauche, utilisant topBadge de MediaCard)
// ---------------------------------------------------------------------------

class _AffinityBadge extends StatelessWidget {
  const _AffinityBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$percent%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
