import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/categories_rail.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/live_tv/channel_groups.dart';
import 'package:orbit_3d_flutter/features/live_tv/widgets/channel_grid_card.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';

/// Replay (catch-up) — navigation à deux niveaux.
///
/// ## Ce que le Replay n'est pas
///
/// Le Replay n'est pas la grille des programmes lue à l'envers. La grille
/// ([EPG (grille)]) décrit ce qui passe et ce qui va passer ; le Replay décrit
/// ce que le panel permet **de rattraper**, et cette information ne vit pas
/// dans la grille. Mesuré sur le panel du 30/09 : l'EPG global ne fournit
/// **aucun** programme rejouable (`epg=0`), parce qu'un guide TV est tourné
/// vers l'avenir. Confondre les deux donnait un écran vide.
///
/// ## Pourquoi deux écrans
///
/// Le catalogue annonce plus de 1400 chaînes réplayables, et le panel ne
/// publie le catch-up que chaîne par chaîne (`get_short_epg`, un appel). Tout
/// sonder en bloc — ce que faisait la sonde de 40 chaînes au démarrage —
/// déclenche une tempête de 429 qui fait échouer l'EPG, les Films et le Live
/// TV au passage. Le découpage en deux niveaux est donc une contrainte du
/// panel, pas un choix de présentation :
///
/// - **niveau 1** : les chaînes replayables, lues dans le catalogue déjà
///   chargé, groupées par pays. Aucun appel réseau ;
/// - **niveau 2** : les programmes d'une chaîne, un seul appel, au choix.
///
/// Le niveau 1 réutilise la tuile de chaîne du Live TV : c'est le même objet,
/// il doit avoir la même taille et la même apparence.
class ReplayScreen extends ConsumerStatefulWidget {
  const ReplayScreen({super.key});

  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends ConsumerState<ReplayScreen> {
  /// Chaîne ouverte au niveau 2, ou `null` au niveau 1.
  Channel? _selected;

  void _open(Channel channel) => setState(() => _selected = channel);

  void _close() => setState(() => _selected = null);

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(liveChannelsProvider);
    final selected = _selected;

    return Scaffold(
      appBar: AppBar(
        // Le retour remonte d'un cran : du niveau 2 vers la grille des
        // chaînes, et de la grille vers l'écran précédent.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Retour',
          onPressed: () {
            if (selected != null) {
              _close();
            } else {
              context.canPop() ? context.pop() : context.go('/home');
            }
          },
        ),
        title: Text(selected?.name ?? 'Replay'),
        actions: [
          if (selected != null)
            IconButton(
              tooltip: 'Rafraîchir',
              icon: const Icon(Icons.refresh),
              // On recharge CETTE chaîne, pas tout le catalogue : c'est le
              // seul appel que l'écran est autorisé à faire.
              onPressed: () =>
                  ref.invalidate(channelReplaysProvider(selected.id)),
            ),
        ],
      ),
      body: channelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(userFriendlyError(err))),
        data: (channels) {
          // Le catalogue est la seule source du niveau 1 : `supportsReplay`
          // vient de `get_live_streams`, déjà chargé pour le Live TV. Aucun
          // appel supplémentaire.
          final replayable = channels.where((c) => c.supportsReplay).toList();
          final open = selected;
          if (open == null) {
            if (replayable.isEmpty) {
              return const _NoReplayAtAll();
            }
            return _ChannelGrid(channels: replayable, onOpen: _open);
          }
          return _ChannelReplaysView(channel: open);
        },
      ),
    );
  }
}

/// AucunReplay : le panel ne publie de catch-up sur aucune chaîne du
/// catalogue.
class _NoReplayAtAll extends StatelessWidget {
  const _NoReplayAtAll();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.replay_rounded, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('Aucun replay disponible', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              "Aucune chaîne de cet abonnement ne déclare de catch-up.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Niveau 1 : les chaînes replayables, groupées par pays.
class _ChannelGrid extends ConsumerStatefulWidget {
  const _ChannelGrid({required this.channels, required this.onOpen});

  final List<Channel> channels;
  final ValueChanged<Channel> onOpen;

  @override
  ConsumerState<_ChannelGrid> createState() => _ChannelGridState();
}

class _ChannelGridState extends ConsumerState<_ChannelGrid> {
  /// Catégorie du rail ; vide = toutes.
  String _selectedGroup = '';

  @override
  Widget build(BuildContext context) {
    final favoriteEntries = ref.watch(favoritesProvider);
    final recentEntries = ref.watch(recentlyWatchedProvider);

    final favIds = favoriteEntries.values
        .where((e) => e.type == ContentType.live)
        .map((e) => e.id)
        .toSet();
    final recentIds = recentEntries.values
        .where((e) => e.type == ContentType.live)
        .map((e) => e.id)
        .toSet();

    // Les groupes viennent du catalogue live, mais on ne retient que les
    // chaînes qui ont du replay : le rail ne propose pas de groupe vide.
    final groups = buildLiveChannelGroups(widget.channels);
    final grouped = groups.length > 1 || groups.firstOrNull?.name.isNotEmpty == true;

    final visible = _visible(
      widget.channels,
      groups: groups,
      favIds: favIds,
      recentIds: recentIds,
    );
    final categories = _categories(
      groups,
      replayIds: {for (final c in widget.channels) c.id},
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
              ? _EmptyCategory(groupId: _selectedGroup)
              : GridView.builder(
                  padding: channelGridPadding,
                  // Même tuile que le Live TV : le Replay montre des chaînes,
                  // il doit les montrer comme le Live TV.
                  gridDelegate: channelGridDelegate,
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final channel = visible[index];
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
                      onTap: () => widget.onOpen(channel),
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<Channel> _visible(
    List<Channel> channels, {
    required List<ChannelGroup> groups,
    required Set<String> favIds,
    required Set<String> recentIds,
  }) {
    final List<Channel> visible;
    if (_selectedGroup == 'fav') {
      visible = channels.where((c) => favIds.contains(c.id)).toList();
    } else if (_selectedGroup == 'recent') {
      visible = channels.where((c) => recentIds.contains(c.id)).toList();
    } else if (_selectedGroup.startsWith('g')) {
      final index = int.tryParse(_selectedGroup.substring(1));
      if (index != null && index >= 0 && index < groups.length) {
        final ids = groups[index].channels.map((c) => c.id).toSet();
        visible = channels.where((c) => ids.contains(c.id)).toList();
      } else {
        visible = const [];
      }
    } else {
      visible = channels;
    }
    return visible..sort((a, b) {
        final numA = a.orderNum > 0 ? a.orderNum : 1 << 30;
        final numB = b.orderNum > 0 ? b.orderNum : 1 << 30;
        return numA.compareTo(numB);
      });
  }

  /// Rail « Tous / Favoris / Récemment / pays », décompté sur les chaînes
  /// rejouables et non sur le catalogue complet.
  static List<MediaCategory> _categories(
    List<ChannelGroup> groups, {
    required Set<String> replayIds,
    required Set<String> favIds,
    required Set<String> recentIds,
  }) {
    return [
      MediaCategory(id: '', name: 'Tous', count: replayIds.length),
      MediaCategory(
        id: 'fav',
        name: 'Favoris',
        count: replayIds.where(favIds.contains).length,
      ),
      MediaCategory(
        id: 'recent',
        name: 'Récemment',
        count: replayIds.where(recentIds.contains).length,
      ),
      for (var i = 0; i < groups.length; i++)
        MediaCategory(
          id: 'g$i',
          name: groups[i].name.isEmpty ? 'Non groupé' : groups[i].name,
          count: groups[i].channels
              .where((c) => replayIds.contains(c.id))
              .length,
        ),
    ];
  }
}

/// Niveau 2 : les programmes rejouables d'UNE chaîne.
///
/// Un seul appel réseau, au montage ([channelReplaysProvider]). Le détail est
/// donc indisponible tant que la réponse n'est pas là, ce qui est le prix de
/// la fenêtre par compte : on ne peut pas lister 14 jours de toutes les chaînes
/// sans que le panel nous coupe.
class _ChannelReplaysView extends ConsumerWidget {
  const _ChannelReplaysView({required this.channel});

  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(channelReplaysProvider(channel.id));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userFriendlyError(err),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () =>
                    ref.invalidate(channelReplaysProvider(channel.id)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
      data: (items) => _ReplayDayView(channel: channel, items: items),
    );
  }
}

/// Bandeau de chaîne : numéro et nom brut, comme sur la maquette.
///
/// L'AppBar porte le même nom, mais le bandeau identifie la ligne dans le flux
/// du programme et reste visible quand la liste défile.
class _ChannelBand extends StatelessWidget {
  const _ChannelBand({required this.channel});

  final Channel channel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          if (channel.orderNum > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '.${channel.orderNum}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSecondaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              channel.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le détail : bandeau de chaîne, onglets de jours, puis les programmes du
/// jour en lignes de table.
class _ReplayDayView extends StatefulWidget {
  const _ReplayDayView({required this.channel, required this.items});

  final Channel channel;
  final List<ReplayItem> items;

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

    // Ordre chronologique ASCENDANT : la journée se lit comme une grille TV,
    // de 00:00 en haut à 23:59 en bas. L'ordre inverse (20:50, 20:45, 20:00…)
    // imposait de remonter la liste pour suivre l'heure.
    final sorted = [...widget.items]..sort(
        (a, b) => (a.startAt ?? a.startDate ?? DateTime(1900))
            .compareTo(b.startAt ?? b.startDate ?? DateTime(1900)),
      );

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
      // Le bandeau reste affiché même sans programme : c'est lui qui dit de
      // quelle chaîne il s'agit, et l'utilisateur vient de choisir cette
      // chaîne. Le faire disparaître avec la liste rendait l'écran vide sans
      // sujet.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChannelBand(channel: widget.channel),
          const Divider(height: 1),
          Expanded(child: _noProgram(theme, scheme)),
        ],
      );
    }

    // Le jour le plus récent reste le jour affiché par défaut (c'est le cas
    // d'usage dominant), mais les onglets se lisent de gauche à droite dans le
    // sens du temps : le plus ancien à gauche, aujourd'hui à droite. L'ordre
    // inverse — aujourd'hui, hier, avant-hier — se lisait à l'envers.
    final newestFirst = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final active = newestFirst.contains(_selectedDay)
        ? _selectedDay!
        : newestFirst.first;
    final tabs = newestFirst.reversed.toList(growable: false);
    final items = byDay[active] ?? const <ReplayItem>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Bandeau de chaîne ──────────────────────────────────────────────
        _ChannelBand(channel: widget.channel),
        const Divider(height: 1),
        // ── Onglets de jours ─────────────────────────────────────────────
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final day = tabs[i];
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
        // ── Lignes du jour sélectionné ───────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: items.length,
            // Un filet entre les lignes : la lecture est verticale et continue,
            // comme les bandes de la grille des programmes.
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _ReplaySlotRow(
              slot: items[i],
              dayStamp: _stampPrefix(active),
            ),
          ),
        ),
      ],
    );
  }

  /// Préfixe de date commun à toutes les lignes d'un même jour : « sept. 12 ».
  String _stampPrefix(DateTime day) => '${day.day} ${_months[day.month - 1]}';

  /// Message quand la chaîne n'a rien de rejouable.
  ///
  /// Les deux causes sont distinguées dans le texte : soit le panel ne publie
  /// rien pour cette chaîne, soit la fenêtre du compte ne couvre pas ce
  /// programme. Un « aucun replay » nu ne permettait aucune de ces réponses.
  Widget _noProgram(ThemeData theme, ColorScheme scheme) {
    final days = widget.channel.archiveDays;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.replay_rounded, size: 48, color: scheme.outline),
            const SizedBox(height: 12),
            Text('Aucun replay disponible', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              days > 0
                  ? 'Aucun programme déjà diffusé dans les $days jours '
                      'd\'archives de ce compte pour cette chaîne.'
                  : 'Le panel ne publie aucun programme déjà diffusé pour cette '
                      'chaîne.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
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

/// Une ligne de la table : titre, intervalle daté, description.
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
      // Ligne de table : ni carte ni ombre. Le relief faisait lire ces
      // programmes comme des objets empilés, alors que la maquette les veut en
      // bandes successives.
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _play(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre d'abord, puis l'intervalle : l'ordre de la maquette.
                // L'inverser donnait l'horaire comme une ligne d'en-tête et le
                // titre comme une légende.
                Text(
                  slot.title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  _range,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
          'Ce groupe ne contient aucune chaîne rejouable.',
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
