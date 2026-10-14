import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/core/widgets/error_state.dart';
import 'package:orbit_3d_flutter/core/widgets/loading_state.dart';
import 'package:orbit_3d_flutter/core/utils/epg_lookup.dart';
import 'package:orbit_3d_flutter/features/epg/replay_utils.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/utils/epg_search.dart';
import 'package:orbit_3d_flutter/utils/epg_gap_filler.dart';
import 'package:orbit_3d_flutter/core/utils/epg_day_window.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_grid_2d_view.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_headbar.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_timeline_controller.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/catch_up_screen.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_preview_header.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Guide TV (EPG) : affiche la Grille EPG seule.
///
/// Les vues lourdes (Orbite 3D) et annexes (Favoris, Recherche) ont été
/// retirées de cet écran pour éliminer la latence : l'Orbite 3D (canvas,
/// rotation, focus) était une cause probable de freeze/ANR sur les box TV.
/// Elles seront repositionnées dans d'autres sections dédiées.
class EpgScreen extends ConsumerStatefulWidget {
  const EpgScreen({super.key});

  @override
  ConsumerState<EpgScreen> createState() => _EpgScreenState();
}

class _EpgScreenState extends ConsumerState<EpgScreen> {
  String? _gridCategory;
  EPGProgram? _selectedProgram;
  Channel? _selectedChannel;
  late final EpgTimelineController _timelineController;

  @override
  void initState() {
    super.initState();
// Fenêtre de la journée, partagée avec le Replay : une seule définition de
    // « la journée » dans toute l'application.
    final gridStartTime = EpgDayWindow.ofNow().start;
    _timelineController = EpgTimelineController(
      gridStartTime: gridStartTime,
      pixelsPerMinute: EpgTimelineController.defaultPixelsPerMinute,
    );
  }

  @override
  void dispose() {
    _timelineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Retour',
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(l.epgGuideTv),
      ),
      body: _buildGrid2DTab(),
    );
  }

  Widget _buildGrid2DTab() {
    final l = AppLocalizations.of(context);
    final channelsAsync = ref.watch(liveChannelsProvider);
    final favoriteEntries = ref.watch(favoritesProvider);
    final recentEntries = ref.watch(recentlyWatchedProvider);

    return channelsAsync.when(
      data: (channels) {
        if (channels.isEmpty) {
          return Center(child: Text(l.noChannelsAvailable));
        }
        const ungroupedLabel = 'Non groupé';
        String categoryOf(Channel c) =>
            c.groupLabel.isEmpty ? ungroupedLabel : c.groupLabel;
        final groupCounts = <String, int>{};
        for (final c in channels) {
          final key = categoryOf(c);
          groupCounts[key] = (groupCounts[key] ?? 0) + 1;
        }
        final categories = [
          for (final entry in groupCounts.entries)
            MediaCategory(
              id: entry.key,
              name: entry.key,
              count: entry.value,
            ),
        ];
        final effective = _gridCategory ?? categories.first.id;
        final favIds = favoriteEntries.values
            .where((e) => e.type == ContentType.live)
            .map((e) => e.id)
            .toSet();
        final recentIds = recentEntries.values
            .where((e) => e.type == ContentType.live)
            .map((e) => e.id)
            .toSet();
        final favCount = channels.where((c) => favIds.contains(c.id)).length;
        final recentCount =
            channels.where((c) => recentIds.contains(c.id)).length;
        final List<Channel> visible;
        if (effective == 'fav') {
          visible = channels.where((c) => favIds.contains(c.id)).toList();
        } else if (effective == 'recent') {
          visible = channels.where((c) => recentIds.contains(c.id)).toList();
        } else {
          visible = channels.where((c) => categoryOf(c) == effective).toList();
        }
        return Column(
          children: [
            // Barre d'en-tête unifiée : programme en cours + programme suivant
            // + actions (favori, lecture, info) pour la chaîne ciblée.
            _EpgHeadbarSection(
              channels: channels,
              controller: _timelineController,
            ),
            _CategoryFilterBar(
              categories: categories,
              selected: effective,
              favCount: favCount,
              recentCount: recentCount,
              onSelected: (category) =>
                  setState(() => _gridCategory = category),
            ),
            // Aperçu du programme sélectionné
            if (_selectedProgram != null)
              EPGPreviewHeader(
                channel: _selectedChannel,
                program: _selectedProgram,
                currentTimeSec: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              ),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Text(
                        effective == 'fav'
                            ? 'Aucune chaîne favorite'
                            : effective == 'recent'
                                ? 'Aucune chaîne récente'
                                : 'Aucune chaîne dans cette catégorie',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    )
                  : _EpgGrid2DWrapper(
                      key: ValueKey(effective),
                      channels: visible.map((c) => c.name).toList(),
                      channelObjects: visible,
                      timelineController: _timelineController,
                      onProgramSelected: (program, channel) {
                        setState(() {
                          _selectedProgram = program;
                          _selectedChannel = channel;
                        });
                        _showProgramDetails(context, program, channel);
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const LoadingState(message: 'Chargement des chaînes…'),
      error: (err, _) => ErrorState(
        icon: Icons.tv_off_rounded,
        title: l.channelsUnavailable,
        message: 'Impossible de charger les chaînes.',
        onRetry: () => ref.invalidate(liveChannelsProvider),
      ),
    );
  }

  void _showProgramDetails(
    BuildContext context,
    EPGProgram program,
    Channel channel,
  ) {
    final l = AppLocalizations.of(context);
    final replayable = isReplayableProgram(
      program,
      now: DateTime.now(),
      channelSupportsReplay: channel.supportsReplay,
    );
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16181E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              program.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_formatTime(program.start)} - ${_formatTime(program.end)}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            if (channel.supportsReplay) ...[
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(
                    Icons.history,
                    color: Color(0xFF6EE7B7),
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Replay disponible sur cette chaîne',
                    style: TextStyle(
                      color: Color(0xFF6EE7B7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            if (program.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                program.description,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l.watchLive),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/player',
                        arguments: {
                          'streamUrl': channel.streamUrl,
                          'title': channel.name,
                          'contentType': 'live',
                        },
                      );
                    },
                  ),
                ),
                if (replayable) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.replay),
                      label: const Text('Replay'),
                      onPressed: () => _playReplay(context, program, channel),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Lance la lecture du replay (timeshift Xtream) d'un programme terminé.
  void _playReplay(
    BuildContext context,
    EPGProgram program,
    Channel channel,
  ) async {
    final l = AppLocalizations.of(context);
    final sub = ref.read(activeSubscriptionProvider);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (sub == null ||
        sub.type != SubscriptionType.xtream ||
        sub.baseUrl == null ||
        sub.username == null ||
        sub.password == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Replay indisponible : non pris en charge par cet abonnement (M3U).',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    // Même constructeur unique que le Replay et le rattrapage : le
    // `catchup-source` du panel prime, et la convention `/timeshift/...` sert
    // de repli. Cette copie locale produisait un format différent, qui ne
    // fonctionne pas sur ce panel.
    final url = ref.read(apiServiceProvider).replayStreamUrl(
          channel: channel,
          baseUrl: sub.baseUrl!,
          username: sub.username!,
          password: sub.password!,
          startEpoch: program.start.millisecondsSinceEpoch ~/ 1000,
          endEpoch: program.end.millisecondsSinceEpoch ~/ 1000,
        );
    if (url.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.unableToBuildReplayUrl),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      '/player',
      arguments: {
        'streamUrl': url,
        'title': '${program.title} (replay)',
        'contentType': 'replay',
        'channelId': channel.id,
      },
    );
  }

  String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

/// Barre de filtrage par catégorie (groupes de chaînes) au-dessus de la grille.
class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
    this.favCount = 0,
    this.recentCount = 0,
  });

  final List<MediaCategory> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final int favCount;
  final int recentCount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      height: 56,
      color: const Color(0xFF0D0E12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(
            label: 'Favoris',
            count: favCount,
            selected: selected == 'fav',
            onTap: () => onSelected('fav'),
          ),
          _chip(
            label: l.recentlyWatched,
            count: recentCount,
            selected: selected == 'recent',
            onTap: () => onSelected('recent'),
          ),
          for (final category in categories)
            _chip(
              label: category.name,
              count: category.count,
              selected: selected == category.id,
              onTap: () => onSelected(category.id),
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    int count = 0,
  }) {
    final labelled = count > 0 ? '$label ($count)' : label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(labelled),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: const Color(0xFF16181E),
        selectedColor: const Color(0xFF2D224D),
        checkmarkColor: const Color(0xFF8B5CF6),
        labelStyle: TextStyle(
          color: selected ? const Color(0xFF8B5CF6) : Colors.white70,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Wrapper pour la Grille EPG avec chargement EPG par chaîne.
class _EpgGrid2DWrapper extends ConsumerStatefulWidget {
  final List<String> channels;
  final List<Channel> channelObjects;
  final EpgTimelineController timelineController;
  final void Function(EPGProgram program, Channel channel)? onProgramSelected;

  const _EpgGrid2DWrapper({
    super.key,
    required this.channels,
    required this.channelObjects,
    required this.timelineController,
    this.onProgramSelected,
  });

  @override
  ConsumerState<_EpgGrid2DWrapper> createState() => _EpgGrid2DWrapperState();
}

class _EpgGrid2DWrapperState extends ConsumerState<_EpgGrid2DWrapper> {
  final Map<String, List<EPGProgram>> _epgData = {};
  final Set<String> _loadingChannels = {};

  @override
  void initState() {
    super.initState();
    _loadAllEpg();
  }

  Future<void> _loadAllEpg() async {
    // 1. Un seul téléchargement XMLTV (le gros morceau), primé une fois via le
    // cache partagé avant de filtrer en parallèle.
    //
    // `ref` est lu ICI, avant toute suspension, comme le veut Riverpod.
    final api = ref.read(apiServiceProvider);
    final cache = ref.read(epgDataCacheProvider);
    final resolved = await safeAsync(
      () => cache.loadFull(api),
      context: '_loadAllEpg cache.loadFull',
    );

    // Le téléchargement XMLTV prend plusieurs secondes. La grille porte un
    // `key: ValueKey(category)`, donc changer de catégorie recrée cet State :
    // l'ancien `_loadAllEpg` se réveillait ici, DEMONTE, et son `ref.read`
    // de la ligne suivante levait « Using ref when a widget is about to or has
    // been unmounted is unsafe ». Chaque `_loadOne` de ce lot échouait, d'où
    // des lignes vides alors que le dump contenait les programmes.
    if (!mounted) return;

    LoggerService.instance.info(
      'EPG: XMLTV chargé (${resolved.isSuccess ? 'ok' : 'échec'}), '
      '$_loadingChannels chaînes à résoudre',
    );

    // 2. Filtre en mémoire par lots : un seul setState par lot de chaînes,
    // au lieu d'un rebuild complet de la grille à chaque chaîne (ANR sinon).
    final byName = {for (final c in widget.channelObjects) c.name: c};
    const chunkSize = 8;
    final missingIds = <String>[];

    for (var i = 0; i < widget.channels.length; i += chunkSize) {
      final chunk = widget.channels.skip(i).take(chunkSize);
      final tasks = <Future<void>>[];
      final chunkResults = <String, List<EPGProgram>>{};
      for (final channelName in chunk) {
        if (_loadingChannels.contains(channelName)) continue;
        _loadingChannels.add(channelName);
        final channel = byName[channelName];
        if (channel == null) {
          _loadingChannels.remove(channelName);
          continue;
        }
        // Si le panel n'expose pas d'identifiant EPG, on tente le nom de la
        // chaîne : l'index XMLTV contient souvent cette forme exacte. Sans ce
        // repli, la ligne restait vide dans la grille.
        // `epgChannelId` peut contenir plusieurs candidats séparés par une
        // virgule (« stream_id,num:stream_id ») : le passer en entier comme
        // clé de provider ne pouvait donc jamais correspondre à l'index
        // XMLTV. On ne transmet que le premier candidat — `channelEpgProvider`
        // essaie de lui-même toutes les formes.
        final epgId = channel.primaryEpgChannelId.isNotEmpty
            ? channel.primaryEpgChannelId
            : channelName;
        tasks.add(_loadOne(
          channelName,
          channel,
          epgId,
          chunkResults,
          missingIds,
        ),);
      }
      await Future.wait(tasks);
      if (mounted) {
        setState(() => _epgData.addAll(chunkResults));
      }
    }

    // 2 bis. Bilan mesuré, pas deviné : `inWindow.isEmpty` est la seule source
    // fiable pour distinguer un programme trouvé d'un bloc de trou, car un
    // bloc comblé porte lui aussi un titre.
    final total = widget.channels.length;
    final missing = missingIds.length;
    if (mounted) setState(() {});

    LoggerService.instance.info(
      'EPG: $total chaînes, ${total - missing} avec programmes, '
      '$missing sans (aucun programme dans la fenêtre) — ${_epgData.length} '
      'lignes construites.${missingIds.isEmpty ? '' : ' Sans résultat pour : '
          '${missingIds.take(8).join(', ')}'}',
    );
  }

  Future<void> _loadOne(
    String channelName,
    Channel channel,
    String epgId,
    Map<String, List<EPGProgram>> out,
    List<String> missingIds,
  ) async {
    final result = await safeAsync(
      // Variante GRILLE : programmes passés compris. La barre du lecteur ne veut
      // que « en cours / à venir », mais la grille représente une journée
      // entière — lui servir du « à venir » laissait la matinée vide, comblée par
      // des blocs de trou alors que les données existaient dans le dump.
      () => ref.read(channelEpgWindowProvider(epgId).future),
      context: '_loadOne channelEpgWindowProvider',
    );
    if (!mounted) return;
    if (result.isSuccess) {
      // Fenêtre de la journée : minuit → minuit, et une seule définition pour
      // toute l'application.
      //
      // La grille commençait à « maintenant moins 1 h », ce qui décalait tout
      // d'une heure par rapport au Replay (00:00 → 24 h) : deux définitions de la
      // même journée, donc deux heures différentes pour un même programme. La
      // spec est nette — T_start = 00:00, T_end = T_start + 24 h.
      final window = EpgDayWindow.ofNow();
      final windowStart = window.start;
      final windowEnd = window.end;
      final windowStartSec = windowStart.millisecondsSinceEpoch ~/ 1000;
      final windowEndSec = windowEnd.millisecondsSinceEpoch ~/ 1000;
      final inWindow = EPGSearchEngine.getProgramsInWindow(
        result.valueOrNull!,
        windowStartSec,
        windowEndSec,
      );
      // Comblement des trous : l'axe de la grille est continu, donc une absence
      // de données doit être un bloc, pas un blanc. Sans lui, un trou de 40 min
      // se lisait comme un programme manquant et décalait la lecture de l'axe.
      out[channelName] = EpgGapFiller.fill(
        programs: inWindow,
        windowStart: windowStart,
        windowEnd: windowEnd,
        channelId: channel.id,
      );
      // Programme « vrai » = au moins un programme dans la fenêtre. Un bloc de
      // trou a lui aussi un titre, donc compter les titres non vides
      // compterait les comblements comme des programmes : c'est ce qui donne
      // l'illusion d'une grille « peuplée » alors que rien n'a été trouvé.
      if (inWindow.isEmpty) {
        missingIds.add('${channel.name}→$epgId');
      }
    } else {
      missingIds.add('${channel.name}→$epgId(erreur)');
      LoggerService.instance
          .warning('_loadOne failed', error: result.errorOrNull);
    }
    if (mounted) {
      _loadingChannels.remove(channelName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadAllEpg,
      child: EpgGrid2DView(
        channels: widget.channels,
        epgData: _epgData,
        pixelsPerMinute: EpgTimelineController.defaultPixelsPerMinute,
        replayChannels: {
          for (final c in widget.channelObjects)
            if (c.supportsReplay) c.name,
        },
        onProgramTap: (program, channelName) {
          final channel =
              widget.channelObjects.firstWhere((c) => c.name == channelName);
          widget.onProgramSelected?.call(program, channel);
        },
        onChannelTap: (channelName) {
          // Invalidate EPG cache on zap to free memory
          ref.read(epgDataCacheProvider).invalidate();
          final channel =
              widget.channelObjects.firstWhere((c) => c.name == channelName);
          Navigator.pushNamed(
            context,
            '/player',
            arguments: {
              'streamUrl': channel.streamUrl,
              'title': channel.name,
              'contentType': 'live',
            },
          );
        },
        onChannelLongPress: (channelName) {
          final channel =
              widget.channelObjects.firstWhere((c) => c.name == channelName);
          if (channel.supportsReplay) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CatchUpScreen(channel: channel),
              ),
            );
          }
        },
        // Use shared timeline controller
        timelineController: widget.timelineController,
      ),
    );
  }
}

/// Section en-tête EPG unifiée : affiche [EpgHeadbar] pour la chaîne ciblée
/// dans la grille (row temps + toolbar du bas).
///
/// - Chaîne ciblée : cliquée dans la colonne de gauche de la grille
///   ([EpgTimelineController.targetedChannel]).
/// - Programme en cours / suivant : calculés via la recherche dichotomique
///   (O(log N)) sur l'EPG chargé par [channelEpgProvider].
class _EpgHeadbarSection extends ConsumerWidget {
  const _EpgHeadbarSection({
    required this.channels,
    required this.controller,
  });

  final List<Channel> channels;
  final EpgTimelineController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return ValueListenableBuilder<String?>(
      valueListenable: controller.targetedChannel,
      builder: (context, channelName, _) {
        if (channelName == null) {
          // Aucune chaîne ciblée : bandeau discret au lieu d'une headbar vide.
          return Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: const Color(0xFF13151B),
            alignment: Alignment.centerLeft,
            child: const Row(
              children: [
                Icon(
                  Icons.live_tv,
                  color: Colors.white38,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Sélectionnez une chaîne pour voir son programme',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          );
        }

        final channel = _byName[channelName];
        if (channel == null) {
          return const SizedBox.shrink();
        }
        return EpgHeadbar(
          key: ValueKey(channel.id),
          type: EpgHeadbarType.live,
          channel: channel,
          isLive: true,
          isFavorite: _isFavorite(ref, 'live', channel),
          currentProgram: ref
              .watch(channelEpgProvider(channel.primaryEpgChannelId))
              .maybeWhen(
                data: (programs) => epgCurrentProgram(programs, DateTime.now()),
                orElse: () => null,
              ),
          nextProgram: ref
              .watch(channelEpgProvider(channel.primaryEpgChannelId))
              .maybeWhen(
                data: (programs) => epgNextProgram(programs, DateTime.now()),
                orElse: () => null,
              ),
          onPlay: () {
            Navigator.pushNamed(
              context,
              '/player',
              arguments: {
                'streamUrl': channel.streamUrl,
                'title': channel.name,
                'contentType': 'live',
              },
            );
          },
          onFavoriteToggle: () {
            final entry = FavoriteEntry(
              type: ContentType.live,
              id: channel.id,
              title: channel.name,
              posterUrl: channel.logoUrl,
              subtitle: channel.groupLabel,
              streamUrl: channel.streamUrl,
            );
            ref.read(favoritesProvider.notifier).toggle(entry);
          },
          onInfo: () {
            final programs =
                ref.read(channelEpgProvider(channel.primaryEpgChannelId)).value;
            final current = programs == null
                ? null
                : epgCurrentProgram(programs, DateTime.now());
            if (current != null) {
              _showProgramBottomSheet(context, current, channel);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l.noProgramInfoAvailable),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        );
      },
    );
  }

  Map<String, Channel> get _byName => {for (final c in channels) c.name: c};

  bool _isFavorite(WidgetRef ref, String type, Channel channel) {
    final favorites = ref.watch(favoritesProvider);
    // Clé canonique alignée sur FavoritesNotifier (profil courant).
    final profile = ref.watch(currentProfileProvider);
    final key = profile == null || profile.id.isEmpty
        ? '$type:${channel.id}'
        : '${profile.id}:$type:${channel.id}';
    return favorites.containsKey(key);
  }

  Future<void> _showProgramBottomSheet(
    BuildContext context,
    EPGProgram program,
    Channel channel,
  ) async {
    final scheme = Theme.of(context).colorScheme;
    final watchFocus = FocusNode();

    void watch() {
      Navigator.pop(context);
      Navigator.pushNamed(
        context,
        '/player',
        arguments: {
          'streamUrl': channel.streamUrl,
          'title': channel.name,
          'contentType': 'live',
          'channelId': channel.id,
        },
      );
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16181E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              program.title,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_hhmm(program.start)} - ${_hhmm(program.end)}',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
            ),
            if (program.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                program.description,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Focus(
              focusNode: watchFocus,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.enter ||
                        event.logicalKey == LogicalKeyboardKey.select ||
                        event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                  watch();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: Text('Regarder ${channel.name}'),
                onPressed: watch,
              ),
            ),
          ],
        ),
      ),
    );
    watchFocus.dispose();
  }

  String _hhmm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}
