import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/orbit_cached_image.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/features/kids/kids_controller.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

class KidsScreen extends ConsumerStatefulWidget {
  const KidsScreen({super.key});

  @override
  ConsumerState<KidsScreen> createState() => _KidsScreenState();
}

class _KidsScreenState extends ConsumerState<KidsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final profile = ref.watch(currentProfileProvider);
    final isChild = profile?.isChild ?? false;

    if (!isChild) {
      return _buildNotChildMode(context);
    }

    final controller = ref.read(kidsControllerProvider.notifier);
    final state = ref.watch(kidsControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0E1117),
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Retour',
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(l.kidsMode),
        backgroundColor: const Color(0xFF1A1F2E),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.tv_rounded), text: 'Chaînes'),
            Tab(icon: Icon(Icons.movie_outlined), text: 'Films'),
            Tab(icon: Icon(Icons.video_library_rounded), text: 'Séries'),
            Tab(icon: Icon(Icons.replay_rounded), text: 'Replay'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChannelsTab(controller, state),
          _buildMoviesTab(controller, state),
          _buildSeriesTab(controller, state),
          _buildReplayTab(controller, state),
        ],
      ),
    );
  }

  Widget _buildNotChildMode(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0E1117),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.child_care_rounded, size: 80, color: Colors.blue.shade300),
              const SizedBox(height: 16),
              const Text(
                'Mode Enfants',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ce mode est accessible uniquement avec un profil Enfant.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/profile/create'),
                icon: const Icon(Icons.person_add_rounded),
                label: Text(l.createKidProfile),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelsTab(KidsController controller, KidsState state) {
    final l = AppLocalizations.of(context);
    return state.channelsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        icon: Icons.tv_rounded,
        title: l.channelsUnavailable,
        message: e.toString(),
        onRetry: controller.loadChannels,
      ),
      data: (channels) {
        if (channels.isEmpty) {
          return EmptyState(
            icon: Icons.tv_rounded,
            title: l.noKidsChannels,
            message: 'Aucune chaîne ne correspond aux filtres de sécurité.',
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            childAspectRatio: 1.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final channel = channels[index];
            return TvFocus(
              onActivate: () => _openChannel(context, channel),
              child: _ChannelCard(channel: channel),
            );
          },
        );
      },
    );
  }

  Widget _buildMoviesTab(KidsController controller, KidsState state) {
    final l = AppLocalizations.of(context);
    return state.moviesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        icon: Icons.movie_outlined,
        title: l.moviesUnavailable,
        message: e.toString(),
        onRetry: controller.loadMovies,
      ),
      data: (movies) {
        if (movies.isEmpty) {
          return EmptyState(
            icon: Icons.movie_outlined,
            title: l.noKidsMovies,
            message: 'Aucun film ne correspond aux filtres de sécurité.',
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            childAspectRatio: 0.55,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: movies.length,
          itemBuilder: (context, index) {
            final movie = movies[index];
            return TvFocus(
              onActivate: () => _openMovie(context, movie),
              child: _KidsMovieCard(movie: movie),
            );
          },
        );
      },
    );
  }

  Widget _buildSeriesTab(KidsController controller, KidsState state) {
    final l = AppLocalizations.of(context);
    return state.seriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        icon: Icons.video_library_rounded,
        title: l.seriesUnavailable,
        message: e.toString(),
        onRetry: controller.loadSeries,
      ),
      data: (series) {
        if (series.isEmpty) {
          return EmptyState(
            icon: Icons.video_library_rounded,
            title: l.noKidsSeries,
            message: 'Aucune série ne correspond aux filtres de sécurité.',
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            childAspectRatio: 0.55,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: series.length,
          itemBuilder: (context, index) {
            final s = series[index];
            return TvFocus(
              onActivate: () => _openSeries(context, s),
              child: _KidsSeriesCard(series: s),
            );
          },
        );
      },
    );
  }

  Widget _buildReplayTab(KidsController controller, KidsState state) {
    final l = AppLocalizations.of(context);
    return state.replaysAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        icon: Icons.replay_rounded,
        title: l.replaysUnavailable,
        message: e.toString(),
        onRetry: controller.loadReplays,
      ),
      data: (replays) {
        if (replays.isEmpty) {
          return EmptyState(
            icon: Icons.replay_rounded,
            title: l.noKidsReplays,
            message: 'Aucun replay ne correspond aux filtres de sécurité.',
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            childAspectRatio: 1.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: replays.length,
          itemBuilder: (context, index) {
            final replay = replays[index];
            return TvFocus(
              onActivate: () => _openReplay(context, replay),
              child: _ReplayCard(replay: replay),
            );
          },
        );
      },
    );
  }

  void _openChannel(BuildContext context, Channel channel) {
    context.go('/player', extra: {
      'url': channel.streamUrl,
      'title': channel.name,
      'type': 'live',
    });
  }

  void _openMovie(BuildContext context, Movie movie) {
    context.go('/vod/detail', extra: movie);
  }

  void _openSeries(BuildContext context, Series series) {
    context.go('/series/detail', extra: series);
  }

  void _openReplay(BuildContext context, ReplayItem replay) {
    context.go('/player', extra: {
      'url': replay.streamUrl,
      'title': replay.title,
      'type': 'replay',
    });
  }
}

class _ChannelCard extends StatelessWidget {
  final Channel channel;

  const _ChannelCard({required this.channel});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          channel.logoUrl.isNotEmpty
              ? OrbitCachedImage(
                  imageUrl: channel.logoUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _Placeholder(scheme: scheme),
                  errorWidget: (_, __, ___) => _Placeholder(scheme: scheme),
                )
              : _Placeholder(scheme: scheme),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Text(
              channel.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KidsMovieCard extends StatelessWidget {
  final Movie movie;

  const _KidsMovieCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                movie.posterUrl.isNotEmpty
                    ? OrbitCachedImage(
                        imageUrl: movie.posterUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _Placeholder(scheme: scheme, icon: Icons.movie_outlined),
                        errorWidget: (_, __, ___) => _Placeholder(scheme: scheme, icon: Icons.movie_outlined),
                      )
                    : _Placeholder(scheme: scheme, icon: Icons.movie_outlined),
                if (movie.pegiLabel?.isNotEmpty == true)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        movie.pegiLabel!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                if (movie.year > 0 || movie.genre.isNotEmpty)
                  Text(
                    [if (movie.year > 0) '${movie.year}', if (movie.genre.isNotEmpty) movie.genre].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KidsSeriesCard extends StatelessWidget {
  final Series series;

  const _KidsSeriesCard({required this.series});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                series.coverUrl.isNotEmpty
                    ? OrbitCachedImage(
                        imageUrl: series.coverUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _Placeholder(scheme: scheme, icon: Icons.video_library_outlined),
                        errorWidget: (_, __, ___) => _Placeholder(scheme: scheme, icon: Icons.video_library_outlined),
                      )
                    : _Placeholder(scheme: scheme, icon: Icons.video_library_outlined),
                if (series.pegiLabel?.isNotEmpty == true)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        series.pegiLabel!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  series.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                if (series.year > 0 || series.genre.isNotEmpty)
                  Text(
                    [if (series.year > 0) '${series.year}', if (series.genre.isNotEmpty) series.genre].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplayCard extends StatelessWidget {
  final ReplayItem replay;

  const _ReplayCard({required this.replay});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Placeholder(scheme: scheme),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  replay.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${replay.startTime} - ${replay.endTime}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final ColorScheme scheme;
  final IconData? icon;

  const _Placeholder({required this.scheme, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.tertiaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(icon ?? Icons.tv, size: 44, color: scheme.primary),
    );
  }
}