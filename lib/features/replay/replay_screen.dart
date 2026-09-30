import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/categories_rail.dart';
import 'package:orbit_3d_flutter/core/widgets/orbit_cached_image.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/live_tv/channel_groups.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';

/// Replays groupés par chaîne.
///
/// Les panels Xtream n'exposent le timeshift que chaîne par chaîne : lister
/// 14 jours de programmes de toutes les chaînes à plat oblige à parcourir un
/// flux interminable. On part donc des chaînes qui ont du replay, et le choix
/// d'une chaîne révèle ses programmes (navigation à 2 niveaux).
class ReplayScreen extends ConsumerStatefulWidget {
  const ReplayScreen({super.key});

  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

/// Replays d'une chaîne, rangés par jour.
class _ChannelReplays {
  _ChannelReplays({required this.id, required this.name, required this.items});

  final String id;
  final String name;
  final List<ReplayItem> items;

  DateTime? get latestStart {
    DateTime? latest;
    for (final item in items) {
      final d = item.startDate;
      if (d != null && (latest == null || d.isAfter(latest))) latest = d;
    }
    return latest;
  }
}

class _ReplayScreenState extends ConsumerState<ReplayScreen> {
  /// Chaîne sélectionnée, ou null pour la liste des chaînes.
  String? _selectedChannelId;

  /// Ouvre le détail replay d'une chaîne (niveau 2).
  void selectChannel(String channelId) {
    setState(() => _selectedChannelId = channelId);
  }

  @override
  Widget build(BuildContext context) {
    final replaysAsync = ref.watch(replaysProvider);

    return Scaffold(
      appBar: AppBar(
        // Retour toujours visible : au 2e niveau il ramène à la liste des
        // chaînes, au 1er niveau il quitte l'écran.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Retour',
          onPressed: () {
            final channelId = _selectedChannelId;
            if (channelId != null) {
              setState(() => _selectedChannelId = null);
            } else {
              context.canPop() ? context.pop() : context.go('/home');
            }
          },
        ),
        title: Text(_selectedChannelId == null
            ? 'Replay'
            : (_channels(replaysAsync.value ?? const <ReplayItem>[])
                    .where((c) => c.id == _selectedChannelId)
                    .firstOrNull
                    ?.name ??
                'Replay')),
        actions: [
          IconButton(
            tooltip: 'Rafraîchir',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(replaysProvider),
          ),
        ],
      ),
      body: replaysAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(userFriendlyError(err))),
        data: (replays) {
          if (replays.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.replay_rounded, size: 64),
                  SizedBox(height: 12),
                  Text('Aucun replay disponible'),
                ],
              ),
            );
          }

          final groups = _channels(replays)
            ..sort((a, b) => (b.latestStart ?? DateTime(1900))
                .compareTo(a.latestStart ?? DateTime(1900)));

          final selected =
              groups.where((c) => c.id == _selectedChannelId).firstOrNull;
          if (selected == null) {
            return _ChannelList(groups: groups);
          }
          return _ReplayDayView(channel: selected);
        },
      ),
    );
  }

  /// Regroupe les replays par chaîne, du plus récent au plus ancien.
  static List<_ChannelReplays> _channels(List<ReplayItem> replays) {
    final grouped = <String, List<ReplayItem>>{};
    final names = <String, String>{};
    for (final r in replays) {
      final key = r.channelId.isNotEmpty
          ? r.channelId
          : (r.channelName.isNotEmpty ? r.channelName : 'sans chaîne');
      grouped.putIfAbsent(key, () => <ReplayItem>[]).add(r);
      if (r.channelName.isNotEmpty) names.putIfAbsent(key, () => r.channelName);
    }
    return [
      for (final entry in grouped.entries)
        _ChannelReplays(
          id: entry.key,
          name: names[entry.key] ?? 'Chaîne inconnue',
          items: entry.value,
        ),
    ];
  }
}

/// Niveau 1 : les chaînes qui proposent du replay, classables par catégorie.
///
/// Même modèle que l'écran Live TV : un rail « Tous / Favoris / Récemment /
/// groupes » à gauche, appliqué ici au sous-ensemble des chaînes qui ont du
/// replay. Les favoris et chaînes récentes sont ceux du catalogue live
/// (recroisés par identifiant de chaîne), pour une expérience cohérente.
class _ChannelList extends ConsumerStatefulWidget {
  const _ChannelList({required this.groups});

  final List<_ChannelReplays> groups;

  @override
  ConsumerState<_ChannelList> createState() => _ChannelListState();
}

class _ChannelListState extends ConsumerState<_ChannelList> {
  /// Catégorie sélectionnée dans le rail : vide = tous.
  String _selectedGroup = '';

  @override
  Widget build(BuildContext context) {
    // Logos : le ReplayItem ne les porte pas, on les récupère via le catalogue
    // live en recoupant sur l'identifiant de chaîne.
    final liveChannels =
        ref.watch(liveChannelsProvider).value ?? const <Channel>[];
    final favoriteEntries = ref.watch(favoritesProvider);
    final recentEntries = ref.watch(recentlyWatchedProvider);

    final byId = <String, Channel>{
      for (final c in liveChannels)
        if (c.id.isNotEmpty) c.id: c,
    };
    final favIds = favoriteEntries.values
        .where((e) => e.type == ContentType.live)
        .map((e) => e.id)
        .toSet();
    final recentIds = recentEntries.values
        .where((e) => e.type == ContentType.live)
        .map((e) => e.id)
        .toSet();

    final channelGroups = buildLiveChannelGroups(liveChannels);
    final grouped =
        channelGroups.length > 1 || channelGroups.firstOrNull?.name.isNotEmpty == true;

    final visible = _visibleGroups(
      widget.groups,
      channelGroups: channelGroups,
      favIds: favIds,
      recentIds: recentIds,
    );

    final categories = _groupToCategories(
      channelGroups,
      replayGroups: widget.groups,
      favIds: favIds,
      recentIds: recentIds,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (grouped && categories.isNotEmpty)
          CategoriesRail(
            categories: categories,
            selectedId: _selectedGroup,
            onSelected: (id) => setState(() => _selectedGroup = id),
          ),
        Expanded(
          child: visible.isEmpty
              ? _EmptyCategory(
                  groupId: _selectedGroup,
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    childAspectRatio: 0.42,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final group = visible[index];
                    final channel = byId[group.id];
                    final latest = group.latestStart;
                    return _ChannelReplayCard(
                      name: group.name,
                      logoUrl: channel?.logoUrl ?? '',
                      programCount: group.items.length,
                      latestLabel: latest == null
                          ? null
                          : 'Dernier : ${_formatDay(latest)}',
                      onTap: () {
                        // Le parent gère la sélection : on remonte l'id.
                        final state = context
                            .findAncestorStateOfType<_ReplayScreenState>();
                        state?.selectChannel(group.id);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Sous-ensemble des chaînes à replay selon la catégorie sélectionnée.
  List<_ChannelReplays> _visibleGroups(
    List<_ChannelReplays> groups, {
    required List<ChannelGroup> channelGroups,
    required Set<String> favIds,
    required Set<String> recentIds,
  }) {
    final List<_ChannelReplays> visible;
    if (_selectedGroup == 'fav') {
      visible = groups.where((g) => favIds.contains(g.id)).toList();
    } else if (_selectedGroup == 'recent') {
      visible = groups.where((g) => recentIds.contains(g.id)).toList();
    } else if (_selectedGroup.startsWith('g')) {
      final index = int.tryParse(_selectedGroup.substring(1));
      if (index != null && index >= 0 && index < channelGroups.length) {
        final ids =
            channelGroups[index].channels.map((c) => c.id).toSet();
        visible = groups.where((g) => ids.contains(g.id)).toList();
      } else {
        visible = const [];
      }
    } else {
      visible = groups;
    }
    return visible
      ..sort(
        (a, b) => (b.latestStart ?? DateTime(1900))
            .compareTo(a.latestStart ?? DateTime(1900)),
      );
  }

  /// Rail de catégories, appliqué au sous-ensemble des chaînes à replay.
  static List<MediaCategory> _groupToCategories(
    List<ChannelGroup> channelGroups, {
    required List<_ChannelReplays> replayGroups,
    required Set<String> favIds,
    required Set<String> recentIds,
  }) {
    final replayIds = {for (final g in replayGroups) g.id};
    return [
      MediaCategory(id: '', name: 'Tous', count: replayGroups.length),
      MediaCategory(
        id: 'fav',
        name: 'Favoris',
        count: replayGroups.where((g) => favIds.contains(g.id)).length,
      ),
      MediaCategory(
        id: 'recent',
        name: 'Récemment',
        count: replayGroups.where((g) => recentIds.contains(g.id)).length,
      ),
      for (var i = 0; i < channelGroups.length; i++)
        MediaCategory(
          id: 'g$i',
          name: channelGroups[i].name.isEmpty
              ? 'Non groupé'
              : channelGroups[i].name,
          count: channelGroups[i]
              .channels
              .where((c) => replayIds.contains(c.id))
              .length,
        ),
    ];
  }

  static String _formatDay(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return "aujourd'hui";
    if (diff == 1) return 'hier';
    if (diff < 7) return 'il y a $diff jours';
    return '${d.day}/${d.month}';
  }
}

/// État vide d'une catégorie du rail (favoris, récents, groupe vide).
class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (icon, title, message) = switch (groupId) {
      'fav' => (
          Icons.favorite_border_rounded,
          'Aucune chaîne favorite',
          "Appuie sur le cœur d'une chaîne pour la retrouver ici.",
        ),
      'recent' => (
          Icons.history_rounded,
          'Aucune chaîne récente',
          'Les chaînes regardées s\'afficheront ici.',
        ),
      _ => (
          Icons.live_tv_outlined,
          'Aucune chaîne dans ce groupe',
          'Ce groupe ne contient aucune chaîne.',
        ),
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: scheme.outline),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Tuile de chaîne du niveau 1.
class _ChannelReplayCard extends StatelessWidget {
  const _ChannelReplayCard({
    required this.name,
    required this.logoUrl,
    required this.programCount,
    required this.latestLabel,
    required this.onTap,
  });

  final String name;
  final String logoUrl;
  final int programCount;
  final String? latestLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return TvFocus(
      onActivate: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: logoUrl.isEmpty
                        ? Icon(Icons.live_tv_rounded,
                            size: 40, color: scheme.outline)
                        : OrbitCachedImage(
                            imageUrl: logoUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Icon(
                              Icons.live_tv_rounded,
                              size: 40,
                              color: scheme.outline,
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.live_tv_rounded,
                              size: 40,
                              color: scheme.outline,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.replay_rounded, size: 12, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '$programCount',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: scheme.primary),
                    ),
                    if (latestLabel != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          latestLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// et une heure.
class _ReplayDayView extends StatefulWidget {
  const _ReplayDayView({required this.channel});

  final _ChannelReplays channel;

  @override
  State<_ReplayDayView> createState() => _ReplayDayViewState();
}

class _ReplayDayViewState extends State<_ReplayDayView> {
  /// Jour sélectionné. `null` tant que l'utilisateur n'a pas choisi : on part
  /// alors sur le jour le plus récent, qui est le cas d'usage dominant.
  DateTime? _selectedDay;

  static const _months = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final sorted = [...widget.channel.items]
      ..sort((a, b) => (b.startAt ?? b.startDate ?? DateTime(1900))
          .compareTo(a.startAt ?? a.startDate ?? DateTime(1900)));

    // Regroupement par jour local.
    final byDay = <DateTime, List<ReplayItem>>{};
    for (final item in sorted) {
      final d = (item.startAt ?? item.startDate)?.toLocal();
      if (d == null) continue;
      byDay
          .putIfAbsent(DateTime(d.year, d.month, d.day), () => <ReplayItem>[])
          .add(item);
    }
    if (byDay.isEmpty) {
      return Center(
        child: Text(
          'Aucun replay disponible',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }

    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final active = days.contains(_selectedDay) ? _selectedDay! : days.first;
    final items = byDay[active] ?? const <ReplayItem>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Onglets de jours ─────────────────────────────────────────────
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final day = days[i];
              final isActive = day == active;
              return ChoiceChip(
                label: Text(_tabLabel(day)),
                selected: isActive,
                onSelected: (_) => setState(() => _selectedDay = day),
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  color: isActive ? scheme.onSecondaryContainer : null,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                ),
                selectedColor: scheme.secondaryContainer,
                backgroundColor: scheme.surfaceContainerHighest,
                side: BorderSide(
                  color: isActive
                      ? scheme.primary
                      : scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        // ── Fiches du jour sélectionné ──────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) =>
                _ReplaySlotRow(slot: items[i], dayStamp: _stampPrefix(active)),
          ),
        ),
      ],
    );
  }

  /// Préfixe de date commun à toutes les fiches d'un même jour : « sept. 12 ».
  String _stampPrefix(DateTime day) {
    return '${day.day} ${_months[day.month - 1]}';
  }

  String _tabLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Hier';
    return '${_months[day.month - 1].toUpperCase()} ${day.day}';
  }
}

class _ReplaySlotRow extends StatelessWidget {
  const _ReplaySlotRow({required this.slot, this.dayStamp});

  final ReplayItem slot;

  /// Date du jour, préfixée aux horaires (« sept. 12, 10:45 »).
  final String? dayStamp;

  String _hhmm(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }

  /// « sept. 12, 10:45 - sept. 12, 11:25 », ou l'intervalle court si la date
  /// n'est pas connue.
  String get _range {
    final start = slot.startAt;
    final end = slot.endAt;
    if (start == null || end == null) {
      if (slot.startTime.isEmpty) return 'Replay disponible';
      return '${slot.startTime} - ${slot.endTime}';
    }
    final day = dayStamp ?? '';
    final s = day.isEmpty ? _hhmm(start) : '$day, ${_hhmm(start)}';
    final e = day.isEmpty ? _hhmm(end) : '$day, ${_hhmm(end)}';
    return '$s - $e';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TvFocus(
      onActivate: () => _play(context),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => _play(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _range,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  slot.title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (slot.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    slot.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (slot.host.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          slot.host,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.play_circle_outline_rounded,
                        size: 26,
                      ),
                    ],
                  ),
                ] else
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.play_circle_outline_rounded, size: 26),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _play(BuildContext context) {
    final subtitle = slot.startTime.isEmpty
        ? 'Replay disponible'
        : '${slot.startTime} - ${slot.endTime}';
    context.push(
      '/player',
      extra: PlayerRouteData(
        streamUrl: slot.streamUrl,
        title: slot.title,
        contentType: PlaybackContentType.replay,
        subtitle: subtitle,
        favorite: FavoriteEntry(
          type: ContentType.replay,
          id: slot.id,
          title: slot.title,
          subtitle: subtitle,
          streamUrl: slot.streamUrl,
        ),
      ),
    );
  }
}
