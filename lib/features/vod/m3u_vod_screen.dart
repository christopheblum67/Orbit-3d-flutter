import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Écran VOD pour les playlists M3U (films + séries détectés automatiquement)
class M3uVodScreen extends ConsumerStatefulWidget {
  const M3uVodScreen({super.key});

  @override
  ConsumerState<M3uVodScreen> createState() => _M3uVodScreenState();
}

class _M3uVodScreenState extends ConsumerState<M3uVodScreen> {
  String _selectedTab = 'films'; // 'films', 'series', 'all'
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sub = ref.watch(activeSubscriptionProvider);

    // Pour M3U uniquement
    if (sub == null || sub.type != SubscriptionType.m3u) {
      return Scaffold(
        appBar: AppBar(title: const Text('VOD M3U')),
        body: const Center(child: Text('Abonnement M3U requis')),
      );
    }

    final vodAsync = ref.watch(vodChannelsProvider);
    final seriesAsync = ref.watch(seriesChannelsProvider);
    final moviesAsync = ref.watch(movieChannelsProvider);

    // Filtre local par recherche
    List<Channel> filterList(List<Channel> source) {
      if (_query.isEmpty) return source;
      final q = _query.toLowerCase();
      return source.where((c) => c.name.toLowerCase().contains(q)).toList();
    }

    final vodList = filterList(vodAsync.value ?? const <Channel>[]);
    final seriesList = filterList(seriesAsync.value ?? const <Channel>[]);
    final moviesList = filterList(moviesAsync.value ?? const <Channel>[]);

    final currentList = switch (_selectedTab) {
      'films' => moviesList,
      'series' => seriesList,
      _ => vodList,
    };

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Retour',
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text('VOD M3U'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TvFocus(
            onFocusChange: (hasFocus) {},
            child: TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Tout (${vodList.length})'),
                Tab(text: 'Films (${moviesList.length})'),
                Tab(text: 'Séries (${seriesList.length})'),
              ],
              onTap: (index) {
                setState(() {
                  _selectedTab = switch (index) {
                    0 => 'all',
                    1 => 'films',
                    _ => 'series',
                  };
                });
              },
            ),
          ),
        ),
      ),
      body: vodAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur: $e')),
        data: (_) {
          if (currentList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_outlined, size: 64, color: Colors.white38),
                  const SizedBox(height: 16),
                  Text(
                    _query.isEmpty ? 'Aucun contenu VOD détecté' : 'Aucun résultat pour "$_query"',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Barre de recherche
              Padding(
                padding: const EdgeInsets.all(16),
                child: TvFocus(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                  ),
                ),
              ),
              // Grille de contenu
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: currentList.length,
                  itemBuilder: (context, index) {
                    final channel = currentList[index];
                    return _M3uVodTile(
                      channel: channel,
                      onTap: () => _openDetail(channel),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openDetail(Channel channel) {
    context.push('/m3u-vod/detail', extra: channel);
  }
}

/// Tuile VOD pour chaîne M3U
class _M3uVodTile extends StatelessWidget {
  const _M3uVodTile({required this.channel, required this.onTap});

  final Channel channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSeries = channel.categoryId == 'series';

    return TvFocus(
      onActivate: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster / Image
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: scheme.surfaceContainerHighest,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: channel.logoUrl.isNotEmpty
                      ? Image.network(
                          channel.logoUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(context, isSeries),
                        )
                      : _buildPlaceholder(context, isSeries),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Titre
            Text(
              channel.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
            ),
            // Badge série/film
            if (isSeries)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'SÉRIE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, bool isSeries) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          isSeries ? Icons.tv_outlined : Icons.movie_outlined,
          size: 48,
          color: Colors.white38,
        ),
      ),
    );
  }
}

/// Écran de détail pour un contenu VOD M3U
class M3uVodDetailScreen extends ConsumerWidget {
  const M3uVodDetailScreen({super.key, required this.channel});

  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSeries = channel.categoryId == 'series' ||
        channel.name.toLowerCase().contains('saison') ||
        channel.name.toLowerCase().contains('episode') ||
        channel.name.toLowerCase().contains('série');

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? TvFocus(
                onActivate: () => context.pop(),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Retour',
                  onPressed: () => context.pop(),
                ),
              )
            : null,
        title: Text(channel.name),
        actions: [
          TvFocus(
            onActivate: () => _playChannel(context, channel),
            child: IconButton(
              icon: const Icon(Icons.play_arrow_rounded),
              tooltip: 'Lire',
              onPressed: () => _playChannel(context, channel),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster + infos principales
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: channel.logoUrl.isNotEmpty
                      ? Image.network(
                          channel.logoUrl,
                          width: 180,
                          height: 270,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(context, isSeries, 180, 270),
                        )
                      : _buildPlaceholder(context, isSeries, 180, 270),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (channel.group.isNotEmpty) ...[
                        _InfoChip(label: 'Groupe', value: channel.group),
                        const SizedBox(height: 4),
                      ],
                      _InfoChip(label: 'Catégorie', value: channel.categoryId),
                      const SizedBox(height: 4),
                      if (isSeries)
                        _InfoChip(
                          label: 'Type',
                          value: 'Série',
                          color: Colors.blueAccent,
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Lancer la lecture'),
                          onPressed: () => _playChannel(context, channel),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // URL du flux (copiable)
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'URL du flux',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(
              channel.streamUrl,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontFamily: 'monospace',
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _playChannel(BuildContext context, Channel channel) {
    context.push('/player', extra: channel);
  }

  Widget _buildPlaceholder(BuildContext context, bool isSeries, [double width = 180, double height = 270]) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          isSeries ? Icons.tv_outlined : Icons.movie_outlined,
          size: 64,
          color: Colors.white38,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color ?? Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}