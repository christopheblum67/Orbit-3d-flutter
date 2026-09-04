import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;
import 'package:orbit_3d_flutter/services/stream_prewarm_service.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/features/live_tv/channel_groups.dart';

class LiveTvScreen extends ConsumerStatefulWidget {
  const LiveTvScreen({super.key});

  @override
  ConsumerState<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends ConsumerState<LiveTvScreen> {
  String _selectedGroup = '';

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(liveChannelsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Live TV')),
      body: channelsAsync.when(
        data: (channels) {
          if (channels.isEmpty) {
            return const EmptyState(
              icon: Icons.live_tv_outlined,
              title: 'Aucune chaîne disponible',
              message: 'Ajoute une source de chaînes dans les réglages.',
            );
          }
          final groups = buildLiveChannelGroups(channels);
          final grouped = groups.length > 1 || groups.first.name.isNotEmpty;
          final categoryGroups = _groupToCategories(groups);

          final List<Channel> visibleChannels;
          if (!grouped) {
            visibleChannels = groups.first.channels;
          } else if (_selectedGroup.isEmpty) {
            visibleChannels = [
              for (final g in groups) ...g.channels,
            ];
          } else if (_selectedGroup.startsWith('g')) {
            final index = int.tryParse(_selectedGroup.substring(1));
            visibleChannels = (index != null && index >= 0 && index < groups.length)
                ? groups[index].channels
                : const [];
          } else {
            visibleChannels = const [];
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (grouped && categoryGroups.isNotEmpty)
                CategoriesRail(
                  categories: categoryGroups,
                  selectedId: _selectedGroup,
                  onSelected: (id) =>
                      setState(() => _selectedGroup = id),
                ),
              Expanded(
                child: visibleChannels.isEmpty
                    ? const EmptyState(
                        icon: Icons.live_tv_outlined,
                        title: 'Aucune chaîne dans ce groupe',
                        message: 'Ce groupe ne contient aucune chaîne.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: visibleChannels.length,
                        itemBuilder: (context, index) => _buildRow(
                          groups,
                          visibleChannels[index],
                          showGroupName: !grouped,
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const LoadingState(message: 'Chargement…'),
        error: (err, _) => ErrorState(
          icon: Icons.live_tv_outlined,
          title: 'Chaînes indisponibles',
          message: userFriendlyError(err),
          onRetry: () => ref.invalidate(liveChannelsProvider),
        ),
      ),
    );
  }

  static List<MediaCategory> _groupToCategories(List<ChannelGroup> groups) {
    final categories = <MediaCategory>[
      const MediaCategory(id: '', name: 'Tous'),
      for (var i = 0; i < groups.length; i++)
        MediaCategory(
          id: 'g$i',
          name: groups[i].name.isEmpty ? 'Non groupé' : groups[i].name,
        ),
    ];
    return categories;
  }

  Widget _buildRow(
    List<ChannelGroup> groups,
    Channel channel, {
    required bool showGroupName,
  }) {
    void prewarm() => StreamPrewarmService.instance.prewarm(
          channel.streamUrl,
          stream_helpers.streamHeaders(channel.streamUrl),
        );
    void onOpen() {
      prewarm();
      _openPlayer(groups, channel);
    }

    final subtitle = showGroupName && channel.groupLabel.isNotEmpty
        ? channel.groupLabel
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TvFocus(
        onActivate: onOpen,
        onFocusChange: (focused) {
          if (focused) prewarm();
        },
        child: ChannelTile(
          title: channel.name,
          subtitle: subtitle,
          icon: Icons.live_tv,
          imageUrl: channel.logoUrl,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (channel.orderNum > 0) _NumBadge(number: channel.orderNum),
              FavoriteButton(channelId: channel.id, channelName: channel.name),
            ],
          ),
          onTap: onOpen,
        ),
      ),
    );
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
      ),
    );
  }
}

class _NumBadge extends StatelessWidget {
  const _NumBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$number',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class FavoriteButton extends ConsumerStatefulWidget {
  const FavoriteButton({
    super.key,
    required this.channelId,
    required this.channelName,
  });

  final String channelId;
  final String channelName;

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton> {
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = ref.read(favoritesServiceProvider);
    final result = await svc.isFavorite('channel', widget.channelId);
    if (mounted) setState(() => _isFav = result);
  }

  @override
  Widget build(BuildContext context) {
    final svc = ref.read(favoritesServiceProvider);
    return IconButton(
      tooltip: _isFav ? 'Retirer des favoris' : 'Ajouter aux favoris',
      icon: Icon(
        _isFav ? Icons.favorite : Icons.favorite_border,
        color: _isFav ? Theme.of(context).colorScheme.error : null,
      ),
      onPressed: () async {
        if (_isFav) {
          await svc.removeFavorite('channel', widget.channelId);
        } else {
          await svc.addFavorite('channel', widget.channelId);
        }
        if (mounted) setState(() => _isFav = !_isFav);
      },
    );
  }
}
