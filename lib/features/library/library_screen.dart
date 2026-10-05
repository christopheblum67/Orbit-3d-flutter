import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/favorites/favorites_screen.dart';
import 'package:orbit_3d_flutter/features/library/content_type_selector.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Écran « Mes contenus » : deux onglets, Favoris et Téléchargements.
///
/// ## Pourquoi un écran unique
///
/// Les deux listes répondent toujours à la même question — « qu'ai-je gardé ? » —
/// et se répondent l'une l'autre : un téléchargement terminé rejoint les
/// favoris, et un favori se télécharge. Les séparer obligait à deux chemins
/// d'accès, dont un qui n'existait pas : la route `/downloads` était déclarée
/// mais aucun lien n'y menait.
///
/// Le type de contenu est choisi par des puces sous les onglets plutôt que par
/// une seconde barre d'onglets : deux barres superposées se disputent la
/// hauteur, et l'une finit par rogner le contenu de l'autre.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key, this.initialTab = 0});

  /// 0 = Favoris, 1 = Téléchargements.
  ///
  /// Les deux routes existantes pointent ici avec un onglet pré-sélectionné :
  /// un lien vers « Favoris » doit arriver sur les favoris, pas sur les
  /// téléchargements.
  final int initialTab;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs =
      TabController(length: 2, vsync: this, initialIndex: widget.initialTab);

  ContentType _favoritesType = ContentType.live;
  ContentType _downloadsType = ContentType.vod;

  @override
  void initState() {
    super.initState();
    // L'action « tout supprimer » n'existe que sur l'onglet Favoris : sans
    // cette reconstruction, elle resterait visible après un switch vers les
    // téléchargements, où elle n'a pas de sens.
    _tabs.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    setState(() {});
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final favorites = ref.watch(favoritesProvider);

    final favCounts = <ContentType, int>{
      for (final type in ContentType.values)
        type: favorites.values.where((e) => e.type == type).length,
    };
    final dlCounts = _downloadCounts(ref);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(l.favoritesAndDownloads),
        actions: [
          // L'action reste sur l'onglet Favoris et suit l'onglet sélectionné :
          // « tout supprimer » n'a pas de sens sur les téléchargements.
          if (_tabs.index == 0 && favorites.isNotEmpty)
            IconButton(
              tooltip: l.deleteAll,
              icon: const Icon(Icons.delete_sweep),
              onPressed: () =>
                  confirmClearAllFavorites(context, ref, favorites.length),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          // Texte seul : les icônes n'apportaient rien ici et mangeaient la
          // hauteur d'une barre déjà en concurrence avec les puces de type.
          tabs: [
            Tab(text: _withCount(l.favorites, favorites.length)),
            Tab(
              text: _withCount(
                l.downloads,
                dlCounts.values.fold(0, (a, b) => a + b),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          Column(
            children: [
              ContentTypeSelector(
                selected: _favoritesType,
                counts: favCounts,
                onChanged: (t) => setState(() => _favoritesType = t),
              ),
              Expanded(child: _favoritesBody()),
            ],
          ),
          Column(
            children: [
              ContentTypeSelector(
                selected: _downloadsType,
                counts: dlCounts,
                // Le direct n'est pas téléchargeable : proposer « Live » et
                // « Replay » ne montrerait qu'une liste vide.
                types: const [ContentType.vod, ContentType.series],
                onChanged: (t) => setState(() => _downloadsType = t),
              ),
              Expanded(child: DownloadsSection(type: _downloadsType)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _favoritesBody() {
    switch (_favoritesType) {
      case ContentType.live:
        return const FavoritesLiveSection();
      case ContentType.vod:
        return const FavoritesVodSection();
      case ContentType.series:
        return const FavoritesSeriesSection();
      case ContentType.replay:
        return const FavoritesReplaySection();
    }
  }

  /// Comptes de téléchargements par type, lus du même flux que la liste.
  Map<ContentType, int> _downloadCounts(WidgetRef ref) {
    final tasks = ref.watch(downloadTasksStreamProvider).value;
    if (tasks == null) return const {};
    final counts = <ContentType, int>{};
    for (final task in tasks) {
      final type = _typeOf(task.contentType);
      if (type != null) counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  static ContentType? _typeOf(String contentType) {
    switch (contentType) {
      case 'live':
        return ContentType.live;
      case 'vod':
        return ContentType.vod;
      case 'series':
        return ContentType.series;
      case 'replay':
        return ContentType.replay;
      default:
        return null;
    }
  }

  static String _withCount(String label, int count) =>
      count > 0 ? '$label ($count)' : label;
}
