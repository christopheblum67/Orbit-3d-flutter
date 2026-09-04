import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/epg_models.dart';
import 'package:orbit_3d_flutter/core/widgets/error_state.dart';
import 'package:orbit_3d_flutter/core/widgets/loading_state.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_grid_2d_view.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/favorites_orbit_system_3d.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/orbit_planet_node.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/nebula_search_space.dart';
import 'package:orbit_3d_flutter/services/favorites_service.dart';

/// Provider pour les favoris
final favoritesListProvider = FutureProvider.autoDispose.family<List<FavoriteChannelNode>, String>((ref, type) async {
    final service = ref.watch(favoritesServiceProvider);
    await service.getFavorites(type);
    return <FavoriteChannelNode>[];
  });

class EpgScreen extends ConsumerStatefulWidget {
  const EpgScreen({super.key});

  @override
  ConsumerState<EpgScreen> createState() => _EpgScreenState();
}

class _EpgScreenState extends ConsumerState<EpgScreen> with SingleTickerProviderStateMixin {
  late TabController _viewTabController;

  @override
  void initState() {
    super.initState();
    _viewTabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _viewTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide TV (EPG)'),
        bottom: TabBar(
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view), text: 'Grille 2D'),
            Tab(icon: Icon(Icons.public), text: 'Orbite 3D'),
            Tab(icon: Icon(Icons.favorite), text: 'Favoris'),
            Tab(icon: Icon(Icons.search), text: 'Recherche'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _buildGrid2DTab(),
          _buildOrbit3DTab(),
          _buildFavoritesOrbitTab(),
          _buildNebulaSearchTab(),
        ],
      ),
    );
  }

  Widget _buildGrid2DTab() {
    final channelsAsync = ref.watch(liveChannelsProvider);

    return channelsAsync.when(
      data: (channels) {
        if (channels.isEmpty) {
          return const Center(child: Text('Aucune chaîne disponible'));
        }
        return _EpgGrid2DWrapper(
          channels: channels.map((c) => c.name).toList(),
          channelObjects: channels,
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

  Widget _buildOrbit3DTab() {
    final channelsAsync = ref.watch(liveChannelsProvider);

    return channelsAsync.when(
      data: (channels) {
        if (channels.isEmpty) {
          return const Center(child: Text('Aucune chaîne disponible'));
        }
        return _Orbit3DView(channels: channels);
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

  Widget _buildFavoritesOrbitTab() {
    final favoritesAsync = ref.watch(favoritesListProvider('channel'));

    return favoritesAsync.when(
      data: (favoriteNodes) {
        if (favoriteNodes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_outline, size: 64, color: Colors.white38),
                SizedBox(height: 16),
                Text('Aucun favori enregistré', style: TextStyle(color: Colors.white38, fontSize: 16)),
                SizedBox(height: 8),
                Text('Appuyez longuement sur une chaîne pour l\'ajouter', style: TextStyle(color: Colors.white24, fontSize: 12)),
              ],
            ),
          );
        }

        return FavoritesOrbitSystem3D(
          favorites: favoriteNodes,
          onZoomOutToCategories: () {},
          onSelectChannel: (node) {
            final channels = ref.read(liveChannelsProvider).valueOrNull;
            if (channels != null) {
              final channel = channels.firstWhere((c) => c.name == node.name, orElse: () => channels.first);
              Navigator.pushNamed(
                context,
                '/player',
                arguments: {
                  'streamUrl': channel.streamUrl,
                  'title': channel.name,
                  'contentType': 'live',
                },
              );
            }
          },
        );
      },
      loading: () => const LoadingState(message: 'Chargement des favoris…'),
      error: (err, _) => ErrorState(
        icon: Icons.favorite_outline,
        title: 'Favoris indisponibles',
        message: 'Impossible de charger les favoris.',
        onRetry: () => ref.invalidate(favoritesListProvider('channel')),
      ),
    );
  }

  Widget _buildNebulaSearchTab() {
    return _NebulaSearchTab();
  }
}

/// Wrapper pour la grille 2D avec chargement EPG par chaîne
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
  final Map<String, List<EPGProgram>> _epgData = {}; // EPGProgram from epg_program.dart
  final Set<String> _loadingChannels = {};

  @override
  void initState() {
    super.initState();
    _loadAllEpg();
  }

  Future<void> _loadAllEpg() async {
    for (final channelName in widget.channels) {
      if (!_loadingChannels.contains(channelName)) {
        _loadingChannels.add(channelName);
        final channel = widget.channelObjects.firstWhere((c) => c.name == channelName);
        if (channel.epgChannelId.isNotEmpty) {
          try {
            final programs = await ref.read(channelEpgProvider(channel.epgChannelId).future);
            if (mounted) {
              setState(() {
                _epgData[channelName] = programs;
              });
            }
          } catch (_) {}
        }
        _loadingChannels.remove(channelName);
      }
    }
    if (mounted) setState(() {});
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
          final channel = widget.channelObjects.firstWhere((c) => c.name == channelName);
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
            Text(program.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('${_formatTime(program.start)} - ${_formatTime(program.end)}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
            if (program.description != null) ...[
              const SizedBox(height: 16),
              Text(program.description!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: FilledButton.icon(icon: const Icon(Icons.play_arrow), label: const Text('Regarder'), onPressed: () { Navigator.pop(context); })),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

/// Vue 3D Orbite des chaînes
class _Orbit3DView extends ConsumerStatefulWidget {
  final List<Channel> channels;

  const _Orbit3DView({super.key, required this.channels});

  @override
  ConsumerState<_Orbit3DView> createState() => _Orbit3DViewState();
}

class _Orbit3DViewState extends ConsumerState<_Orbit3DView> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat(reverse: false);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channels = ref.watch(liveChannelsProvider).valueOrNull ?? [];

    if (channels.isEmpty) {
      return const Center(child: Text('Aucune chaîne disponible'));
    }

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            setState(() => _focusedIndex = (_focusedIndex - 1 + channels.length) % channels.length);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            setState(() => _focusedIndex = (_focusedIndex + 1) % channels.length);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
            _launchChannel(channels[_focusedIndex]);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        color: const Color(0xFF0B0C10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ...List.generate(3, (ring) => Container(
              width: 200.0 + ring * 120.0,
              height: 200.0 + ring * 120.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.15 - ring * 0.03), width: 1),
              ),
            )),
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                final channelsList = ref.watch(liveChannelsProvider).valueOrNull ?? [];
                return Stack(
                  alignment: Alignment.center,
                  children: List.generate(channelsList.length, (index) {
                    final channel = channelsList[index];
                    final isFocused = index == _focusedIndex;
                    final angleStep = (2 * math.pi) / channelsList.length;
                    final currentAngle = (angleStep * index) + (_rotationController.value * 2 * math.pi);

                    final radius = 120.0 + (index % 3) * 80.0;
                    final x = radius * math.cos(currentAngle);
                    final y = radius * math.sin(currentAngle);

                    return Transform.translate(
                      offset: Offset(x, y),
                      child: OrbitPlanetNode(
                        planet: OrbitChannelPlanet.fromChannel(
                          channel,
                          preference: 0.5 + (index % 3) * 0.2,
                          currentProgram: 'Programme en cours',
                          progress: 0.3 + (index % 4) * 0.2,
                        ),
                        angleRadians: currentAngle,
                        baseRadius: 150.0,
                        isFocused: isFocused,
                        onTap: () => _launchChannel(channel),
                      ),
                    );
                  }),
                );
              },
            ),

            GestureDetector(
              onTap: () => _launchChannel(channels[_focusedIndex]),
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF00CFE8)]),
                  boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5)],
                ),
                child: Center(child: Text(channels[_focusedIndex].name.substring(0, math.min(3, channels[_focusedIndex].name.length)), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
              ),
            ),

            Positioned(
              bottom: 60,
              child: Column(
                children: [
                  Text(channels[_focusedIndex].name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF8B5CF6))),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.keyboard_arrow_left, color: Colors.white38), SizedBox(width: 8),
                      Icon(Icons.keyboard_arrow_right, color: Colors.white38), SizedBox(width: 16),
                      Text('← → Naviguer  ·  OK Lancer', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchChannel(Channel channel) {
    Navigator.pushNamed(context, '/player', arguments: {'streamUrl': channel.streamUrl, 'title': channel.name, 'contentType': 'live'});
  }
}

/// Onglet recherche nébuleuse
class _NebulaSearchTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NebulaSearchTab> createState() => _NebulaSearchTabState();
}

class _NebulaSearchTabState extends ConsumerState<_NebulaSearchTab> {
  final TextEditingController _searchController = TextEditingController();
  List<NebulaSearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) { setState(() => _searchResults = []); return; }
    setState(() => _isSearching = true);

    final channels = ref.read(liveChannelsProvider).valueOrNull ?? [];
    final movies = ref.read(moviesProvider).valueOrNull ?? [];
    final series = ref.read(seriesProvider).valueOrNull ?? [];

    final results = <NebulaSearchResult>[];
    final lowerQuery = query.toLowerCase();

    for (final ch in channels) {
      if (ch.name.toLowerCase().contains(lowerQuery)) {
        results.add(NebulaSearchResult(title: ch.name, type: 'Live', relevanceScore: 1.0));
      }
    }
    for (final m in movies) {
      if (m.title.toLowerCase().contains(lowerQuery)) {
        results.add(NebulaSearchResult(title: m.title, type: 'VOD', relevanceScore: 0.9));
      }
    }
    for (final s in series) {
      if (s.title.toLowerCase().contains(lowerQuery)) {
        results.add(NebulaSearchResult(title: s.title, type: 'Séries', relevanceScore: 0.8));
      }
    }
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    if (mounted) setState(() { _searchResults = results.take(20).toList(); _isSearching = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: TextField(
        controller: _searchController, style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Rechercher une chaîne, un film, une série...', hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          suffixIcon: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6))) : IconButton(icon: const Icon(Icons.mic, color: Color(0xFF8B5CF6)), onPressed: () {}),
          filled: true, fillColor: const Color(0xFF16181E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2)),
        ),
        onChanged: (value) { Future.delayed(const Duration(milliseconds: 300), () { if (_searchController.text == value) _performSearch(value); }); },
      )),
      Expanded(child: NebulaSearchSpace(searchQuery: _searchController.text, results: _searchResults, onResultTap: (result) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Navigation vers ${result.title} (${result.type})')));
      })),
    ]);
  }
}