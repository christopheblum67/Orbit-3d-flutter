import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/hardware/player_config.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/features/live_tv/widgets/channel_browse_view.dart';
import 'package:orbit_3d_flutter/features/live_tv/widgets/channel_grid_card.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/device_profile_provider.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;
import 'package:orbit_3d_flutter/services/stream_prewarm_service.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/features/live_tv/channel_groups.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

class LiveTvScreen extends ConsumerStatefulWidget {
  const LiveTvScreen({super.key});

  @override
  ConsumerState<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends ConsumerState<LiveTvScreen> {
  String _selectedGroup = '';

  /// Chaîne ouverte dans la vue de navigation (aperçu live + EPG), ou `null`
  /// quand on est sur la grille.
  ///
  /// Choisir une chaîne dans la grille fait CHANGER L'AFFICHAGE : on passe
  /// d'un coup sur la vue à deux zones (liste des chaînes de la catégorie à
  /// gauche, diffusion en cours et EPG à droite). Le retour arrière ramène à la
  /// grille — c'est donc là, et seulement là, qu'on change de catégorie.
  Channel? _browsingChannel;

  /// Chaîne sélectionnée dans la vue de navigation, pour le cas où la chaîne
  /// ouverte quitte le groupe courant (changement de catégorie).
  Channel? _browsingSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final channelsAsync = ref.watch(liveChannelsProvider);
    final favoriteEntries = ref.watch(favoritesProvider);
    final recentEntries = ref.watch(recentlyWatchedProvider);
    return Scaffold(
      appBar: AppBar(
        leading: _browsingChannel != null
            // En navigation, le retour remonte d'un cran vers la grille. Depuis
            // la grille, il quitte l'écran : deux destinations distinctes pour
            // deux écrans distincts, et non un retour qui sort de Live TV
            // pendant qu'on regarde l'aperçu d'une chaîne.
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Retour aux chaînes',
                onPressed: _closeBrowse,
              )
            : context.canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Retour',
                    onPressed: () => context.pop(),
                  )
                : null,
        title: Text(l.liveTv),
        actions: [
          IconButton(
            tooltip: l.searchChannel,
            icon: const Icon(Icons.live_tv),
            onPressed: () => context.push('/search?type=live'),
          ),
        ],
      ),
      // Le retour SYSTÈME (bouton matériel, geste) doit ramener à la grille
      // quand la vue d'aperçu est ouverte, exactement comme le bouton de la
      // barre d'outils.
      //
      // L'aperçu étant dessiné DANS la route Live TV, un `pop` le faisait
      // sortir de l'écran : le retour perdait la grille et ses catégories, ce
      // qui donnait l'impression d'une présentation différente.
      body: PopScope(
        canPop: _browsingChannel == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _closeBrowse();
        },
        child: TvSafeArea(
          child: channelsAsync.when(
          data: (channels) {
            if (channels.isEmpty) {
              return EmptyState(
                icon: Icons.live_tv_outlined,
                title: l.noChannelsAvailable,
                message: 'Ajoute une source de chaînes dans les réglages.',
              );
            }
            final groups = buildLiveChannelGroups(channels);
            final grouped = groups.length > 1 || groups.first.name.isNotEmpty;
            final favIds = favoriteEntries.values
                .where((e) => e.type == ContentType.live)
                .map((e) => e.id)
                .toSet();
            final liveRecentIds = recentEntries.values
                .where((e) => e.type == ContentType.live)
                .map((e) => e.id)
                .toSet();
            final categoryGroups = _groupToCategories(
              groups,
              totalCount: channels.length,
              favCount: channels.where((c) => favIds.contains(c.id)).length,
              recentCount:
                  channels.where((c) => liveRecentIds.contains(c.id)).length,
            );
  
            final List<Channel> visibleChannels;
            // Résolution du contenu d'une catégorie. Extraite en fonction parce
            // que les flèches de la vue de navigation en ont besoin aussi :
            // changing de catégorie sans repasser par la grille doit charger la
            // même liste que la grille.
            List<Channel> channelsFor(String group) {
              if (group == 'fav') {
                return channels.where((c) => favIds.contains(c.id)).toList();
              }
              if (group == 'recent') {
                return channels.where((c) => liveRecentIds.contains(c.id)).toList();
              }
              if (!grouped) return groups.first.channels;
              if (group.isEmpty) {
                return [for (final g in groups) ...g.channels];
              }
              if (group.startsWith('g')) {
                final index = int.tryParse(group.substring(1));
                return (index != null && index >= 0 && index < groups.length)
                    ? groups[index].channels
                    : const <Channel>[];
              }
              return const <Channel>[];
            }
  
            visibleChannels = channelsFor(_selectedGroup);
  
            // Vue de navigation : elle prime sur la grille, et se referme au
            // retour arrière.
            final browsing = _browsingChannel;
            if (browsing != null && visibleChannels.isNotEmpty) {
              final selected = _browsingSelected ?? browsing;
              final previousCategory =
                  _stepCategory(categoryGroups, _selectedGroup, -1);
              final nextCategory = _stepCategory(categoryGroups, _selectedGroup, 1);
              final currentCategory = categoryGroups
                  .firstWhere(
                    (c) => c.id == _selectedGroup,
                    orElse: () => categoryGroups.first,
                  )
                  .name;
              return ChannelBrowseView(
                channels: visibleChannels,
                selected: visibleChannels.any((c) => c.id == selected.id)
                    ? selected
                    : visibleChannels.first,
                onSelect: (c) => setState(() => _browsingSelected = c),
                onWatch: () => _openPlayer(groups, selected),
                onBack: _closeBrowse,
                categoryName: currentCategory,
                onPreviousCategory: previousCategory == null
                    ? null
                    : () => _goToCategory(previousCategory, channelsFor),
                onNextCategory: nextCategory == null
                    ? null
                    : () => _goToCategory(nextCategory, channelsFor),
              );
            }
  
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (grouped && categoryGroups.isNotEmpty)
                  CategoriesRail(
                    categories: categoryGroups,
                    selectedId: _selectedGroup,
                    onSelected: (id) => setState(() {
                        _selectedGroup = id;
                        // Changer de catégorie referme la vue de navigation :
                        // celle-ci est attachée à une catégorie, pas au catalogue.
                        _browsingChannel = null;
                        _browsingSelected = null;
                      }),
                  ),
                Expanded(
                  child: visibleChannels.isEmpty
                      ? EmptyState(
                          icon: Icons.live_tv_outlined,
                          title: _selectedGroup == 'fav'
                              ? 'Aucune chaîne favorite'
                              : _selectedGroup == 'recent'
                                  ? 'Aucune chaîne récente'
                                  : 'Aucune chaîne dans ce groupe',
                          message: _selectedGroup == 'fav'
                              ? 'Appuie sur le cœur d\'une chaîne pour la '
                                  'retrouver ici.'
                              : _selectedGroup == 'recent'
                                  ? 'Les chaînes regardées s\'afficheront ici.'
                                  : 'Ce groupe ne contient aucune chaîne.',
                        )
                      : FocusTraversalGroup(
                          policy: OrderedTraversalPolicy(),
                          child: GridView.builder(
                            padding: channelGridPadding,
                            // Delegate partagé avec le Replay : même tuile, même
                            // taille sur les deux écrans.
                            gridDelegate: channelGridDelegate,
                            itemCount: visibleChannels.length,
                            itemBuilder: (context, index) {
                              final channel = visibleChannels[index];
                              return ChannelGridCard(
                                name: channel.name,
                                logoUrl: channel.logoUrl,
                                badgeNumber: channel.orderNum,
                                favoriteEntry: FavoriteEntry(
                                  type: ContentType.live,
                                  id: channel.id,
                                  title: channel.name,
                                  posterUrl: channel.logoUrl,
                                  subtitle: channel.groupLabel,
                                  streamUrl: channel.streamUrl,
                                ),
                                onTap: () => _openChannel(channel),
                                onFocus: () => unawaited(_prewarm(channel)),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
          loading: () => const LoadingState(message: 'Chargement…'),
          error: (err, _) => ErrorState(
            icon: Icons.live_tv_outlined,
            title: l.channelsUnavailable,
            message: userFriendlyError(err),
            onRetry: () => ref.invalidate(liveChannelsProvider),
          ),
          ),
        ),
      ),
    );
  }

  static List<MediaCategory> _groupToCategories(
    List<ChannelGroup> groups, {
    required int totalCount,
    required int favCount,
    required int recentCount,
  }) {
    final categories = <MediaCategory>[
      MediaCategory(id: '', name: 'Tous', count: totalCount),
      MediaCategory(id: 'fav', name: 'Favoris', count: favCount),
      MediaCategory(id: 'recent', name: 'Récemment', count: recentCount),
      for (var i = 0; i < groups.length; i++)
        MediaCategory(
          id: 'g$i',
          name: groups[i].name.isEmpty ? 'Non groupé' : groups[i].name,
          count: groups[i].channels.length,
        ),
    ];
    return categories;
  }

  /// Ferme la vue de navigation et revient à la grille.
  void _closeBrowse() {
    setState(() {
      _browsingChannel = null;
      _browsingSelected = null;
    });
  }

  /// Catégorie vers laquelle pointer la flèche, en ignorant les catégories
  /// vides — sinon le pas pouvait atterrir sur « Favoris » sans rien dedans.
  ///
  /// Renvoie `null` quand il n'existe aucune autre catégorie àillede, ce qui
  /// fait disparaître la flèche plutôt que de la laisser inerte.
  static String? _stepCategory(
    List<MediaCategory> categories,
    String currentId,
    int delta,
  ) {
    if (categories.length < 2) return null;
    final index = categories.indexWhere((c) => c.id == currentId);
    if (index < 0) return null;
    for (var step = 1; step <= categories.length; step++) {
      // En Dart, `%` avec un diviseur positif donne toujours un reste positif :
      // le parcours arrière est donc correct sans correction manuelle.
      final candidate = categories[(index + delta * step) % categories.length];
      if (candidate.count > 0) return candidate.id;
    }
    return null;
  }

  /// Change de catégorie depuis la vue de navigation, SANS repasser par la
  /// grille : c'est précisément ce que les flèches évitent.
  ///
  /// La chaîne affichée appartient rarement à la nouvelle catégorie, donc on
  /// libère la sélection : l'aperçu et l'EPG repartent sur la première chaîne
  /// du groupe, et celle-ci est préchauffée.
  void _goToCategory(String id, List<Channel> Function(String) channelsFor) {
    final target = channelsFor(id);
    setState(() {
      _selectedGroup = id;
      _browsingSelected = null;
    });
    if (target.isNotEmpty) unawaited(_prewarm(target.first));
  }

  /// Précharge le flux au curseur : le contrôleur créé en amont est moins cher
  /// à démarrer qu'un contrôleur neuf.
  ///
  /// Le profil media3 est poussé AVANT la création du contrôleur : la config
  /// est lue à la construction de l'ExoPlayer, donc un préchauffage lancé sans
  /// ce `push` figerait des seuils par défaut (tampons de 50 s, pas de plafond
  /// de résolution) sur le contrôleur que l'écran de lecture récupère ensuite —
  /// la première chaîne regardée après un démarrage d'application ignorait le
  /// profil de l'appareil.
  Future<void> _prewarm(Channel channel) async {
    await PlayerProfileService.pushForDevice(ref.read(deviceProfileProvider));
    if (!mounted) return;
    StreamPrewarmService.instance.prewarm(
      channel.streamUrl,
      stream_helpers.streamHeaders(channel.streamUrl),
    );
  }

  /// Choisir une chaîne fait CHANGER L'AFFICHAGE : on bascule sur la vue de
  /// navigation (liste des chaînes de la catégorie à gauche, diffusion en
  /// cours et EPG à droite), au lieu d'une feuille modale. La lecture
  /// plein écran y reste une action explicite.
  ///
  /// Lancer la lecture dès l'appui était un défaut d'usage inverse : le logo
  /// seul ne confirme pas la chaîne choisie, et un appui adjacent figeait la
  /// télé. La vue de navigation donne la confirmation visuelle (l'aperçu) sans
  /// imposer de geste supplémentaire.
  void _openChannel(Channel channel) {
    unawaited(_prewarm(channel));
    setState(() {
      _browsingChannel = channel;
      _browsingSelected = channel;
    });
  }

  void _openPlayer(List<ChannelGroup> groups, Channel channel) {
    var groupIndex = -1;
    for (var i = 0; i < groups.length; i++) {
      if (groups[i].channels.contains(channel)) {
        groupIndex = i;
        break;
      }
    }
    final list =
        groupIndex >= 0 ? groups[groupIndex].channels : <Channel>[channel];
    final index = list.indexOf(channel);
    context.push(
      '/player',
      extra: PlayerRouteData(
        streamUrl: channel.streamUrl,
        title: channel.name,
        channels: list,
        index: index,
        contentType: PlaybackContentType.live,
        favorite: FavoriteEntry(
          type: ContentType.live,
          id: channel.id,
          title: channel.name,
          posterUrl: channel.logoUrl,
          subtitle: channel.groupLabel,
          streamUrl: channel.streamUrl,
        ),
      ),
    );
  }
}
