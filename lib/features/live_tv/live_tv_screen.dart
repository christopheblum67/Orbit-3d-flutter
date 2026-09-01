import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/channel.dart';
import '../../providers/providers.dart';
import '../../core/widgets/tv_focus.dart';
import '../../core/widgets/widgets.dart';
import '../../services/stream_prewarm_service.dart';
import '../../services/user_friendly_error.dart';
import '../player/player_screen.dart';
import 'channel_groups.dart';

class LiveTvScreen extends ConsumerWidget {
  const LiveTvScreen({super.key});

  static String _refererFor(Uri uri) {
    final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
    return '${uri.scheme}://${uri.host}:$port/';
  }

  static Map<String, String> _httpHeadersFor(String url) {
    final uri = Uri.parse(url);
    return {
      'User-Agent':
          'Orbit3D/1.0 (Linux; Android 14; FireTV) ExoPlayerLib/2.19.1',
      'Accept': '*/*',
      'Referer': _refererFor(uri),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          final useHeaders = groups.length > 1 || groups.first.name.isNotEmpty;
          final rows = useHeaders ? _flattenGroups(groups) : _flatRows(groups.first.channels);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            itemBuilder: (context, index) => _buildRow(
              context,
              rows[index],
              showGroupName: !useHeaders,
              groups: groups,
            ),
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

  List<_Row> _flattenGroups(List<ChannelGroup> groups) {
    final rows = <_Row>[];
    for (final group in groups) {
      if (group.name.isNotEmpty) {
        rows.add(_Row.header(group.name, group.channels.length));
      }
      for (final channel in group.channels) {
        rows.add(_Row.channel(channel));
      }
    }
    return rows;
  }

  List<_Row> _flatRows(List<Channel> channels) {
    return [for (final channel in channels) _Row.channel(channel)];
  }

  Widget _buildRow(
    BuildContext context,
    _Row row, {
    required bool showGroupName,
    required List<ChannelGroup> groups,
  }) {
    if (row.channel == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: SectionHeader(
          icon: Icons.live_tv_outlined,
          title: row.title!,
          subtitle: '${row.count} chaînes',
        ),
      );
    }
    final channel = row.channel!;
    void prewarm() =>
        StreamPrewarmService.instance.prewarm(
          channel.streamUrl,
          _httpHeadersFor(channel.streamUrl),
        );
    void onOpen() {
      prewarm();
      _openPlayer(context, groups, channel);
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
          trailing: channel.orderNum > 0 ? _NumBadge(number: channel.orderNum) : null,
          onTap: onOpen,
        ),
      ),
    );
  }
void _openPlayer(
    BuildContext context,
    List<ChannelGroup> groups,
    Channel channel,
  ) {
    var groupIndex = -1;
    for (var i = 0; i < groups.length; i++) {
      if (groups[i].channels.contains(channel)) {
        groupIndex = i;
        break;
      }
    }
    final list = groupIndex >= 0 ? groups[groupIndex].channels : <Channel>[channel];
    final index = list.indexOf(channel);
    context.push(
      '/player',
      extra: PlayerRouteData(
        streamUrl: channel.streamUrl,
        title: channel.name,
        channels: list,
        index: index,
      ),
    );
  }
}

class _Row {
  _Row.header(this.title, this.count) : channel = null;

  _Row.channel(this.channel) : title = null, count = 0;

  final String? title;
  final int count;
  final Channel? channel;
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