# EPG — grille : 6. l’écran EPG

> **Partie 1/3**

> Fiche générée depuis le code source — extraction fidèle, commentaires compris. Chaque bloc est limité à 200 lignes pour rester copiable sans saturer le presse-papier.

Sources : `lib/features/epg/epg_screen.dart`

### 6.1 `EpgScreen` — suite 1/3

`lib/features/epg/epg_screen.dart` · lignes 1–400

#### `lib/features/epg/epg_screen.dart` · lignes 1–200 · partie 1/2

```dart
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
  final Set<String> _loadingChannels = {};

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
                      loadingChannels: _loadingChannels,
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
```

#### `lib/features/epg/epg_screen.dart` · lignes 201–400 · partie 2/2

```dart
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
```
