import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/core/widgets/error_state.dart';
import 'package:orbit_3d_flutter/core/widgets/loading_state.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_grid_2d_view.dart';

/// Guide TV (EPG) : affiche la grille 2D seule.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guide TV (EPG)')),
      body: _buildGrid2DTab(),
    );
  }

  Widget _buildGrid2DTab() {
    final channelsAsync = ref.watch(liveChannelsProvider);
    final favoriteEntries = ref.watch(favoritesProvider);
    final recentEntries = ref.watch(recentlyWatchedProvider);

    return channelsAsync.when(
      data: (channels) {
        if (channels.isEmpty) {
          return const Center(child: Text('Aucune chaîne disponible'));
        }
        final categories = <String>[];
        for (final c in channels) {
          if (c.groupLabel.isNotEmpty && !categories.contains(c.groupLabel)) {
            categories.add(c.groupLabel);
          }
        }
        // Démarre sur la 1re catégorie de chaînes (perf : pas de tout-chargement).
        final effective =
            _gridCategory ?? (categories.isNotEmpty ? categories.first : null);
        final favIds = favoriteEntries.values
            .where((e) => e.type == ContentType.live)
            .map((e) => e.id)
            .toSet();
        final recentIds = recentEntries.values
            .where((e) => e.type == ContentType.live)
            .map((e) => e.id)
            .toSet();
        final List<Channel> visible;
        if (effective == 'fav') {
          visible = channels.where((c) => favIds.contains(c.id)).toList();
        } else if (effective == 'recent') {
          visible = channels.where((c) => recentIds.contains(c.id)).toList();
        } else if (effective == null) {
          visible = const [];
        } else {
          visible = channels.where((c) => c.groupLabel == effective).toList();
        }
        return Column(
          children: [
            _CategoryFilterBar(
              categories: categories,
              selected: effective,
              onSelected: (category) =>
                  setState(() => _gridCategory = category),
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
                    ),
            ),
          ],
        );
      },
      loading: () => const LoadingState(message: 'Chargement des chaînes…'),
      error: (err, _) => ErrorState(
        icon: Icons.tv_off_rounded,
        title: 'Chaînes indisponibles',
        message: 'Impossible de charger les chaînes.',
        onRetry: () => ref.invalidate(liveChannelsProvider),
      ),
    );
  }
}

/// Barre de filtrage par catégorie (groupes de chaînes) au-dessus de la grille.
class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: const Color(0xFF0D0E12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(
            label: 'Favoris',
            selected: selected == 'fav',
            onTap: () => onSelected('fav'),
          ),
          _chip(
            label: 'Récemment',
            selected: selected == 'recent',
            onTap: () => onSelected('recent'),
          ),
          for (final category in categories)
            _chip(
              label: category,
              selected: selected == category,
              onTap: () => onSelected(category),
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
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

/// Wrapper pour la grille 2D avec chargement EPG par chaîne.
class _EpgGrid2DWrapper extends ConsumerStatefulWidget {
  final List<String> channels;
  final List<Channel> channelObjects;

  const _EpgGrid2DWrapper({
    super.key,
    required this.channels,
    required this.channelObjects,
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
    final api = ref.read(apiServiceProvider);
    final cache = ref.read(epgDataCacheProvider);
    try {
      await cache.loadFull(api);
    } catch (_) {}

    // 2. Filtre en mémoire par lots : un seul setState par lot de chaînes,
    // au lieu d'un rebuild complet de la grille à chaque chaîne (ANR sinon).
    final byName = {for (final c in widget.channelObjects) c.name: c};
    const chunkSize = 8;
    for (var i = 0; i < widget.channels.length; i += chunkSize) {
      final chunk = widget.channels.skip(i).take(chunkSize);
      final tasks = <Future<void>>[];
      final chunkResults = <String, List<EPGProgram>>{};
      for (final channelName in chunk) {
        if (_loadingChannels.contains(channelName)) continue;
        _loadingChannels.add(channelName);
        final channel = byName[channelName];
        if (channel == null || channel.epgChannelId.isEmpty) {
          _loadingChannels.remove(channelName);
          continue;
        }
        tasks.add(_loadOne(channelName, channel, chunkResults));
      }
      await Future.wait(tasks);
      if (mounted) {
        setState(() => _epgData.addAll(chunkResults));
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadOne(
    String channelName,
    Channel channel,
    Map<String, List<EPGProgram>> out,
  ) async {
    try {
      final programs =
          await ref.read(channelEpgProvider(channel.epgChannelId).future);
      out[channelName] = programs;
    } catch (_) {}
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
        pixelsPerMinute: 4.0,
        onProgramTap: (program) {
          _showProgramDetails(context, program);
        },
        onChannelTap: (channelName) {
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
      ),
    );
  }

  void _showProgramDetails(BuildContext context, EPGProgram program) {
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
                    label: const Text('Regarder'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}
