import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/search.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/core/widgets/cached_image.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (query != _lastQuery) {
        _lastQuery = query;
        setState(() {});
      }
    });
  }

  void _clearQuery() {
    _searchController.clear();
    _onQueryChanged('');
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    final uri = GoRouterState.of(context).uri;
    final typeParam = uri.queryParameters['type'];
    final filterType =
        typeParam != null ? SearchType.values.byName(typeParam) : null;
    final categoryId = uri.queryParameters['category'];

    final searchAsync = filterType != null
        ? ref.watch(
            searchFilteredProvider(
              (
                query: query,
                filterType: filterType,
                categoryId: categoryId,
              ),
            ),
          )
        : ref.watch(searchProvider(query));
    final suggestionsAsync = ref.watch(searchSuggestionsProvider(query));
    final historyAsync = ref.watch(searchServiceProvider).getHistory();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(query, suggestionsAsync, historyAsync, filterType),
            // Sélecteur de catégorie : la recherche suit le même principe de
            // filtrage que les grilles VOD / Séries / Chaînes. Sans lui, une
            // recherche dans une section renvoyait toute la section, et
            // l'utilisateur découvrait des résultats hors du périmètre choisi.
            if (filterType != null && categoryId != null)
              _buildCategorySelector(filterType),
            Expanded(
              child: query.isEmpty
                  ? _buildEmptyState(historyAsync, filterType)
                  : _buildResults(searchAsync, query, filterType),
            ),
          ],
        ),
      ),
    );
  }

  /// Sélecteur de catégorie, aligné sur le principe des grilles de section.
  ///
  /// Alimente `?category=` dans l'URL plutôt qu'un état local : la catégorie
  /// choisie survit à une rotation, à une reconstruction de l'écran, et reste
  /// partageable. C'est aussi ce qui permet à `searchFilteredProvider` de
  /// réagir sans état dupliqué.
  ///
  /// L'EPG et le replay n'ont pas de grille de catégories équivalente : le
  /// sélecteur ne s'affiche alors pas, plutôt que d'imposer un filtrage qui ne
  /// correspond à rien.
  Widget _buildCategorySelector(SearchType filterType) {
    final AsyncValue<List<MediaCategory>> cats = switch (filterType) {
      SearchType.vod => ref.watch(vodCategoriesProvider),
      SearchType.series => ref.watch(seriesCategoriesProvider),
      _ => const AsyncValue.data(<MediaCategory>[]),
    };
    final categories = cats.value ?? const <MediaCategory>[];
    final uri = GoRouterState.of(context).uri;
    final current = uri.queryParameters['category'] ?? '';

    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // « Toutes » remet la catégorie à zéro (paramètre absent).
          _categoryChip(
            label: 'Toutes',
            selected: current.isEmpty,
            onTap: () => _setCategory(null),
          ),
          for (final c in categories)
            _categoryChip(
              label: c.name,
              selected: current == c.id,
              onTap: () => _setCategory(c.id),
            ),
        ],
      ),
    );
  }

  Widget _categoryChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? scheme.onSecondaryContainer : null,
            ),
        selectedColor: scheme.secondaryContainer,
        backgroundColor: scheme.surfaceContainerHighest,
      ),
    );
  }

  void _setCategory(String? id) {
    final uri = GoRouterState.of(context).uri;
    final params = <String, String>{...uri.queryParameters};
    if (id == null || id.isEmpty) {
      params.remove('category');
    } else {
      params['category'] = id;
    }
    context.go(uri.replace(queryParameters: params).toString());
  }

  Widget _buildSearchBar(
    String query,
    AsyncValue<List<SearchSuggestion>> suggestionsAsync,
    Future<List<String>> historyFuture,
    SearchType? filterType,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final searchController = SearchController();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SearchAnchor(
        searchController: searchController,
        viewBackgroundColor: scheme.surface,
        viewHintText: filterType != null
            ? 'Rechercher dans ${_typeLabel(filterType).toLowerCase()}...'
            : 'Rechercher Live, Films, Séries, Replay, EPG...',
        viewTrailing: query.isNotEmpty
            ? <Widget>[
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearQuery,
                  tooltip: 'Effacer',
                ),
              ]
            : null,
        suggestionsBuilder: (context, controller) {
          return _buildSuggestions(suggestionsAsync, historyFuture);
        },
        builder: (context, controller) {
          return SearchBar(
            controller: controller,
            focusNode: _focusNode,
            hintText: filterType != null
                ? 'Rechercher dans ${_typeLabel(filterType).toLowerCase()}...'
                : 'Rechercher...',
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Retour',
                ),
              ],
            ),
            trailing: <Widget>[
              if (query.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearQuery,
                  tooltip: 'Effacer',
                ),
            ],
            onTap: () => controller.openView(),
            onChanged: (value) {
              _searchController.text = value;
              _onQueryChanged(value);
            },
            onSubmitted: (value) {
              _focusNode.unfocus();
            },
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 12),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            elevation: const WidgetStatePropertyAll(0),
          );
        },
      ),
    );
  }

  Iterable<Widget> _buildSuggestions(
    AsyncValue<List<SearchSuggestion>> suggestionsAsync,
    Future<List<String>> historyFuture,
  ) {
    return suggestionsAsync.when(
      data: (suggestions) => _buildSuggestionsList(suggestions),
      loading: () => _buildSuggestionsList([]),
      error: (_, __) => _buildHistorySuggestions(historyFuture),
    );
  }

  Iterable<Widget> _buildSuggestionsList(List<SearchSuggestion> suggestions) {
    if (suggestions.isEmpty) return const [];

    return [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child:
            Text('Suggestions', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      ...suggestions.map((s) => _buildSuggestionTile(s)),
    ];
  }

  Iterable<Widget> _buildHistorySuggestions(
    Future<List<String>> historyFuture,
  ) {
    return [
      FutureBuilder<List<String>>(
        future: historyFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }
          final history = snapshot.data!.take(5).toList();
          final l = AppLocalizations.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  l.recentSearches,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ...history.map(
                (h) => _buildSuggestionTile(
                  SearchSuggestion(text: h, isHistory: true),
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  Widget _buildSuggestionTile(SearchSuggestion suggestion) {
    return ListTile(
      leading: Icon(
        suggestion.isHistory ? Icons.history : _typeIcon(suggestion.type),
        size: 20,
      ),
      title: Text(suggestion.text),
      trailing: suggestion.isHistory
          ? IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () async {
                await ref.read(searchServiceProvider).clearHistory();
                // Effacement disque : aucune garde, le `setState` pouvait
                // s'exécuter sur un State démonté.
                if (!mounted) return;
                setState(() {});
              },
              tooltip: 'Supprimer de l\'historique',
            )
          : null,
      onTap: () {
        _searchController.text = suggestion.text;
        _searchController.selection =
            TextSelection.collapsed(offset: suggestion.text.length);
        _focusNode.unfocus();
      },
    );
  }

  Widget _buildEmptyState(
    Future<List<String>> historyFuture,
    SearchType? filterType,
  ) {
    return FutureBuilder<List<String>>(
      future: historyFuture,
      builder: (context, snapshot) {
        final history = snapshot.data ?? [];
        final hasHistory = history.isNotEmpty;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(searchServiceProvider);
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      filterType != null
                          ? 'Recherche dans ${_typeLabel(filterType)}'
                          : 'Recherche unifiée',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    if (filterType != null) ...[
                      const SizedBox(width: 12),
                      Chip(
                        label: Text(_typeLabel(filterType)),
                        avatar: Icon(_typeIcon(filterType), size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  filterType != null
                      ? 'Tapez pour rechercher uniquement dans les ${_typeLabel(filterType).toLowerCase()}.'
                      : 'Tapez votre recherche pour trouver des chaînes Live, films, séries, replays ou programmes EPG.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                if (hasHistory) ...[
                  (() {
                    final l = AppLocalizations.of(context);
                    return Row(
                      children: [
                        Text(
                          l.recentSearches,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            await ref
                                .read(searchServiceProvider)
                                .clearHistory();
                            // Effacement disque : aucune garde, le `setState`
                            // pouvait s'exécuter sur un State démonté.
                            if (!mounted) return;
                            setState(() {});
                          },
                          child: const Text('Effacer'),
                        ),
                      ],
                    );
                  }()),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: history
                        .take(8)
                        .map((h) => _buildHistoryChip(h))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryChip(String query) {
    return ActionChip(
      label: Text(query),
      onPressed: () {
        _searchController.text = query;
        _focusNode.unfocus();
      },
      avatar: const Icon(Icons.history, size: 16),
    );
  }

  Widget _buildResults(
    AsyncValue<UnifiedSearchResult> searchAsync,
    String query,
    SearchType? filterType,
  ) {
    return searchAsync.when(
      data: (result) {
        if (result.items.isEmpty) {
          return _buildNoResults(query);
        }
        return RefreshIndicator(
          onRefresh: () async {
            if (filterType != null) {
              ref.invalidate(
                searchFilteredProvider(
                  (
                    query: query,
                    filterType: filterType,
                    categoryId: GoRouterState.of(context)
                        .uri
                        .queryParameters['category'],
                  ),
                ),
              );
            } else {
              ref.invalidate(searchProvider(query));
            }
            await ref.read(searchServiceProvider).addToHistory(query);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (result.isOffline) _buildOfflineBanner(),
              _buildResultsHeader(context, result, filterType),
              ..._buildGroupedResults(result, query),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildOfflineBanner() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: scheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mode hors ligne — résultats locaux uniquement',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(
    BuildContext context,
    UnifiedSearchResult result,
    SearchType? filterType,
  ) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            '${result.count} résultat${result.count > 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          if (filterType != null)
            Chip(
              label: Text(_typeLabel(filterType)),
              avatar: Icon(_typeIcon(filterType), size: 14),
              visualDensity: VisualDensity.compact,
            ),
          if (result.isOffline)
            Chip(
              label: Text(l.offline),
              avatar: const Icon(Icons.wifi_off, size: 14),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Iterable<Widget> _buildGroupedResults(
    UnifiedSearchResult result,
    String query,
  ) {
    final grouped = result.groupedByType;
    final typeOrder = [
      SearchType.live,
      SearchType.vod,
      SearchType.series,
      SearchType.replay,
      SearchType.epg,
    ];

    final widgets = <Widget>[];
    for (final type in typeOrder) {
      final items = grouped[type];
      if (items == null || items.isEmpty) continue;
      widgets.add(_buildSectionHeader(type, items.length));
      widgets.addAll(items.map((item) => _buildResultTile(item, query)));
      widgets.add(const SizedBox(height: 16));
    }
    return widgets;
  }

  Widget _buildSectionHeader(SearchType type, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Row(
        children: [
          Icon(
            _typeIcon(type),
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '${_typeLabel(type)} ($count)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(SearchItem item, String query) {
    final highlightedTitle = _highlightMatch(item.title, query);
    final highlightedSubtitle = _highlightMatch(item.subtitle, query);

    return InkWell(
      onTap: () => _onItemTap(item),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: item.posterUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedImage(
                    imageUrl: item.posterUrl,
                    width: 56,
                    height: 84,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _placeholderIcon(item.type),
                  ),
                )
              : _placeholderIcon(item.type),
          title: Text.rich(
            highlightedTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: item.subtitle.isNotEmpty
              ? Text.rich(
                  highlightedSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: item.streamUrl != null && item.streamUrl!.isNotEmpty
              ? const Icon(Icons.play_circle_filled, size: 28)
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
      ),
    );
  }

  Widget _placeholderIcon(SearchType type) {
    return Container(
      width: 56,
      height: 84,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _typeIcon(type),
        size: 28,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  TextSpan _highlightMatch(String text, String query) {
    if (query.trim().isEmpty || text.isEmpty) {
      return TextSpan(text: text);
    }

    final normalizedQuery = query.toLowerCase().trim();
    final normalizedText = text.toLowerCase();

    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = normalizedText.indexOf(normalizedQuery, start);
      if (index == -1) break;

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + normalizedQuery.length),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      start = index + normalizedQuery.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return TextSpan(children: spans.isEmpty ? [TextSpan(text: text)] : spans);
  }

  void _onItemTap(SearchItem item) {
    if (item.streamUrl != null && item.streamUrl!.isNotEmpty) {
      final playbackType = switch (item.type) {
        SearchType.vod => PlaybackContentType.vod,
        SearchType.series => PlaybackContentType.series,
        SearchType.replay => PlaybackContentType.replay,
        _ => PlaybackContentType.live,
      };
      final movie =
          item.originalObject is Movie ? item.originalObject as Movie : null;
      final series =
          item.originalObject is Series ? item.originalObject as Series : null;
      context.push(
        '/player',
        extra: PlayerRouteData(
          streamUrl: item.streamUrl!,
          title: item.title,
          contentType: playbackType,
          posterUrl: item.posterUrl.isNotEmpty ? item.posterUrl : null,
          subtitle: item.subtitle.isNotEmpty ? item.subtitle : null,
          rating: (movie != null && movie.rating > 0)
              ? movie.rating
              : ((series != null && series.rating > 0) ? series.rating : null),
          genre: (movie != null && movie.genre.isNotEmpty)
              ? movie.genre
              : ((series != null && series.genre.isNotEmpty)
                  ? series.genre
                  : null),
          year: movie?.year ?? series?.year ?? 0,
          favorite: FavoriteEntry(
            type: ContentType.values.firstWhere(
              (t) => t.name == item.type.name,
              orElse: () => ContentType.vod,
            ),
            id: item.id,
            title: item.title,
            posterUrl: item.posterUrl,
            subtitle: item.subtitle,
            streamUrl: item.streamUrl!,
          ),
        ),
      );
    } else if (item.type == SearchType.series &&
        item.originalObject is Series) {
      Navigator.of(context)
          .pushNamed('/series', arguments: item.originalObject);
    } else if (item.type == SearchType.epg &&
        item.originalObject is EPGProgram) {
      _showEpgDetail(item.originalObject as EPGProgram);
    }
  }

  void _showEpgDetail(EPGProgram program) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              program.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${program.channelId} · ${program.start.toString().substring(11, 16)}–${program.end.toString().substring(11, 16)}',
            ),
            if (program.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(program.description),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat pour "$query"',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez avec d\'autres termes ou vérifiez l\'orthographe.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(l.searchError, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () =>
                ref.invalidate(searchProvider(_searchController.text.trim())),
            child: Text(l.retry),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(SearchType? type) {
    return switch (type) {
      SearchType.live => Icons.live_tv,
      SearchType.vod => Icons.movie,
      SearchType.series => Icons.tv,
      SearchType.replay => Icons.replay,
      SearchType.epg => Icons.schedule,
      null => Icons.search,
    };
  }

  String _typeLabel(SearchType type) {
    return switch (type) {
      SearchType.live => 'Live TV',
      SearchType.vod => 'Films',
      SearchType.series => 'Séries',
      SearchType.replay => 'Replay',
      SearchType.epg => 'Guide TV',
    };
  }
}
